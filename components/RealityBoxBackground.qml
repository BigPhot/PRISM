// OrangeBoxBackground.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Studio.DesignEffects

Rectangle {
    id: realityBoxBackground
    radius: 30
    color: "#f53f3f3f"
    border.color: "#75fc5a03"

    Image {
        id: backgroundImage
        x: 16; y: 16; width: 410; height: 437
        source: "../images/upper_bckg.jpg"
        fillMode: Image.PreserveAspectCrop
    }

    Image {
        id: topBackgroundImage
        x: 22; y: 1; width: 390; height: 20
        source: "../images/upper_bckg.jpg"
        fillMode: Image.TileHorizontally
    }


    Image {
        id: leftBackgroundImage
        x: 1; y: 24; width: 18; height: 422
        source: "../images/upper_bckg.jpg"
        fillMode: Image.TileVertically
    }

    Image {
        id: bottomBackgroundImage
        x: 22; y: 450; width: 390; height: 19
        source: "../images/upper_bckg.jpg"
        fillMode: Image.TileHorizontally
    }

    Image {
        id: rightBackgroundImage
        x: 420; y: 24; width: 18; height: 422
        source: "../images/upper_bckg.jpg"
        fillMode: Image.TileVertically
    }

    Rectangle {
        id: topLeftCircle
        x: 3; y: 2; width: 40; height: 40
        radius: 35
        rotation: 45
        gradient: Gradient {
            GradientStop { position: 0; color: "#000000" }
            GradientStop { position: 0.25; color: "#050505" }
            GradientStop { position: 0.75; color: "#313131" }
            GradientStop { position: 1; color: "#565656" }
            orientation: Gradient.Horizontal
        }
    }


    Rectangle {
        id: topRightCircle
        x: 396; y:1; width: 40; height: 40; 
        radius: 35
        rotation: 135
        gradient: Gradient {
            GradientStop { position: 0; color: "#000000" }
            GradientStop { position: 0.25; color: "#050505" }
            GradientStop { position: 0.75; color: "#313131" }
            GradientStop { position: 1; color: "#565656" }
            orientation: Gradient.Horizontal
        }   
    }

    Rectangle {
        id: bottomLeftCircle
        x: 3; y: 428; width: 40; height: 40
        radius: 35
        rotation: 315
        gradient: Gradient {
            GradientStop { position: 0; color: "#000000" }
            GradientStop { position: 0.25; color: "#050505" }
            GradientStop { position: 0.75; color: "#313131" }
            GradientStop { position: 1; color: "#565656" }
            orientation: Gradient.Horizontal
        }
    }

    Rectangle {
        id: bottomRightCircle
        x: 397; y: 428; width: 40; height: 40
        radius: 35
        rotation: 225
        gradient: Gradient {
            GradientStop { position: 0; color: "#000000" }
            GradientStop { position: 0.25; color: "#050505" }
            GradientStop { position: 0.75; color: "#313131" }
            GradientStop { position: 1; color: "#565656" }
            orientation: Gradient.Horizontal
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
