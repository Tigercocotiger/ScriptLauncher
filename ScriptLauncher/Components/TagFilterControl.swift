//
//  TagFilterControl.swift
//  ScriptLauncher
//
//  Created by MacBook14M3P-005 on 16/03/2025.
//


import SwiftUI

struct TagFilterControl: View {
    @ObservedObject var tagsViewModel: TagsViewModel
    @Binding var selectedTag: String?
    let isDarkMode: Bool
    let scripts: [ScriptFile]
    
    // Fonction pour calculer le nombre de scripts par tag
    private func scriptCountForTag(_ tagName: String) -> Int {
        return scripts.filter { $0.tags.contains(tagName) }.count
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Option "Tous" (aucun tag sélectionné)
                Button(action: {
                    selectedTag = nil
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "tag")
                            .font(.system(size: 10))
                        
                        Text("Tous")
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(selectedTag == nil 
                        ? DesignSystem.accentColor(for: isDarkMode).opacity(0.2)
                        : (isDarkMode ? Color(white: 0.25) : Color(white: 0.95)))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedTag == nil 
                                ? DesignSystem.accentColor(for: isDarkMode)
                                : Color.gray.opacity(0.3),
                                lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Liste des tags disponibles
                ForEach(tagsViewModel.tags.sorted(by: { $0.name < $1.name })) { tag in
                    let scriptCount = scriptCountForTag(tag.name)
                    
                    // Ne pas afficher les tags sans scripts associés
                    if scriptCount > 0 {
                        Button(action: {
                            if selectedTag == tag.name {
                                selectedTag = nil
                            } else {
                                selectedTag = tag.name
                            }
                        }) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(tag.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(tag.name)
                                    .font(.system(size: 12))
                                
                                // Afficher le compteur de scripts
                                TagStatistics(
                                    tagName: tag.name,
                                    count: scriptCount,
                                    color: tag.color,
                                    isDarkMode: isDarkMode
                                )
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedTag == tag.name 
                                ? tag.color.opacity(0.2)
                                : (isDarkMode ? Color(white: 0.25) : Color(white: 0.95)))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedTag == tag.name 
                                        ? tag.color
                                        : Color.gray.opacity(0.3),
                                        lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(isDarkMode ? Color.black.opacity(0.3) : Color.gray.opacity(0.05))
        .cornerRadius(DesignSystem.smallCornerRadius)
    }
}

// Statistiques pour le nombre de scripts par tag
struct TagStatistics: View {
    let tagName: String
    let count: Int
    let color: Color
    let isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            
            Text("\(count)")
                .font(.system(size: 10))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.6))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Preview
#Preview("TagFilterControl - Light Mode") {
    let tagsViewModel = TagsViewModel()
    // Ajouter des tags de test
    tagsViewModel.addTag(name: "Important", color: .red)
    tagsViewModel.addTag(name: "Automatisation", color: .blue)
    tagsViewModel.addTag(name: "Maintenance", color: .green)
    
    // Créer des scripts de test
    let scripts = [
        ScriptFile(name: "script1.scpt", path: "/path/1", isFavorite: true, lastExecuted: Date(), tags: ["Important"]),
        ScriptFile(name: "script2.scpt", path: "/path/2", isFavorite: false, lastExecuted: nil, tags: ["Automatisation"]),
        ScriptFile(name: "script3.scpt", path: "/path/3", isFavorite: false, lastExecuted: Date(), tags: ["Important", "Automatisation"]),
        ScriptFile(name: "script4.scpt", path: "/path/4", isFavorite: false, lastExecuted: Date(), tags: ["Maintenance"])
    ]
    
    return TagFilterControl(
        tagsViewModel: tagsViewModel,
        selectedTag: .constant("Important"),
        isDarkMode: false,
        scripts: scripts
    )
    .frame(width: 400)
    .padding()
}

#Preview("TagFilterControl - Dark Mode") {
    let tagsViewModel = TagsViewModel()
    // Ajouter des tags de test
    tagsViewModel.addTag(name: "Important", color: .red)
    tagsViewModel.addTag(name: "Automatisation", color: .blue)
    tagsViewModel.addTag(name: "Maintenance", color: .green)
    
    // Créer des scripts de test
    let scripts = [
        ScriptFile(name: "script1.scpt", path: "/path/1", isFavorite: true, lastExecuted: Date(), tags: ["Important"]),
        ScriptFile(name: "script2.scpt", path: "/path/2", isFavorite: false, lastExecuted: nil, tags: ["Automatisation"]),
        ScriptFile(name: "script3.scpt", path: "/path/3", isFavorite: false, lastExecuted: Date(), tags: ["Important", "Automatisation"]),
        ScriptFile(name: "script4.scpt", path: "/path/4", isFavorite: false, lastExecuted: Date(), tags: ["Maintenance"])
    ]
    
    return TagFilterControl(
        tagsViewModel: tagsViewModel,
        selectedTag: .constant(nil),
        isDarkMode: true,
        scripts: scripts
    )
    .frame(width: 400)
    .padding()
    .background(Color.black)
}
