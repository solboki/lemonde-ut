import QtQuick 2.12
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtWebEngine 1.8

Item {
    id: accountPage

    signal loginStateChanged(bool loggedIn)
    property bool showWebView: false
    property string pendingUrl: ""
    property var sharedProfile: null
    property real globalZoom: 2.5

    // Poubelle à popups
    WebEngineView {
        id: trashView
        visible: false
        width: 1
        height: 1
        onLoadingChanged: {
            if (loadRequest.status === WebEngineView.LoadSucceededStatus ||
                loadRequest.status === WebEngineView.LoadFailedStatus)
                trashView.url = "about:blank"
        }
        onNewViewRequested: request.openIn(trashView)
        profile: WebEngineProfile {
            storageName: "trash-account"
            offTheRecord: true
        }
        settings {
            javascriptEnabled: false
            autoLoadImages: false
            javascriptCanOpenWindows: false
        }
    }

    // CSS pour masquer header/nav du site dans les pages compte
    WebEngineScript {
        id: accountCssScript
        name: "account-css"
        injectionPoint: WebEngineScript.DocumentReady
        worldId: WebEngineScript.MainWorld
        sourceCode: "(function() {
  if (document.getElementById('ut-account-css')) return;
  var s = document.createElement('style');
  s.id = 'ut-account-css';
  s.textContent = '\\
    header, nav, [class*=\"Header__\"], [class*=\"header__\"],\\
    [class*=\"Nav__\"], [class*=\"nav__\"],\\
    [class*=\"TopBar\"], [class*=\"Burger\"],\\
    [class*=\"StickyNav\"], [class*=\"sticky-nav\"],\\
    .Footer, .Nav__wrapper,\\
    #didomi-host, .didomi-popup-container, [id*=\"didomi\"],\\
    [class*=\"app-download\"], [class*=\"AppBanner\"] {\\
      display: none !important;\\
    }\\
    body {\\
      padding-top: 0 !important;\\
      margin-top: 0 !important;\\
    }\\
  ';
  document.head.appendChild(s);
})();"
    }

    function openWebPage(url) {
        accountWebView.url = url
        showWebView = true
    }

    // Menu compte
    Rectangle {
        id: accountMenu
        anchors.fill: parent
        color: root.colorBackground
        visible: !showWebView

        Flickable {
            anchors.fill: parent
            contentHeight: accountColumn.height + units.gu(4)

            Column {
                id: accountColumn
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: units.gu(2)
                }
                spacing: units.gu(0.5)

                // En-tête compte
                Item {
                    width: parent.width
                    height: units.gu(12)
                    Column {
                        anchors.centerIn: parent
                        spacing: units.gu(1)
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: units.gu(8)
                            height: units.gu(8)
                            radius: units.gu(4)
                            color: root.colorPrimary
                            Label {
                                anchors.centerIn: parent
                                text: "M"
                                textSize: Label.XLarge
                                color: "white"
                                font.weight: Font.Bold
                            }
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Abonné Le Monde"
                            textSize: Label.Medium
                            color: root.colorText
                            font.weight: Font.DemiBold
                        }
                    }
                }

                ListItem {
                    divider.visible: false
                    height: units.gu(1)
                }

                ListItem {
                    ListItemLayout {
                        title.text: "Se connecter / Mon compte"
                        subtitle.text: "Gérer votre abonnement"
                        Icon {
                            name: "contact"
                            SlotsLayout.position: SlotsLayout.Leading
                            width: units.gu(3)
                            color: root.colorPrimary
                        }
                        ProgressionSlot {}
                    }
                    onClicked: accountPage.openWebPage("https://compte.lemonde.fr/dashboard")
                }

                ListItem {
                    ListItemLayout {
                        title.text: "Mon abonnement"
                        subtitle.text: "Détails et renouvellement"
                        Icon {
                            name: "starred"
                            SlotsLayout.position: SlotsLayout.Leading
                            width: units.gu(3)
                            color: root.colorAccent
                        }
                        ProgressionSlot {}
                    }
                    onClicked: accountPage.openWebPage("https://abo.lemonde.fr/#mes-offres")
                }

                ListItem {
                    ListItemLayout {
                        title.text: "Newsletters"
                        subtitle.text: "Gérer vos newsletters"
                        Icon {
                            name: "email"
                            SlotsLayout.position: SlotsLayout.Leading
                            width: units.gu(3)
                            color: root.colorPrimary
                        }
                        ProgressionSlot {}
                    }
                    onClicked: accountPage.openWebPage("https://www.lemonde.fr/newsletters/")
                }

                // Séparateur
                ListItem {
                    divider.visible: false
                    height: units.gu(0.5)
                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: units.gu(2)
                            rightMargin: units.gu(2)
                            verticalCenter: parent.verticalCenter
                        }
                        height: units.dp(1)
                        color: Qt.rgba(0,0,0,0.1)
                    }
                }

                Label {
                    text: "Application"
                    textSize: Label.Small
                    color: root.colorTextLight
                    font.weight: Font.DemiBold
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                    }
                    height: units.gu(4)
                    verticalAlignment: Text.AlignBottom
                }

                ListItem {
                    ListItemLayout {
                        title.text: "Effacer le cache"
                        subtitle.text: "Libérer de l'espace de stockage"
                        Icon {
                            name: "reset"
                            SlotsLayout.position: SlotsLayout.Leading
                            width: units.gu(3)
                            color: root.colorTextLight
                        }
                    }
                    onClicked: {
                        accountWebView.profile.clearHttpCache()
                        clearConfirmLabel.visible = true
                        clearConfirmTimer.start()
                    }
                }

                Label {
                    id: clearConfirmLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Cache effacé"
                    color: "#27ae60"
                    textSize: Label.Small
                    visible: false
                    Timer {
                        id: clearConfirmTimer
                        interval: 2000
                        onTriggered: clearConfirmLabel.visible = false
                    }
                }

                ListItem {
                    ListItemLayout {
                        title.text: "Se déconnecter"
                        subtitle.text: "Effacer les cookies et la session"
                        Icon {
                            name: "system-log-out"
                            SlotsLayout.position: SlotsLayout.Leading
                            width: units.gu(3)
                            color: UbuntuColors.red
                        }
                    }
                    onClicked: PopupUtils.open(logoutDialogComponent, accountPage)
                }

                // Séparateur
                ListItem {
                    divider.visible: false
                    height: units.gu(0.5)
                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: units.gu(2)
                            rightMargin: units.gu(2)
                            verticalCenter: parent.verticalCenter
                        }
                        height: units.dp(1)
                        color: Qt.rgba(0,0,0,0.1)
                    }
                }

                ListItem {
                    ListItemLayout {
                        title.text: "À propos"
                        subtitle.text: "Le Monde pour Ubuntu Touch v1.0.0"
                        Icon {
                            name: "info"
                            SlotsLayout.position: SlotsLayout.Leading
                            width: units.gu(3)
                            color: root.colorTextLight
                        }
                    }
                }
            }
        }
    }

    // WebView compte - toujours présente, juste cachée/montrée via z et opacity
    Rectangle {
        id: webViewContainer
        anchors.fill: parent
        color: root.colorBackground
        visible: showWebView
        z: showWebView ? 10 : -1

        Rectangle {
            id: accountWebHeader
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: units.gu(5)
            color: root.colorPrimary
            z: 10

            Row {
                anchors {
                    fill: parent
                    leftMargin: units.gu(1)
                }
                spacing: units.gu(1)

                AbstractButton {
                    width: units.gu(5)
                    height: parent.height
                    onClicked: {
                        showWebView = false
                    }
                    Icon {
                        anchors.centerIn: parent
                        width: units.gu(2.5)
                        height: units.gu(2.5)
                        name: "back"
                        color: "white"
                    }
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Mon compte"
                    color: "white"
                    textSize: Label.Large
                }
            }
        }

        WebEngineView {
            id: accountWebView
            anchors {
                top: accountWebHeader.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            profile: accountPage.sharedProfile
            zoomFactor: accountPage.globalZoom

            settings {
                javascriptEnabled: true
                localStorageEnabled: true
                javascriptCanOpenWindows: false
            }

            userScripts: [accountCssScript]

            onLoadingChanged: {
                if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                    // Détecter la connexion
                    runJavaScript(
                        "document.querySelector('[class*=\"user-connected\"]') !== null || document.querySelector('[class*=\"logged\"]') !== null",
                        function(result) {
                            if (result) accountPage.loginStateChanged(true)
                        }
                    )
                }
            }

            onNewViewRequested: request.openIn(trashView)

            // Barre de progression
            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                }
                height: units.dp(3)
                width: parent.width * (accountWebView.loadProgress / 100)
                color: root.colorAccent
                visible: accountWebView.loading
                z: 5
            }
        }
    }

    Component {
        id: logoutDialogComponent
        Dialog {
            id: logoutDialog
            title: "Se déconnecter ?"
            text: "Vos cookies et votre session seront effacés."

            Button {
                text: "Annuler"
                onClicked: PopupUtils.close(logoutDialog)
            }

            Button {
                text: "Se déconnecter"
                color: UbuntuColors.red
                onClicked: {
                    // Supprimer les cookies via JS
                    accountWebView.runJavaScript(
                        "document.cookie.split(';').forEach(function(c) {" +
                        "  var name = c.split('=')[0].trim();" +
                        "  document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=.lemonde.fr';" +
                        "  document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/';" +
                        "});"
                    )
                    // Vider le cache et le stockage local
                    accountWebView.profile.clearHttpCache()
                    // Naviguer vers la page de déconnexion Le Monde
                    accountWebView.url = "https://secure.lemonde.fr/sfuser/deconnexion"
                    accountPage.loginStateChanged(false)
                    showWebView = false
                    PopupUtils.close(logoutDialog)
                }
            }
        }
    }
}
