# 🚀 ScriptLauncher

ScriptLauncher est une application macOS moderne permettant d'organiser, gérer et exécuter vos scripts AppleScript et .scpt plus facilement. Cette interface élégante vous offre une expérience fluide pour lancer vos automatisations.

## ✨ Fonctionnalités

- **🎨 Interface élégante** - Design moderne avec support des modes clair et sombre
- **☑️ Sélection multiple** - Sélectionnez et exécutez plusieurs scripts simultanément
- **⏱️ Suivi en temps réel** - Compteurs de temps qui s'actualisent automatiquement
- **📜 Historique d'exécution** - Conserve l'historique des scripts exécutés (succès/échec)
- **⭐ Gestion des favoris** - Marquez vos scripts les plus utilisés pour un accès rapide
- **🔍 Recherche instantanée** - Trouvez rapidement vos scripts par leur nom
- **🏷️ Système de tags avancé** - Catégorisez et filtrez vos scripts avec des tags colorés personnalisables
- **📊 Vue liste et grille** - Choisissez le mode d'affichage qui vous convient
- **📤 Exécution en temps réel** - Visualisez la sortie de vos scripts pendant leur exécution
- **⌨️ Raccourcis clavier** - Naviguez et exécutez vos scripts efficacement
- **📂 Sélection de dossier** - Changez facilement le dossier cible des scripts
- **💾 Configuration portable** - Vos préférences sont conservées même sur clé USB
- **📥 Créateur d'installateurs DMG/PKG** - Générez facilement des scripts d'installation avec support d'installation silencieuse

## 📋 Prérequis

- macOS 13.5 ou supérieur
- Xcode 16.2 ou supérieur pour compilation

## 📥 Installation

1. Clonez ce dépôt
2. Ouvrez le projet dans Xcode
3. Compilez et exécutez l'application

```bash
git clone https://github.com/tigercocotiger/ScriptLauncher.git
cd ScriptLauncher
open ScriptLauncher.xcodeproj
```

## 🎮 Utilisation

### ⚙️ Configuration

ScriptLauncher est entièrement portable. Vous pouvez le déplacer sur une clé USB et l'utiliser sur n'importe quel Mac. Vos préférences, favoris et autres paramètres sont stockés dans un dossier `Resources/ScriptLauncher` à côté de l'application.

Pour changer le dossier cible des scripts :
1. Cliquez sur l'icône d'engrenage à côté du chemin affiché
2. Sélectionnez un dossier contenant des scripts (.scpt ou .applescript)
3. Le nouveau chemin sera automatiquement sauvegardé

### ⌨️ Raccourcis clavier

- `⌘ + Entrée` : Exécuter le script sélectionné
- `⌘ + ⇧ + Entrée` : Exécuter tous les scripts sélectionnés
- `⌘ + ⌥ + A` : Sélectionner tous les scripts visibles
- `⌘ + S` : Ajouter/retirer des favoris
- `⌘ + G` : Basculer entre vue liste et grille
- `⌘ + D` : Basculer entre mode clair et sombre
- `⌘ + I` : Afficher/masquer l'aide
- `⌘ + .` : Arrêter tous les scripts en cours
- `⌘ + ⇧ + N` : Créer un installateur DMG
- `Échap` : Annuler la recherche

### 📋 Sélection multiple

Vous pouvez sélectionner plusieurs scripts pour les exécuter en même temps :

1. Cochez les cases à côté des scripts que vous souhaitez exécuter
2. Utilisez le raccourci `⌘ + ⌥ + A` pour sélectionner tous les scripts visibles
3. Utilisez les boutons "Tout sélectionner" ou "Désélectionner tout"
4. Cliquez sur "Exécuter X scripts" pour lancer tous les scripts sélectionnés

### 🏷️ Gestion et filtrage par tags

Le système de tags amélioré vous permet de catégoriser et filtrer vos scripts :

1. Cliquez sur l'icône de tag à côté d'un script pour gérer ses tags
2. Créez de nouveaux tags avec des couleurs personnalisées
3. Attribuez plusieurs tags à un même script
4. Utilisez la barre de filtres par tags pour afficher uniquement les scripts possédant un tag spécifique
5. Cliquez directement sur les indicateurs de tag dans les listes et grilles pour filtrer rapidement
6. Les scripts avec le tag sélectionné sont visuellement mis en évidence

Les statistiques de chaque tag (nombre de scripts associés) sont affichées directement dans la barre de filtres.

### 📥 Créateur d'installateurs DMG/PKG

Créez facilement des scripts d'installation pour vos applications DMG ou packages PKG :

1. Cliquez sur "Créer installateur DMG" ou utilisez `⌘ + ⇧ + N`
2. Sélectionnez le fichier DMG source
3. Les informations (nom du volume, chemin de l'application) sont automatiquement extraites
4. Pour les packages PKG, l'installation silencieuse est supportée avec authentification automatique
5. Le script généré utilise des logs colorés avec émojis pour suivre l'avancement
6. Une fois créé, vous pouvez ajouter des tags au script dans la liste principale

### 📊 Gestion de l'historique

La section "Scripts en cours d'exécution" vous permet de :

- Visualiser tous les scripts exécutés avec leur statut
- Suivre leur progression et leur temps d'exécution en temps réel
- Arrêter un script spécifique ou tous les scripts en cours
- Effacer l'historique des scripts terminés
- Consulter le résultat d'un script en le sélectionnant
- Relancer un script déjà exécuté

Le code couleur indique l'état de chaque script :
- 🟠 En cours
- 🟢 Terminé
- 🔴 Erreur

## 📁 Structure du projet

```
ScriptLauncher/
├── Components/         # 🧩 Composants d'interface réutilisables
├── Models/             # 📊 Définitions des modèles de données et ViewModels
├── Styles/             # 🎨 Système de design et styles d'interface
├── Utils/              # 🔧 Utilitaires et fonctions d'aide
└── Views/              # 📱 Vues principales de l'application
```

### 🧱 Composants principaux

- **ContentView** - Vue principale qui orchestre l'application
- **TagFilterControl** - Barre de filtrage par tags avec statistiques
- **RunningScriptsView** - Affichage des scripts en cours d'exécution
- **MultiResultSection** - Affichage des résultats d'exécution
- **FolderSelector** - Sélection du dossier cible des scripts
- **ConfigManager** - Gestion de la configuration portable
- **TagsViewModel** - Gestion des tags et de leurs couleurs
- **MultiselectScriptsList/GridView** - Affichage des scripts avec sélection multiple
- **RunningScriptsViewModel** - Gestion des scripts en cours avec timer
- **DMGInstallerCreator** - Génération de scripts d'installation pour DMG/PKG

## 🛠️ Personnalisation

### 🎨 Système de design

Le système de design est centralisé dans `DesignSystem.swift`. Vous pouvez facilement modifier les couleurs, espaces et rayons pour adapter l'interface à vos préférences.

### 🌍 Localisation

L'interface est actuellement en français. Pour ajouter d'autres langues, créez des fichiers de localisation pour les chaînes utilisées dans l'application.

### 📝 Édition des propriétés de scripts

La nouvelle fonctionnalité d'édition de propriétés vous permet de :
- Modifier le nom des scripts (tout en conservant l'extension)
- Personnaliser les icônes des scripts avec des images de votre choix
- Conserver automatiquement les associations de tags lors du renommage
- Visualiser un aperçu en temps réel des modifications

## 💻 Développement

### 🏗️ Architecture

L'application est construite avec SwiftUI et suit une architecture MVVM :
- Les modèles de données sont définis dans `Models.swift`
- Les ViewModels gèrent l'état et la logique métier
- Les vues sont réactives et se mettent à jour lorsque les données changent

### 🔮 Extensions possibles

- 📅 Planification des scripts
- 🐚 Support des scripts Shell et Python
- 📊 Statistiques d'exécution
- 🌐 Support multilingue

## 📋 Changelog

### Version 1.2 (Mars 2025)
- 🏷️ Ajout du filtrage par tags avec statistiques et mise en évidence
- 📦 Support de l'installation silencieuse des packages PKG
- 🛠️ Amélioration de l'installateur de DMG avec moins de popups
- 🖼️ Optimisation de l'interface des tags dans les vues liste et grille
- 🐛 Corrections de bugs et améliorations de performance

### Version 1.1 (Mars 2025)
- ✨ Nouveau créateur d'installateurs DMG avec extraction automatique d'informations
- 🏷️ Amélioration du système de tags avec couleurs personnalisables
- 📊 Nouveau mode d'affichage en grille avec visualisation des tags
- 📄 Logs colorés avec émojis pour un meilleur suivi des scripts
- 🐛 Corrections de bugs et améliorations de performance

### Version 1.0 (Février 2025)
- 🚀 Version initiale

## 👥 Contributeurs

- Marco SIMON (Auteur original)

---

*🚀 ScriptLauncher - Simplifiez l'exécution de vos scripts macOS*
