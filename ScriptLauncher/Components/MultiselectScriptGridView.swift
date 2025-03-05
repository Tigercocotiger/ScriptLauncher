//
//  MultiselectScriptGridView.swift
//  ScriptLauncher
//
//  Created on 05/03/2025.
//

import SwiftUI
import Cocoa

struct MultiselectScriptGridView: View {
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
    
    // Définir le nombre de colonnes en fonction de la largeur
    private let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 160), spacing: 12)
    ]
    
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredScripts) { script in
                            MultiselectScriptGridItemView(
                                script: script,
                                isDarkMode: isDarkMode,
                                onToggleSelect: { onToggleSelect(script) },
                                onFavorite: { onToggleFavorite(script) }
                            )
                        }
                    }
                    .padding(.vertical, DesignSystem.spacing)
                    .padding(.horizontal, DesignSystem.spacing)
                }
            }
        }
    }
}

// Élément de grille pour un script avec sélection multiple
struct MultiselectScriptGridItemView: View {
    let script: ScriptFile
    let isDarkMode: Bool
    let onToggleSelect: () -> Void
    let onFavorite: () -> Void
    
    @State private var scriptIcon: NSImage? = nil
    @State private var hasLoadedIcon: Bool = false
    
    // Extraire le nom du script sans l'extension
    private var scriptNameWithoutExtension: String {
        let name = script.name
        if let dotIndex = name.lastIndex(of: ".") {
            return String(name[..<dotIndex])
        }
        return name
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Partie supérieure avec icône et sélection
            HStack {
                // Case à cocher pour la sélection
                Button(action: onToggleSelect) {
                    Image(systemName: script.isSelected ? "checkmark.square.fill" : "square")
                        .font(.system(size: 14))
                        .foregroundColor(script.isSelected 
                                        ? DesignSystem.accentColor(for: isDarkMode)
                                        : DesignSystem.textSecondary(for: isDarkMode))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Affichage de l'icône personnalisée ou par défaut
                if hasLoadedIcon, let icon = scriptIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: script.name.hasSuffix(".scpt") ? "applescript" : "doc.text.fill")
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
                }
                
                Spacer()
                
                // Icône de favori
                Button(action: onFavorite) {
                    Image(systemName: script.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundColor(script.isFavorite
                                         ? DesignSystem.favoriteColor()
                                         : DesignSystem.textSecondary(for: isDarkMode))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Nom du script sans extension
            Text(scriptNameWithoutExtension)
                .font(.system(size: 12))
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                .lineLimit(2)
                .frame(height: 30, alignment: .top)
            
            // Date d'exécution
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
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                .fill(script.isSelected
                      ? DesignSystem.accentColor(for: isDarkMode).opacity(isDarkMode ? 0.3 : 0.1)
                      : DesignSystem.cardBackground(for: isDarkMode))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                        .stroke(
                            script.isSelected
                                ? DesignSystem.accentColor(for: isDarkMode).opacity(0.5)
                                : Color.gray.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggleSelect)
        .onAppear {
            loadScriptIcon()
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
}

// MARK: - Preview
#Preview("MultiselectScriptGridView - Mode clair") {
    MultiselectScriptGridView(
        scripts: [
            ScriptFile(name: "script1.scpt", path: "/path/1", isFavorite: true, lastExecuted: Date(), isSelected: true),
            ScriptFile(name: "script2.applescript", path: "/path/2", isFavorite: false, lastExecuted: nil, isSelected: false),
            ScriptFile(name: "script3.scpt", path: "/path/3", isFavorite: false, lastExecuted: Date().addingTimeInterval(-3600), isSelected: true),
            ScriptFile(name: "script_with_very_long_name.scpt", path: "/path/4", isFavorite: true, lastExecuted: Date().addingTimeInterval(-86400), isSelected: false)
        ],
        isDarkMode: false,
        showFavoritesOnly: false,
        searchText: "",
        onToggleSelect: { _ in },
        onToggleFavorite: { _ in },
        onSelectAll: {},
        onUnselectAll: {}
    )
    .frame(width: 600, height: 400)
    .background(Color.white)
}