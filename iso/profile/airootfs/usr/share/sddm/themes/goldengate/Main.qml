import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 2256
    height: 1504
    color: "#111622"

    // Safe first-boot username resolution (prevents blank lastUser bug on first boot after install)
    readonly property string resolvedUser: {
        if (userModel.lastUser && userModel.lastUser.length > 0) {
            return userModel.lastUser;
        }
        var first = userModel.data(userModel.index(0, 0), Qt.UserRole + 1);
        return first ? first : "user";
    }

    property string statusMessage: "Face ID Active — Glance at Camera or Enter Password"
    property bool hasError: false

    // Warm Golden Gate dusk gradient background
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#141B2D" }
        GradientStop { position: 0.55; color: "#2A2438" }
        GradientStop { position: 1.0; color: "#191522" }
    }

    // Face ID Dynamic Island / Notch Pill at top center
    Rectangle {
        id: faceIdPill
        anchors.top: parent.top
        anchors.topMargin: 28
        anchors.horizontalCenter: parent.horizontalCenter
        width: 380
        height: 34
        radius: 17
        color: "#CC12141C"
        border.color: "#38FFFFFF"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "🔒 " + root.statusMessage
            color: root.hasError ? "#FF6B6B" : "#D6E2F5"
            font.family: "Inter"
            font.pixelSize: 13
            font.weight: Font.Medium
        }
    }

    // macOS 27 Golden Gate Oversized Top Clock & Date
    Column {
        anchors.top: faceIdPill.bottom
        anchors.topMargin: 44
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4

        Text {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
            color: "#D8E2F2"
            font.family: "Inter"
            font.pixelSize: 24
            font.weight: Font.DemiBold
        }

        Text {
            id: timeLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(new Date(), "h:mm")
            color: "#F8FAFC"
            font.family: "Inter"
            font.pixelSize: 108
            font.weight: Font.Bold
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date();
            dateLabel.text = Qt.formatDateTime(now, "dddd, MMMM d");
            timeLabel.text = Qt.formatDateTime(now, "h:mm");
        }
    }

    // Bottom-Center User Avatar & Liquid Glass Password Pill
    Column {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 86
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        Rectangle {
            width: 72
            height: 72
            radius: 36
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#33FFFFFF"
            border.color: "#66FFFFFF"
            border.width: 1.5

            Text {
                anchors.centerIn: parent
                text: root.resolvedUser.length > 0 ? root.resolvedUser.slice(0, 1).toUpperCase() : "G"
                color: "#FFFFFF"
                font.family: "Inter"
                font.pixelSize: 30
                font.weight: Font.Bold
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.resolvedUser
            color: "#F5F7FA"
            font.family: "Inter"
            font.pixelSize: 17
            font.weight: Font.DemiBold
        }

        Rectangle {
            width: 240
            height: 38
            radius: 19
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#40FFFFFF"
            border.color: root.hasError ? "#FF6B6B" : "#70FFFFFF"
            border.width: 1

            TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 36
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: "#FFFFFF"
                font.family: "Inter"
                font.pixelSize: 14
                focus: true
                Keys.onReturnPressed: sddm.login(root.resolvedUser, passwordInput.text, sessionModel.lastIndex)
                Keys.onEnterPressed: sddm.login(root.resolvedUser, passwordInput.text, sessionModel.lastIndex)
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "Enter Password"
                color: "#A8FFFFFF"
                font.family: "Inter"
                font.pixelSize: 13
                visible: passwordInput.text.length === 0
            }

            Rectangle {
                width: 26
                height: 26
                radius: 13
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                color: "#55FFFFFF"

                Text {
                    anchors.centerIn: parent
                    text: "→"
                    color: "#FFFFFF"
                    font.pixelSize: 14
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: sddm.login(root.resolvedUser, passwordInput.text, sessionModel.lastIndex)
                }
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.hasError = true;
            root.statusMessage = "Incorrect Password — Try Again or Use Face ID";
            passwordInput.text = "";
            passwordInput.forceActiveFocus();
        }
    }

    Component.onCompleted: passwordInput.forceActiveFocus()
}
