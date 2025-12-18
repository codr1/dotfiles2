# Dotfiles

Cross-machine dotfiles managed with [chezmoi](https://www.chezmoi.io/). Supports WSL, VMs, and bare-metal systems running sway, hyprland, or i3.

## Quick Start

### New Machine

```bash
# Install chezmoi and apply dotfiles in one command
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply codr1

# Or if chezmoi is already installed
chezmoi init --apply codr1
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

## Profile Differences

| Feature | WSL | VM | Bare-metal |
|---------|-----|-----|------------|
| Mod key | Alt (Mod1) | Super (Mod4) | Super (Mod4) |
| Terminal | foot | ghostty | ghostty |
| Clipboard sync | Yes | No | No |
| Battery module | No | No | Yes |
| Backlight module | No | No | Yes |
| Swaylock | No | No | Yes |

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
pacman -S sway waybar wofi foot mako grim slurp wl-clipboard swaylock starship

# Arch - i3 (X11)
pacman -S i3 polybar wofi foot mako maim xclip picom feh starship

# Fedora - sway (Wayland)
dnf install sway waybar wofi foot mako grim slurp wl-clipboard swaylock starship

# Fedora - i3 (X11)
dnf install i3 polybar wofi foot mako maim xclip picom feh starship

# Or install starship via curl
curl -sS https://starship.rs/install.sh | sh
```

### Fonts

Polybar and Waybar use icon fonts for status indicators:

```bash
# Arch
pacman -S ttf-font-awesome ttf-jetbrains-mono-nerd

# Fedora
dnf install fontawesome-fonts jetbrains-mono-fonts
```

Without these fonts, icons will render as boxes.
