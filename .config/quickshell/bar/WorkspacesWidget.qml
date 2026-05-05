import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// WorkspacesWidget.qml
// Outer pill = the whole workspace strip
// Each workspace number = its own inner pill
// Active workspace pill is wider (more hPad) and uses accent color
Item {
    id: root
    implicitWidth:  outerPill.implicitWidth
    implicitHeight: outerPill.implicitHeight

    // ── Colours (inherit from Bar via root.parent chain, or just hardcode) ───
    property color accent:      "#cba6f7"
    property color accentDim:   "#45475a"
    property color pillBg:      "#1e1e2e"
    property color pillBorder:  "#313244"
    property color textColor:   "#cdd6f4"
    property color mutedColor:  "#585b70"

    // How many workspaces to show
    property int wsCount: 10

    // ── Outer pill ───────────────────────────────────────────────────────────
    Rectangle {
        id:           outerPill
        implicitWidth:  innerRow.implicitWidth  + 10
        implicitHeight: innerRow.implicitHeight + 10
        color:        root.pillBg
        border.color: root.pillBorder
        border.width: 1
        radius:       999

        RowLayout {
            id:               innerRow
            anchors.centerIn: parent
            spacing:          3

            Repeater {
                model: root.wsCount

                delegate: Item {
                    id:    wsItem
                    property int   wsId:     index + 1
                    property bool  isActive: Hyprland.focusedWorkspace !== null &&
                                             Hyprland.focusedWorkspace.id === wsId
                    // Check if this workspace has any windows
                    property bool  hasWin:   Hyprland.workspaces.values.some(
                                                 function(w) { return w.id === wsId; }
                                             )

                    // Animate width change when focused
                    implicitWidth:  innerPill.implicitWidth
                    implicitHeight: innerPill.implicitHeight

                    // ── Inner pill per workspace ─────────────────────────────
                    Rectangle {
                        id:     innerPill
                        // Active workspace gets extra horizontal padding (wider pill)
                        implicitWidth:  wsLabel.implicitWidth + (wsItem.isActive ? 22 : 14)
                        implicitHeight: wsLabel.implicitHeight + 8

                        Behavior on implicitWidth {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }

                        color: wsItem.isActive
                               ? Qt.rgba(203/255, 166/255, 247/255, 0.18)  // accent tinted
                               : "transparent"

                        border.color: wsItem.isActive
                                      ? root.accent
                                      : (wsItem.hasWin ? root.accentDim : root.pillBorder)
                        border.width: 1
                        radius:       999

                        Text {
                            id:               wsLabel
                            anchors.centerIn: parent
                            text:             wsItem.wsId
                            color:            wsItem.isActive
                                              ? root.accent
                                              : (wsItem.hasWin ? root.textColor : root.mutedColor)
                            font {
                                family:    "monospace"
                                pixelSize: 12
                                bold:      wsItem.isActive
                            }
                        }

                        // Click to switch workspace
                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    Hyprland.dispatch("workspace " + wsItem.wsId)
                        }
                    }
                }
            }
        }
    }
}
