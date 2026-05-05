import QtQuick
import QtQuick.Layouts

// Pill.qml — reusable rounded-rectangle pill wrapper
// Usage:
//   Pill { /* children go here */ }
//   Pill { borderColor: "#ff0000"; bgColor: "transparent"; ... }

Item {
    id: root

    // ── Public props ─────────────────────────────────────────────────────────
    property color bgColor:     "#1e1e2e"
    property color borderColor: "#313244"
    property int   borderWidth: 1
    property int   radius:      999   // full pill
    property int   hPad:        10    // horizontal padding
    property int   vPad:        4     // vertical padding

    // Let children declare their own sizes; pill wraps them
    implicitWidth:  innerRow.implicitWidth  + hPad * 2
    implicitHeight: innerRow.implicitHeight + vPad * 2

    // Background
    Rectangle {
        anchors.fill: parent
        color:        root.bgColor
        border.color: root.borderColor
        border.width: root.borderWidth
        radius:       root.radius
    }

    // Content container
    RowLayout {
        id:             innerRow
        anchors.centerIn: parent
        spacing:        6
        // children injected via default property
    }

    default property alias content: innerRow.data
}
