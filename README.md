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

## Managed Configs

| Config | Templated | Notes |
|--------|-----------|-------|
| `foot/foot.ini` | No | Terminal |
| `ghostty/config` | No | Terminal |
| `mako/config` | No | Notifications |
| `starship/starship.toml` | Yes | Shell prompt - languages, time, hostname, icons |
| `sway/config` | Yes | WM - terminal, modkey, clipboard, scale |
| `waybar/config` | Yes | Status bar - battery/backlight per profile |
| `waybar/style.css` | No | TokyoNight theme |
| `wofi/*` | No | App launcher + power menu |

## Profile Differences

| Feature | WSL | VM | Bare-metal |
|---------|-----|-----|------------|
| Mod key | Alt (Mod1) | Super (Mod4) | Super (Mod4) |
| Terminal | foot | ghostty | ghostty |
| Clipboard sync | Yes | No | No |
| Battery module | No | No | Yes |
| Backlight module | No | No | Yes |

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
# Arch
pacman -S sway waybar wofi foot mako grim slurp wl-clipboard starship

# Or install starship via curl
curl -sS https://starship.rs/install.sh | sh
```
