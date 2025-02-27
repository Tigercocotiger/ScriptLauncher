import SwiftUI

// Vue pour une ligne de script
struct ScriptRowView: View {
    let script: ScriptFile
    let isSelected: Bool
    let isDarkMode: Bool
    let onTap: () -> Void
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
            // Icône de type
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
            
            // Bouton favori (visible au survol)
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
        .onTapGesture(perform: onTap)
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
#Preview("Ligne de script - Mode clair") {
    VStack(spacing: 8) {
        // Script normal
        ScriptRowView(
            script: ScriptFile(name: "test_script.scpt", path: "/path/to/script", isFavorite: false, lastExecuted: nil),
            isSelected: false,
            isDarkMode: false,
            onTap: {},
            onFavorite: {}
        )
        .padding(.horizontal)
        .background(Color.white)
        
        // Script favori
        ScriptRowView(
            script: ScriptFile(name: "favorite_script.scpt", path: "/path/to/favorite", isFavorite: true, lastExecuted: Date()),
            isSelected: true,
            isDarkMode: false,
            onTap: {},
            onFavorite: {}
        )
        .padding(.horizontal)
        .background(Color.blue.opacity(0.1))
    }
    .padding()
    .frame(width: 400, height: 120)
}

#Preview("Ligne de script - Mode sombre") {
    VStack(spacing: 8) {
        ScriptRowView(
            script: ScriptFile(name: "dark_mode_script.applescript", path: "/path/to/dark", isFavorite: false, lastExecuted: Date().addingTimeInterval(-3600)),
            isSelected: false,
            isDarkMode: true,
            onTap: {},
            onFavorite: {}
        )
        .padding(.horizontal)
        .background(Color.black)
    }
    .padding()
    .frame(width: 400, height: 60)
}
