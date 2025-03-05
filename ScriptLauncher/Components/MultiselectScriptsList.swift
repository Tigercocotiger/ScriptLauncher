//
//  MultiselectScriptsList.swift
//  ScriptLauncher
//
//  Created on 05/03/2025.
//

import SwiftUI

struct MultiselectScriptsList: View {
    let scripts: [ScriptFile]
    let isDarkMode: Bool
    let showFavoritesOnly: Bool
    let searchText: String
    let onToggleSelect: (ScriptFile) -> Void
    let onToggleFavorite: (ScriptFile) -> Void
    let onSelectAll: () -> Void
    let onUnselectAll: () -> Void
    
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
            return matchesSearch && matchesFavorite
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
                            onToggleSelect: { onToggleSelect(script) },
                            onFavorite: { onToggleFavorite(script) }
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
                            
                            Text(showFavoritesOnly
                                 ? "Aucun script favori"
                                 : (searchText.isEmpty ? "Aucun script trouvé" : "Aucun résultat pour '\(searchText)'"))
                                .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                        }
                    }
                }
            )
        }
    }
}

// MARK: - Preview
#Preview("MultiselectScriptsList - Mode clair") {
    MultiselectScriptsList(
        scripts: [
            ScriptFile(name: "script1.scpt", path: "/path/1", isFavorite: true, lastExecuted: Date(), isSelected: true),
            ScriptFile(name: "script2.applescript", path: "/path/2", isFavorite: false, lastExecuted: nil, isSelected: false),
            ScriptFile(name: "script3.scpt", path: "/path/3", isFavorite: false, lastExecuted: Date().addingTimeInterval(-3600), isSelected: true)
        ],
        isDarkMode: false,
        showFavoritesOnly: false,
        searchText: "",
        onToggleSelect: { _ in },
        onToggleFavorite: { _ in },
        onSelectAll: {},
        onUnselectAll: {}
    )
    .frame(width: 400, height: 300)
    .background(Color.white)
}

#Preview("MultiselectScriptsList - Vide") {
    MultiselectScriptsList(
        scripts: [],
        isDarkMode: true,
        showFavoritesOnly: false,
        searchText: "introuvable",
        onToggleSelect: { _ in },
        onToggleFavorite: { _ in },
        onSelectAll: {},
        onUnselectAll: {}
    )
    .frame(width: 400, height: 300)
    .background(Color.black)
}