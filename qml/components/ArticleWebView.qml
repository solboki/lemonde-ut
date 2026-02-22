import QtQuick 2.12
import Ubuntu.Components 1.3
import QtWebEngine 1.8

Item {
    id: articleView

    signal pdfRequested(string url)

    readonly property string baseUrl: "https://www.lemonde.fr"

    property var sharedProfile: null
    property real globalZoom: 2.5

    property alias url: webView.url
    property alias loading: webView.loading
    property alias canGoBack: webView.canGoBack
    property alias canGoForward: webView.canGoForward

    function reload() {
        webView.reload()
    }

    function goHome() {
        webView.url = baseUrl
    }

    function goBack() {
        if (webView.canGoBack) webView.goBack()
    }

    function goForward() {
        if (webView.canGoForward) webView.goForward()
    }

    function navigateTo(section) {
        webView.url = baseUrl + section
    }

    // Barre de progression
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
        }
        height: units.dp(3)
        width: parent.width * (webView.loadProgress / 100)
        color: root.colorAccent
        visible: webView.loading
        z: 10
        Behavior on width { NumberAnimation { duration: 200 } }
    }

    // WebEngineView cachée qui absorbe les popups (poubelle)
    WebEngineView {
        id: trashView
        visible: false
        width: 1
        height: 1
        // Se nettoie après chaque chargement
        onLoadingChanged: {
            if (loadRequest.status === WebEngineView.LoadSucceededStatus ||
                loadRequest.status === WebEngineView.LoadFailedStatus) {
                trashView.url = "about:blank"
            }
        }
        // Si la poubelle reçoit elle-même des demandes de popup, on les ignore
        onNewViewRequested: {
            request.openIn(trashView)
        }

        profile: WebEngineProfile {
            storageName: "lemonde-trash"
            offTheRecord: true
        }
        settings {
            javascriptEnabled: false
            autoLoadImages: false
            javascriptCanOpenWindows: false
        }
    }

    // UserScript injecté au tout début du chargement (DocumentCreation)
    WebEngineScript {
        id: adBlockScript
        name: "adblock"
        sourceUrl: ""
        injectionPoint: WebEngineScript.DocumentCreation
        worldId: WebEngineScript.MainWorld
        sourceCode: "(function() {
  window.open = function() { return null; };
  Object.defineProperty(window, 'open', {
    value: function() { return null; },
    writable: false,
    configurable: false
  });
})();"
    }

    // UserScript CSS injection au chargement du DOM
    WebEngineScript {
        id: cssInjectScript
        name: "cssinject"
        injectionPoint: WebEngineScript.DocumentReady
        worldId: WebEngineScript.MainWorld
        sourceCode: "(function() {
  if (document.getElementById('lemonde-ut-css')) return;
  var s = document.createElement('style');
  s.id = 'lemonde-ut-css';
  s.textContent = '\\
    .Nav__wrapper, .Footer, .StickyBanner,\\
    .dfp_slot, [class*=\"Ad__\"], [class*=\"Banner__\"],\\
    .CookieConsent, #didomi-host, .didomi-popup-container,\\
    .didomi-notice, [id*=\"didomi\"],\\
    .partner-bar, .app-banner, .overlay-app,\\
    [class*=\"app-download\"], [class*=\"AppBanner\"],\\
    iframe[src*=\"safeframe\"], iframe[src*=\"doubleclick\"],\\
    iframe[src*=\"googlesyndication\"], iframe[id*=\"google_ads\"],\\
    [id*=\"google_ads\"], [class*=\"dfp\"], [class*=\"outbrain\"],\\
    [id*=\"taboola\"], [class*=\"taboola\"],\\
    div[data-adformat], div[data-google-query-id],\\
    header, [class*=\"Header__\"], [class*=\"header__\"],\\
    nav, [class*=\"Nav__\"], [class*=\"nav__\"],\\
    [class*=\"TopBar\"], [class*=\"Burger\"],\\
    [class*=\"StickyNav\"], [class*=\"sticky-nav\"] {\\
      display: none !important;\\
    }\\
    body { -webkit-text-size-adjust: 100%; overflow-x: hidden; padding-top: 0 !important; margin-top: 0 !important; }\\
    article, .article__content, .article__body {\\
      max-width: 100% !important; padding: 0 12px !important;\\
      font-size: 17px !important; line-height: 1.65 !important;\\
    }\\
    .article__heading h1 { font-size: 24px !important; line-height: 1.3 !important; }\\
    img, figure, video { max-width: 100% !important; height: auto !important; }\\
    ::-webkit-scrollbar { width: 3px; }\\
    ::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.2); border-radius: 3px; }\\
    /* Masquer tout sous l article : Pour approfondir, commentaires, partage, etc. */\\
    [class*=\"article__reactions\"], [class*=\"Reactions\"],\\
    [class*=\"article__siblings\"], [class*=\"Siblings\"],\\
    [class*=\"article__footer\"], [class*=\"ArticleFooter\"],\\
    [class*=\"catcher\"], [class*=\"Catcher\"],\\
    [class*=\"article__comments\"], [class*=\"Comments\"],\\
    [class*=\"article__share\"], [class*=\"Share__\"],\\
    [class*=\"article__related\"], [class*=\"Related\"],\\
    [class*=\"Pour-approfondir\"], [class*=\"pour-approfondir\"],\\
    [class*=\"suggested\"], [class*=\"Suggested\"],\\
    [class*=\"more-articles\"], [class*=\"MoreArticles\"],\\
    [class*=\"newsletter-insert\"], [class*=\"Newsletter\"],\\
    [class*=\"bottom-page\"], [class*=\"BottomPage\"] {\\
      display: none !important;\\
    }\\
  ';
  document.head.appendChild(s);
  document.querySelectorAll('iframe').forEach(function(f) {
    var t = (f.src || '') + (f.id || '');
    if (/safeframe|doubleclick|googlesyndication|google_ads/i.test(t)) f.remove();
  });
  new MutationObserver(function(ml) {
    ml.forEach(function(m) {
      m.addedNodes.forEach(function(n) {
        if (n.tagName === 'IFRAME') {
          var t = (n.src || '') + (n.id || '');
          if (/safeframe|doubleclick|googlesyndication|google_ads/i.test(t)) n.remove();
        }
      });
    });
  }).observe(document.documentElement, {childList: true, subtree: true});
  /* Nettoyage du bas des articles */
  function cleanArticleBottom() {
    var selectors = [
      '[class*=\"article__reactions\"]', '[class*=\"Reactions\"]',
      '[class*=\"article__siblings\"]', '[class*=\"Siblings\"]',
      '[class*=\"article__footer\"]', '[class*=\"catcher\"]',
      '[class*=\"Catcher\"]', '[class*=\"article__comments\"]',
      '[class*=\"article__share\"]', '[class*=\"Share__\"]',
      '[class*=\"article__related\"]', '[class*=\"Related\"]',
      '[class*=\"suggested\"]', '[class*=\"Suggested\"]',
      '[class*=\"more-articles\"]', '[class*=\"MoreArticles\"]',
      '[class*=\"newsletter-insert\"]', '[class*=\"Newsletter\"]',
      '[class*=\"bottom-page\"]', '[class*=\"BottomPage\"]',
      '[class*=\"Pour-approfondir\"]', '[class*=\"pour-approfondir\"]'
    ];
    selectors.forEach(function(sel) {
      document.querySelectorAll(sel).forEach(function(el) { el.style.display = 'none'; });
    });
  }
  cleanArticleBottom();
  setTimeout(cleanArticleBottom, 2000);
  setTimeout(cleanArticleBottom, 5000);
})();"
    }

    WebEngineView {
        id: webView
        anchors.fill: parent
        url: articleView.baseUrl
        zoomFactor: articleView.globalZoom

        profile: articleView.sharedProfile

        settings {
            javascriptEnabled: true
            localStorageEnabled: true
            javascriptCanOpenWindows: false
            allowRunningInsecureContent: false
            fullScreenSupportEnabled: true
            pluginsEnabled: true
        }

        // Attacher les UserScripts
        userScripts: [adBlockScript, cssInjectScript]

        onNavigationRequested: {
            var urlStr = request.url.toString()

            // Bloquer domaines pub
            if (urlStr.indexOf("safeframe") !== -1 ||
                urlStr.indexOf("doubleclick") !== -1 ||
                urlStr.indexOf("googlesyndication") !== -1 ||
                urlStr.indexOf("googleadservices") !== -1 ||
                urlStr.indexOf("pagead") !== -1 ||
                urlStr.indexOf("outbrain") !== -1 ||
                urlStr.indexOf("taboola") !== -1) {
                request.action = WebEngineNavigationRequest.IgnoreRequest
                return
            }

            // Liens PDF
            if (urlStr.match(/\.pdf($|\?)/i) || urlStr.match(/journal\/pdf/i)) {
                request.action = WebEngineNavigationRequest.IgnoreRequest
                articleView.pdfRequested(urlStr)
                return
            }

            // Liens externes
            if (!urlStr.startsWith("https://www.lemonde.fr") &&
                !urlStr.startsWith("https://journal.lemonde.fr") &&
                !urlStr.startsWith("https://secure.lemonde.fr") &&
                !urlStr.startsWith("https://abo.lemonde.fr") &&
                !urlStr.startsWith("https://assets-decodeurs.lemonde.fr") &&
                urlStr.startsWith("http")) {
                request.action = WebEngineNavigationRequest.IgnoreRequest
                return
            }

            request.action = WebEngineNavigationRequest.AcceptRequest
        }

        // CRUCIAL : absorber les popups dans la poubelle au lieu de laisser le système les gérer
        onNewViewRequested: {
            request.openIn(trashView)
        }

        function goBackOrHome() {
            if (canGoBack) goBack()
            else url = articleView.baseUrl
        }
    }

    // Swipe retour
    MouseArea {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: units.gu(2)
        z: 5
        property real startX: 0
        onPressed: startX = mouse.x
        onReleased: {
            if (mouse.x - startX > units.gu(8))
                webView.goBackOrHome()
        }
    }
}
