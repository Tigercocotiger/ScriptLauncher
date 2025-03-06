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
    
    // Définir le nombre de colonnes avec taille fixe
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 160), spacing: 16)
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
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredScripts) { script in
                            MultiselectScriptGridItemView(
                                script: script,
                                isDarkMode: isDarkMode,
                                onToggleSelect: { onToggleSelect(script) },
                                onFavorite: { onToggleFavorite(script) }
                            )
                            .frame(width: 160, height: 180) // Hauteur réduite car on a supprimé les boutons
                        }
                    }
                    .padding(.vertical, DesignSystem.spacing)
                    .padding(.horizontal, DesignSystem.spacing)
                }
            }
        }
    }
}

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
        VStack(alignment: .center, spacing: 0) {
            // Partie supérieure avec icône centrée
            ZStack {
                // Cercle de fond
                Circle()
                    .fill(script.isSelected
                          ? DesignSystem.accentColor(for: isDarkMode).opacity(0.2)
                          : (isDarkMode ? Color(white: 0.25) : Color(white: 0.95)))
                    .frame(width: 80, height: 80)
                
                // Icône du script
                if hasLoadedIcon, let icon = scriptIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 45, height: 45)
                } else {
                    Image(systemName: script.name.hasSuffix(".scpt") ? "applescript" : "doc.text.fill")
                        .font(.system(size: 30))
                        .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
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
                }
                .buttonStyle(PlainButtonStyle())
                .position(x: 10, y: 10)
                .help(script.isFavorite ? "Retirer des favoris" : "Ajouter aux favoris")
            }
            .frame(width: 90, height: 90) // Taille fixe légèrement agrandie
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Nom du script sans extension
            Text(scriptNameWithoutExtension)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 140, height: 32) // Taille fixe
                .padding(.bottom, 4)
            
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
            .frame(height: 16) // Hauteur fixe
            
            Spacer()
        }
        .frame(width: 160, height: 180) // Taille totale fixe réduite
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
