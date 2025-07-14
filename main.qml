

/*
This is a UI file (.ui.qml) that is intended to be edited in Qt Design Studio only.
It is supposed to be strictly declarative and only uses a subset of QML. If you edit
this file manually, you might introduce QML code that is not supported by Qt Design Studio.
Check out https://doc.qt.io/qtcreator/creator-quick-ui-forms.html for details on .ui.qml files.
*/
import QtQuick
import QtQuick.Controls.Windows
import QtQuick.Studio.DesignEffects
import io.qt.dynamicmenu 1.0
import "components"

ApplicationWindow {
    id: mainWindow
    width: Screen.width
    height: Screen.height
    opacity: 1
    color: "#010101"
    visible: true


    MenuBackend {
        id: menuBackend
    }

    Image {
        id: matte
        x: -200; y: -100; width: 2500; height: 1500;
        opacity: 0.2
        source: "./images/matte.jpg"
        fillMode: Image.PreserveAspectFit
    }

    Rectangle {
        id: topHalfWindow
        x: 55; y: 70; width: 1800; height: 470
        z: 9999
        color: "#00f64f1f"
        
        property var currentDragTask: null
        property var originalParent: null
        property int originalIndex: -1


        Item {
            id: overlay
            anchors.fill: parent
            z: 10000
            visible: true  // always visible
        }

        DevBoxBackground {
            id: devBoxBg
            width: 880
            anchors.top: parent.top
            anchors.bottom: parent.bottom 
            anchors.left: parent.left; anchors.leftMargin: 460
        }

        RealityBoxBackground {
            id: rltyBoxBg
            width: 440
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
        }

        IdeasBoxBackground  {
            id: ideasBoxBg
            width: 440
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left            
        }

        Image {
            x: 833; y: 5; width: 115; height: 50
            source: "./images/dev_title.png"
            fillMode: Image.PreserveAspectCrop
        }

        Image {
            x: 1522; y: 5; width: 120; height: 50
            source: "./images/reality_title.png"
            fillMode: Image.PreserveAspectCrop
        }

        IdeasMenuScroll{
            id: ideasScrollView
            dragRoot: topHalfWindow
            overlay: overlay
            anchors.top: ideasBoxBg.top; anchors.topMargin: 5
            anchors.left: ideasBoxBg.left; anchors.leftMargin: 17
            menuBackends: menuBackend
        }

        DevMenuScroll{
            id: devScrollView
            dragRoot: topHalfWindow
            overlay: overlay
            anchors.top: devBoxBg.top; anchors.topMargin: 60
            anchors.left: devBoxBg.left; anchors.leftMargin: 15
            menuBackends: menuBackend
            inputBackends: inputBackend
        }

        RealityMenuScroll{
            id: rltyScrollViews
            dragRoot: topHalfWindow
            overlay: overlay
            anchors.top: rltyBoxBg.top; anchors.topMargin: 57
            anchors.left: rltyBoxBg.left; anchors.leftMargin: 15
            menuBackends: menuBackend
        }
    }

    Rectangle {
        id: bottomHalfWindow
        x: 55; y: 558; width: 1812; height: 450
        color: "#00f64f1f"
        
        GraphBackground {
            id: graphBoxBg
            y: -1;  height: 460; z: 0
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 906; anchors.rightMargin: 8
        }

        Graph {
            id: graph
            z: 1
            anchors.top: graphBoxBg.top; anchors.topMargin: 75
            anchors.left: graphBoxBg.left; anchors.leftMargin: 62
        }

        RangeSlider {
            id: rangeSlider
            x: 1550
            y: 27
            z: 10
            width: 200 
            height: 20   
            onRangeChanged: graph.setDateRange(startDate, endDate)
        }
        
        Rectangle {
            id: rectangle3
            y: -1
            height: 460
            color: "#373737"
            radius: 45
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 8
            anchors.rightMargin: 1213
            DesignEffect {
                layerBlurRadius: 5
                effects: [
                    DesignDropShadow {}
                ]
            }
        }
    }

    ProjectSelector {
        id: projectSelector
        anchors.left: parent.left; anchors.leftMargin: 5
        anchors.top: parent.top; anchors.topMargin: 400
        anchors.bottom: parent.bottom
        projects: [
            { image: "../images/Bored_title.png", name: "Alpha" },
            { image: "images/project2.jpg", name: "Beta" },
            { image: "images/project3.jpg", name: "Gamma" }
        ]
        onProjectSelected: (index) => {
            console.log("Switched to project:", index)
            menuBackend.cycleTaskFile(index)
            // You can swap project views here based on index
        }
    }
}
