# ScriptLauncher

ScriptLauncher est une application macOS moderne permettant d'organiser, gérer et exécuter vos scripts AppleScript et .scpt plus facilement. Cette interface élégante vous offre une expérience fluide pour lancer vos automatisations.

## Fonctionnalités

- **Interface élégante** - Design moderne avec support des modes clair et sombre
- **Gestion des favoris** - Marquez vos scripts les plus utilisés pour un accès rapide
- **Recherche instantanée** - Trouvez rapidement vos scripts par leur nom
- **Vue liste et grille** - Choisissez le mode d'affichage qui vous convient
- **Exécution en temps réel** - Visualisez la sortie de vos scripts pendant leur exécution
- **Historique d'exécution** - Gardez une trace de quand vos scripts ont été exécutés
- **Raccourcis clavier** - Naviguez et exécutez vos scripts efficacement

## Prérequis

- macOS 13.5 ou supérieur
- Xcode 16.2 ou supérieur pour compilation

## Installation

1. Clonez ce dépôt
2. Ouvrez le projet dans Xcode
3. Compilez et exécutez l'application

```bash
git clone https://github.com/votre-nom/ScriptLauncher.git
cd ScriptLauncher
open ScriptLauncher.xcodeproj
```

## Utilisation

### Configuration

Par défaut, l'application recherche des scripts dans le dossier `/Volumes/Marco/Dév/Fonctionnel`. Vous pouvez modifier ce chemin dans le fichier `ContentView.swift` :

```swift
private let folderPath = "/chemin/vers/vos/scripts"
```

### Raccourcis clavier

- `⌘ + Enter` : Exécuter le script sélectionné
- `⌘ + S` : Ajouter/retirer des favoris
- `⌘ + G` : Basculer entre vue liste et grille
- `⌘ + D` : Basculer entre mode clair et sombre
- `⌘ + I` : Afficher/masquer l'aide
- `Échap` : Annuler la recherche

## Structure du projet

```
ScriptLauncher/
├── Components/         # Composants d'interface réutilisables
├── Models/             # Définitions des modèles de données
├── Styles/             # Système de design et styles d'interface
├── Utils/              # Utilitaires et fonctions d'aide
└── Views/              # Vues principales de l'application
```

### Composants principaux

- **ContentView** - Vue principale qui orchestre l'application
- **ScriptsList** / **ScriptGridView** - Affichage des scripts en liste ou grille
- **ResultSection** - Affichage des résultats d'exécution
- **SearchBar** - Recherche et filtrage des scripts

## Personnalisation

### Système de design

Le système de design est centralisé dans `DesignSystem.swift`. Vous pouvez facilement modifier les couleurs, espaces et rayons pour adapter l'interface à vos préférences.

### Localisation

L'interface est actuellement en français. Pour ajouter d'autres langues, créez des fichiers de localisation pour les chaînes utilisées dans l'application.

## Développement

### Architecture

L'application est construite avec SwiftUI et suit une architecture MVVM simplifiée :
- Les modèles de données sont définis dans `Models.swift`
- Les vues sont réactives et se mettent à jour lorsque les données changent
- La logique métier est contenue dans les vues principales

### Extensions possibles

- Support de plusieurs dossiers de scripts
- Organisation par catégories
- Paramètres personnalisables
- Planification des scripts
- Support des scripts Shell et Python

## Contributeurs

- Marco SIMON (Auteur original)

---

*ScriptLauncher - Simplifiez l'exécution de vos scripts macOS*
