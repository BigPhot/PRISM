// MenuScrollView.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Studio.DesignEffects

Item {
    id: devMenuScroll
    width: 855
    height: 600

    // External interface properties injected by parent or controller
    property var menuBackends
    property var inputBackends
    property var dragRoot 
    property var overlay

    // Scrollable container for menu items and steps
    Flickable {
        id: menuContainer
        width: parent.width
        height: 408
        contentWidth: width
        contentHeight: columnView.height
        clip: true

        // Enables wheel scrolling only when mouse is inside area
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse
            //enabled: mouseArea.containsMouse
        }

        // Used to detect hover state for scrolling control
        MouseArea {
            id: menuScrollArea
            anchors.fill: parent
            hoverEnabled: true
        }

        // Stack of UI elements (input + task list)
        Column {
            id: columnView
            width: parent.width
            spacing: 5

            // Input field overlay for either context or step creation
            Rectangle {
                id: inputContainer
                width: 855
                height: 99
                radius: 25
                visible: false
                border.color: "#85fc5a03"

                // Tracks the action this input is for
                property string actionType: ""
                property int parentIndex: -1

                gradient: Gradient {
                    GradientStop { position: 0; color: "#282828" }
                    GradientStop { position: 0.5; color: "#424242" }
                    GradientStop { position: 1; color: "#f50e0e0e" }
                }

                // Text entry with submit handling
                TextInput {
                    id: inputField
                    anchors.fill: parent
                    anchors.topMargin: 25
                    anchors.leftMargin: 18
                    color: "#ffffff"
                    font.pixelSize: 14
                    horizontalAlignment: TextInput.AlignHCLeft
                    wrapMode: TextInput.Wrap

                    // Pressing Enter submits the input to the backend
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            if (inputContainer.actionType === "context") {
                                inputBackend.processContextInput(inputField.text, inputContainer.parentIndex)
                            } else if (inputContainer.actionType === "add") {
                                inputBackend.processStepInput(inputField.text, inputContainer.parentIndex)
                            }

                            inputField.clear()
                            inputContainer.visible = !inputContainer.visible
                            menuBackends.refreshMenu()
                        }
                    }
                }

                // Fade animation when changing opacity
                Behavior on opacity {
                    NumberAnimation { duration: 500 }
                }
            }

            // The main list of task cards
            ListView {
                id: menuList
                width: parent.width
                height: 400
                model: menuBackend.DevMenuItems

                // One visual task + its substeps
                delegate: Item {
                    id: taskRect
                    width: 910
                    height: 165 + (submenuContainer.visible ? submenuContainer.height : 0)

                    property int taskIndex: index

                    Column {
                        width: parent.width
                        spacing: 0

                        // Visual representation of the main task
                        DevMenu {
                            width: 850
                            height: 160
                        }

                        // Container for the task's substeps
                        Rectangle {
                            id: submenuContainer
                            visible: false
                            width: parent.width
                            height: 160
                            color: "transparent"

                            // Metadata and references passed to step delegates
                            property int stepIndex: index
                            property var stepData: modelData
                            property var submenuLists: submenuList
                            property var menuBackends: menuBackend

                            // List of individual steps under this task
                            ListView {
                                id: submenuList
                                width: parent.width
                                height: parent.height
                                model: menuBackend.SubMenuItems

                                // Used to track multi-selection if needed
                                property var selectedIndices: []

                                // Visual representation of a single step
                                delegate: Item {
                                    id: stepItem
                                    width: submenuList.width
                                    height: 40  // Matches DevSubMenu height

                                    property int stepIndex: index
                                    property string selectedStep: ""
                                    property string selectedParentTitle: ""
                                    property string selectedParentDescription: ""

                                    DevSubMenu {
                                        id: stepContent
                                        width: 830
                                        stepData: modelData
                                        stepIndex: index
                                        submenuLists: submenuList
                                        menuBackends: menuBackend
                                        selectedStep: stepItem.selectedStep
                                        selectedParentTitle: stepItem.selectedParentTitle
                                        selectedParentDescription: stepItem.selectedParentDescription
                                    }

                                    // Enables dragging steps within the submenu
                                    MouseArea {
                                        id: stepDragArea
                                        width: parent.width * 0.2
                                        height: parent.height
                                        drag.target: stepItem
                                        drag.axis: Drag.YAxis

                                        Drag.active: drag.active
                                        Drag.hotSpot.y: height / 2
                                        Drag.mimeData: { "stepIndex": stepIndex }

                                        // Handles repositioning steps when released
                                        onReleased: {
                                            let dragY = stepItem.y
                                            let itemHeight = stepItem.height
                                            let totalSteps = submenuList.count

                                            let fromIndex = stepIndex
                                            let toIndex = Math.floor(dragY / itemHeight)

                                            toIndex = Math.max(0, Math.min(toIndex, totalSteps - 1))

                                            if (toIndex !== fromIndex) {
                                                menuBackend.moveStep(fromIndex, toIndex)
                                            } else {
                                                stepItem.y = fromIndex * itemHeight
                                            }
                                        }
                                    }
                                }

                                Component.onCompleted: {
                                    selectedIndices = []
                                }
                            }
                        }
                    }

                    // Drag handle for full task movement
                    MouseArea {
                        id: taskDragArea
                        width: parent.width * 0.1
                        anchors.left: parent.left 
                        height: 165
                        anchors.top: parent.top

                        drag.target: taskRect
                        drag.axis: Drag.XAndYAxis

                        Drag.active: drag.active
                        Drag.hotSpot.x: width / 2
                        Drag.hotSpot.y: height / 2
                        Drag.mimeData: { "taskIndex": taskIndex }

                        // Prepares the task for global dragging across categories
                        onPressed: {
                            dragRoot.originalParent = taskRect.parent
                            dragRoot.originalIndex = taskIndex

                            let globalPos = taskRect.mapToItem(null, 0, 0)
                            taskRect.parent = overlay

                            let localPos = overlay.mapFromItem(null, globalPos.x, globalPos.y)
                            taskRect.x = localPos.x
                            taskRect.y = localPos.y
                            taskRect.z = 9999

                            dragRoot.currentDragTask = {
                                index: taskIndex,
                                category: "dev",
                                item: taskRect
                            }
                        }

                        // Handles logic after task drop (category switch or reorder)
                        onReleased: {
                            if (!dragRoot.currentDragTask)
                                return

                            let dragInfo = dragRoot.currentDragTask
                            let fromIndex = dragInfo.index

                            let dragY = taskRect.y + menuList.contentY
                            let dragX = taskRect.x

                            let targetCategory = getDropCategory(dragX)
                            let toIndex = getDropIndex(dragY, 165, menuBackend.DevMenuItems.length)

                            // Reparent task back to original layout container
                            taskRect.parent = dragRoot.originalParent
                            taskRect.x = 0
                            taskRect.y = fromIndex * 165
                            taskRect.z = 0

                            if (targetCategory && targetCategory !== dragInfo.category) {
                                menuBackend.moveTaskToCategory(
                                    dragInfo.category,
                                    fromIndex,
                                    targetCategory
                                )
                            } else if (toIndex !== -1 && toIndex !== fromIndex) {
                                menuBackend.moveTask(fromIndex, toIndex, dragInfo.category)
                            } else {
                                console.log("No valid move detected.")
                            }

                            dragRoot.currentDragTask = null
                        }
                    }

                    // Computes the index to insert dragged task based on Y position
                    function getDropIndex(dragY, taskHeight, itemCount) {
                        for (let i = 0; i < itemCount; i++) {
                            let itemTop = i * taskHeight
                            let itemBottom = itemTop + taskHeight
                            let upperZone = itemTop + taskHeight * 0.75
                            let bottomZone = itemTop - taskHeight * 0.25

                            if (dragY >= bottomZone && dragY < upperZone) {
                                return i
                            }
                        }
                        return -1
                    }

                    // Maps horizontal position to a semantic task category
                    function getDropCategory(dragX) {
                        if (dragX >= ideasBoxBg.x && dragX < ideasBoxBg.x + ideasBoxBg.width){
                            return "idea"
                        } else if (dragX >= devBoxBg.x && dragX < devBoxBg.x + devBoxBg.width){
                            return "dev"
                        } else if (dragX >= rltyBoxBg.x && dragX < rltyBoxBg.x + rltyBoxBg.width){
                            return "rlty"
                        } else {
                            return null
                        }
                    }
                }
            }
        }
    }
}
