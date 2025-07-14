// ProjectCarousel.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    width: 40
    height: parent.height

    property var projects: [] // Array of { image: string, name: string }
    signal projectSelected(int index)
    

    ListView {
        id: listView
        anchors.fill: parent
        orientation: ListView.Vertical
        spacing: 10
        clip: true
        model: projects

        delegate: Item {
            width: listView.width
            height: 40

            Rectangle {
                id: thumbnailBox
                width: 40
                height: 40
                color: index === listView.currentIndex ? "#80C8FF" : "#222"
                border.color: index === listView.currentIndex ? "#4AF" : "#444"
                anchors.fill: parent

                Image {
                    id: thumb
                    anchors.fill: parent
                    source: modelData.image
                    fillMode: Image.Stretch
                    smooth: true
                    clip: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        listView.currentIndex = index
                        projectSelected(index)
                    }
                }
            }
        }
    }
}
