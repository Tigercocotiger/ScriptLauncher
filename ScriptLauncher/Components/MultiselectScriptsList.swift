//
//  MultiselectScriptsList.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 05/03/2025.
//  Updated on 06/03/2025. - Added tags support
//  Updated on 17/03/2025. - Added tag filtering support
//  Updated on 23/03/2025. - Added script properties editing
//

import SwiftUI

struct MultiselectScriptsList: View {
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
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredScripts) { script in
                        MultiselectScriptRowView(
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
                        .padding(.horizontal, DesignSystem.spacing)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        
                        if script.id != filteredScripts.last?.id {
                            Divider()
                                .padding(.leading, DesignSystem.spacing + 44) // Indentation pour aligner sous l'icône
                        }
                    }
                }
                .padding(.vertical, 1)
            }
            .overlay(
                Group {
                    if filteredScripts.isEmpty {
                        VStack(spacing: DesignSystem.spacing) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            
                            if selectedTag != nil {
                                Text("Aucun script avec le tag '\(selectedTag!)'")
                                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            } else if showFavoritesOnly {
                                Text("Aucun script favori")
                                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            } else if !searchText.isEmpty {
                                Text("Aucun résultat pour '\(searchText)'")
                                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            } else {
                                Text("Aucun script trouvé")
                                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            }
                        }
                    }
                }
            )
        }
    }
}

// MARK: - Preview
#Preview("MultiselectScriptsList - Mode clair") {
    let tagsViewModel = TagsViewModel()
    tagsViewModel.addTag(name: "Important", color: .red)
    tagsViewModel.addTag(name: "Automatisation", color: .blue)
    
    return MultiselectScriptsList(
        scripts: [
            ScriptFile(name: "script1.scpt", path: "/path/1", isFavorite: true, lastExecuted: Date(), isSelected: true, tags: ["Important"]),
            ScriptFile(name: "script2.applescript", path: "/path/2", isFavorite: false, lastExecuted: nil, isSelected: false),
            ScriptFile(name: "script3.scpt", path: "/path/3", isFavorite: false, lastExecuted: Date().addingTimeInterval(-3600), isSelected: true, tags: ["Automatisation"])
        ],
        isDarkMode: false,
        showFavoritesOnly: false,
        searchText: "",
        selectedTag: nil,
        tagsViewModel: tagsViewModel,
        onToggleSelect: { _ in },
        onToggleFavorite: { _ in },
        onUpdateTags: { _ in },
        onSelectAll: {},
        onUnselectAll: {},
        onTagClick: { _ in },
        onScriptUpdated: { _ in }
    )
    .frame(width: 400, height: 300)
    .background(Color.white)
}

#Preview("MultiselectScriptsList - Vide") {
    let tagsViewModel = TagsViewModel()
    
    return MultiselectScriptsList(
        scripts: [],
        isDarkMode: true,
        showFavoritesOnly: false,
        searchText: "introuvable",
        selectedTag: nil,
        tagsViewModel: tagsViewModel,
        onToggleSelect: { _ in },
        onToggleFavorite: { _ in },
        onUpdateTags: { _ in },
        onSelectAll: {},
        onUnselectAll: {},
        onTagClick: { _ in },
        onScriptUpdated: { _ in }
    )
    .frame(width: 400, height: 300)
    .background(Color.black)
}
