//
//  MultiselectScriptRowView.swift
//  ScriptLauncher
//
//  Created on 05/03/2025.
//  Updated on 06/03/2025. - Added tags support
//  Updated on 17/03/2025. - Added tag filtering support
//  Updated on 23/03/2025. - Added script properties editing
//  Updated on 25/03/2025. - Added edit mode support
//

import SwiftUI
import Cocoa

// Vue pour une ligne de script avec sélection multiple
struct MultiselectScriptRowView: View {
    let script: ScriptFile
    let isDarkMode: Bool
    let tagsViewModel: TagsViewModel
    let selectedTag: String?
    let isEditMode: Bool
    let onToggleSelect: () -> Void
    let onFavorite: () -> Void
    let onUpdateTags: (ScriptFile) -> Void
    let onTagClick: ((String) -> Void)?
    let onScriptUpdated: ((ScriptFile) -> Void)?
    
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
    
    // Propriété calculée pour déterminer la couleur de fond
    private var rowBackground: some View {
        Group {
            if script.isSelected {
                // Si le script est sélectionné, utiliser la couleur d'accent
                DesignSystem.accentColor(for: isDarkMode).opacity(isDarkMode ? 0.3 : 0.1)
            } else if let tagName = selectedTag, script.tags.contains(tagName),
                      let tag = tagsViewModel.getTag(name: tagName) {
                // Si un tag est sélectionné et que le script a ce tag, utiliser la couleur du tag
                tag.color.opacity(isDarkMode ? 0.15 : 0.1)
            } else {
                // Sinon, fond transparent
                Color.clear
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Case à cocher pour la sélection
            Button(action: onToggleSelect) {
                Image(systemName: script.isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundColor(script.isSelected
                                    ? DesignSystem.accentColor(for: isDarkMode)
                                    : DesignSystem.textSecondary(for: isDarkMode))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Icône du script
            ZStack {
                // Étoile de favori si applicable
                if script.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.favoriteColor())
                        .offset(x: 8, y: -8)
                        .zIndex(1)
                }
                
                // Icône du script
                if hasLoadedIcon, let icon = scriptIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: script.name.hasSuffix(".scpt") ? "applescript" : "doc.text.fill")
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
                        .frame(width: 20, height: 20)
                }
            }
            .frame(width: 24, height: 24)
            
            // Nom du script sans extension
            Text(scriptNameWithoutExtension)
                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                .lineLimit(1)
            
            // Affichage des tags
            ScriptTagsDisplay(
                tags: script.tags,
                tagsViewModel: tagsViewModel,
                onTagClick: onTagClick
            )
            
            Spacer()
            
            // Date d'exécution
            if let lastExec = script.lastExecuted {
                Text(timeAgo(from: lastExec))
                    .font(.caption)
                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
            }
            
            // Groupe de boutons d'édition - visible uniquement en mode édition
            HStack(spacing: 4) {
                if isEditMode {
                    // Bouton pour éditer les propriétés
                    ScriptPropertiesButton(
                        script: script,
                        isDarkMode: isDarkMode,
                        showPropertiesEditor: $showPropertiesEditor,
                        onSuccess: { updatedScript in
                            loadScriptIcon()
                            onScriptUpdated?(updatedScript)
                        }
                    )
                    
                    // Bouton pour gérer les tags
                    Button(action: {
                        showTagsEditor = true
                    }) {
                        Image(systemName: "tag")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(0.6)
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
                    
                    // Bouton favori
                    Button(action: onFavorite) {
                        Image(systemName: script.isFavorite ? "star.slash" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(0.6)
                    .help(script.isFavorite ? "Retirer des favoris" : "Ajouter aux favoris")
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggleSelect)
        .background(rowBackground) // Utiliser la nouvelle propriété calculée
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
            return "\(day)j"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m"
        } else {
            return "<1m"
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

// MARK: - Preview
#Preview("MultiselectScriptRowView - Mode clair") {
    // Créer un TagsViewModel pour la prévisualisation
    let tagsViewModel = TagsViewModel()
    tagsViewModel.addTag(name: "Important", color: .red)
    tagsViewModel.addTag(name: "Automatisation", color: .blue)
    
    let script = ScriptFile(
        name: "test_script.scpt",
        path: "/Applications/Script Editor.app",
        isFavorite: false,
        lastExecuted: nil,
        isSelected: false,
        tags: ["Important"]
    )
    
    return VStack(spacing: 8) {
        // Script normal avec mode édition activé
        MultiselectScriptRowView(
            script: script,
            isDarkMode: false,
            tagsViewModel: tagsViewModel,
            selectedTag: nil,
            isEditMode: true,
            onToggleSelect: {},
            onFavorite: {},
            onUpdateTags: { _ in },
            onTagClick: { _ in },
            onScriptUpdated: { _ in }
        )
        .padding(.horizontal)
        .background(Color.white)
        
        // Script normal avec mode édition désactivé
        MultiselectScriptRowView(
            script: script,
            isDarkMode: false,
            tagsViewModel: tagsViewModel,
            selectedTag: nil,
            isEditMode: false,
            onToggleSelect: {},
            onFavorite: {},
            onUpdateTags: { _ in },
            onTagClick: { _ in },
            onScriptUpdated: { _ in }
        )
        .padding(.horizontal)
        .background(Color.white)
        
        // Script sélectionné
        MultiselectScriptRowView(
            script: ScriptFile(
                name: "selected_script.scpt",
                path: "/Applications/Automator.app",
                isFavorite: false,
                lastExecuted: Date(),
                isSelected: true,
                tags: ["Automatisation"]
            ),
            isDarkMode: false,
            tagsViewModel: tagsViewModel,
            selectedTag: nil,
            isEditMode: true,
            onToggleSelect: {},
            onFavorite: {},
            onUpdateTags: { _ in },
            onTagClick: { _ in },
            onScriptUpdated: { _ in }
        )
        .padding(.horizontal)
        
        // Script favori et sélectionné
        MultiselectScriptRowView(
            script: ScriptFile(
                name: "favorite_script.scpt",
                path: "/System/Applications/Utilities/Terminal.app",
                isFavorite: true,
                lastExecuted: Date(),
                isSelected: true,
                tags: ["Important", "Automatisation"]
            ),
            isDarkMode: false,
            tagsViewModel: tagsViewModel,
            selectedTag: nil,
            isEditMode: true,
            onToggleSelect: {},
            onFavorite: {},
            onUpdateTags: { _ in },
            onTagClick: { _ in },
            onScriptUpdated: { _ in }
        )
        .padding(.horizontal)
    }
    .padding()
    .frame(width: 400, height: 300)
}

#Preview("MultiselectScriptRowView - Mode sombre") {
    let tagsViewModel = TagsViewModel()
    tagsViewModel.addTag(name: "Important", color: .red)
    
    return VStack(spacing: 8) {
        MultiselectScriptRowView(
            script: ScriptFile(
                name: "dark_mode_script.applescript",
                path: "/System/Applications/Utilities/Console.app",
                isFavorite: false,
                lastExecuted: Date().addingTimeInterval(-3600),
                isSelected: true,
                tags: ["Important"]
            ),
            isDarkMode: true,
            tagsViewModel: tagsViewModel,
            selectedTag: "Important",
            isEditMode: true,
            onToggleSelect: {},
            onFavorite: {},
            onUpdateTags: { _ in },
            onTagClick: { _ in },
            onScriptUpdated: { _ in }
        )
        .padding(.horizontal)
        .background(Color.black)
    }
    .padding()
    .frame(width: 400, height: 60)
}
