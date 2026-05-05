import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Io // Required for the Process module

ShellRoot {
    // Make sure this matches the exact name of your installed Nerd Font!
    readonly property string iconFont: "JetBrainsMono Nerd Font Propo"

    // FIX 1: The Process object for your Power Menu
    Process {
        id: wlogoutProcess
        command: ["wlogout"]
    }

    // FIX 2: Pipewire Object Tracker (This forces the volume to update in real-time)
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // FIX 3: Timer for the Clock (Updates every second)
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockText.text = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }

    PanelWindow {
        anchors.top: true
        anchors.left: true
        anchors.right: true
        height: 30
        color: "transparent"
        exclusionMode: ExclusionMode.Exclusive

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            // --- LEFT: Time ---
            Rectangle {
                color: "#1e1e2e"; radius: 20
                implicitWidth: 90; implicitHeight: 30
                Text {
                    id: clockText
                    anchors.centerIn: parent
                    color: "#cdd6f4"
                    text: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                }
            }

            Item { Layout.fillWidth: true }

            // --- CENTER: Workspaces (Pill-in-Pill) ---
            Rectangle {
                color: "#1e1e2e"; radius: 20
                implicitWidth: wsRow.width + 16; implicitHeight: 32
                Row {
                    id: wsRow; anchors.centerIn: parent; spacing: 8
                    
                    Repeater {
                        model: 5
                        delegate: Rectangle {
                            // FIX 4: Correct Hyprland property is `focusedWorkspace`
                            readonly property bool isFocused: Hyprland.focusedWorkspace?.id === index + 1
                            
                            width: isFocused ? 38 : 24
                            height: 20; radius: 10
                            color: isFocused ? "#89b4fa" : "#313244"
                            
                            Behavior on width { NumberAnimation { duration: 200 } }
                            
                            Text {
                                anchors.centerIn: parent
                                text: index + 1
                                color: isFocused ? "#11111b" : "#cdd6f4"
                                font.bold: true
                            }
                            
                            // Click to switch workspaces
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Hyprland.dispatch("workspace " + (index + 1))
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // --- RIGHT: System Group (Volume & Power) ---
            Rectangle {
                color: "#1e1e2e"; radius: 20
                implicitWidth: statusRow.width + 24; implicitHeight: 30
                Row {
                    id: statusRow; anchors.centerIn: parent; spacing: 18

                    // VOLUME
                    Row {
                        spacing: 5
                        Text { 
                            font.family: iconFont
                            text: Pipewire.defaultAudioSink?.audio?.muted ? "󰝟" : "󰕾"
                            color: Pipewire.defaultAudioSink?.audio?.muted ? "#f38ba8" : "#fab387" 
                        }
                        Text { 
                            text: Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100) + "%"
                            color: "#cdd6f4"
                        }
                    }

                    // POWER MENU
                    Text {
                        font.family: iconFont
                        text: ""
                        color: "#f38ba8"
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                // Stop and start the process to guarantee it runs every click
                                wlogoutProcess.running = false
                                wlogoutProcess.running = true
                            }
                        }
                    }
                }
            }
        }
    }
}
