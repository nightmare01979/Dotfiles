import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// SystemTrayWidget.qml
// Volume + Bluetooth + Power in ONE outer pill (grouped), each sub-item
// also has its own inner pill border. Very low RAM — no DBus daemon polling,
// just shell commands on a slow timer.

Item {
    id: root
    implicitWidth:  outerPill.implicitWidth
    implicitHeight: outerPill.implicitHeight

    // ── State ────────────────────────────────────────────────────────────────
    property int    volume:      50
    property bool   volMuted:    false
    property string btStatus:   "off"   // "on" | "off" | "connected"
    property string btDevice:   ""

    // ── Colors ───────────────────────────────────────────────────────────────
    property color accent:      "#cba6f7"
    property color pillBg:      "#1e1e2e"
    property color pillBorder:  "#313244"
    property color textColor:   "#cdd6f4"
    property color mutedColor:  "#585b70"
    property color warnColor:   "#f38ba8"

    // ── Processes ────────────────────────────────────────────────────────────

    // Volume — wpctl (pipewire) or fallback to amixer
    Process {
        id: volProc
        // Gets default sink volume as percentage, e.g. "75" or "MUTED"
        command: ["sh", "-c",
            "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | " +
            "awk '{if($2==\"[MUTED]\") print \"MUTED\"; else printf \"%d\", $2*100}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var t = text.trim()
                if (t === "MUTED") {
                    root.volMuted = true
                } else {
                    root.volMuted = false
                    root.volume   = parseInt(t) || 0
                }
            }
        }
    }

    // Bluetooth — minimal bluetoothctl call
    Process {
        id: btProc
        command: ["sh", "-c",
            "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && " +
            "(bluetoothctl info 2>/dev/null | grep -q 'Connected: yes' && echo connected || echo on) " +
            "|| echo off"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.btStatus = text.trim()
            }
        }
    }

    // Bluetooth connected device name (only when connected)
    Process {
        id: btDeviceProc
        command: ["sh", "-c",
            "bluetoothctl info 2>/dev/null | grep 'Name:' | head -1 | sed 's/.*Name: //'"]
        running: root.btStatus === "connected"
        stdout: StdioCollector {
            onStreamFinished: root.btDevice = text.trim()
        }
    }

    // Refresh timer — 3 s is plenty; saves CPU vs 1 s
    Timer {
        interval: 3000
        running:  true
        repeat:   true
        onTriggered: {
            volProc.running = true
            btProc.running  = true
        }
    }

    // ── Outer pill (groups all three) ────────────────────────────────────────
    Rectangle {
        id:           outerPill
        implicitWidth:  trayRow.implicitWidth  + 10
        implicitHeight: trayRow.implicitHeight + 10
        color:        root.pillBg
        border.color: root.pillBorder
        border.width: 1
        radius:       999

        RowLayout {
            id:               trayRow
            anchors.centerIn: parent
            spacing:          4

            // ── Volume inner pill ─────────────────────────────────────────────
            Rectangle {
                implicitWidth:  volRow.implicitWidth  + 14
                implicitHeight: volRow.implicitHeight + 8
                color:        root.volMuted
                              ? Qt.rgba(243/255, 139/255, 168/255, 0.12)
                              : "transparent"
                border.color: root.volMuted ? root.warnColor : root.pillBorder
                border.width: 1
                radius:       999

                RowLayout {
                    id:               volRow
                    anchors.centerIn: parent
                    spacing:          4

                    Text {
                        text:  root.volMuted ? "󰖁" : (root.volume > 60 ? "󰕾" : (root.volume > 20 ? "󰖀" : "󰕿"))
                        color: root.volMuted ? root.warnColor : root.textColor
                        font { family: "monospace"; pixelSize: 14 }
                    }
                    Text {
                        text:  root.volMuted ? "mute" : root.volume + "%"
                        color: root.volMuted ? root.warnColor : root.textColor
                        font { family: "monospace"; pixelSize: 12 }
                    }
                }

                // Scroll wheel to change volume
                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        // Toggle mute on click
                        volMuteProc.running = true
                    }
                    onWheel: function(wheel) {
                        var delta = wheel.angleDelta.y > 0 ? 5 : -5
                        volChangeProc.command = ["sh", "-c",
                            "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.abs(delta) + "%" +
                            (delta > 0 ? "+" : "-")]
                        volChangeProc.running = true
                    }
                }
            }

            // Separator dot
            Text {
                text:  "·"
                color: root.mutedColor
                font { pixelSize: 10 }
            }

            // ── Bluetooth inner pill ──────────────────────────────────────────
            Rectangle {
                implicitWidth:  btRow.implicitWidth  + 14
                implicitHeight: btRow.implicitHeight + 8
                color: root.btStatus === "connected"
                       ? Qt.rgba(203/255, 166/255, 247/255, 0.12)
                       : "transparent"
                border.color: root.btStatus === "connected"
                              ? root.accent
                              : (root.btStatus === "on" ? root.pillBorder : root.mutedColor)
                border.width: 1
                radius:       999

                RowLayout {
                    id:               btRow
                    anchors.centerIn: parent
                    spacing:          4

                    Text {
                        text:  root.btStatus === "connected" ? "󰂱" :
                               root.btStatus === "on"        ? "󰂯" : "󰂲"
                        color: root.btStatus === "connected" ? root.accent :
                               root.btStatus === "on"        ? root.textColor : root.mutedColor
                        font { family: "monospace"; pixelSize: 14 }
                    }
                    Text {
                        visible: root.btStatus === "connected" && root.btDevice !== ""
                        text:    root.btDevice.length > 12
                                 ? root.btDevice.substring(0, 12) + "…"
                                 : root.btDevice
                        color:   root.accent
                        font { family: "monospace"; pixelSize: 11 }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        // Toggle bluetooth power
                        btToggleProc.command = ["sh", "-c",
                            root.btStatus === "off"
                            ? "bluetoothctl power on"
                            : "bluetoothctl power off"]
                        btToggleProc.running = true
                    }
                }
            }

            // Separator dot
            Text {
                text:  "·"
                color: root.mutedColor
                font { pixelSize: 10 }
            }

            // ── Power inner pill ──────────────────────────────────────────────
            Rectangle {
                id: powerPill
                implicitWidth:  powerIcon.implicitWidth  + 14
                implicitHeight: powerIcon.implicitHeight + 8
                color: powerArea.containsMouse
                       ? Qt.rgba(243/255, 139/255, 168/255, 0.18)
                       : "transparent"
                border.color: powerArea.containsMouse ? root.warnColor : root.pillBorder
                border.width: 1
                radius:       999

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Text {
                    id:               powerIcon
                    anchors.centerIn: parent
                    text:             "⏻"
                    color:            powerArea.containsMouse ? root.warnColor : root.textColor
                    font { family: "monospace"; pixelSize: 14 }

                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id:          powerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:   powerMenuProc.running = true
                }
            }
        }
    }

    // ── Helper processes (fire-and-forget) ────────────────────────────────────
    Process {
        id:      volMuteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        onRunningChanged: if (!running) volProc.running = true
    }

    Process {
        id:      volChangeProc
        command: []
        onRunningChanged: if (!running) volProc.running = true
    }

    Process {
        id:      btToggleProc
        command: []
        onRunningChanged: if (!running) {
            // Short delay then re-poll
            btRefreshTimer.start()
        }
    }

    Timer {
        id:       btRefreshTimer
        interval: 800
        repeat:   false
        onTriggered: btProc.running = true
    }

    // Power menu — uses wlogout if installed, else hyprlock/systemctl
    // Edit this command to match your setup
    Process {
        id:      powerMenuProc
        command: ["sh", "-c",
            "if command -v wlogout &>/dev/null; then wlogout; " +
            "elif command -v wofi &>/dev/null; then " +
            "  echo -e 'Shutdown\nReboot\nLogout\nSuspend' | " +
            "  wofi --dmenu -p 'Power' | " +
            "  xargs -I{} sh -c 'case \"{}\" in " +
            "    Shutdown) systemctl poweroff;; " +
            "    Reboot)   systemctl reboot;; " +
            "    Logout)   hyprctl dispatch exit;; " +
            "    Suspend)  systemctl suspend;; esac'; " +
            "else hyprctl dispatch exit; fi"]
    }
}
