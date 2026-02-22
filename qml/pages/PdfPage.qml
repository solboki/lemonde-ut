import QtQuick 2.12
import Ubuntu.Components 1.3
import QtWebEngine 1.8

Item {
    id: pdfPage

    property string pdfUrl: ""
    property bool viewingPdf: pdfUrl !== ""
    property real globalZoom: 2.5
    property var sharedProfile: null

    onPdfUrlChanged: {
        if (pdfUrl !== "") {
            pdfWebView.url = pdfUrl
            viewingPdf = true
        }
    }

    function backToJournal() {
        pdfUrl = ""
        viewingPdf = false
        journalWebView.url = "https://journal.lemonde.fr"
    }

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
            storageName: "trash-pdf"
            offTheRecord: true
        }
        settings {
            javascriptEnabled: false
            autoLoadImages: false
            javascriptCanOpenWindows: false
        }
    }

    // UserScript anti window.open + spoof mobile dimensions (avant que Twipe s'initialise)
    WebEngineScript {
        id: adBlockScript
        name: "adblock-pdf"
        injectionPoint: WebEngineScript.DocumentCreation
        worldId: WebEngineScript.MainWorld
        sourceCode: "(function() {
  /* Bloquer popups */
  Object.defineProperty(window, 'open', {
    value: function() { return null; },
    writable: false,
    configurable: false
  });

  /* Spoofer les dimensions pour que Twipe pense être sur mobile */
  var mobileWidth = 412;
  var mobileHeight = 869;
  try {
    Object.defineProperty(screen, 'width', { get: function() { return mobileWidth; }, configurable: true });
    Object.defineProperty(screen, 'height', { get: function() { return mobileHeight; }, configurable: true });
    Object.defineProperty(screen, 'availWidth', { get: function() { return mobileWidth; }, configurable: true });
    Object.defineProperty(screen, 'availHeight', { get: function() { return mobileHeight; }, configurable: true });
  } catch(e) {}

  /* Injecter viewport meta immédiatement avec largeur fixe mobile */
  var meta = document.createElement('meta');
  meta.name = 'viewport';
  meta.content = 'width=412, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes';
  (document.head || document.documentElement).appendChild(meta);

  /* Spoofer aussi window.outerWidth/outerHeight si utilisé */
  try {
    Object.defineProperty(window, 'outerWidth', { get: function() { return mobileWidth; }, configurable: true });
    Object.defineProperty(window, 'outerHeight', { get: function() { return mobileHeight; }, configurable: true });
  } catch(e) {}

  /* Spoofer innerWidth/innerHeight pour que le layout JS détecte mobile */
  try {
    Object.defineProperty(window, 'innerWidth', { get: function() { return mobileWidth; }, configurable: true });
    Object.defineProperty(window, 'innerHeight', { get: function() { return mobileHeight; }, configurable: true });
  } catch(e) {}

  /* Spoofer matchMedia pour les media queries CSS comme (max-width: 768px) */
  var origMatchMedia = window.matchMedia;
  window.matchMedia = function(query) {
    /* Intercepter les requêtes de largeur pour toujours répondre mobile */
    var m = query.match(/\\(max-width:\\s*(\\d+)px\\)/);
    if (m && parseInt(m[1]) >= mobileWidth) {
      return { matches: true, media: query, addListener: function(){}, removeListener: function(){}, addEventListener: function(){}, removeEventListener: function(){}, onchange: null, dispatchEvent: function(){} };
    }
    var m2 = query.match(/\\(min-width:\\s*(\\d+)px\\)/);
    if (m2 && parseInt(m2[1]) > mobileWidth) {
      return { matches: false, media: query, addListener: function(){}, removeListener: function(){}, addEventListener: function(){}, removeEventListener: function(){}, onchange: null, dispatchEvent: function(){} };
    }
    return origMatchMedia.call(window, query);
  };

  /* Spoofer la détection tactile pour confirmer le mode mobile */
  try {
    if (!('ontouchstart' in window)) {
      window.ontouchstart = null;
    }
    Object.defineProperty(navigator, 'maxTouchPoints', { get: function() { return 5; }, configurable: true });
  } catch(e) {}
})();"
    }

    // CSS léger + navigation par swipe pour le reader Twipe
    WebEngineScript {
        id: journalReaderCSS
        name: "journal-reader-css"
        injectionPoint: WebEngineScript.DocumentReady
        worldId: WebEngineScript.MainWorld
        sourceCode: "(function() {
  if (document.getElementById('ut-journal-css')) return;
  var s = document.createElement('style');
  s.id = 'ut-journal-css';
  s.textContent = [
    '#didomi-host, .didomi-popup-container, [id*=\"didomi\"],',
    '[class*=\"app-download\"], [class*=\"AppBanner\"] { display: none !important; }',
    'html, body { overflow-x: hidden !important; -webkit-text-size-adjust: 100% !important; }',
    'img, figure, svg, video { max-width: 100% !important; height: auto !important; }',
    '::-webkit-scrollbar { width: 3px; }',
    '::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.3); border-radius: 3px; }'
  ].join('\\n');
  document.head.appendChild(s);

  /* Navigation par swipe : change le numéro de page dans le hash */
  function goToPage(delta) {
    var h = location.hash;
    var m = h.match(/\\/page\\/(\\d+)/);
    if (m) {
      var cur = parseInt(m[1]);
      var next = cur + delta;
      if (next < 1) next = 1;
      location.hash = h.replace(/\\/page\\/\\d+/, '/page/' + next);
      return;
    }
    /* Hash pas encore prêt : attendre et réessayer */
    var retries = 0;
    var timer = setInterval(function() {
      retries++;
      var h2 = location.hash;
      var m2 = h2.match(/\\/page\\/(\\d+)/);
      if (m2) {
        clearInterval(timer);
        var cur = parseInt(m2[1]);
        var next = cur + delta;
        if (next < 1) next = 1;
        location.hash = h2.replace(/\\/page\\/\\d+/, '/page/' + next);
      } else if (retries > 20) {
        clearInterval(timer);
      }
    }, 250);
  }

  /* Touch */
  var tX = 0, tY = 0, tT = 0;
  document.addEventListener('touchstart', function(e) {
    if (e.touches && e.touches.length === 1) {
      tX = e.touches[0].clientX;
      tY = e.touches[0].clientY;
      tT = Date.now();
    }
  }, { passive: true, capture: true });
  document.addEventListener('touchend', function(e) {
    if (!e.changedTouches || e.changedTouches.length < 1) return;
    var dx = e.changedTouches[0].clientX - tX;
    var dy = e.changedTouches[0].clientY - tY;
    var dt = Date.now() - tT;
    if (Math.abs(dx) < 60 || Math.abs(dy) > Math.abs(dx) * 0.7 || dt > 600) return;
    if (dx < 0) goToPage(1);
    else goToPage(-1);
  }, { passive: true, capture: true });

  /* Mouse (pour clickable desktop) */
  var mX = 0, mY = 0, mT = 0;
  document.addEventListener('mousedown', function(e) {
    mX = e.clientX; mY = e.clientY; mT = Date.now();
  }, true);
  document.addEventListener('mouseup', function(e) {
    var dx = e.clientX - mX;
    var dy = e.clientY - mY;
    var dt = Date.now() - mT;
    if (Math.abs(dx) < 60 || Math.abs(dy) > Math.abs(dx) * 0.7 || dt > 600) return;
    if (dx < 0) goToPage(1);
    else goToPage(-1);
  }, true);
})();"
    }

    // Header pour le mode PDF
    Rectangle {
        id: pdfHeader
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: viewingPdf ? units.gu(5) : 0
        color: root.colorPrimary
        visible: viewingPdf
        z: 10

        Behavior on height {
            NumberAnimation { duration: 200 }
        }

        Row {
            anchors {
                fill: parent
                leftMargin: units.gu(1)
                rightMargin: units.gu(1)
            }
            spacing: units.gu(1)

            AbstractButton {
                width: units.gu(5)
                height: parent.height
                onClicked: pdfPage.backToJournal()
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
                text: "Journal PDF"
                color: "white"
                textSize: Label.Large
            }

            Item {
                width: units.gu(1)
                height: 1
            }

            AbstractButton {
                width: units.gu(5)
                height: parent.height
                onClicked: {
                    if (pdfWebView.zoomFactor < 5.0)
                        pdfWebView.zoomFactor += 0.5
                    else
                        pdfWebView.zoomFactor = 2.5
                }
                Icon {
                    anchors.centerIn: parent
                    width: units.gu(2.5)
                    height: units.gu(2.5)
                    name: "zoom-in"
                    color: "white"
                }
            }
        }
    }

    // WebEngineView journal.lemonde.fr
    WebEngineView {
        id: journalWebView
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        visible: !viewingPdf
        zoomFactor: pdfPage.globalZoom

        profile: pdfPage.sharedProfile

        // Charger l'URL après que le profil soit prêt
        Timer {
            id: journalLoadTimer
            interval: 300
            repeat: false
            onTriggered: journalWebView.url = "https://journal.lemonde.fr"
        }
        Component.onCompleted: journalLoadTimer.start()

        settings {
            javascriptEnabled: true
            localStorageEnabled: true
            javascriptCanOpenWindows: false
            pluginsEnabled: true
        }

        userScripts: [adBlockScript, journalReaderCSS]

        // Quand Twipe a fini de charger, forcer l'initialisation du hash
        onLoadingChanged: {
            if (loadRequest.status === WebEngineLoadRequest.LoadSucceededStatus) {
                journalWebView.runJavaScript(
                    "(function() {
                        function tryInitHash() {
                            var h = location.hash;
                            if (h.match(/\\/page\\/\\d+/)) return true;
                            /* Essayer de construire le hash avec l'ID édition */
                            if (typeof lmdCurrentPage !== 'undefined' && lmdCurrentPage > 0) {
                                var m = h.match(/^#(\\d+)/);
                                if (m) {
                                    location.hash = '#' + m[1] + '/page/' + lmdCurrentPage;
                                    return true;
                                }
                            }
                            return false;
                        }
                        /* Twipe peut mettre du temps à s'initialiser */
                        var attempts = 0;
                        var poller = setInterval(function() {
                            attempts++;
                            if (tryInitHash() || attempts > 20) clearInterval(poller);
                        }, 500);
                    })();"
                )
            }
        }

        onNavigationRequested: {
            var urlStr = request.url.toString()
            if (urlStr.indexOf("safeframe") !== -1 ||
                urlStr.indexOf("doubleclick") !== -1 ||
                urlStr.indexOf("googlesyndication") !== -1) {
                request.action = WebEngineNavigationRequest.IgnoreRequest
                return
            }
            if (urlStr.match(/\.pdf($|\?)/i)) {
                request.action = WebEngineNavigationRequest.IgnoreRequest
                pdfPage.pdfUrl = urlStr
                return
            }
            request.action = WebEngineNavigationRequest.AcceptRequest
        }

        onNewViewRequested: request.openIn(trashView)
    }

    // WebEngineView PDF viewer
    WebEngineView {
        id: pdfWebView
        anchors {
            top: pdfHeader.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        visible: viewingPdf
        zoomFactor: 2.5

        profile: pdfPage.sharedProfile

        settings {
            javascriptEnabled: true
            javascriptCanOpenWindows: false
            pluginsEnabled: true
        }

        onNewViewRequested: request.openIn(trashView)

        // Barre de progression
        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
            }
            height: units.dp(3)
            width: parent.width * (pdfWebView.loadProgress / 100)
            color: root.colorAccent
            visible: pdfWebView.loading
            z: 5
        }

        // Indicateur de chargement
        Rectangle {
            anchors.centerIn: parent
            width: units.gu(25)
            height: units.gu(10)
            radius: units.gu(1)
            color: Qt.rgba(0,0,0,0.8)
            visible: pdfWebView.loading

            Column {
                anchors.centerIn: parent
                spacing: units.gu(1)

                ActivityIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: pdfWebView.loading
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Chargement..."
                    color: "white"
                    textSize: Label.Medium
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: pdfWebView.loadProgress + "%"
                    color: root.colorAccent
                    textSize: Label.Small
                }
            }
        }
    }
}
