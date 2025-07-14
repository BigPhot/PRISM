import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Studio.DesignEffects

Rectangle {
    id: devBackground
    color: "#f53f3f3f"
    radius: 30
    opacity: 0.9
    border.color: "#fc5a03"

    Image {
        id: backgroundImage
        x: 16; y: 16; width: 845; height: 437
        source: "../images/upper_bckg.jpg"
        fillMode: Image.PreserveAspectCrop
    }

    Image {
        id: topBackgroundImage
        // Top edge tiling
        x: 30; y: 0; width: 825; height: 19
        source: "../images/upper_bckg.jpg"
        fillMode: Image.TileHorizontally 
    }

    Image {
        id: leftBackgroundImage
        // Left edge tiling
        x: 2; y: 24; width: 18; height: 416
        source: "../images/upper_bckg.jpg"
        fillMode: Image.TileVertically 
    }

    Image {
        id: bottomBackgroundImage
        // Bottom edge tiling
        x: 26; y: 452; width: 825; height: 19
        source: "../images/upper_bckg.jpg"
        fillMode: Image.TileHorizontally 
    }

    Image {
        id: rightBackgroundImage
        // Right edge tiling
        x: 860; y: 24; width: 18; height: 416
        source: "../images/upper_bckg.jpg"
        fillMode: Image.TileVertically 
    }

    Rectangle {
        id: topLeftCircle
        x: 3; y: 2; width: 40; height: 40; radius: 35
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
        x: 837; y: 2; width: 40; height: 40; radius: 35
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
        x: 3; y: 428; width: 40; height: 40; radius: 35
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
        x: 837; y: 428; width: 40; height: 40; radius: 35
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
        // Creates a glowing orange shadow effect behind the whole container
        layerBlurRadius: 3
        effects: [
            DesignDropShadow {
                color: "#fc5a03"; spread: 3; blur: 5
                offsetX: 0; offsetY: 0; showBehind: true
            }
        ]
    }
}
