// MenuScrollView.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Studio.DesignEffects

Item {
    id: realityMenuScroll
    // Root container with fixed width and height
    width: 405
    height: 600

    // Properties to hold external references for backend logic, drag state, and overlay container
    property var menuBackends
    property var dragRoot 
    property var overlay

    Flickable {
        id: menuContainer
        // Scrollable container for the menu list
        width: parent.width
        height: 408
        contentWidth: width
        contentHeight: columnView.height
        clip: true  // Prevents drawing outside bounds

        // Handles mouse wheel scrolling when mouse is over the Flickable
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse
            enabled: mouseArea.containsMouse
        }
        
        // MouseArea to detect mouse hover inside Flickable, needed for WheelHandler enablement
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
        }

        Column {
            id: columnView           
            // Container holding the list and spacing between items
            width: parent.width
            spacing: 5

            ListView {
                id: menuList 
                // ListView displaying "reality" menu items from the backend model
                width: parent.width
                height: 400
                model: menuBackend.RltyMenuItems

                delegate: Item {
                    id: taskRect
                    // Delegate Item for each task rectangle including submenu container
                    width: 405
                    height: 165 + (submenuContainer.visible ? submenuContainer.height : 0)

                    // Stores the index of this task in the model
                    property int taskIndex: index 

                    Column {
                        width: parent.width
                        spacing: 0
                                    
                        RealityMenu {
                            id: realityMenu
                            // Main visible part of each task (160 height)
                            width: 405
                            height: 160
                        }

                        Rectangle {
                            id: submenuContainer
                            // Submenu container, initially hidden, expands below main menu item
                            visible: false
                            width: parent.width
                            height: 119
                            color: "transparent"

                            ListView {
                                id: submenuList
                                // Submenu ListView showing submenu steps related to this task
                                width: parent.width
                                height: parent.height
                                model: menuBackend.SubMenuItems

                                delegate: RealitySubMenu {
                                    // Delegate representing each submenu step
                                    width: 380
                                    stepData: modelData
                                    stepIndex: index
                                    submenuLists: submenuList
                                    menuBackends: menuBackend
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: dragArea
                        // Area to handle dragging of the task item, only left 20% width active
                        width: parent.width * 0.2
                        height: parent.height
                        anchors.left: parent.left
                        drag.target: taskRect
                        drag.axis: Drag.XAndYAxis

                        // Enables dragging behavior with hotspot at center of dragged item
                        Drag.active: drag.active
                        Drag.hotSpot.x: width / 2
                        Drag.hotSpot.y: height / 2
                        Drag.mimeData: { "taskIndex": taskIndex }

                        onPressed: {
                            // Save original parent and index before reparenting for drag
                            dragRoot.originalParent = taskRect.parent
                            dragRoot.originalIndex = taskIndex

                            // Convert global position for proper positioning in overlay
                            let globalPos = taskRect.mapToItem(null, 0, 0)
                            taskRect.parent = overlay

                            let localPos = overlay.mapFromItem(null, globalPos.x, globalPos.y)
                            taskRect.x = localPos.x
                            taskRect.y = localPos.y
                            taskRect.z = 9999  // Bring dragged item to front

                            // Save drag info in dragRoot for use on drop
                            dragRoot.currentDragTask = {
                                index: taskIndex,
                                category: "rlty",
                                item: taskRect
                            }
                            console.log("Task reparented to:", taskRect.parent)
                        }

                        onReleased: {
                            if (!dragRoot.currentDragTask)
                                return;

                            let dragInfo = dragRoot.currentDragTask;
                            let fromIndex = dragInfo.index;

                            // Calculate drop coordinates relative to list content
                            let dragY = taskRect.y + menuList.contentY;
                            let dragX = taskRect.x;

                            // Determine drop category based on X position
                            let targetCategory = getDropCategory(dragX);
                            // Determine drop index based on Y position
                            let toIndex = getDropIndex(dragY, 165, menuBackend.DevMenuItems.length);

                            // Reparent back to original container and reset position
                            taskRect.parent = dragRoot.originalParent;
                            taskRect.x = 0;
                            taskRect.y = fromIndex * 165;
                            taskRect.z = 0;

                            // If dropped in different category, move task between categories
                            if (targetCategory && targetCategory !== dragInfo.category) {
                                menuBackend.moveTaskToCategory(
                                    dragInfo.category,
                                    fromIndex,
                                    targetCategory
                                );
                            } else if (toIndex !== -1 && toIndex !== fromIndex) {
                                // If dropped in same category but different position, reorder tasks
                                menuBackend.moveTask(fromIndex, toIndex, dragInfo.category);
                            } else {
                                // No movement needed
                                console.log("No valid move detected.");
                            }

                            // Clear current drag task info
                            dragRoot.currentDragTask = null;
                        }
                    }

                    // Returns the target index in list where item should be dropped based on Y coordinate
                    function getDropIndex(dragY, taskHeight, itemCount) {
                        console.log('num', itemCount)
                        for (let i = 0; i < itemCount; i++) {
                            let itemTop = i * taskHeight
                            let itemBottom = itemTop + taskHeight
                            let upperZone = itemTop + taskHeight * 0.75
                            let bottomZone = itemTop - taskHeight * 0.25

                            console.log(dragY, itemTop, upperZone)

                            if (dragY >= bottomZone && dragY < upperZone) {
                                return i
                            }
                        }
                        return -1
                    }

                    // Returns the category ("idea", "dev", or "rlty") based on X coordinate of drop
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
