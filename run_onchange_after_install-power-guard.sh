#!/bin/bash
# Installer for the udev-driven battery guard.
#
# Idempotent — chezmoi re-runs this whenever its content hash changes.
# Runs after run_once_after_install-power.sh (`power-guard` sorts after
# `power` alphabetically), so on fresh installs the UPower drop-in
# briefly exists before this script comments it out.
#
# Installs three system files:
#   /usr/local/bin/battery-critical-check              — guard script
#   /etc/systemd/system/battery-critical-check.service — oneshot unit
#   /etc/udev/rules.d/99-battery-warn.rules            — trigger
#
# And disables the UPower critical-suspend drop-in (comments it out; we
# leave the file so we can revive if the guard proves flaky).
#
# Escalation ladder (only while status == Discharging):
#   ≤10%  → warning notification (normal urgency)
#   ≤8%   → critical notification (red border via urgency=critical)
#   ≤5%   → critical notification + systemctl suspend (3s grace)
#
# Bare-metal only — gated by chezmoi via .chezmoiignore on other profiles.

set -euo pipefail

if ! [ -d /sys/class/power_supply/BAT0 ]; then
    echo "No battery detected — skipping power-guard install."
    exit 0
fi

sudo -v >/dev/null 2>&1 || sudo true

# ---- 1. Guard script ------------------------------------------------------
sudo tee /usr/local/bin/battery-critical-check >/dev/null <<'SCRIPT'
#!/bin/bash
# battery-critical-check
#
# Invoked by battery-critical-check.service (a oneshot unit) which is
# kicked off by /etc/udev/rules.d/99-battery-warn.rules on every
# power_supply capacity/status change for BAT0.
#
# Escalates as capacity drops (only while status == Discharging):
#   ≤10%  → "battery low" notification (normal urgency)
#   ≤8%   → CRITICAL notification (red border via urgency=critical)
#   ≤5%   → CRITICAL notification + systemctl suspend (3s grace)
#
# /run/battery-warn.state holds the previous observed capacity so each
# threshold notification fires exactly once per discharge cycle. State
# lives on tmpfs (clears on reboot) and is explicitly cleared here
# whenever status != Discharging.

set -euo pipefail

BAT=/sys/class/power_supply/BAT0
STATE=/run/battery-warn.state
USER_NAME=vess
USER_UID=$(id -u "$USER_NAME")
BUS="unix:path=/run/user/${USER_UID}/bus"
XRD="/run/user/${USER_UID}"

STATUS=$(cat "$BAT/status" 2>/dev/null || echo Unknown)
CAP=$(cat "$BAT/capacity" 2>/dev/null || echo 100)

# Not on battery → reset state and bail. Includes Charging, Full,
# Not charging, Unknown — anything that isn't an active discharge.
if [[ "$STATUS" != "Discharging" ]]; then
    rm -f "$STATE"
    exit 0
fi

# Bad reads happen (rare); fail loudly rather than silently mis-suspend.
if ! [[ "$CAP" =~ ^[0-9]+$ ]]; then
    echo "battery-critical-check: non-numeric capacity: '$CAP'" >&2
    exit 1
fi

notify() {
    local urgency="$1" title="$2" body="$3"
    # Root can't talk to the user's session bus without help. runuser
    # drops privileges and env re-seeds the two vars notify-send needs
    # to reach swaync. Failures here are non-fatal — a missed notification
    # must never block the suspend action below.
    runuser -u "$USER_NAME" -- env \
        DBUS_SESSION_BUS_ADDRESS="$BUS" \
        XDG_RUNTIME_DIR="$XRD" \
        notify-send -u "$urgency" -a battery-guard "$title" "$body" || true
}

prev=$(cat "$STATE" 2>/dev/null || echo 100)

if (( CAP <= 5 )); then
    notify critical "Battery ${CAP}% — suspending in 3s" "Plug in NOW to cancel."
    sleep 3
    # Re-check: user may have plugged in during the grace period.
    if [[ "$(cat "$BAT/status" 2>/dev/null || echo Unknown)" == "Discharging" ]]; then
        /usr/bin/systemctl suspend
    fi
elif (( CAP <= 8 && prev > 8 )); then
    notify critical "Battery critical: ${CAP}%" "Suspend at 5%. Plug in immediately."
elif (( CAP <= 10 && prev > 10 )); then
    notify normal "Battery low: ${CAP}%" "Consider plugging in soon."
fi

echo "$CAP" > "$STATE"
SCRIPT
sudo chmod 755 /usr/local/bin/battery-critical-check

# ---- 2. Systemd unit ------------------------------------------------------
sudo tee /etc/systemd/system/battery-critical-check.service >/dev/null <<'UNIT'
[Unit]
Description=Battery capacity guard — notify or suspend on low battery
Documentation=file:///usr/local/bin/battery-critical-check

[Service]
Type=oneshot
ExecStart=/usr/local/bin/battery-critical-check
UNIT

# ---- 3. Udev rule ---------------------------------------------------------
# Fires on every capacity or status change event for BAT0. The guard
# script is idempotent (state file mediates notification levels), so the
# 1% capacity ticks are cheap.
sudo tee /etc/udev/rules.d/99-battery-warn.rules >/dev/null <<'RULE'
# Kick the battery guard on every BAT0 change event. Using systemctl
# start --no-block means the actual work runs in a separate systemd-
# managed service that survives udev's post-event process cleanup —
# udev would otherwise kill /usr/bin/systemctl suspend before it
# reaches logind.
SUBSYSTEM=="power_supply", KERNEL=="BAT0", ACTION=="change", \
    RUN+="/usr/bin/systemctl start --no-block battery-critical-check.service"
RULE

# ---- 4. Reload systemd + udev --------------------------------------------
sudo systemctl daemon-reload
sudo udevadm control --reload-rules

# ---- 5. Disable UPower drop-in (idempotent) ------------------------------
# We've moved the critical-suspend responsibility to the udev guard.
# Rewrite the drop-in to its commented form so we can revive it later
# if the guard proves flaky.
upower_dropin=/etc/UPower/UPower.conf.d/10-critical-suspend.conf
if [ -f "$upower_dropin" ] && grep -qE '^\[UPower\]' "$upower_dropin"; then
    sudo tee "$upower_dropin" >/dev/null <<'EOF'
# Override: when battery hits PercentageAction (default 2%), suspend
# instead of powering off. Safe on this machine because s2idle is
# reliable and we have no disk swap to hibernate to.
#
# Disabled — the udev-driven battery guard now handles low-battery
# notifications and suspend. To revive: uncomment the three lines below
# and `sudo systemctl restart upower.service`.
#[UPower]
#CriticalPowerAction=Suspend
#AllowRiskyCriticalPowerAction=true
EOF
    sudo systemctl restart upower.service
fi

echo
echo "Battery guard installed."
echo "  Watch events:  udevadm monitor --subsystem-match=power_supply"
echo "  Watch runs:    journalctl -u battery-critical-check.service -f"
echo "  Manual fire:   udevadm trigger --subsystem-match=power_supply --action=change"
