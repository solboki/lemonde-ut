import QtQuick 2.12
import Ubuntu.Components 1.3

Rectangle {
    id: bottomNav
    height: units.gu(6)
    color: root.colorPrimary

    property int currentIndex: 0
    signal tabSelected(int index)
    signal homeRequested()

    // Ombre portée en haut
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.top
        }
        height: units.dp(1)
        color: Qt.rgba(0, 0, 0, 0.15)
    }

    Row {
        anchors.fill: parent

        // Bouton À la une (action, pas un onglet)
        Item {
            width: parent.width / 4
            height: parent.height

            Column {
                anchors.centerIn: parent
                spacing: units.dp(2)

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: units.gu(2.5)
                    height: units.gu(2.5)
                    name: "home"
                    color: root.colorAccent
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "À la une"
                    textSize: Label.XSmall
                    color: root.colorAccent
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: bottomNav.homeRequested()
            }
        }

        // Onglets classiques
        Repeater {
            model: [
                { icon: "browser-tabs", label: "Articles" },
                { icon: "document-open", label: "Journal" },
                { icon: "contact", label: "Compte" }
            ]

            delegate: Item {
                width: parent.width / 4
                height: parent.height

                // Indicateur actif
                Rectangle {
                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: parent.width * 0.5
                    height: units.dp(3)
                    radius: units.dp(1.5)
                    color: root.colorAccent
                    visible: bottomNav.currentIndex === index

                    Behavior on visible {
                        NumberAnimation { duration: 150 }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: units.dp(2)

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: units.gu(2.5)
                        height: units.gu(2.5)
                        name: modelData.icon
                        color: bottomNav.currentIndex === index ? root.colorAccent : Qt.rgba(1,1,1,0.5)

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        textSize: Label.XSmall
                        color: bottomNav.currentIndex === index ? root.colorAccent : Qt.rgba(1,1,1,0.5)

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: bottomNav.tabSelected(index)
                }
            }
        }
    }
}
