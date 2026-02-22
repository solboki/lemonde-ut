import QtQuick 2.12
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.12 as QQC2
import QtWebEngine 1.8

import "components"
import "pages"

MainView {
    id: root

    objectName: "mainView"
    applicationName: "lemonde.solboki"

    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    // Couleurs Le Monde
    readonly property color colorPrimary: "#1a1a2e"
    readonly property color colorAccent: "#e8b931"
    readonly property color colorBackground: "#f5f5f0"
    readonly property color colorText: "#2a2a2a"
    readonly property color colorTextLight: "#666666"

    // État de l'application
    property string currentPdfUrl: ""
    property bool isLoggedIn: false

    // Zoom global pour les WebViews (hors PDF viewer)
    property var zoomLevels: [1.0, 1.5, 2.0, 2.5, 3.0, 3.5]
    property int zoomIndex: 3  // 2.5 par défaut
    property real globalZoom: zoomLevels[zoomIndex]

    // Profil partagé unique pour toutes les WebViews
    WebEngineProfile {
        id: mainSharedProfile
        storageName: "lemonde-storage"
        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
        httpUserAgent: "Mozilla/5.0 (Linux; Ubuntu Touch; Fairphone 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Mobile Safari/537.36"
        httpCacheType: WebEngineProfile.DiskHttpCache
    }

    PageStack {
        id: pageStack
        anchors.fill: parent

        Component.onCompleted: {
            pageStack.push(mainPage)
        }
    }

    // Page principale avec onglets
    Component {
        id: mainPage

        Page {
            id: homePage

            header: PageHeader {
                id: appHeader

                contents: Item {
                    anchors.fill: parent
                    Image {
                        source: Qt.resolvedUrl("images/lemonde-header.png")
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        height: parent.height * 0.6
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }

                StyleHints {
                    foregroundColor: "white"
                    backgroundColor: root.colorPrimary
                }

                leadingActionBar.actions: [
                    Action {
                        iconName: "navigation-menu"
                        text: "Menu"
                        onTriggered: PopupUtils.open(menuPopoverComponent, homePage)
                    }
                ]

                trailingActionBar.numberOfSlots: 4
                trailingActionBar.actions: [
                    Action {
                        iconName: "reload"
                        text: "Actualiser"
                        onTriggered: {
                            if (contentSwipe.currentIndex === 0 && articlesLoader.item)
                                articlesLoader.item.reload()
                        }
                    },
                    Action {
                        text: "×" + root.globalZoom.toFixed(1)
                        iconName: "zoom-in"
                        onTriggered: {
                            root.zoomIndex = (root.zoomIndex + 1) % root.zoomLevels.length
                        }
                    },
                    Action {
                        iconName: "next"
                        text: "Suivant"
                        enabled: contentSwipe.currentIndex === 0 && articlesLoader.item && articlesLoader.item.canGoForward
                        onTriggered: {
                            if (articlesLoader.item) articlesLoader.item.goForward()
                        }
                    },
                    Action {
                        iconName: "previous"
                        text: "Précédent"
                        enabled: contentSwipe.currentIndex === 0 && articlesLoader.item && articlesLoader.item.canGoBack
                        onTriggered: {
                            if (articlesLoader.item) articlesLoader.item.goBack()
                        }
                    }
                ]
            }

            // Contenu principal - SwipeView synchronisé avec les onglets
            QQC2.SwipeView {
                id: contentSwipe
                interactive: false  // Navigation uniquement via la barre du bas
                anchors {
                    top: homePage.header.bottom
                    left: parent.left
                    right: parent.right
                    bottom: bottomBar.top
                }

                // Onglet 1 : Articles (WebView)
                Loader {
                    id: articlesLoader
                    active: QQC2.SwipeView.isCurrentItem || QQC2.SwipeView.isPreviousItem || QQC2.SwipeView.isNextItem
                    sourceComponent: ArticleWebView {
                        id: articleWebView
                        sharedProfile: mainSharedProfile
                        globalZoom: root.globalZoom
                        onPdfRequested: {
                            root.currentPdfUrl = url
                            contentSwipe.currentIndex = 1 // Basculer vers l'onglet PDF
                        }
                    }
                }

                // Onglet 2 : Journal PDF
                Loader {
                    id: pdfLoader
                    active: QQC2.SwipeView.isCurrentItem || QQC2.SwipeView.isPreviousItem || QQC2.SwipeView.isNextItem
                    sourceComponent: PdfPage {
                        pdfUrl: root.currentPdfUrl
                        globalZoom: root.globalZoom
                        sharedProfile: mainSharedProfile
                    }
                }

                // Onglet 3 : Compte
                Loader {
                    id: accountLoader
                    active: QQC2.SwipeView.isCurrentItem
                    sourceComponent: AccountPage {
                        sharedProfile: mainSharedProfile
                        globalZoom: root.globalZoom
                        onLoginStateChanged: {
                            root.isLoggedIn = loggedIn
                        }
                    }
                }
            }

            // Barre de navigation basse
            BottomNav {
                id: bottomBar
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                currentIndex: contentSwipe.currentIndex
                onTabSelected: contentSwipe.currentIndex = index
                onHomeRequested: {
                    contentSwipe.currentIndex = 0
                    if (articlesLoader.item) articlesLoader.item.goHome()
                }
            }

            // Menu contextuel
            Component {
                id: menuPopoverComponent
                Popover {
                    id: menuPopover
                    Column {
                        id: menuColumn
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }

                        ListItem {
                            ListItemLayout {
                                title.text: "Accueil"
                                Icon { name: "home"; SlotsLayout.position: SlotsLayout.Leading; width: units.gu(2) }
                            }
                            onClicked: {
                                contentSwipe.currentIndex = 0
                                if (articlesLoader.item) articlesLoader.item.goHome()
                                PopupUtils.close(menuPopover)
                            }
                        }

                        ListItem {
                            ListItemLayout {
                                title.text: "En continu"
                                Icon { name: "media-playback-start"; SlotsLayout.position: SlotsLayout.Leading; width: units.gu(2) }
                            }
                            onClicked: {
                                contentSwipe.currentIndex = 0
                                if (articlesLoader.item) articlesLoader.item.navigateTo("/en-continu/")
                                PopupUtils.close(menuPopover)
                            }
                        }

                        ListItem {
                            ListItemLayout {
                                title.text: "International"
                                Icon { name: "language-chooser"; SlotsLayout.position: SlotsLayout.Leading; width: units.gu(2) }
                            }
                            onClicked: {
                                contentSwipe.currentIndex = 0
                                if (articlesLoader.item) articlesLoader.item.navigateTo("/international/")
                                PopupUtils.close(menuPopover)
                            }
                        }

                        ListItem {
                            ListItemLayout {
                                title.text: "Politique"
                                Icon { name: "contact-group"; SlotsLayout.position: SlotsLayout.Leading; width: units.gu(2) }
                            }
                            onClicked: {
                                contentSwipe.currentIndex = 0
                                if (articlesLoader.item) articlesLoader.item.navigateTo("/politique/")
                                PopupUtils.close(menuPopover)
                            }
                        }

                        ListItem {
                            ListItemLayout {
                                title.text: "Économie"
                                Icon { name: "transfer-progress"; SlotsLayout.position: SlotsLayout.Leading; width: units.gu(2) }
                            }
                            onClicked: {
                                contentSwipe.currentIndex = 0
                                if (articlesLoader.item) articlesLoader.item.navigateTo("/economie/")
                                PopupUtils.close(menuPopover)
                            }
                        }

                        ListItem {
                            ListItemLayout {
                                title.text: "Planète"
                                Icon { name: "location"; SlotsLayout.position: SlotsLayout.Leading; width: units.gu(2) }
                            }
                            onClicked: {
                                contentSwipe.currentIndex = 0
                                if (articlesLoader.item) articlesLoader.item.navigateTo("/planete/")
                                PopupUtils.close(menuPopover)
                            }
                        }

                        ListItem {
                            ListItemLayout {
                                title.text: "Sport"
                                Icon { name: "like"; SlotsLayout.position: SlotsLayout.Leading; width: units.gu(2) }
                            }
                            onClicked: {
                                contentSwipe.currentIndex = 0
                                if (articlesLoader.item) articlesLoader.item.navigateTo("/sport/")
                                PopupUtils.close(menuPopover)
                            }
                        }

                        ListItem {
                            ListItemLayout {
                                title.text: "Culture"
                                Icon { name: "note"; SlotsLayout.position: SlotsLayout.Leading; width: units.gu(2) }
                            }
                            onClicked: {
                                contentSwipe.currentIndex = 0
                                if (articlesLoader.item) articlesLoader.item.navigateTo("/culture/")
                                PopupUtils.close(menuPopover)
                            }
                        }

                        ListItem {
                            ListItemLayout {
                                title.text: "Sciences"
                                Icon { name: "settings"; SlotsLayout.position: SlotsLayout.Leading; width: units.gu(2) }
                            }
                            onClicked: {
                                contentSwipe.currentIndex = 0
                                if (articlesLoader.item) articlesLoader.item.navigateTo("/sciences/")
                                PopupUtils.close(menuPopover)
                            }
                        }

                        ListItem {
                            ListItemLayout {
                                title.text: "Opinions"
                                Icon { name: "edit"; SlotsLayout.position: SlotsLayout.Leading; width: units.gu(2) }
                            }
                            onClicked: {
                                contentSwipe.currentIndex = 0
                                if (articlesLoader.item) articlesLoader.item.navigateTo("/idees/")
                                PopupUtils.close(menuPopover)
                            }
                        }

                        ListItem {
                            ListItemLayout {
                                title.text: "Vidéos"
                                Icon { name: "camcorder"; SlotsLayout.position: SlotsLayout.Leading; width: units.gu(2) }
                            }
                            onClicked: {
                                contentSwipe.currentIndex = 0
                                if (articlesLoader.item) articlesLoader.item.navigateTo("/videos/")
                                PopupUtils.close(menuPopover)
                            }
                        }
                    }
                }
            }
        }
    }
}
