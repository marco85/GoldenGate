import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 2256
    height: 1504
    color: "#0F121C"

    // Safe first-boot username resolution
    readonly property string resolvedUser: {
        if (userModel.lastUser && userModel.lastUser.length > 0) {
            return userModel.lastUser;
        }
        var first = userModel.data(userModel.index(0, 0), Qt.UserRole + 1);
        return first ? first : "live";
    }

    // Face ID State Machine: "scanning", "unlocked", "failed", "password"
    property string faceIdState: "scanning"
    property string statusMessage: "Face ID"
    property bool isShaking: false

    // macOS 27 Golden Gate Dusk Gradient
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#111728" }
        GradientStop { position: 0.50; color: "#2B213A" }
        GradientStop { position: 1.0; color: "#16131F" }
    }

    // Dynamic Island / Face ID Top Pill
    Rectangle {
        id: dynamicIsland
        anchors.top: parent.top
        anchors.topMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.faceIdState === "unlocked" ? 220 : (root.faceIdState === "failed" ? 260 : 190)
        height: 38
        radius: 19
        color: "#E60F111A"
        border.color: root.faceIdState === "unlocked" ? "#5030D158" : (root.faceIdState === "failed" ? "#60FF453A" : "#30FFFFFF")
        border.width: 1.2

        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        Row {
            id: faceIdRow
            anchors.centerIn: parent
            spacing: 10
            x: root.isShaking ? shakeOffset : 0

            property real shakeOffset: 0

            // Animated Apple Face ID Padlock / Glyph
            Item {
                id: padlockContainer
                width: 22
                height: 24
                anchors.verticalCenter: parent.verticalCenter

                // Padlock Shackle
                Rectangle {
                    id: shackle
                    width: 13
                    height: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    color: "transparent"
                    border.color: root.faceIdState === "unlocked" ? "#30D158" : (root.faceIdState === "failed" ? "#FF453A" : "#F5F5F7")
                    border.width: 2.2
                    radius: 6.5
                    transformOrigin: Item.BottomRight

                    // Spring open rotation & translation when face unlocked
                    rotation: root.faceIdState === "unlocked" ? -28 : 0
                    y: root.faceIdState === "unlocked" ? -5 : 0

                    Behavior on rotation {
                        NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
                    }
                    Behavior on y {
                        NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                    }
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                }

                // Padlock Body
                Rectangle {
                    id: lockBody
                    width: 18
                    height: 13
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    radius: 3.5
                    color: root.faceIdState === "unlocked" ? "#30D158" : (root.faceIdState === "failed" ? "#FF453A" : "#E5E5EA")

                    Behavior on color { ColorAnimation { duration: 200 } }

                    // Keyhole dot
                    Rectangle {
                        width: 3
                        height: 3
                        radius: 1.5
                        anchors.centerIn: parent
                        color: "#0F111A"
                    }
                }

                // Scanning pulse animation
                SequentialAnimation on scale {
                    running: root.faceIdState === "scanning"
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.95; to: 1.06; duration: 800; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 1.06; to: 0.95; duration: 800; easing.type: Easing.InOutQuad }
                }
            }

            // Face ID Status Text
            Text {
                id: faceIdText
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (root.faceIdState === "unlocked") return "Unlocked";
                    if (root.faceIdState === "failed") return "Face Not Recognized";
                    return "Face ID";
                }
                color: root.faceIdState === "unlocked" ? "#30D158" : (root.faceIdState === "failed" ? "#FF453A" : "#E5E5EA")
                font.family: "Inter"
                font.pixelSize: 13
                font.weight: Font.DemiBold

                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        // Horizontal shake animation on failed attempt
        SequentialAnimation {
            id: shakeAnimation
            loops: 1
            PropertyAnimation { target: faceIdRow; property: "shakeOffset"; to: -10; duration: 50 }
            PropertyAnimation { target: faceIdRow; property: "shakeOffset"; to: 10; duration: 50 }
            PropertyAnimation { target: faceIdRow; property: "shakeOffset"; to: -7; duration: 50 }
            PropertyAnimation { target: faceIdRow; property: "shakeOffset"; to: 7; duration: 50 }
            PropertyAnimation { target: faceIdRow; property: "shakeOffset"; to: 0; duration: 50 }
            onStopped: root.isShaking = false
        }
    }

    // Oversized macOS Clock & Date
    Column {
        anchors.top: dynamicIsland.bottom
        anchors.topMargin: 46
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4

        Text {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
            color: "#DCE5F5"
            font.family: "Inter"
            font.pixelSize: 25
            font.weight: Font.DemiBold
        }

        Text {
            id: timeLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(new Date(), "h:mm")
            color: "#F8FAFC"
            font.family: "Inter"
            font.pixelSize: 110
            font.weight: Font.Bold
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date();
            dateLabel.text = Qt.formatDateTime(now, "dddd, MMMM d");
            timeLabel.text = Qt.formatDateTime(now, "h:mm");
        }
    }

    // User Avatar & Glass Password Pill
    Column {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 88
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        // Glass Avatar Ring
        Rectangle {
            width: 76
            height: 76
            radius: 38
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#30FFFFFF"
            border.color: "#60FFFFFF"
            border.width: 1.5

            Text {
                anchors.centerIn: parent
                text: root.resolvedUser.length > 0 ? root.resolvedUser.slice(0, 1).toUpperCase() : "G"
                color: "#FFFFFF"
                font.family: "Inter"
                font.pixelSize: 32
                font.weight: Font.Bold
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.resolvedUser
            color: "#F8FAFC"
            font.family: "Inter"
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }

        // Liquid Glass Password Field
        Rectangle {
            id: passwordPill
            width: 250
            height: 40
            radius: 20
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#38FFFFFF"
            border.color: root.faceIdState === "failed" ? "#FF453A" : "#65FFFFFF"
            border.width: 1

            TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 40
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: "#FFFFFF"
                font.family: "Inter"
                font.pixelSize: 14
                focus: true

                Keys.onReturnPressed: doLogin()
                Keys.onEnterPressed: doLogin()
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "Enter Password"
                color: "#95FFFFFF"
                font.family: "Inter"
                font.pixelSize: 13
                visible: passwordInput.text.length === 0
            }

            // Circular submit button
            Rectangle {
                width: 28
                height: 28
                radius: 14
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                color: "#55FFFFFF"

                Text {
                    anchors.centerIn: parent
                    text: "→"
                    color: "#FFFFFF"
                    font.pixelSize: 15
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: doLogin()
                }
            }
        }
    }

    function doLogin() {
        sddm.login(root.resolvedUser, passwordInput.text, sessionModel.lastIndex);
    }

    function triggerFaceUnlock() {
        root.faceIdState = "unlocked";
        // Auto-login on recognized face
        var delayTimer = Qt.createQmlObject('import QtQuick 2.15; Timer { interval: 400; running: true; repeat: false; onTriggered: doLogin(); }', root, "unlockTimer");
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.faceIdState = "failed";
            root.isShaking = true;
            shakeAnimation.restart();
            passwordInput.text = "";
            passwordInput.forceActiveFocus();
        }
        function onLoginSucceeded() {
            root.faceIdState = "unlocked";
        }
    }

    Component.onCompleted: {
        passwordInput.forceActiveFocus();
        // If password is empty (live USB session), trigger face unlock immediately
        if (root.resolvedUser === "live") {
            triggerFaceUnlock();
        }
    }
}
