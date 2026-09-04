#!/bin/bash
set -e
DOTFILES="$HOME/dotfiles"

if [ ! -d "$DOTFILES/.git" ]; then
    echo "📥 Cloning dotfiles repo..."
    git clone git@github.com:nightmare01979/Dotfiles.git "$DOTFILES"
fi

notify() {
    hyprctl notify 1 4000 "rgb(cdd6f4)" "$1"
}

# shows a notification that lasts 999 seconds (basically forever)
notify_persistent() {
    hyprctl notify 1 999000 "rgb(cdd6f4)" "$1"
}

trap 'hyprctl dismissnotify 1; hyprctl notify 3 6000 "rgb(f38ba8)" "❌ Backup failed at line $LINENO"' ERR

notify "Updating package lists..."
pacman -Qqe > "$DOTFILES/pkglist.txt"
pacman -Qqem > "$DOTFILES/aurlist.txt"

# persistent notif for the slow copy step
notify_persistent "Copying .config..."
rm -rf "$DOTFILES/.config"
mkdir "$DOTFILES/.config"
cp -rv "$HOME/.config/hypr" "$DOTFILES/configs"
cp -rv "$HOME/.config/waybar" "$DOTFILES/configs"
cp -rv "$HOME/.config/rofi" "$DOTFILES/configs"
cp -rv "$HOME/.config/kitty" "$DOTFILES/configs"
cp -rv "$HOME/.config/wal" "$DOTFILES/configs"
cp -rv "$HOME/.config/gtk-3.0" "$DOTFILES/configs"
cp -rv "$HOME/.config/gtk-4.0" "$DOTFILES/configs"
cp -rv "$HOME/.config/Thunar" "$DOTFILES/configs"
cp -rv "$HOME/.config/nvim" "$DOTFILES/configs"
cp -rv "$HOME/.config/fastfetch" "$DOTFILES/configs"
cp -rv "$HOME/.config/btop" "$DOTFILES/configs"
cp -rv "$HOME/.config/cava" "$DOTFILES/configs"
cp -rv "$HOME/.config/systemd" "$DOTFILES/configs"
cp -rv "$HOME/.config/vis" "$DOTFILES/configs"
cp -rv "$HOME/.config/obsidian" "$DOTFILES/configs"
cp -rv "$HOME/.config/i3" "$DOTFILES/configs"
cp -rv "$HOME/.config/picom" "$DOTFILES/configs"
cp -rv "$HOME/.config/polybar" "$DOTFILES/configs"
cp -rv "$HOME/.config/wlogout" "$DOTFILES/configs"
cp -rv "$HOME/.config/xdg-desktop-portal" "$DOTFILES/configs"
cp -rv "$HOME/.zshrc" "$DOTFILES/"
cp -rv "$HOME/wallpapers" "$DOTFILES/"
cp -rv "$HOME/shfiles" "$DOTFILES/"
hyprctl dismissnotify 1  # kill it once done

notify "Cleaning junk files..."
rm -rf "$DOTFILES/.config/Code"
rm -rf "$DOTFILES"/.config/*cache*
rm -rf "$DOTFILES"/.config/*Cache*
rm -rf "$DOTFILES/.config/Cache"
rm -rf "$DOTFILES/.config/CachedData"
rm -rf "$DOTFILES/.config/GPUCache"
rm -rf "$DOTFILES/.config/logs"
rm -rf "$DOTFILES/.config/BraveSoftware"
find "$DOTFILES/.config" -type f -name "*.log" -delete

notify_persistent "Committing and pushing..."
cd "$DOTFILES"
git add .
if ! git diff --cached --quiet; then
    git commit -m "backup $(date '+%Y-%m-%d %H:%M')"
    git push
    hyprctl dismissnotify 1
#    rm -r dotfiles
    hyprctl notify 0 5000 "rgb(a6e3a1)" "Backup complete!"
else
    hyprctl dismissnotify 1
    hyprctl notify 1 5000 "rgb(cdd6f4)" "Nothing to commit"
fi
