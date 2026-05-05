import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

// shell.qml — main entry point
// Place this folder at ~/.config/quickshell/bar/
ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar { screen: modelData }
    }
}
