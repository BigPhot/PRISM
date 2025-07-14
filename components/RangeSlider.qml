import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Studio.DesignEffects

Item {
    id: root
    width: 400
    height: 120

    signal rangeChanged(date startDate, date endDate)

    property date minDate: new Date(2025, 4, 19)  // May 1
    property date maxDate: new Date(2025, 5, 30) // June 30

    property int minValue: 0
    property int maxValue: 100

    property int rangeStart: 0
    property int rangeEnd: 100

    // Helpers
    function valueToDate(val) {
        let percent = (val - minValue) / (maxValue - minValue)
        let ms = maxDate.getTime() - minDate.getTime()
        return new Date(minDate.getTime() + percent * ms)
    }

    function updateRangeFromThumbs() {
        let startRatio = (leftThumb.x + leftThumb.width / 2 - timelineBar.x) / timelineBar.width
        let endRatio = (rightThumb.x + rightThumb.width / 2 - timelineBar.x) / timelineBar.width

        startRatio = Math.max(0, Math.min(1, startRatio))
        endRatio = Math.max(0, Math.min(1, endRatio))

        rangeStart = Math.round(startRatio * 100)
        rangeEnd = Math.round(endRatio * 100)

        let totalMs = maxDate.getTime() - minDate.getTime()
        let startDate = new Date(minDate.getTime() + startRatio * totalMs)
        let endDate = new Date(minDate.getTime() + endRatio * totalMs)

        rangeChanged(startDate, endDate)
    }

    // Timeline bar
    Rectangle {
        id: timelineBar
        width: parent.width - 40
        height: 6
        radius: 3
        color: "#fc5a03"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
    }

    // Highlight between thumbs
    Rectangle {
        id: selectionHighlight
        y: timelineBar.y
        height: timelineBar.height
        color: "#fc5a03"
        radius: 3
        x: leftThumb.x + leftThumb.width / 2
        width: rightThumb.x - leftThumb.x
        z: -1
    }

    // Left thumb
    Rectangle {
        id: leftThumb
        width: 8
        height: 18
        radius: 15
        color: "#fc5a03"
        y: timelineBar.y - 12
        x: timelineBar.x + rangeStart / 100 * timelineBar.width - width / 2

        MouseArea {
            anchors.fill: parent
            drag.target: parent
            drag.axis: Drag.XAxis
            drag.minimumX: timelineBar.x - parent.width / 2
            drag.maximumX: rightThumb.x - parent.width

            onReleased: updateRangeFromThumbs()
        }
    }

    // Right thumb
    Rectangle {
        id: rightThumb
        width: 8
        height: 18
        radius: 15
        color: "#fc5a03"
        y: timelineBar.y - 12
        x: timelineBar.x + rangeEnd / 100 * timelineBar.width - width / 2

        MouseArea {
            anchors.fill: parent
            drag.target: parent
            drag.axis: Drag.XAxis
            drag.minimumX: leftThumb.x + leftThumb.width
            drag.maximumX: timelineBar.x + timelineBar.width - parent.width / 2

            onReleased: updateRangeFromThumbs()
        }
    }


    // Range info
    Row {
        anchors.top: parent.top
        anchors.topMargin: 28
        anchors.left: parent.left
        anchors.leftMargin: 28
        spacing: 8

        Text {
            text: Qt.formatDate(valueToDate(rangeStart), "MMM d, yyyy")
            font.pixelSize: 12
            color: "#bbb"
        }

        Text {
            text: "-"
            font.pixelSize: 12
            color: "#bbb"
        }


        Text {
            text: Qt.formatDate(valueToDate(rangeEnd), "MMM d, yyyy")
            font.pixelSize: 12
            color: "#bbb"
        }

        DesignEffect {
            id: shadow
            layerBlurRadius: 0
            // Combo of drop and inner shadows for visual depth and elevation
            effects: [
                DesignDropShadow {
                    color: "#212121"
                    spread: 1
                    showBehind: true
                    offsetY: 1
                    offsetX: 1
                    blur: 5
                },
                DesignInnerShadow {
                    color: "#ffffff"
                    spread: -1
                    offsetY: 1
                    offsetX: 1
                    blur: 7
                }
            ]
        }
    }
        

}
