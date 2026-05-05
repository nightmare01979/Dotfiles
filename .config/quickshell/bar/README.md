# quickshell-bar

A minimal, transparent Quickshell status bar for Hyprland (Arch Linux).

```
Left: Clock    Center: Workspaces    Right: Volume · Bluetooth · Power
```

Designed to use as little RAM as possible:
- No unnecessary DBus polling
- System info refreshed every 3 s (not every second)
- No notification daemon, no app launcher — just the bar

---

## Install

### 1. Install Quickshell (AUR)
```bash
yay -S quickshell-git
# or
paru -S quickshell-git
```

### 2. Install font with icons
Icons use Nerd Font glyphs. Install any Nerd Font:
```bash
yay -S ttf-jetbrains-mono-nerd
# then set fontFam in Bar.qml to "JetBrainsMono Nerd Font"
```

If you don't want Nerd Fonts, replace the icon Text items in
SystemTrayWidget.qml with plain ASCII like: "VOL", "BT", "PWR"

### 3. Copy config
```bash
mkdir -p ~/.config/quickshell/bar
cp -r ./* ~/.config/quickshell/bar/
```

### 4. Run
```bash
quickshell -c bar
```

### 5. Auto-start with Hyprland
Add to `~/.config/hypr/hyprland.conf`:
```
exec-once = quickshell -c bar
```

Remove/disable waybar from exec-once first.

---

## Dependencies

| Tool | Purpose | Install |
|------|---------|---------|
| `wpctl` | Volume control | `pacman -S wireplumber` |
| `bluetoothctl` | Bluetooth | `pacman -S bluez-utils` |
| `wlogout` *(optional)* | Power menu | `yay -S wlogout` |
| `wofi` *(fallback)* | Power menu fallback | `pacman -S wofi` |

---

## Customization

### Colors
Edit the `property color` lines at the top of `Bar.qml`. Everything
inherits from there. The accent color is `#cba6f7` (Catppuccin mauve)
by default.

### Number of workspaces
Change `property int wsCount: 10` in `WorkspacesWidget.qml`.

### Power menu
Edit the `powerMenuProc` command in `SystemTrayWidget.qml` to use
whatever launcher/menu you prefer.

### Volume backend
The bar uses `wpctl` (PipeWire). If you use PulseAudio, replace the
`volProc` command with:
```
"amixer get Master | grep -o '[0-9]*%' | head -1 | tr -d '%'"
```

---

## RAM comparison

After startup (~30 s), check with:
```bash
cat /proc/$(pgrep quickshell)/status | grep VmRSS
cat /proc/$(pgrep waybar)/status | grep VmRSS
```
