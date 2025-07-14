import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: devSubMenu
    height: 40
    radius: 20

    // Adding the missing properties
    property var menuBackends
    property var submenuLists
    property var stepData
    property var stepIndex

    property string selectedStep
    property string selectedParentTitle
    property string selectedParentDescription
    property int elapsedSeconds: 0

    border.color: submenuLists.selectedIndices.includes(stepIndex) ? "white" : "#75fc5a03"

    gradient: Gradient {
        GradientStop { position: 0; color: "#282828" }
        GradientStop { position: 0.5; color: "#424242" }
        GradientStop { position: 1; color: "#f50e0e0e" }
    }

    Timer {
        id: stepTimer
        interval: 1000
        running: false
        repeat: true
        onTriggered: {
            elapsedSeconds++
        }
    }

    Text {
        id: description
        anchors.left: parent.left; anchors.leftMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        text: stepData.description || "No description"
        color: "white"
        horizontalAlignment: Text.AlignLeft
        font.pixelSize: 15
    }

    Text {
        id: playButton
        anchors.right: parent.right; anchors.rightMargin: 60
        anchors.verticalCenter: parent.verticalCenter
        text: stepTimer.running ? "⏸" : "▶ "
        color: "#fc5a03"
        font.pixelSize: 18
    }

    Text {
        id: timeElapsed
        text: Qt.formatTime(new Date((stepData.duration + elapsedSeconds) * 1000), "mm:ss") || "00:00"
        anchors.right: parent.right
        anchors.rightMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        color: "#fc5a03"
        font.pixelSize: 14
    }

    Rectangle {
        id: clickArea
        width: parent.width * 0.6; height: parent.height
        color: "transparent"
        anchors.left: parent.left
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: {
                toggleSelection(stepIndex) // Ensure selection toggles here
            }
        }
    }

    Rectangle {
        id: timerContainer
        width: 20; height: 20
        color: "transparent"
        radius: 4
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right; anchors.rightMargin: 50

        MouseArea {
            anchors.fill: parent
            onClicked: {
                stepTimer.stop()
                Qt.callLater(function() {
                    let menuDetails = menuBackend.getCurrentMenuDetails("dev")
                    menuBackend.recordStepTime(
                        stepData.description,
                        elapsedSeconds,
                        menuDetails.title,
                        menuDetails.description
                    )
                })
            }
            cursorShape: Qt.PointingHandCursor
        }

        Text {
            id: pauseButton
            anchors.centerIn: parent
            text: "■"
            color: "#fc5a03"
            font.pixelSize: 12
        }
    }

    Rectangle {
        id: timeClickArea
        width: 16; height: parent.height
        color: "transparent"
        anchors.right: parent.right; anchors.rightMargin: 63

        MouseArea {
            id: timerToggle
            anchors.fill: parent
            onClicked: stepTimer.running = !stepTimer.running
            cursorShape: Qt.PointingHandCursor
        }
    }

    MouseArea {
        id: rightClick
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: (mouse) => showContextSubMenu(mouse, stepData)
    }

    function toggleSelection(itemstepIndex) {
        let currentstepIndex = submenuList.selectedIndices.indexOf(itemstepIndex)
        if (currentstepIndex !== -1) {
            submenuList.selectedIndices.splice(currentstepIndex, 1)
        } else {
            submenuList.selectedIndices.push(itemstepIndex)
        }
        submenuList.selectedIndices = submenuList.selectedIndices.slice() // Update the selectedIndices array
    }

    function showContextSubMenu(mouse, stepData) {
        let menuDetails = menuBackend.getCurrentMenuDetails("dev")
        stepItem.selectedStep = stepData.description
        stepItem.selectedParentTitle = menuDetails.title
        stepItem.selectedParentDescription = menuDetails.description
        contextSubMenu.stepData = stepData
        contextSubMenu.parentTitle = menuDetails.title
        contextSubMenu.parentDescription = menuDetails.description
        contextSubMenu.x = mouse.x
        contextSubMenu.y = mouse.y
        contextSubMenu.open()
    }

    Menu {
        id: contextSubMenu
        property var stepData
        property string parentTitle
        property string parentDescription

        MenuItem {
            id: combineSteps
            text: "Combine"
            onTriggered: {
                let descriptions = []
                let stepData = menuBackend.SubMenuItems
                for (let i = 0; i < submenuList.selectedIndices.length; i++) {
                    let stepIndex = submenuList.selectedIndices[i]
                    if (stepIndex >= 0 && stepIndex < stepData.length) {
                        descriptions.push(stepData[stepIndex].description)
                    }
                }
                menuBackend.combineSteps(descriptions, contextSubMenu.parentTitle, contextSubMenu.parentDescription)
            }
        }

        MenuItem {
            id: expandStep
            text: "Expand"
            onTriggered: {
                menuBackend.expandStep(
                    contextSubMenu.stepData.description,
                    contextSubMenu.parentTitle,
                    contextSubMenu.parentDescription
                );
            }
        }

        MenuItem {
            id: deleteStep
            text: "Delete"
            onTriggered: {
                menuBackend.deleteStep(
                    contextSubMenu.stepData.description,
                    contextSubMenu.parentTitle,
                    contextSubMenu.parentDescription
                );
            }
        }
    }
}
