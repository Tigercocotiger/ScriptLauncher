# ScriptLauncher

ScriptLauncher est une application macOS moderne permettant d'organiser, gérer et exécuter vos scripts AppleScript et .scpt plus facilement. Cette interface élégante vous offre une expérience fluide pour lancer vos automatisations.

## Fonctionnalités

- **Interface élégante** - Design moderne avec support des modes clair et sombre
- **Sélection multiple** - Sélectionnez et exécutez plusieurs scripts simultanément
- **Suivi en temps réel** - Compteurs de temps qui s'actualisent automatiquement
- **Historique d'exécution** - Conserve l'historique des scripts exécutés (succès/échec)
- **Gestion des favoris** - Marquez vos scripts les plus utilisés pour un accès rapide
- **Recherche instantanée** - Trouvez rapidement vos scripts par leur nom
- **Vue liste et grille** - Choisissez le mode d'affichage qui vous convient
- **Exécution en temps réel** - Visualisez la sortie de vos scripts pendant leur exécution
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

- `⌘ + Entrée` : Exécuter le script sélectionné
- `⌘ + ⇧ + Entrée` : Exécuter tous les scripts sélectionnés
- `⌘ + ⌥ + A` : Sélectionner tous les scripts visibles
- `⌘ + S` : Ajouter/retirer des favoris
- `⌘ + G` : Basculer entre vue liste et grille
- `⌘ + D` : Basculer entre mode clair et sombre
- `⌘ + I` : Afficher/masquer l'aide
- `⌘ + .` : Arrêter tous les scripts en cours
- `Échap` : Annuler la recherche

### Sélection multiple

Vous pouvez sélectionner plusieurs scripts pour les exécuter en même temps :

1. Cochez les cases à côté des scripts que vous souhaitez exécuter
2. Utilisez le raccourci `⌘ + ⌥ + A` pour sélectionner tous les scripts visibles
3. Utilisez les boutons "Tout sélectionner" ou "Désélectionner tout"
4. Cliquez sur "Exécuter X scripts" pour lancer tous les scripts sélectionnés

### Gestion de l'historique

La section "Scripts en cours d'exécution" vous permet de :

- Visualiser tous les scripts exécutés avec leur statut
- Suivre leur progression et leur temps d'exécution en temps réel
- Arrêter un script spécifique ou tous les scripts en cours
- Effacer l'historique des scripts terminés
- Consulter le résultat d'un script en le sélectionnant

Le code couleur indique l'état de chaque script :
- 🟠 En cours
- 🟢 Terminé
- 🔴 Erreur

## Structure du projet

```
ScriptLauncher/
├── Components/         # Composants d'interface réutilisables
├── Models/             # Définitions des modèles de données et ViewModels
├── Styles/             # Système de design et styles d'interface
├── Utils/              # Utilitaires et fonctions d'aide
└── Views/              # Vues principales de l'application
```

### Composants principaux

- **ContentView** - Vue principale qui orchestre l'application
- **RunningScriptsView** - Affichage des scripts en cours d'exécution
- **MultiResultSection** - Affichage des résultats d'exécution
- **MultiselectScriptsList/GridView** - Affichage des scripts avec sélection multiple
- **RunningScriptsViewModel** - Gestion des scripts en cours avec timer

## Personnalisation

### Système de design

Le système de design est centralisé dans `DesignSystem.swift`. Vous pouvez facilement modifier les couleurs, espaces et rayons pour adapter l'interface à vos préférences.

### Localisation

L'interface est actuellement en français. Pour ajouter d'autres langues, créez des fichiers de localisation pour les chaînes utilisées dans l'application.

## Développement

### Architecture

L'application est construite avec SwiftUI et suit une architecture MVVM :
- Les modèles de données sont définis dans `Models.swift`
- Les ViewModels gèrent l'état et la logique métier
- Les vues sont réactives et se mettent à jour lorsque les données changent

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
