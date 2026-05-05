import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    // ===== CONFIG =====
    property real iconSize: 32
    property real dockHeight: 52
    property real dockRadius: 12
    property real dockPadding: 8
    property string dockColor: "#cc1e1e2e"
    property real dotWidth: 14
    property real dotHeight: 3
    property real previewWidth: 280
    property real previewHeight: 160
    // ==================

    function resolveIcon(appId) {
        const overrides = {
            "zen": "zen-browser",
            "nautilus": "org.gnome.Nautilus",
            "thunar": "org.xfce.thunar",
        }
        const name = overrides[appId] ?? appId
        return Quickshell.iconPath(name, "image-missing")
    }

    property var groupedApps: {
        var map = new Map()
        var order = []
        for (const toplevel of ToplevelManager.toplevels.values) {
            const id = toplevel.appId.toLowerCase()
            if (!map.has(id)) {
                map.set(id, { appId: id, toplevels: [], active: false })
                order.push(id)
            }
            map.get(id).toplevels.push(toplevel)
            if (toplevel.activated) map.get(id).active = true
        }
        return order.map(id => map.get(id))
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: dockWindow
            required property var modelData
            screen: modelData

            anchors.bottom: true
            exclusiveZone: 0
            color: "transparent"
            implicitHeight: dockHeight + previewHeight + 80
            implicitWidth: screen.width

            WlrLayershell.namespace: "quickshell:mydock"
            WlrLayershell.layer: WlrLayer.Top

            mask: Region { item: inputZone }

            property bool workspaceEmpty: groupedApps.length === 0
            property var hoveredApp: null
            property bool shouldReveal: false

            MouseArea {
                id: inputZone
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: dockBackground.implicitWidth + 32
                height: dockWindow.shouldReveal
                    ? dockHeight + previewHeight + 80
                    : 20
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                onContainsMouseChanged: {
                    if (containsMouse) {
                        hideTimer.stop()
                        dockWindow.shouldReveal = true
                    } else {
                        hideTimer.restart()
                    }
                }

                onClicked: (mouse) => {
                    // Check preview cards first
                    if (previewPopup.visible) {
                        for (let i = 0; i < previewRepeater.count; i++) {
                            const card = previewRepeater.itemAt(i)
                            if (!card) continue
                            const pos = mapToItem(card, mouse.x, mouse.y)
                            if (pos.x >= 0 && pos.x <= card.width
                             && pos.y >= 0 && pos.y <= card.height) {
                                card.toplevel.activate()
                                return
                            }
                        }
                    }
                    // Check dock icons
                    for (let i = 0; i < iconRepeater.count; i++) {
                        const item = iconRepeater.itemAt(i)
                        if (!item) continue
                        const pos = mapToItem(item, mouse.x, mouse.y)
                        if (pos.x >= 0 && pos.x <= item.width
                         && pos.y >= 0 && pos.y <= item.height) {
                            item.lastFocused = (item.lastFocused + 1) % item.windowCount
                            item.modelData.toplevels[item.lastFocused].activate()
                            return
                        }
                    }
                }

                onPositionChanged: (mouse) => {
                    let foundIcon = null
                    for (let i = 0; i < iconRepeater.count; i++) {
                        const item = iconRepeater.itemAt(i)
                        if (!item) continue
                        const pos = mapToItem(item, mouse.x, mouse.y)
                        if (pos.x >= 0 && pos.x <= item.width
                         && pos.y >= 0 && pos.y <= item.height) {
                            foundIcon = item.modelData
                            break
                        }
                    }
                    if (foundIcon !== null) {
                        if (dockWindow.hoveredApp?.appId !== foundIcon.appId) {
                            showPreviewTimer.currentApp = foundIcon
                            showPreviewTimer.restart()
                        }
                    } else {
                        showPreviewTimer.stop()
                    }
                }
            }

            Component.onCompleted: {
                shouldReveal = workspaceEmpty
            }

            onWorkspaceEmptyChanged: {
                if (workspaceEmpty) {
                    hideTimer.stop()
                    shouldReveal = true
                } else if (!inputZone.containsMouse) {
                    hideTimer.restart()
                }
            }

            Timer {
                id: hideTimer
                interval: 600
                onTriggered: {
                    if (!inputZone.containsMouse && !dockWindow.workspaceEmpty) {
                        dockWindow.shouldReveal = false
                        dockWindow.hoveredApp = null
                    }
                }
            }

            // 200ms delay — fast enough to feel snappy
            Timer {
                id: showPreviewTimer
                interval: 200
                property var currentApp: null
                onTriggered: {
                    if (inputZone.containsMouse) {
                        dockWindow.hoveredApp = currentApp
                    }
                }
            }

            Rectangle {
                id: previewPopup
                visible: dockWindow.hoveredApp !== null
                      && dockWindow.shouldReveal
                      && previewRepeater.count > 0
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                color: "#cc1e1e2e"
                radius: 10
                border.width: 1
                border.color: "#44ffffff"

                anchors.bottom: dockBackground.top
                anchors.bottomMargin: 8
                anchors.horizontalCenter: dockBackground.horizontalCenter
                implicitWidth: previewRow.implicitWidth + 16
                implicitHeight: previewHeight + 44

                RowLayout {
                    id: previewRow
                    anchors.centerIn: parent
                    spacing: 8

                    Repeater {
                        id: previewRepeater
                        model: dockWindow.hoveredApp?.toplevels ?? []
                        delegate: Item {
                            id: previewCard
                            required property var modelData
                            property var toplevel: modelData

                            width: previewWidth
                            height: previewHeight + 24

                            Text {
                                id: titleText
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 4
                                text: toplevel.title ?? ""
                                color: "#cdd6f4"
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }

                            // Wrap in Item with enabled:false so it
                            // cannot intercept clicks from inputZone
                            Item {
                                enabled: false
                                anchors.top: titleText.bottom
                                anchors.topMargin: 4
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: scopy.width
                                height: scopy.height

                                ScreencopyView {
                                    id: scopy
                                    captureSource: toplevel
                                    live: true
                                    paintCursor: false
                                    constraintSize: Qt.size(previewWidth, previewHeight)

                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: scopy.width
                                            height: scopy.height
                                            radius: 6
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: dockBackground
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: dockWindow.shouldReveal ? 8 : -dockHeight - 8

                Behavior on anchors.bottomMargin {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }

                height: dockHeight
                radius: dockRadius
                color: dockColor
                implicitWidth: Math.max(dockRow.implicitWidth + dockPadding * 2, 60)

                Behavior on implicitWidth {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                RowLayout {
                    id: dockRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        id: iconRepeater
                        model: groupedApps
                        delegate: Item {
                            id: iconItem
                            required property var modelData
                            property bool isActive: modelData.active
                            property int windowCount: modelData.toplevels.length
                            property int lastFocused: 0

                            width: iconSize + 12
                            height: dockHeight

                            Rectangle {
                                id: iconBg
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: (dockHeight - iconSize - 8) / 2
                                width: iconSize + 8
                                height: iconSize + 8
                                radius: 8
                                color: {
                                    if (dockWindow.hoveredApp?.appId === modelData.appId)
                                        return "#33ffffff"
                                    if (isActive)
                                        return "#22ffffff"
                                    return "transparent"
                                }
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Image {
                                    anchors.centerIn: parent
                                    source: resolveIcon(modelData.appId)
                                    width: iconSize
                                    height: iconSize
                                    smooth: true
                                }
                            }

                            RowLayout {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 4
                                spacing: 3

                                Repeater {
                                    model: Math.min(windowCount, 4)
                                    delegate: Rectangle {
                                        required property int index
                                        radius: dotHeight / 2
                                        implicitWidth: windowCount <= 4 ? dotWidth : dotHeight
                                        implicitHeight: dotHeight
                                        color: isActive ? "#89b4fa" : "#45475a"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
