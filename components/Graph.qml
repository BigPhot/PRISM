import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Studio.DesignEffects

Rectangle {
    width: 790
    height: 320
    visible: true
    color: "transparent"



    property date visibleStartDate: new Date(2025, 4, 1)
    property date visibleEndDate: new Date(2025, 5, 30)

    ListModel { id: tickModel }

    function getDateDifferenceInDays(start, end) {
        return Math.floor((end - start) / (1000 * 60 * 60 * 24))
    }

    function getBucketSize(days) {
        if (days <= 7)        return 1         // daily
        else if (days <= 31)  return 3         // every 3 days
        else if (days <= 90)  return 7         // weekly
        else if (days <= 180) return 14        // bi-weekly
        else if (days <= 365) return 30        // monthly
        else                  return 60        // bi-monthly
    }

    function setDateRange(startDate, endDate) {
        visibleStartDate = startDate
        visibleEndDate = endDate
        //console.log(startDate, endDate)
        nodeModel.onDateChanged(startDate, endDate)
        updateGrid()
    }

    function updateGrid() {
        tickModel.clear()

        const totalDays = getDateDifferenceInDays(visibleStartDate, visibleEndDate)
        const bucket = getBucketSize(totalDays)

        let d = new Date(visibleStartDate)
        while (d <= visibleEndDate) {
            tickModel.append({ date: new Date(d) })
            d.setDate(d.getDate() + bucket)
        }

        grid.requestPaint()
    }

    Rectangle {
        id: graphArea
        anchors.fill: parent
        color: "transparent"

        // 🔹 Grid Canvas
        Canvas {
            id: grid
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                ctx.strokeStyle = "rgba(255,255,255,0.08)"
                ctx.lineWidth = 1

                // Vertical lines based on tickModel
                for (let i = 0; i < tickModel.count; i++) {
                    let tickDate = tickModel.get(i).date
                    let x = (tickDate - visibleStartDate) / (visibleEndDate - visibleStartDate) * width
                    ctx.beginPath()
                    ctx.moveTo(x, 0)
                    ctx.lineTo(x, height)
                    ctx.stroke()
                }

                // Horizontal grid lines based on y tick count
                let tickCount = ticksModel.count
                for (let i = 0; i < tickCount; i++) {
                    let tickValue = ticksModel.get(i).value
                    let percent = tickValue / yTicks.maxY   // scale to height
                    let y = (1 - percent) * height   // invert so 0 is bottom
                    ctx.beginPath()
                    ctx.moveTo(0, y)
                    ctx.lineTo(width, y)
                    ctx.stroke()
                }
            }
        }

        // 🔹 Tick Marks + Labels
        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 0
            Repeater {
                model: tickModel
                delegate: Column {
                    width: 1
                    spacing: 2
                    x: {
                        let date = model.date
                        let percent = (date - visibleStartDate) / (visibleEndDate - visibleStartDate)
                        return percent * graphArea.width
                    }

                    Rectangle {
                        width: 1
                        height: 8
                        color: "#aaa"
                    }

                    Text {
                        text: Qt.formatDate(model.date, "MMM d")
                        font.pixelSize: 10
                        color: "#aaa"
                        rotation: -45
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        // 🔹 Y Tick Marks + Labels
        Item {
            id: yTicks
            width: 40
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left; anchors.leftMargin: 1

            property int maxY: nodeModel.scaledMaxY
            property var ticks: []

            function generateTicks() {

                let rawStep = maxY / 7;

                // Round rawStep up to nearest multiple of 10
                let step = Math.ceil(rawStep / 10) * 10;

                // Calculate number of intervals with that step, but clamp to minIntervals..maxIntervals
                let intervals = Math.round(maxY / step);


                // Calculate max value as step * intervals (rounding up maxY)
                let maxVal = step * intervals;

                // Generate ticks from 0 to maxVal
                let result = [];
                for (let i = 0; i <= intervals; i++) {
                    result.push(i * step);
                }

                // Update maxY to maxVal so everything aligns nicely
                maxY = maxVal;

                return result;
            }
            
            ListModel {
                id: ticksModel
            }

            function updateTicksModel() {
                ticksModel.clear()
                ticks = generateTicks()
                for (var i = 0; i < ticks.length; i++) {
                    ticksModel.append({"value": ticks[i]})
                }
            }
            Component.onCompleted: {
                updateTicksModel()
            }

            Repeater {
                model: ticksModel
                delegate: Item {
                    width: parent.width
                    height: 1

                    y: {
                        let percent = modelData / yTicks.maxY
                        return (1 - percent) * parent.height
                    }

                    Row {
                        spacing: 4
                        anchors.right: parent.left

                        Text {
                            text: modelData
                            font.pixelSize: 10
                            color: "#aaa"
                        }

                        Rectangle {
                            width: 6
                            height: 1
                            color: "#aaa"
                        }
                    }
                }
            }
        }


        // 🔹 Axes
        Rectangle { width: 2; height: parent.height; color: "#fc5a03"; x: 0 }
        Rectangle { width: parent.width; height: 2; color: "#fc5a03"; y: parent.height }
        Rectangle { width: parent.width; height: 2; color: "#fc5a03"; y: 0 }
        Rectangle { width: 2; height: parent.height; color: "#fc5a03"; x: parent.width }

        // 🔹 Axis Labels
        Text {
            text: "Y"
            color: "orange"
            x: 10
            y: 10
            font.pixelSize: 14
        }

        // 🔹 Connection Lines
        Canvas {
            id: connectionLines
            anchors.fill: parent
            antialiasing: true
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = "#80C8FF"
                ctx.lineWidth = 2

                ctx.beginPath()

                for (let i = 0; i < nodeModel.count - 1; i++) {
                    let p1 = nodeModel.get(i)
                    let p2 = nodeModel.get(i + 1)

                    let x1 = p1.x + 7.5
                    let y1 = p1.y + 7.5
                    let x2 = p2.x + 7.5
                    let y2 = p2.y + 7.5

                    let dx = x2 - x1
                    let dy = y2 - y1
                    let dist = Math.sqrt(dx * dx + dy * dy)
                    let ux = dx / dist
                    let uy = dy / dist
                    let r = 7.5

                    let startX = x1 + ux * r
                    let startY = y1 + uy * r
                    let endX = x2 - ux * r
                    let endY = y2 - uy * r

                    let cx1 = startX + dx * 0.25
                    let cy1 = startY + dy * 0.1
                    let cx2 = startX + dx * 0.75
                    let cy2 = startY + dy * 0.9

                    if (i === 0)
                        ctx.moveTo(startX, startY)

                    ctx.bezierCurveTo(cx1, cy1, cx2, cy2, endX, endY)
                }


                ctx.stroke()
            }
            Connections {
                target: nodeModel
                function onNodesChanged() {
                    connectionLines.requestPaint()
                }
            }
        }

        // 🔹 Draggable Nodes
        Repeater {
            id: points
            model: nodeModel

            Rectangle {
                id: dot
                width: 15
                height: 15
                radius: 20
                color: 'black'
                x: model.x
                y: model.y

                property int modelIndex: index

                Text {
                    anchors.centerIn: parent
                    text: model.label
                    color: "black"
                    font.pixelSize: 14
                }

                MouseArea {
                    anchors.fill: parent
                    drag.target: parent
                    onReleased: {
                        nodeModel.set(dot.modelIndex, {
                            x: dot.x,
                            y: dot.y,
                            label: nodeModel.get(dot.modelIndex).label
                        })
                        connectionLines.requestPaint()
                    }
                }

                DesignEffect {
                    id: orangeGlow
                    layerBlurRadius: 3
                    effects: [
                        DesignDropShadow {
                            color: "#fc5a03"; spread: 3; blur: 5
                            offsetX: 0; offsetY: 0; showBehind: true
                        }
                    ]
                }
            }
        }        
    }
    Component.onCompleted: updateGrid()
}
