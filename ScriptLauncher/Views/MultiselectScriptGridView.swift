//
//  MultiselectScriptGridView.swift
//  ScriptLauncher
//
//  Created on 05/03/2025.
//  Updated on 06/03/2025. - Added tags support
//  Updated on 07/03/2025. - Added tag color backgrounds with sections
//

import SwiftUI
import Cocoa

struct MultiselectScriptGridView: View {
    let scripts: [ScriptFile]
    let isDarkMode: Bool
    let showFavoritesOnly: Bool
    let searchText: String
    let tagsViewModel: TagsViewModel
    let onToggleSelect: (ScriptFile) -> Void
    let onToggleFavorite: (ScriptFile) -> Void
    let onUpdateTags: (ScriptFile) -> Void
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
                                tagsViewModel: tagsViewModel,
                                onToggleSelect: { onToggleSelect(script) },
                                onFavorite: { onToggleFavorite(script) },
                                onUpdateTags: { onUpdateTags($0) }
                            )
                            .frame(width: 160, height: 180)
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
    let tagsViewModel: TagsViewModel
    let onToggleSelect: () -> Void
    let onFavorite: () -> Void
    let onUpdateTags: (ScriptFile) -> Void
    
    @State private var scriptIcon: NSImage? = nil
    @State private var hasLoadedIcon: Bool = false
    @State private var showTagsEditor: Bool = false
    
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
        // Si sélectionné, utiliser uniquement la couleur d'accent
        if script.isSelected {
            return [DesignSystem.accentColor(for: isDarkMode).opacity(0.2)]
        }
        
        // Récupérer les couleurs des tags associés au script
        let colors = script.tags.compactMap { tagName in
            tagsViewModel.getTag(name: tagName)?.color
        }
        
        // Si pas de tags ou pas de couleurs, retourner la couleur par défaut
        if colors.isEmpty {
            return [isDarkMode ? Color(white: 0.25) : Color(white: 0.95)]
        }
        
        // Appliquer l'opacité aux couleurs
        return colors.map { $0.opacity(isDarkMode ? 0.3 : 0.2) }
    }
    
    // Vue personnalisée pour le fond divisé par couleurs de tags
    private var tagSectionBackground: some View {
        ZStack {
            // Cercle de base pour le fond
            Circle()
                .fill(isDarkMode ? Color(white: 0.2) : Color(white: 0.93))
                .frame(width: 80, height: 80)
            
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
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
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
                }
                .buttonStyle(PlainButtonStyle())
                .position(x: 70, y: 70)
                .help("Gérer les tags")
                .sheet(isPresented: $showTagsEditor) {
                    ScriptTagsEditor(
                        tagsViewModel: tagsViewModel,
                        script: script,
                        isPresented: $showTagsEditor,
                        isDarkMode: isDarkMode, // Ajout du paramètre isDarkMode
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
                    ScriptTagsDisplay(tags: script.tags, tagsViewModel: tagsViewModel)
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

// MARK: - Preview
#Preview("MultiselectScriptGridView - Mode clair") {
    let tagsViewModel = TagsViewModel()
    tagsViewModel.addTag(name: "Important", color: .red)
    tagsViewModel.addTag(name: "Automatisation", color: .blue)
    tagsViewModel.addTag(name: "Maintenance", color: .green)
    tagsViewModel.addTag(name: "Documentation", color: .orange)
    tagsViewModel.addTag(name: "Backup", color: .purple)
    
    return MultiselectScriptGridView(
        scripts: [
            ScriptFile(name: "script1.scpt", path: "/path/1", isFavorite: true, lastExecuted: Date(), isSelected: true, tags: ["Important"]),
            ScriptFile(name: "script2.applescript", path: "/path/2", isFavorite: false, lastExecuted: nil, isSelected: false),
            ScriptFile(name: "script3.scpt", path: "/path/3", isFavorite: false, lastExecuted: Date().addingTimeInterval(-3600), isSelected: false, tags: ["Automatisation"]),
            ScriptFile(name: "script4.scpt", path: "/path/4", isFavorite: true, lastExecuted: Date().addingTimeInterval(-86400), isSelected: false, tags: ["Important", "Automatisation"]),
            ScriptFile(name: "script5.scpt", path: "/path/5", isFavorite: false, lastExecuted: Date(), isSelected: false, tags: ["Important", "Automatisation", "Maintenance"]),
            ScriptFile(name: "script6.scpt", path: "/path/6", isFavorite: false, lastExecuted: Date(), isSelected: false, tags: ["Documentation", "Automatisation", "Backup", "Maintenance"]),
        ],
        isDarkMode: false,
        showFavoritesOnly: false,
        searchText: "",
        tagsViewModel: tagsViewModel,
        onToggleSelect: { _ in },
        onToggleFavorite: { _ in },
        onUpdateTags: { _ in },
        onSelectAll: {},
        onUnselectAll: {}
    )
    .frame(width: 600, height: 400)
    .background(Color.white)
}

#Preview("MultiselectScriptGridView - Mode sombre") {
    let tagsViewModel = TagsViewModel()
    tagsViewModel.addTag(name: "Important", color: .red)
    tagsViewModel.addTag(name: "Automatisation", color: .blue)
    tagsViewModel.addTag(name: "Maintenance", color: .green)
    tagsViewModel.addTag(name: "Documentation", color: .orange)
    
    return MultiselectScriptGridView(
        scripts: [
            ScriptFile(name: "script1.scpt", path: "/path/1", isFavorite: true, lastExecuted: Date(), isSelected: false, tags: ["Important"]),
            ScriptFile(name: "script2.applescript", path: "/path/2", isFavorite: false, lastExecuted: nil, isSelected: false),
            ScriptFile(name: "script3.scpt", path: "/path/3", isFavorite: false, lastExecuted: Date().addingTimeInterval(-3600), isSelected: false, tags: ["Automatisation"]),
            ScriptFile(name: "script4.scpt", path: "/path/4", isFavorite: true, lastExecuted: Date().addingTimeInterval(-86400), isSelected: true, tags: ["Important", "Automatisation"]),
            ScriptFile(name: "script5.scpt", path: "/path/5", isFavorite: false, lastExecuted: Date(), isSelected: false, tags: ["Important", "Automatisation", "Maintenance", "Documentation"]),
        ],
        isDarkMode: true,
        showFavoritesOnly: false,
        searchText: "",
        tagsViewModel: tagsViewModel,
        onToggleSelect: { _ in },
        onToggleFavorite: { _ in },
        onUpdateTags: { _ in },
        onSelectAll: {},
        onUnselectAll: {}
    )
    .frame(width: 600, height: 400)
    .background(Color.black)
}
