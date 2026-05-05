import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// ClockWidget.qml — time display inside a pill
Item {
    id: root
    implicitWidth:  pill.implicitWidth
    implicitHeight: pill.implicitHeight

    property string _time: "00:00"

    // ── Process: call `date` every second ────────────────────────────────────
    Process {
        id: dateProc
        command: ["date", "+%H:%M"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root._time = text.trim()
        }
    }

    Timer {
        interval: 1000
        running:  true
        repeat:   true
        onTriggered: dateProc.running = true
    }

    // ── UI ───────────────────────────────────────────────────────────────────
    Pill {
        id:   pill
        hPad: 12
        vPad: 5

        Text {
            text:  root._time
            color: "#cdd6f4"
            font {
                family:    "monospace"
                pixelSize: 13
                bold:      true
            }
        }
    }
}
