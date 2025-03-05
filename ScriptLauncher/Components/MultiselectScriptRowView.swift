//
//  MultiselectScriptRowView.swift
//  ScriptLauncher
//
//  Created on 05/03/2025.
//

import SwiftUI

// Vue pour une ligne de script avec sélection multiple
struct MultiselectScriptRowView: View {
    let script: ScriptFile
    let isDarkMode: Bool
    let onToggleSelect: () -> Void
    let onFavorite: () -> Void
    
    // Extraire le nom du script sans l'extension
    private var scriptNameWithoutExtension: String {
        let name = script.name
        if let dotIndex = name.lastIndex(of: ".") {
            return String(name[..<dotIndex])
        }
        return name
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
            
            // Icône de type avec état favori
            Image(systemName: script.isFavorite ? "star.fill" : "doc.text")
                .font(.system(size: 16))
                .foregroundColor(script.isFavorite
                                 ? DesignSystem.favoriteColor()
                                 : DesignSystem.textSecondary(for: isDarkMode))
                .frame(width: 20)
            
            // Nom du script sans extension
            Text(scriptNameWithoutExtension)
                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                .lineLimit(1)
            
            Spacer()
            
            // Date d'exécution
            if let lastExec = script.lastExecuted {
                Text(timeAgo(from: lastExec))
                    .font(.caption)
                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
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
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggleSelect)
        .background(
            script.isSelected
                ? (isDarkMode
                    ? DesignSystem.accentColor(for: isDarkMode).opacity(0.3)
                    : DesignSystem.accentColor(for: isDarkMode).opacity(0.1))
                : Color.clear
        )
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
}

// MARK: - Preview
#Preview("MultiselectScriptRowView - Mode clair") {
    VStack(spacing: 8) {
        // Script normal
        MultiselectScriptRowView(
            script: ScriptFile(name: "test_script.scpt", path: "/path/to/script", isFavorite: false, lastExecuted: nil, isSelected: false),
            isDarkMode: false,
            onToggleSelect: {},
            onFavorite: {}
        )
        .padding(.horizontal)
        .background(Color.white)
        
        // Script sélectionné
        MultiselectScriptRowView(
            script: ScriptFile(name: "selected_script.scpt", path: "/path/to/selected", isFavorite: false, lastExecuted: Date(), isSelected: true),
            isDarkMode: false,
            onToggleSelect: {},
            onFavorite: {}
        )
        .padding(.horizontal)
        
        // Script favori et sélectionné
        MultiselectScriptRowView(
            script: ScriptFile(name: "favorite_script.scpt", path: "/path/to/favorite", isFavorite: true, lastExecuted: Date(), isSelected: true),
            isDarkMode: false,
            onToggleSelect: {},
            onFavorite: {}
        )
        .padding(.horizontal)
    }
    .padding()
    .frame(width: 400, height: 150)
}

#Preview("MultiselectScriptRowView - Mode sombre") {
    VStack(spacing: 8) {
        MultiselectScriptRowView(
            script: ScriptFile(name: "dark_mode_script.applescript", path: "/path/to/dark", isFavorite: false, lastExecuted: Date().addingTimeInterval(-3600), isSelected: true),
            isDarkMode: true,
            onToggleSelect: {},
            onFavorite: {}
        )
        .padding(.horizontal)
        .background(Color.black)
    }
    .padding()
    .frame(width: 400, height: 60)
}