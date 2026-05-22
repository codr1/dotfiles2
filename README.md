# Dotfiles

Cross-machine dotfiles managed with [chezmoi](https://www.chezmoi.io/). Supports WSL, VMs, and bare-metal systems running sway, hyprland, or i3.

## Quick Start

### New Machine

```bash
# Install chezmoi and apply dotfiles in one command
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply codr1/dotfiles2

# Or if chezmoi is already installed
chezmoi init --apply codr1/dotfiles2
```

On first run, chezmoi will auto-detect your environment (WSL/VM/bare-metal) and prompt for confirmation.

### Pull Updates

```bash
chezmoi update
```

## Variables

Set per-machine in `~/.config/chezmoi/chezmoi.toml`:

| Variable | Options | Default | Description |
|----------|---------|---------|-------------|
| `profile` | `wsl`, `vm`, `bare-metal` | auto-detected | Machine type |
| `wm` | `sway`, `hyprland`, `i3` | `sway` | Window manager |
| `theme` | see [Themes](#themes) | `tokyonight-night` | Color scheme for all components |
| `scale` | `1.0`, `1.25`, `1.5`, `2.0` | `1.0` | Display scaling |
| `multimonitor` | `true`, `false` | `false` | Multi-monitor support |
| `terminal` | `foot`, `ghostty` | `ghostty` (foot on WSL) | Terminal emulator |
| `modkey` | `Mod1`, `Mod4` | `Mod4` (Mod1 on WSL) | WM modifier key (Alt vs Super) |
| `starship_languages` | list of languages | `["go","python","nodejs"]` | Language modules to enable in prompt |
| `starship_show_time` | `true`, `false` | `true` | Show time in prompt |
| `starship_hostname_mode` | `always`, `ssh-only`, `never` | `always` | When to show hostname |
| `starship_show_icons` | `true`, `false` | `true` | Show directory icons |
| `starship_theme` | `tokyonight` | `tokyonight` | Prompt color scheme |
| `locales` | list of `locale.gen` lines | `["en_US.UTF-8 UTF-8"]` | Locales to generate (consumed by `setup-locale`) |
| `system_locale` | locale name | `"en_US.UTF-8"` | System `LANG` written to `/etc/locale.conf`; empty = skip |

### Example

```toml
# ~/.config/chezmoi/chezmoi.toml
[data]
    profile = "wsl"
    wm = "sway"
    theme = "catppuccin-mocha"
    scale = 1.0
    multimonitor = false
    terminal = "foot"
    modkey = "Mod1"
    hostname = "Tizona"

    # Starship prompt configuration
    starship_languages = ["go", "python", "nodejs"]
    starship_show_time = true
    starship_hostname_mode = "always"
    starship_show_icons = true
    starship_theme = "tokyonight"
```

## Themes

All desktop components share a centralized theme system. Change `theme` in your chezmoi config and run `chezmoi apply` to update everything at once.

### Available Themes

| Theme | Description |
|-------|-------------|
| `tokyonight-night` | Dark blue theme (default) |
| `tokyonight-storm` | Slightly lighter TokyoNight variant |
| `nord` | Arctic, bluish color palette |
| `catppuccin-mocha` | Warm dark theme with pastel accents |
| `catppuccin-latte` | Light theme with pastel accents |
| `dracula` | Dark theme with vibrant colors |

### Themed Components

The following configs use the theme system:

| Component | File | What's themed |
|-----------|------|---------------|
| Waybar | `style.css.tmpl` | Bar colors, workspace indicators |
| Polybar | `config.ini.tmpl` | Bar colors, module accents |
| Sway/i3 | `config.tmpl` | Window borders (focused, unfocused, urgent) |
| Mako | `private_config.tmpl` | Notification background, text, borders |
| Wofi | `style.css.tmpl` | Launcher colors |
| Swaylock | `config.tmpl` | Lock screen ring and text colors |
| Foot | `private_foot.ini.tmpl` | References theme by name |
| Ghostty | `config.tmpl` | References theme by name |

### Terminal Themes

Foot and Ghostty reference themes by name rather than embedding colors:
- **Foot**: Uses `/usr/share/foot/themes/{theme}` - ensure theme files are installed
- **Ghostty**: Uses built-in themes - theme names may differ slightly (e.g., `TokyoNight` vs `tokyonight-night`)

## Managed Configs

| Config | Templated | Notes |
|--------|-----------|-------|
| `foot/foot.ini` | Yes | Terminal - theme reference |
| `ghostty/config` | Yes | Terminal - theme reference |
| `mako/config` | Yes | Notifications - themed |
| `picom/picom.conf` | No | X11 compositor (i3 only) |
| `polybar/*` | Yes | Status bar for i3 - themed |
| `starship/starship.toml` | Yes | Shell prompt - languages, time, hostname, icons |
| `sway/config` | Yes | WM config for sway and i3 - themed borders |
| `swaylock/config` | Yes | Lock screen - themed (bare-metal only) |
| `waybar/config` | Yes | Status bar for sway - battery/backlight per profile |
| `waybar/style.css` | Yes | Status bar - themed |
| `wofi/*` | Yes | App launcher + power menu - themed |
| `bashrc.d/dotfiles2.sh` | No | Sourced from `~/.bashrc` — adds `~/.local/bin` to PATH, inits starship |
| `local/bin/setup-locale` | Yes | Distro-aware locale generator (Arch/Debian/Fedora) |
| `local/bin/start-sway` | No | sway launcher (WSL only) |
| `local/bin/setup-sway-wsl` | No | One-time host setup helper (WSL only) |
| `local/bin/clipboard-to-win` | No | wl-paste → clip.exe (WSL only) |
| `local/bin/win-to-clipboard` | No | Windows clipboard → wl-copy (WSL only) |
| `systemd/user/win-to-clipboard.service` | No | Runs win-to-clipboard (WSL only) |

### Shell integration

`~/.bashrc` is **not** taken over. Instead, a one-time `run_once_after_*` script
appends a small block to it (idempotent, marker-guarded) that sources every
`~/.bashrc.d/*.sh`. chezmoi manages `~/.bashrc.d/dotfiles2.sh`; you keep your
own `.bashrc` and can drop additional files into `~/.bashrc.d/` at will.

## Profile Differences

| Feature | WSL | VM | Bare-metal |
|---------|-----|-----|------------|
| Mod key | Alt (Mod1) | Super (Mod4) | Super (Mod4) |
| Terminal | foot | ghostty | ghostty |
| Clipboard sync | Yes | No | No |
| Battery module | No | No | Yes |
| Backlight module | No | No | Yes |
| Swaylock | No | No | Yes |

## WSL Setup

When `profile = "wsl"` is detected, chezmoi deploys a small bootstrap toolkit
under `~/.local/bin/` that handles the rough edges of running sway under WSL2 +
WSLg (broken `/tmp/.X11-unix` sticky bit, missing user systemd, clipboard sync).

### One-time host setup

After the first `chezmoi apply`, run:

```bash
sudo ~/.local/bin/setup-sway-wsl
```

This does two things, both of which legitimately require root:

1. **Enables systemd lingering** (`loginctl enable-linger $USER`) so the user
   systemd manager starts at WSL boot, not at sway launch.
2. **Installs a tightly-scoped NOPASSWD sudoers entry** at
   `/etc/sudoers.d/sway-wsl-$USER` covering exactly two commands —
   `umount /tmp/.X11-unix` and `rm -rf /tmp/.X11-unix` — so subsequent
   `start-sway` runs don't prompt.

Idempotent — safe to re-run.

### Launching sway

```bash
start-sway
```

`~/.local/bin/start-sway` sets the right XDG environment, kicks user systemd
if needed, resets `/tmp/.X11-unix` so XWayland will start, and symlinks WSLg's
Wayland socket. Then `exec sway`.

### Why the X11 dance is needed

WSLg bind-mounts `/tmp/.X11-unix` from the Windows side without the sticky bit.
xorg-server's `_XSERVTransUNIXCreateListener` refuses to use the directory
without it (multi-user security check), so XWayland fails to start. Microsoft
has had a fix in PRs since 2023 ([wslg#1137](https://github.com/microsoft/wslg/pull/1137),
[wslg#1422](https://github.com/microsoft/wslg/pull/1422)); not yet merged.
Until it is, `start-sway` reconstructs the directory at launch.

### Clipboard sync

`win-to-clipboard.service` (systemd user unit) watches the Windows clipboard
via a single persistent PowerShell process and pushes changes to wl-copy when
a sway window is focused. The reverse direction is wired via `wl-paste --watch`
calling `clipboard-to-win`, which forwards to `clip.exe`. Sentinel files in
`/tmp` break the copy loop. This works once user systemd is up — i.e., once
you've run `setup-sway-wsl`.

## Locale Setup

Bare-metal installers usually configure the locale during install, but **WSL
distros ship with no locales generated**, and the inherited `LANG` from
Windows immediately breaks (e.g. `en_US.UTF-8` is not generated → C locale
fallback → GTK warnings everywhere).

`~/.local/bin/setup-locale` fixes this in a distro-aware way (Arch, Debian/
Ubuntu, Fedora/RHEL). It reads the `locales` and `system_locale` data fields
from your chezmoi config:

```bash
sudo ~/.local/bin/setup-locale
```

| Family | What it does |
|--------|--------------|
| Arch (incl. Manjaro, EndeavourOS, CachyOS, Garuda, Artix) | Uncomments lines in `/etc/locale.gen`, runs `locale-gen`, writes `/etc/locale.conf` |
| Debian (incl. Ubuntu, Mint, Pop, Kali, Raspbian) | Installs `locales` package if needed, then same as Arch but uses `update-locale` for `/etc/default/locale` |
| Fedora (incl. RHEL, CentOS, Rocky, AlmaLinux, Nobara) | `dnf install glibc-langpack-<lang>` for each locale, writes `/etc/locale.conf` |

Override per-machine in `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
    locales = ["en_US.UTF-8 UTF-8", "ja_JP.UTF-8 UTF-8"]
    system_locale = "ja_JP.UTF-8"
```

Idempotent — safe to re-run. Bare-metal users who already have their locale
set up can skip it entirely.

## Window Manager Support

The `sway/config` file serves both **sway** (Wayland) and **i3** (X11) using chezmoi conditionals. They share ~95% of the same syntax.

### sway vs i3 Differences

| Feature | sway | i3 |
|---------|------|-----|
| Compositor | Built-in | picom (auto-started) |
| Wallpaper | `output * bg` | feh |
| Screenshots | grim/slurp | maim/xclip |
| Lock modifier | `--locked` flag | (none) |
| Status bar | waybar | polybar |
| Exit dialog | swaynag | i3-nagbar |

### i3-specific files

When `wm = "i3"`, these additional configs are deployed:
- `picom/picom.conf` - X11 compositor with rounded corners, opacity, blur
- `polybar/config.ini` - Status bar with themed colors
- `polybar/launch.sh` - Multi-monitor polybar launcher

### Floating Window Rules

Both sway and i3 configs include floating rules for:
- `pavucontrol` - Audio control
- Firefox popups (Sharing Indicator, Picture-in-Picture, About dialog)
- GNOME Control Center
- GNOME Calculator
- Generic Picture-in-Picture windows

Hyprland requires a separate config (different syntax entirely) - not yet implemented.

## Starship Prompt Configuration

The starship prompt is optimized for performance with configurable language detection.

### Performance

**Default languages** (`go`, `python`, `nodejs`) provide a good balance. Each additional language adds:
- Filesystem checks for project markers
- Version command execution
- ~10-50ms per language in large directories

**Available languages:**
- `c`, `cpp`, `lua`, `conda`, `container`, `java`, `rust`, `go`, `php`, `python`, `nodejs`

**Git optimizations:**
- `ignore_submodules = true` - skip submodule scanning
- `command_timeout = 500` - kill slow operations after 500ms

### Customizing Languages

Edit `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
    # Enable only the languages you use
    starship_languages = ["rust", "nodejs", "python"]

    # Or enable everything (slower)
    starship_languages = ["c", "cpp", "lua", "conda", "container", "java", "rust", "go", "php", "python", "nodejs"]
```

Then apply changes:

```bash
chezmoi apply ~/.config/starship/starship.toml
```

### Hostname Modes

- `always` - Show hostname everywhere (default, good for multi-machine workflows)
- `ssh-only` - Show only in SSH sessions (recommended for single-machine use)
- `never` - Never show hostname

### Other Options

- `starship_show_time` - Toggle time display
- `starship_show_icons` - Toggle fancy directory icons
- `starship_theme` - Color scheme (currently only `tokyonight`)

## Common Commands

```bash
chezmoi diff              # Preview changes
chezmoi apply             # Apply changes
chezmoi update            # Pull + apply from remote
chezmoi add ~/.config/x   # Add new config
chezmoi edit ~/.config/x  # Edit in source dir
chezmoi managed           # List managed files
chezmoi init              # Re-run setup prompts
```

## Adding Templated Configs

```bash
chezmoi add --template ~/.config/app/config
```

Then edit with conditionals:

```
{{- if eq .profile "wsl" }}
wsl-specific-setting = true
{{- end }}
```

## Dependencies

```bash
# Arch - sway (Wayland)
pacman -S sway swaybg waybar wofi foot mako grim slurp wl-clipboard swaylock starship xorg-xwayland

# Arch - i3 (X11)
pacman -S i3 polybar wofi foot mako maim xclip picom feh starship

# Fedora - sway (Wayland)
dnf install sway swaybg waybar wofi foot mako grim slurp wl-clipboard swaylock starship xorg-x11-server-Xwayland

# Fedora - i3 (X11)
dnf install i3 polybar wofi foot mako maim xclip picom feh starship

# Or install starship via curl
curl -sS https://starship.rs/install.sh | sh
```

`swaybg` is what sway shells out to for the wallpaper — without it, `output * bg ...` silently fails. `xorg-xwayland` enables X11 apps to run inside sway; skip it only if you exclusively use Wayland-native apps.

### Fonts

Polybar and Waybar use icon fonts for status indicators:

```bash
# Arch
pacman -S woff2-font-awesome ttf-jetbrains-mono-nerd

# Fedora
dnf install fontawesome-fonts jetbrains-mono-fonts
```

Without these fonts, icons will render as boxes.

## Attribution

The WSL clipboard-sync scripts and the structural skeleton of `start-sway`
(systemd kickstart, `/tmp/.X11-unix` reset, WSLg socket linkage) are vendored
from [jordankoehn/sway-wsl2](https://github.com/jordankoehn/sway-wsl2) (MIT).
Thanks. Local additions: NOPASSWD-sudoers helper, toolkit env vars,
`exec sway`, idempotent host-setup script.
