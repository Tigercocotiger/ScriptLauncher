//
//  HelpContent.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 10/03/2025.
//  Updated on 23/03/2025. - Added script properties editing
//  Updated on 30/03/2025. - Added edit mode section
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
            • ⌘ + E : Activer/désactiver le mode d'édition
            • ⌘ + . : Arrêter tous les scripts en cours
            • ⌘ + ⇧ + N : Créer un installateur DMG
            • ⌘ + ⇧ + C : Nettoyer la configuration
            • Échap : Annuler la recherche ou fermer l'aide
            """
        ),
        
        HelpSection(
            title: "Mode d'édition",
            content: """
            Le mode d'édition permet de personnaliser rapidement vos scripts :
            
            • Activez ou désactivez le mode en cliquant sur l'icône de crayon dans la barre de recherche
            • Utilisez le raccourci ⌘ + E pour basculer le mode d'édition
            • En mode édition, des boutons apparaissent sur les bordures des cartes :
              - Étoile : marquer comme favori
              - Crayon : modifier nom et icône
              - Étiquette : gérer les tags
            
            Ces boutons sont positionnés sur les bordures pour préserver la visibilité des icônes.
            Vous pouvez désactiver ce mode pour une interface plus épurée, particulièrement utile 
            sur les petits écrans.
            
            Le mode d'édition est automatiquement sauvegardé dans vos préférences.
            """
        ),
        
        HelpSection(
            title: "Personnalisation des scripts",
            content: """
            Vous pouvez modifier les propriétés visuelles de vos scripts :
            
            1. Cliquez sur l'icône de crayon à côté d'un script
            2. Modifiez le nom du script (l'extension est conservée)
            3. Changez l'icône en sélectionnant une nouvelle image
            4. Appuyez sur "Enregistrer" pour appliquer les modifications
            
            Cette fonction est utile pour repérer visuellement vos scripts les plus importants avec des icônes personnalisées. Les icônes standard peuvent être changées pour des icônes colorées ou qui reflètent mieux le but du script.
            
            Note : La modification s'applique uniquement à l'apparence du fichier, pas à son contenu.
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
            4. Filtrez vos scripts en cliquant sur un tag dans la barre de filtres
            5. Les pastilles de couleur affichées sur les cartes indiquent les tags associés
            
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
        
        HelpSection(
            title: "Nettoyage de la configuration",
            content: """
            Pour assurer la portabilité de vos scripts et tags :
            
            1. Utilisez l'option "Nettoyer la configuration" dans le menu Outils (⌘⇧C)
            2. Cette fonction simplifie les chemins absolus dans votre configuration
            3. Les références aux scripts utilisent désormais uniquement les noms de fichiers
            
            Cette fonction est particulièrement utile lorsque vous déplacez l'application
            entre différents ordinateurs ou clés USB.
            """
        ),
    ]
}
