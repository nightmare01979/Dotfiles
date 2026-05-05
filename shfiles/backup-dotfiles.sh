#!/bin/bash

set -e

DOTFILES="$HOME/dotfiles"

echo "📦 Updating package lists..."
pacman -Qqe > "$DOTFILES/pkglist.txt"
pacman -Qqem > "$DOTFILES/aurlist.txt"

echo "📁 Copying full .config..."

# remove old backup
rm -rf "$DOTFILES/.config"
mkdir "$DOTFILES/.config"

# copy everything
cp -rv "$HOME/.config" "$DOTFILES/"
cp -rv "$HOME/shfiles" "$DOTFILES/"
echo "🧹 Cleaning junk files..."

# remove common junk (prevents big files)
rm -rf "$DOTFILES/.config/Code"
rm -rf "$DOTFILES/.config/*cache*"
rm -rf "$DOTFILES/.config/Cache"
rm -rf "$DOTFILES/.config/CachedData"
rm -rf "$DOTFILES/.config/GPUCache"
rm -rf "$DOTFILES/.config/logs"
rm -rf "$DOTFILES/.config/BraveSoftware"

# remove log files
find "$DOTFILES/.config" -type f -name "*.log" -delete

echo "📝 Committing changes..."

cd "$DOTFILES"

git add .

if ! git diff --cached --quiet; then
    git commit -m "backup $(date '+%Y-%m-%d %H:%M')"
    git push
    echo "✅ Backup complete!"
else
    echo "✔ Nothing to commit"
fi
