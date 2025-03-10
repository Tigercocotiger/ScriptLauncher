//
//  HelpContent.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 10/03/2025.
//


import Foundation

struct HelpContent {
    static let helpSections = [
        HelpSection(
            title: "Raccourcis clavier",
            content: """
            • ⌘ + Entrée : Exécuter le script sélectionné
            • ⌘ + ⇧ + Entrée : Exécuter tous les scripts sélectionnés
            • ⌘ + ⌥ + A : Sélectionner tous les scripts visibles
            • ⌘ + I : Afficher/masquer l'aide
            • ⌘ + S : Ajouter/retirer des favoris
            • ⌘ + G : Basculer entre vue liste et grille
            • ⌘ + D : Basculer entre mode clair et sombre
            • ⌘ + . : Arrêter tous les scripts en cours
            • ⌘ + ⇧ + N : Créer un installateur DMG
            • Échap : Annuler la recherche ou fermer l'aide
            """
        ),
        HelpSection(
            title: "Sélection multiple",
            content: """
            Vous pouvez sélectionner plusieurs scripts pour les exécuter en même temps :
            
            1. Cochez les cases à côté des scripts que vous souhaitez exécuter
            2. Utilisez le raccourci ⌘ + ⌥ + A pour sélectionner tous les scripts visibles
            3. Utilisez les boutons "Tout sélectionner" ou "Désélectionner tout" 
            4. Cliquez sur "Exécuter X scripts" pour lancer tous les scripts sélectionnés
            
            La sélection multiple vous permet d'automatiser plusieurs tâches simultanément.
            """
        ),
        HelpSection(
            title: "Gestion des tags",
            content: """
            Les tags vous permettent d'organiser vos scripts en groupes :
            
            1. Cliquez sur l'icône de tag à côté d'un script pour ajouter ou modifier ses tags
            2. Vous pouvez créer de nouveaux tags avec des couleurs personnalisées
            3. Utilisez les tags pour identifier rapidement les types de scripts
            
            Les tags sont automatiquement sauvegardés et conservés entre les sessions.
            """
        ),
        HelpSection(
            title: "Créateur d'installateur DMG",
            content: """
            Vous pouvez créer rapidement des scripts d'installation DMG :
            
            1. Cliquez sur le bouton "Créer installateur DMG" ou utilisez ⌘⇧N
            2. Sélectionnez le fichier DMG à installer
            3. Les informations seront automatiquement extraites
            4. Complétez les paramètres et créez le script
            
            Le script créé sera automatiquement disponible dans la liste des scripts.
            """
        ),
        HelpSection(
            title: "Gestion des favoris",
            content: """
            Pour ajouter un script aux favoris :
            • Cliquez sur l'icône d'étoile à côté du script
            • Sélectionnez le script et utilisez ⌘ + S
            
            Pour n'afficher que les favoris :
            • Activez le bouton d'étoile dans la barre de recherche
            
            Les favoris sont automatiquement sauvegardés dans les préférences de l'application.
            """
        ),
        HelpSection(
            title: "Scripts en cours d'exécution",
            content: """
            La section "Scripts en cours d'exécution" vous permet de :
            
            • Visualiser tous les scripts actuellement en exécution
            • Suivre leur progression et leur temps d'exécution
            • Arrêter un script spécifique ou tous les scripts
            • Consulter le résultat d'un script en le sélectionnant
            
            Le code couleur indique l'état de chaque script :
            🟠 En cours  🟢 Terminé  🔴 Erreur
            """
        ),
        HelpSection(
            title: "Recherche et filtrage",
            content: """
            La barre de recherche vous permet de filtrer rapidement vos scripts :
            
            • Tapez un terme pour filtrer les scripts par nom
            • Combinez la recherche avec le filtre de favoris
            • Appuyez sur Échap pour effacer la recherche
            
            Le résultat de la recherche s'affiche instantanément dans la liste des scripts.
            """
        ),
        HelpSection(
            title: "Dossier cible",
            content: """
            Vous pouvez changer le dossier contenant vos scripts en cliquant sur le bouton 
            en forme d'engrenage en haut de l'application.
            
            Le dossier sélectionné doit contenir des fichiers .scpt ou .applescript pour être valide.
            
            Le chemin du dossier est sauvegardé avec l'application et sera conservé même si vous 
            déplacez l'application sur une clé USB.
            """
        ),
    ]
}