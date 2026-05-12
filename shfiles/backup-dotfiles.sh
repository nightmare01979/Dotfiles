#!/bin/bash
set -e
DOTFILES="$HOME/dotfiles"

notify() {
    hyprctl notify 1 4000 "rgb(cdd6f4)" "$1"
}

trap 'hyprctl notify 3 6000 "rgb(f38ba8)" "❌ Backup failed at line $LINENO"' ERR

notify "📦 Updating package lists..."
pacman -Qqe > "$DOTFILES/pkglist.txt"
pacman -Qqem > "$DOTFILES/aurlist.txt"

notify "📁 Copying full .config..."
rm -rf "$DOTFILES/.config"
mkdir "$DOTFILES/.config"
cp -rv "$HOME/.config" "$DOTFILES/"
cp -rv "$HOME/shfiles" "$DOTFILES/"

notify "🧹 Cleaning junk files..."
rm -rf "$DOTFILES/.config/Code"
rm -rf "$DOTFILES"/.config/*cache*
rm -rf "$DOTFILES"/.config/*Cache*
rm -rf "$DOTFILES/.config/Cache"
rm -rf "$DOTFILES/.config/CachedData"
rm -rf "$DOTFILES/.config/GPUCache"
rm -rf "$DOTFILES/.config/logs"
rm -rf "$DOTFILES/.config/BraveSoftware"
find "$DOTFILES/.config" -type f -name "*.log" -delete

notify "🔃 Committing changes..."
cd "$DOTFILES"
git add .
if ! git diff --cached --quiet; then
    git commit -m "backup $(date '+%Y-%m-%d %H:%M')"
    git push
    hyprctl notify 0 5000 "rgb(a6e3a1)" "✅ Backup complete!"
else
    hyprctl notify 1 5000 "rgb(cdd6f4)" "ℹ️ Nothing to commit"
fi
