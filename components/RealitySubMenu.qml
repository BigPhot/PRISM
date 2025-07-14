import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: realitySubMenu
    // Fixed height and rounded corners for the step rectangle
    height: 60
    radius: 20

    // Properties passed from outside for backend interaction, submenu control, and step data
    property var menuBackends
    property var submenuLists
    property var stepData
    property var stepIndex

    // Properties for tracking selection state and elapsed time
    property string selectedStep: ""
    property string selectedParentTitle: ""
    property string selectedParentDescription: ""
    property int elapsedSeconds: 0

    // Border color with transparency
    border.color: "#75fc5a03"

    // Gradient background with three color stops for a subtle dark shading effect
    gradient: Gradient {
        GradientStop { position: 0; color: "#282828" }
        GradientStop { position: 0.5; color: "#424242" }
        GradientStop { position: 1; color: "#f50e0e0e" }
    }

    Text {
        id: description
        // Left-aligned text showing the step description or a fallback string
        width: 270
        anchors.left: parent.left
        anchors.leftMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        text: stepData.description || "No description"
        color: "white"
        horizontalAlignment: Text.AlignLeft
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }

    Text {
        id: timeElapsed
        // Right-aligned text showing formatted time (duration + elapsed seconds)
        // Displays in mm:ss format, fallback to "00:00"
        text: Qt.formatTime(new Date((stepData.duration + elapsedSeconds) * 1000), "mm:ss") || "00:00"
        anchors.right: parent.right
        anchors.rightMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        color: "#fc5a03"
        font.pixelSize: 14
    }
}
