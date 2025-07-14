// MenuScrollView.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Studio.DesignEffects

Item {
    id: ideaMenuScroll
    width: 405
    height: 600

    // Backend objects and helpers injected from outside
    property var menuBackends
    // Object holding drag state like original parent, index, and current dragged task info
    property var dragRoot  
    // Overlay Item used as temporary parent to allow dragging items freely above other UI
    property var overlay   

    // "Add" button outside scrollable Flickable area
    Rectangle {
        id: add
        x: 157; y: 3; width: 105; height: 42

        // Image filling the add button rectangle
        Image {
            id: ideaImage
            anchors.fill: parent
            source: "../images/idea_title.png"
            fillMode: Image.PreserveAspectCrop
        }

        // MouseArea detects clicks on the add button
        MouseArea {
            id: addButton
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: {
                // Toggle visibility of the input container for adding new tasks
                ideaMenuContainer.inputContainer.visible = !ideaMenuContainer.inputContainer.visible
                // Hide the add button while input is visible
                add.visible = !add.visible
            }
        }
    }

    // Scrollable container holding the task list and input container
    Flickable {
        id: ideaMenuContainer
        width: parent.width
        height: 408
        anchors.top: parent.top
        anchors.topMargin: 50

        // Content size defined by the column containing input and list
        contentWidth: width
        contentHeight: columnView.height
        clip: true

        // Expose the input container so it can be toggled externally
        property alias inputContainer: inputContainer
        
        // Transparent MouseArea to capture hover for wheel scrolling activation
        MouseArea {
            id: wheelArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        // WheelHandler enabled only when mouse hovers over flickable area
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse
            enabled: wheelArea.containsMouse
        }

        // Column to stack the input container and the list vertically
        Column {
            id: columnView
            width: parent.width
            spacing: 5

            // Input container for new task entry, initially hidden
            Rectangle {
                id: inputContainer
                width: 405
                height: 99
                radius: 25
                visible: false
                border.color: "#85fc5a03"

                // Properties to track the action type and index of the parent task
                property string actionType: ""
                property int parentIndex: -1

                // Background gradient styling
                gradient: Gradient {
                    GradientStop { position: 0; color: "#282828" }
                    GradientStop { position: 0.5; color: "#424242" }
                    GradientStop { position: 1; color: "#f50e0e0e" }
                }

                // TextInput for typing the new task
                TextInput {
                    id: inputField
                    anchors.fill: parent
                    anchors.topMargin: 25
                    anchors.leftMargin: 18
                    color: "#ffffff"
                    font.pixelSize: 14
                    horizontalAlignment: TextInput.AlignHCLeft
                    wrapMode: TextInput.Wrap

                    // Submit input on Enter or Return key press
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            // Process the input with backend
                            inputBackend.processTaskInput(inputField.text);   
                            inputField.clear();
                            inputContainer.visible = false;
                            add.visible = true;
                            // Refresh the menu to show the new task
                            menuBackend.refreshMenu();
                        }
                    }
                }

                // Animate opacity changes on visibility toggle
                Behavior on opacity {
                    NumberAnimation { duration: 500 }
                }
            }
       
            // ListView displaying tasks (ideas)
            ListView {
                id: menuList 
                width: parent.width
                height: 400
                model: menuBackend.IdeaMenuItems

                // Delegate describing each task item and its submenu
                delegate: Item {
                    id: taskRect
                    width: 405
                    // Height expands if submenu is visible
                    height: 165 + (submenuContainer.visible ? submenuContainer.height : 0)

                    // Track this delegate's index for drag and drop operations
                    property int taskIndex: index  

                    // Vertical layout stacking the task and submenu
                    Column {
                        width: parent.width
                        spacing: 0

                        // Main task display component (custom component)
                        IdeasMenu {
                            width: 405
                            height: 160
                        }

                        // Submenu container for steps or subtasks, initially hidden
                        Rectangle {
                            id: submenuContainer
                            visible: false
                            width: parent.width
                            height: 119
                            color: "transparent"

                            // ListView showing submenu items for the task
                            ListView {
                                id: submenuList
                                width: parent.width
                                height: parent.height
                                model: menuBackend.SubMenuItems

                                // Delegate for submenu steps (custom component)
                                delegate: RealitySubMenu {
                                    width: 380
                                    stepData: modelData
                                    stepIndex: index
                                    submenuLists: submenuList
                                    menuBackends: menuBackend
                                }
                            }
                        }
                    }

                    // MouseArea for dragging the task, limited to left 20% width
                    MouseArea {
                        id: dragArea
                        width: parent.width * 0.2
                        height: parent.height
                        anchors.left: parent.left
                        drag.target: taskRect
                        drag.axis: Drag.XAndYAxis

                        // Enable drag only if Drag is active
                        Drag.active: drag.active
                        // Set drag hotspot to center of dragged area
                        Drag.hotSpot.x: width / 2
                        Drag.hotSpot.y: height / 2
                        // Attach MIME data with task index for drag drop identification
                        Drag.mimeData: { "taskIndex": taskIndex }

                        onPressed: {
                            // Save original parent and index before dragging
                            dragRoot.originalParent = taskRect.parent
                            dragRoot.originalIndex = taskIndex

                            // Map task position to global and then to overlay local coordinates
                            let globalPos = taskRect.mapToItem(null, 0, 0)
                            taskRect.parent = overlay
                            let localPos = overlay.mapFromItem(null, globalPos.x, globalPos.y)

                            // Position dragged item inside overlay at same place visually
                            taskRect.x = localPos.x
                            taskRect.y = localPos.y
                            // Bring dragged item to front visually
                            taskRect.z = 9999

                            // Save current drag task info for drop handling
                            dragRoot.currentDragTask = {
                                index: taskIndex,
                                category: "idea",
                                item: taskRect
                            }
                            console.log("Task reparented to:", taskRect.parent)
                        }

                        onReleased: {
                            if (!dragRoot.currentDragTask)
                                return;

                            let dragInfo = dragRoot.currentDragTask;
                            let fromIndex = dragInfo.index;

                            // Calculate dragged position relative to list content scroll
                            let dragY = taskRect.y + menuList.contentY;
                            let dragX = taskRect.x;

                            // Determine drop category based on horizontal position
                            let targetCategory = getDropCategory(dragX);
                            // Calculate drop index in the list based on vertical position
                            let toIndex = getDropIndex(dragY, 165, menuBackend.DevMenuItems.length);

                            // Reparent dragged item back to its original parent
                            taskRect.parent = dragRoot.originalParent;

                            // Reset dragged item's position to original list layout position
                            taskRect.x = 0;
                            taskRect.y = fromIndex * 165;
                            taskRect.z = 0;

                            // Move task to a different category if dropped in another box
                            if (targetCategory && targetCategory !== dragInfo.category) {
                                menuBackend.moveTaskToCategory(
                                    dragInfo.category,
                                    fromIndex,
                                    targetCategory
                                );
                            } else if (toIndex !== -1 && toIndex !== fromIndex) {
                                // Move task to new index in the same category
                                menuBackend.moveTask(fromIndex, toIndex, dragInfo.category);
                            } else {
                                // No move detected, do nothing
                                console.log("No valid move detected.");
                            }
                            // Clear drag state
                            dragRoot.currentDragTask = null;
                        }
                    }

                    // Calculate target index in the list for drop based on Y position
                    function getDropIndex(dragY, taskHeight, itemCount) {
                        console.log('num', itemCount)
                        for (let i = 0; i < itemCount; i++) {
                            let itemTop = i * taskHeight
                            let itemBottom = itemTop + taskHeight
                            // Zones used to define sensitive drop area for smoother UX
                            let upperZone = itemTop + taskHeight * 0.75
                            let bottomZone = itemTop - taskHeight * 0.25

                            console.log(dragY, itemTop, upperZone)

                            // Return index if dragY falls inside the sensitive zone around the item
                            if (dragY >= bottomZone && dragY < upperZone) {
                                return i
                            }
                        }
                        return -1
                    }

                    // Determine drop category based on horizontal drag position relative to defined boxes
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
