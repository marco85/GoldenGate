import QtQuick 2.15
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#121622"
            Column {
                anchors.centerIn: parent
                spacing: 14
                Text {
                    text: "macOS 27 Golden Gate — Built for Surface Laptop 5"
                    color: "#FFFFFF"
                    font.family: "Inter"
                    font.pixelSize: 24
                    font.bold: true
                }
                Text {
                    text: "Liquid Glass translucency, calibrated MacBook trackpad inertia, Face ID IR unlock, and 3-engine AirDrop."
                    color: "#A5B4CB"
                    font.family: "Inter"
                    font.pixelSize: 15
                }
            }
        }
    }
}
