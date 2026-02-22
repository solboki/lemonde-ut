# Le Monde pour Ubuntu Touch

Application native pour lire **Le Monde** sur Ubuntu Touch (Fairphone 5 et autres appareils compatibles).

![Licence GPL-3.0](https://img.shields.io/badge/licence-GPL--3.0-blue)
![Architecture](https://img.shields.io/badge/architecture-all-green)
![Framework](https://img.shields.io/badge/framework-ubuntu--sdk--20.04-orange)

## Fonctionnalités

- **Articles** — lecture du site lemonde.fr en version mobile, nettoyée des publicités, bandeaux cookies, headers de navigation et bas d'articles (commentaires, suggestions, partages)
- **Journal électronique** — accès au journal quotidien via journal.lemonde.fr (reader Twipe) avec affichage mobile et navigation par swipe horizontal entre les pages
- **Compte** — connexion / déconnexion et gestion de l'abonnement via compte.lemonde.fr
- **Navigation** — barre de navigation en bas (À la une, Articles, Journal, Compte), menu hamburger avec accès aux rubriques (International, Politique, Économie, Sport, Culture, etc.)
- **Zoom réglable** — bouton dans le header pour ajuster le zoom (×1.0 à ×3.5) sur tous les onglets

> **Note** : un abonnement numérique Le Monde est nécessaire pour accéder aux articles réservés aux abonnés et au journal électronique.

## Captures d'écran

*À venir*

## Architecture technique

L'application est construite en **QML natif** avec **QtWebEngine** (Chromium) pour le rendu web.

### Points techniques notables

- **Profil cookies partagé** — un unique `WebEngineProfile` (storageName `lemonde-storage`) assure la persistance de session entre les onglets Articles et Compte. Le Journal utilise un profil inline avec le même storageName pour la compatibilité mobile
- **Injection CSS/JS** — suppression des publicités, bandeaux Didomi, headers de navigation du site, et pieds d'articles via `WebEngineScript` injecté à `DocumentReady` et `MutationObserver` pour le contenu dynamique
- **Spoofing mobile pour Twipe** — le reader Twipe du journal détecte le type d'appareil via JavaScript (`screen.width`, `innerWidth`, `matchMedia`, `maxTouchPoints`). Un script injecté à `DocumentCreation` spoofie toutes ces valeurs pour forcer le rendu mobile
- **Navigation du journal par swipe** — détection du geste horizontal (touch + mouse) et changement du numéro de page dans le hash de l'URL (`#.../page/N`)
- **Anti-popups** — triple couche : override de `window.open`, `javascriptCanOpenWindows: false`, et pattern "trash WebView" (`onNewViewRequested: request.openIn(trashView)`) pour absorber les popups publicitaires
- **Zoom adaptatif** — `zoomFactor` global (par défaut 2.5) pour compenser le DPI élevé des écrans mobiles (1080px → viewport effectif ~430px)

### Structure du projet

```
lemonde-ut/
├── manifest.json              # Métadonnées du package Click
├── clickable.yaml             # Configuration Clickable (builder: pure)
├── lemonde.apparmor           # Permissions (networking, webview)
├── lemonde.desktop            # Entrée du lanceur d'applications
├── assets/
│   └── lemonde-icon.svg       # Icône de l'application
└── qml/
    ├── Main.qml               # Point d'entrée, header, profil partagé, SwipeView
    ├── images/
    │   └── lemonde-header.png # Logo Le Monde pour le header
    ├── components/
    │   ├── ArticleWebView.qml # WebView articles avec injection CSS/JS
    │   └── BottomNav.qml      # Barre de navigation en bas (4 boutons)
    └── pages/
        ├── PdfPage.qml        # Journal Twipe + viewer PDF + spoofing mobile
        └── AccountPage.qml    # Gestion du compte et connexion
```

## Installation

### Prérequis

- Un appareil sous **Ubuntu Touch 20.04** (testé sur Fairphone 5)
- [Clickable](https://clickable-ut.dev/) installé sur votre PC
- Le mode développeur activé sur le téléphone

### Depuis les sources

```bash
git clone https://github.com/solboki/lemonde-ut.git
cd lemonde-ut
clickable
```

L'application est compilée, empaquetée et installée automatiquement sur le téléphone connecté en USB.

### Test en mode desktop

```bash
clickable desktop
```

### Depuis l'OpenStore

Recherchez **Le Monde** dans l'OpenStore sur votre appareil Ubuntu Touch.

## Développement

### Contraintes Qt 5.12

Ubuntu Touch 20.04 utilise Qt 5.12. Points de vigilance :

- `import QtWebEngine 1.8` (pas 1.10+)
- Syntaxe QML multi-ligne obligatoire (pas de `}; property` sur une même ligne)
- `WebEngineProfile.MemoryHttpCache` au lieu de `DiskHttpCache` pour éviter les problèmes de cache

### Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou un pull request.

## Changelog

### v1.1.0
- **Authentification persistante** — les cookies de session sont conservés entre les lancements grâce au profil partagé unique et au cache disque
- **Session unifiée** — une seule connexion pour tous les onglets (Articles, Journal, Compte) via un `WebEngineProfile` partagé
- **Zoom réglable** — bouton dans le header pour cycler entre ×1.0, ×1.5, ×2.0, ×2.5, ×3.0, ×3.5
- **Navigation du journal par swipe** — swipe horizontal pour changer de page dans le journal Twipe, avec initialisation automatique du hash
- **Swipe désactivé entre onglets** — navigation uniquement via la barre du bas
- **Scrolling PDF corrigé** — suppression du PinchArea qui bloquait le défilement vertical
- **Logo Le Monde** dans le header à la place du titre texte
- **Icône personnalisée** de l'application

### v1.0.0
- Version initiale
- Lecture d'articles lemonde.fr en version mobile
- Journal électronique via journal.lemonde.fr (reader Twipe)
- Gestion du compte abonné
- Suppression des publicités et bandeaux cookies
- Affichage adapté au Fairphone 5 (zoom ×2.5)

## Crédits

- **Boris (solboki)** — conception, tests et intégration
- **Claude (Anthropic)** — développement et architecture de l'application, codé en pair-programming avec Boris via Claude.ai

## Licence

Ce projet est distribué sous licence [GPL-3.0](LICENSE).

Le Monde® est une marque déposée du Groupe Le Monde. Cette application n'est ni affiliée à, ni approuvée par Le Monde. Elle fournit simplement une interface de lecture optimisée pour Ubuntu Touch.
