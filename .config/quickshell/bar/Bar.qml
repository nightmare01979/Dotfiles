import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Bar.qml — the main panel window
PanelWindow {
    id: root

    required property var screen
    property var screenRef: screen

    // ── Appearance ──────────────────────────────────────────────────────────
    property color accent:      "#cba6f7"   // mauve  — change freely
    property color accentDim:   "#45475a"   // surface2
    property color pillBg:      "#1e1e2e"   // base (semi-dark)
    property color pillBorder:  "#313244"   // surface0
    property color textColor:   "#cdd6f4"   // text
    property color mutedColor:  "#6c7086"   // overlay0
    property string fontFam:    "monospace"
    property int   fontSize:    13

    // ── Layout ───────────────────────────────────────────────────────────────
    anchors.top:   true
    anchors.left:  true
    anchors.right: true
    implicitHeight: 36

    // Fully transparent window — modules have their own backgrounds
    color: "transparent"

    // Make bar a layer-surface that sits above windows but below popups
    WlrLayershell.layer:    WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: implicitHeight

    // ── Root row ─────────────────────────────────────────────────────────────
    RowLayout {
        anchors.fill:    parent
        anchors.margins: 4
        spacing:         0

        // ── LEFT — Clock ────────────────────────────────────────────────────
        ClockWidget {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.leftMargin: 4
        }

        // Spacer
        Item { Layout.fillWidth: true }

        // ── CENTER — Workspaces ─────────────────────────────────────────────
        WorkspacesWidget {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        }

        // Spacer
        Item { Layout.fillWidth: true }

        // ── RIGHT — System tray (vol + bt + power) ──────────────────────────
        SystemTrayWidget {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Layout.rightMargin: 4
        }
    }
}
