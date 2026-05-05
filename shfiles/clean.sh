#!/bin/bash

echo "Starting system cleanup..."

# 1. Remove old cached packages (keeps only the latest 3)
echo "--- Cleaning package cache ---"
sudo paccache -r

# 2. Remove orphaned packages (if any exist)
echo "--- Removing orphaned packages ---"
ORPHANS=$(pacman -Qtdq)
if [ -n "$ORPHANS" ]; then
    sudo pacman -Rns $ORPHANS
else
    echo "No orphans to remove."
fi

# 3. Clear system logs older than 7 days
echo "--- Vacuuming journal logs ---"
sudo journalctl --vacuum-time=7d

# 4. Clear user cache
# Note: This may log you out of some apps or slow them down initially
echo "--- Clearing user cache ---"
rm -rf ~/.cache/*
sudo pacman -Scc

# 5. Clear Clipboard (since you're using cliphist)
if command -v cliphist &> /dev/null; then
    echo "--- Wiping clipboard history ---"
    cliphist wipe
fi

echo "Done! Your system is fresh."
