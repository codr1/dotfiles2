#!/bin/bash
# One-shot installer for the dotfiles2 power-management stack.
# Idempotent — chezmoi will only run this on a fresh machine (and after
# the script content changes), so repeat invocations are not the common
# case, but the operations below all tolerate being re-run.
#
# What it does:
#   1. Install required packages (swayidle, thermald) if missing.
#   2. Enable & start system services: power-profiles-daemon, thermald.
#   3. Enable & start user services: swayidle, auto-power-profile.timer.
#   4. Drop in a UPower override so critical-battery (≤2%) SUSPENDS
#      instead of shutting down. Default UPower behavior on systems with
#      no disk swap is PowerOff (the "Auto" fallback when hibernate is
#      unavailable + AllowRiskyCriticalPowerAction=false). On a laptop
#      where s2idle is reliable, suspend is the user-friendlier choice.
#
# Bare-metal only — gated by chezmoi via .chezmoiignore on non-bare-metal
# profiles.

set -euo pipefail

# Skip on profiles that don't have any battery / lid concept.
if ! [ -d /sys/class/power_supply/BAT0 ]; then
    echo "No battery detected — skipping power stack install."
    exit 0
fi

need_sudo() { sudo -v >/dev/null 2>&1 || sudo true; }

# ---- 1. Packages ----------------------------------------------------------
# Skip thermald on platforms that ship their own thermal controller.
# Lenovo ThinkPads with DYTC (Dynamic Thermal Control) expose
# /sys/devices/platform/thinkpad_acpi/dytc_lapmode; thermald detects this
# and refuses to run, so installing it is pointless on those machines.
want_thermald=1
if [ -e /sys/devices/platform/thinkpad_acpi/dytc_lapmode ]; then
    echo "Detected Lenovo DYTC platform thermal controller — skipping thermald."
    want_thermald=0
fi

missing=( swayidle )
(( want_thermald )) && missing+=( thermald )
to_install=()
for pkg in "${missing[@]}"; do
    pacman -Q "$pkg" >/dev/null 2>&1 || to_install+=("$pkg")
done
if (( ${#to_install[@]} )); then
    echo ">>> installing: ${to_install[*]}"
    need_sudo
    sudo pacman -S --needed --noconfirm "${to_install[@]}"
fi

# ---- 2. System services ---------------------------------------------------
need_sudo
(( want_thermald )) && sudo systemctl enable --now thermald.service
sudo systemctl enable power-profiles-daemon.service
# PPD may already be running from session login; only start if inactive
sudo systemctl is-active power-profiles-daemon.service >/dev/null 2>&1 \
    || sudo systemctl start power-profiles-daemon.service

# ---- 3. User services -----------------------------------------------------
systemctl --user daemon-reload
systemctl --user enable --now swayidle.service
systemctl --user enable --now auto-power-profile.timer

# ---- 4. UPower critical action override -----------------------------------
# Use a drop-in rather than editing the shipped config — survives package
# upgrades cleanly.
upower_dir=/etc/UPower/UPower.conf.d
if ! [ -f "$upower_dir/10-critical-suspend.conf" ]; then
    need_sudo
    sudo install -d "$upower_dir"
    sudo tee "$upower_dir/10-critical-suspend.conf" >/dev/null <<'EOF'
# Override: when battery hits PercentageAction (default 2%), suspend
# instead of powering off. Safe on this machine because s2idle is
# reliable and we have no disk swap to hibernate to.
[UPower]
CriticalPowerAction=Suspend
AllowRiskyCriticalPowerAction=true
EOF
    sudo systemctl restart upower.service
fi

echo
echo "Power stack installed."
echo "  systemctl --user status swayidle.service auto-power-profile.timer"
echo "  systemctl status thermald power-profiles-daemon"
