// js/inject-mobile.js
// CSS et JS injectés dans la WebView Le Monde pour une meilleure expérience mobile

var LEMONDE_MOBILE_CSS = `
    /* Masquer éléments inutiles en mode app */
    .Nav__wrapper,
    .Footer,
    .Breadcrumb,
    .StickyBanner,
    .dfp_slot,
    .Ad,
    [class*="Ad__"],
    [class*="Banner__"],
    .CookieConsent,
    #didomi-host,
    .didomi-popup-container,
    .didomi-notice,
    [id*="didomi"],
    .partner-bar,
    .app-banner,
    .overlay-app,
    [class*="app-download"],
    [class*="AppBanner"],
    .ReaderWall__footer {
        display: none !important;
    }

    /* Optimisation de la mise en page mobile */
    body {
        -webkit-text-size-adjust: 100%;
        overflow-x: hidden;
        max-width: 100vw;
    }

    article, .article__content, .article__body {
        max-width: 100% !important;
        padding: 0 12px !important;
        margin: 0 auto !important;
        font-size: 17px !important;
        line-height: 1.65 !important;
    }

    .article__heading h1 {
        font-size: 24px !important;
        line-height: 1.3 !important;
    }

    /* Images responsives */
    img, figure, video {
        max-width: 100% !important;
        height: auto !important;
    }

    /* Meilleure lisibilité */
    .article__paragraph {
        font-size: 17px !important;
        line-height: 1.65 !important;
        margin-bottom: 1em !important;
    }

    /* Adaptation header pour mode app (remplacé par TopBar QML) */
    header[class*="Header"] {
        position: relative !important;
        top: 0 !important;
    }

    /* Scrollbar fine */
    ::-webkit-scrollbar {
        width: 3px;
    }
    ::-webkit-scrollbar-thumb {
        background: rgba(0,0,0,0.2);
        border-radius: 3px;
    }

    /* PDF download links - style spécial */
    a[href*=".pdf"], a[href*="journal/"] {
        display: inline-block;
        padding: 8px 16px;
        background: #1a1a2e;
        color: #e8b931 !important;
        border-radius: 8px;
        text-decoration: none !important;
        font-weight: bold;
        margin: 4px 0;
    }
`;

var LEMONDE_MOBILE_JS = `
    // Intercepter les clics sur les liens PDF pour les gérer via QML
    document.addEventListener('click', function(e) {
        var link = e.target.closest('a');
        if (link && link.href) {
            // Liens PDF → signal vers QML
            if (link.href.match(/\\.pdf($|\\?)/i) || link.href.match(/journal\\/pdf/i)) {
                e.preventDefault();
                e.stopPropagation();
                // Communiquer l'URL PDF au handler QML
                if (window.pdfHandler) {
                    window.pdfHandler.openPdf(link.href);
                }
                return false;
            }
            // Liens externes → ouvrir dans le navigateur système
            if (!link.href.startsWith('https://www.lemonde.fr') &&
                !link.href.startsWith('https://journal.lemonde.fr') &&
                !link.href.startsWith('https://secure.lemonde.fr')) {
                e.preventDefault();
                Qt.openUrlExternally(link.href);
                return false;
            }
        }
    }, true);

    // Signaler que l'injection est terminée
    console.log('[LeMonde-UT] Mobile injection loaded');
`;

function injectMobileStyles() {
    var style = document.createElement('style');
    style.id = 'lemonde-ut-mobile-css';
    style.textContent = LEMONDE_MOBILE_CSS;
    document.head.appendChild(style);

    var script = document.createElement('script');
    script.id = 'lemonde-ut-mobile-js';
    script.textContent = LEMONDE_MOBILE_JS;
    document.head.appendChild(script);
}

injectMobileStyles();
