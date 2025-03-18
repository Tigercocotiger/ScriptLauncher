//
//  MultiselectScriptGridView.swift
//  ScriptLauncher
//
//  Created on 05/03/2025.
//  Updated on 06/03/2025. - Added tags support
//  Updated on 07/03/2025. - Added tag color backgrounds with sections
//  Updated on 17/03/2025. - Added tag filtering support
//  Updated on 23/03/2025. - Added script properties editing
//

import SwiftUI
import Cocoa

struct MultiselectScriptGridView: View {
    let scripts: [ScriptFile]
    let isDarkMode: Bool
    let showFavoritesOnly: Bool
    let searchText: String
    let selectedTag: String?  // Nouveau paramètre
    let tagsViewModel: TagsViewModel
    let onToggleSelect: (ScriptFile) -> Void
    let onToggleFavorite: (ScriptFile) -> Void
    let onUpdateTags: (ScriptFile) -> Void
    let onSelectAll: () -> Void
    let onUnselectAll: () -> Void
    let onTagClick: ((String) -> Void)?  // Nouveau paramètre
    let onScriptUpdated: ((ScriptFile) -> Void)? // Nouveau callback pour les mises à jour de script
    
    // Nombre total de scripts affichés après filtrage
    private var filteredScriptsCount: Int {
        filteredScripts.count
    }
    
    // Nombre de scripts sélectionnés
    private var selectedScriptsCount: Int {
        filteredScripts.filter { $0.isSelected }.count
    }
    
    private var filteredScripts: [ScriptFile] {
        scripts.filter { script in
            let matchesSearch = searchText.isEmpty ||
                script.name.localizedCaseInsensitiveContains(searchText)
            let matchesFavorite = !showFavoritesOnly || script.isFavorite
            let matchesTag = selectedTag == nil || script.tags.contains(selectedTag!)
            return matchesSearch && matchesFavorite && matchesTag
        }
    }
    
    // Définir le nombre de colonnes avec taille fixe
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 160), spacing: 20)
    ]
    
    // Cette modification concerne la structure MultiselectScriptGridView

    var body: some View {
        VStack(spacing: 0) {
            // Barre d'actions de sélection
            if filteredScriptsCount > 0 {
                HStack {
                    Text("\(selectedScriptsCount) script\(selectedScriptsCount != 1 ? "s" : "") sélectionné\(selectedScriptsCount != 1 ? "s" : "") sur \(filteredScriptsCount)")
                        .font(.caption)
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: onSelectAll) {
                            Text("Tout sélectionner")
                                .font(.caption)
                                .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(selectedScriptsCount == filteredScriptsCount)
                        
                        Button(action: onUnselectAll) {
                            Text("Désélectionner tout")
                                .font(.caption)
                                .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(selectedScriptsCount == 0)
                    }
                }
                .padding(.horizontal, DesignSystem.spacing)
                .padding(.vertical, 8)
                .background(isDarkMode ? Color.black.opacity(0.2) : Color.gray.opacity(0.05))
            }
            
            if filteredScripts.isEmpty {
                // Affichage centré lorsqu'aucun script n'est trouvé
                VStack(spacing: DesignSystem.spacing) {
                    Spacer()
                    
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                    
                    if selectedTag != nil {
                        Text("Aucun script avec le tag '\(selectedTag!)'")
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            .multilineTextAlignment(.center)
                    } else if showFavoritesOnly {
                        Text("Aucun script favori")
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            .multilineTextAlignment(.center)
                    } else if !searchText.isEmpty {
                        Text("Aucun résultat pour '\(searchText)'")
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Aucun script trouvé")
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Fond coloré pour la zone de défilement
                ZStack {
                    // Fond
                    (isDarkMode ? Color.black.opacity(0.1) : Color.gray.opacity(0.03))
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Espace fixe en haut - même pour toutes les vues
                        Spacer()
                            .frame(height: 16)
                        
                        // La grille elle-même avec padding fixe
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(filteredScripts) { script in
                                    MultiselectScriptGridItemView(
                                        script: script,
                                        isDarkMode: isDarkMode,
                                        tagsViewModel: tagsViewModel,
                                        selectedTag: selectedTag,
                                        onToggleSelect: { onToggleSelect(script) },
                                        onFavorite: { onToggleFavorite(script) },
                                        onUpdateTags: { onUpdateTags($0) },
                                        onTagClick: onTagClick,
                                        onScriptUpdated: onScriptUpdated
                                    )
                                    .frame(width: 160, height: 180)
                                }
                            }
                            .padding([.horizontal, .bottom], DesignSystem.spacing)
                        }
                    }
                }
            }
        }
    }
}
struct MultiselectScriptGridItemView: View {
    let script: ScriptFile
    let isDarkMode: Bool
    let tagsViewModel: TagsViewModel
    let selectedTag: String? // Nouveau paramètre
    let onToggleSelect: () -> Void
    let onFavorite: () -> Void
    let onUpdateTags: (ScriptFile) -> Void
    let onTagClick: ((String) -> Void)?  // Nouveau paramètre
    let onScriptUpdated: ((ScriptFile) -> Void)? // Nouveau callback pour mise à jour
    
    @State private var scriptIcon: NSImage? = nil
    @State private var hasLoadedIcon: Bool = false
    @State private var showTagsEditor: Bool = false
    @State private var showPropertiesEditor: Bool = false
    
    // Extraire le nom du script sans l'extension
    private var scriptNameWithoutExtension: String {
        let name = script.name
        if let dotIndex = name.lastIndex(of: ".") {
            return String(name[..<dotIndex])
        }
        return name
    }
    
    // Obtenir les couleurs des tags pour le script
    private var tagColors: [Color] {
        // Si sélectionné, utiliser uniquement la couleur d'accent avec une opacité plus forte
        if script.isSelected {
            return [DesignSystem.accentColor(for: isDarkMode).opacity(0.3)]
        }
        
        // Si un tag est sélectionné et que le script a ce tag, mettre en évidence ce tag
        if let tagName = selectedTag, script.tags.contains(tagName),
           let tag = tagsViewModel.getTag(name: tagName) {
            // Utiliser la couleur du tag sélectionné avec une opacité plus élevée
            return [tag.color.opacity(0.4)]
        }
        
        // Récupérer les couleurs des tags associés au script
        let colors = script.tags.compactMap { tagName in
            tagsViewModel.getTag(name: tagName)?.color
        }
        
        // Si pas de tags ou pas de couleurs, retourner la couleur par défaut
        if colors.isEmpty {
            return [isDarkMode ? Color(white: 0.2) : Color(white: 0.92)]
        }
        
        // Appliquer l'opacité aux couleurs - augmentée pour plus de contraste
        return colors.map { $0.opacity(isDarkMode ? 0.4 : 0.35) }
    }
    
    // Détermine si le script doit avoir une bordure spéciale pour le tag sélectionné
    private var shouldHighlightBorder: Bool {
        if let tagName = selectedTag, script.tags.contains(tagName) {
            return true
        }
        return false
    }
    
    // Couleur de la bordure pour la mise en évidence du tag
    private var borderColor: Color {
        if let tagName = selectedTag, script.tags.contains(tagName),
           let tag = tagsViewModel.getTag(name: tagName) {
            return tag.color.opacity(0.8)
        }
        return script.isSelected
            ? DesignSystem.accentColor(for: isDarkMode).opacity(0.5)
            : Color.gray.opacity(0.2)
    }
    
    // Vue personnalisée pour le fond divisé par couleurs de tags
    private var tagSectionBackground: some View {
        ZStack {
            // Cercle de base pour le fond
            Circle()
                .fill(isDarkMode ? Color(white: 0.12) : Color(white: 0.9))
                .frame(width: 80, height: 80)
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            // Superposer les sections pour chaque tag
            ForEach(0..<tagColors.count, id: \.self) { index in
                TagSectionShape(
                    sectionCount: tagColors.count,
                    sectionIndex: index
                )
                .fill(tagColors[index])
                .frame(width: 80, height: 80)
            }
            
            // Contour pour unifier l'ensemble
            Circle()
                .stroke(isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1), lineWidth: 1)
                .frame(width: 80, height: 80)
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Partie supérieure avec icône centrée
            ZStack {
                // Fond divisé par sections de couleurs de tags
                tagSectionBackground
                
                // Icône du script
                if hasLoadedIcon, let icon = scriptIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 45, height: 45)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                } else {
                    Image(systemName: script.name.hasSuffix(".scpt") ? "applescript" : "doc.text.fill")
                        .font(.system(size: 30))
                        .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                
                // Badge de sélection en haut à droite
                if script.isSelected {
                    Circle()
                        .fill(DesignSystem.accentColor(for: isDarkMode))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .position(x: 70, y: 10)
                }
                
                // Bouton favori interactif en haut à gauche
                Button(action: onFavorite) {
                    Circle()
                        .fill(script.isFavorite ? DesignSystem.favoriteColor() : Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(script.isFavorite ? .white : Color.gray.opacity(0.7))
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                .buttonStyle(PlainButtonStyle())
                .position(x: 10, y: 10)
                .help(script.isFavorite ? "Retirer des favoris" : "Ajouter aux favoris")
                
                // Bouton pour éditer les propriétés (en bas à gauche)
                Button(action: {
                    showPropertiesEditor = true
                }) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 10))
                                .foregroundColor(Color.gray.opacity(0.7))
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                .buttonStyle(PlainButtonStyle())
                .position(x: 10, y: 70)
                .help("Modifier le nom et l'icône")
                .sheet(isPresented: $showPropertiesEditor) {
                    ScriptPropertiesEditor(
                        isPresented: $showPropertiesEditor,
                        script: script,
                        isDarkMode: isDarkMode,
                        onSave: { script, newName, newIcon in
                            // Appliquer les modifications via ScriptIconManager
                            ScriptIconManager.applyChanges(for: script, newName: newName, newIcon: newIcon) { result in
                                // Fermer la fenêtre d'édition
                                showPropertiesEditor = false
                                
                                // Traiter le résultat
                                switch result {
                                case .success(let updatedScript):
                                    // Recharger l'icône si elle a été modifiée
                                    loadScriptIcon()
                                    // Passer le script mis à jour au parent
                                    onScriptUpdated?(updatedScript)
                                case .failure(let error):
                                    // Afficher l'erreur
                                    let alert = NSAlert()
                                    alert.messageText = "Erreur lors de la modification"
                                    alert.informativeText = error.localizedDescription
                                    alert.alertStyle = .critical
                                    alert.addButton(withTitle: "OK")
                                    alert.runModal()
                                }
                            }
                        }
                    )
                }
                
                // Bouton pour gérer les tags en bas à droite
                Button(action: {
                    showTagsEditor = true
                }) {
                    Circle()
                        .fill(!script.tags.isEmpty ? DesignSystem.accentColor(for: isDarkMode) : Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "tag.fill")
                                .font(.system(size: 10))
                                .foregroundColor(!script.tags.isEmpty ? .white : Color.gray.opacity(0.7))
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                .buttonStyle(PlainButtonStyle())
                .position(x: 70, y: 70)
                .help("Gérer les tags")
                .sheet(isPresented: $showTagsEditor) {
                    ScriptTagsEditor(
                        tagsViewModel: tagsViewModel,
                        script: script,
                        isPresented: $showTagsEditor,
                        isDarkMode: isDarkMode,
                        onSave: onUpdateTags
                    )
                }
            }
            .frame(width: 90, height: 90)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Nom du script sans extension
            Text(scriptNameWithoutExtension)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 140, height: 32)
                .padding(.bottom, 4)
            
            // Tags visuels sous le nom
            if !script.tags.isEmpty {
                HStack(spacing: 4) {
                    ScriptTagsDisplay(
                        tags: script.tags,
                        tagsViewModel: tagsViewModel,
                        onTagClick: onTagClick
                    )
                }
                .frame(height: 12)
                .padding(.bottom, 4)
            }
            
            // Date d'exécution
            ZStack {
                if let lastExec = script.lastExecuted {
                    Text(timeAgo(from: lastExec))
                        .font(.caption2)
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                } else {
                    Text("Non exécuté")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                        .opacity(0.6)
                }
            }
            .frame(height: 16)
            
            Spacer()
        }
        .frame(width: 160, height: 180)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                .fill(
                    isDarkMode
                    ? (script.isSelected
                       ? DesignSystem.accentColor(for: isDarkMode).opacity(0.15)
                       : Color(red: 0.13, green: 0.13, blue: 0.15))
                    : (script.isSelected
                       ? DesignSystem.accentColor(for: isDarkMode).opacity(0.08)
                       : Color(red: 0.97, green: 0.97, blue: 0.98))
                )
                .shadow(
                    color: script.isSelected
                    ? Color.black.opacity(isDarkMode ? 0.3 : 0.15)
                    : Color.black.opacity(isDarkMode ? 0.2 : 0.08),
                    radius: 4,
                    x: 0,
                    y: 2
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                        .stroke(
                            borderColor,
                            lineWidth: shouldHighlightBorder ? 2 : 1
                        )
                )
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggleSelect)
        .onAppear {
            loadScriptIcon()
        }
    }
    
    // Formatage du temps écoulé
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "il y a \(day)j"
        } else if let hour = components.hour, hour > 0 {
            return "il y a \(hour)h"
        } else if let minute = components.minute, minute > 0 {
            return "il y a \(minute)m"
        } else {
            return "à l'instant"
        }
    }
    
    // Fonction pour charger l'icône du script
    private func loadScriptIcon() {
        DispatchQueue.global(qos: .userInitiated).async {
            let workspace = NSWorkspace.shared
            let icon = workspace.icon(forFile: script.path)
            
            DispatchQueue.main.async {
                self.scriptIcon = icon
                self.hasLoadedIcon = true
            }
        }
    }
}

// Forme personnalisée pour créer une section du cercle
struct TagSectionShape: Shape {
    let sectionCount: Int
    let sectionIndex: Int
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        // Calculer les angles de début et de fin pour cette section
        let angleSize = 2 * CGFloat.pi / CGFloat(sectionCount)
        let startAngle = angleSize * CGFloat(sectionIndex) - CGFloat.pi / 2
        let endAngle = startAngle + angleSize
        
        var path = Path()
        path.move(to: center)
        path.addArc(center: center,
                    radius: radius,
                    startAngle: Angle(radians: Double(startAngle)),
                    endAngle: Angle(radians: Double(endAngle)),
                    clockwise: false)
        path.closeSubpath()
        
        return path
    }
}
