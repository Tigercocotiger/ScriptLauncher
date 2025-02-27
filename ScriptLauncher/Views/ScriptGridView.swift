import SwiftUI
import Cocoa

struct ScriptGridView: View {
    let scripts: [ScriptFile]
    let selectedScript: ScriptFile?
    let isDarkMode: Bool
    let showFavoritesOnly: Bool
    let searchText: String
    let onScriptSelect: (ScriptFile) -> Void
    let onToggleFavorite: (ScriptFile) -> Void
    
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
                        ScriptGridItemView(
                            script: script,
                            isSelected: selectedScript?.id == script.id,
                            isDarkMode: isDarkMode,
                            onTap: { onScriptSelect(script) },
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

// Élément de grille pour un script
struct ScriptGridItemView: View {
    let script: ScriptFile
    let isSelected: Bool
    let isDarkMode: Bool
    let onTap: () -> Void
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
            // Partie supérieure avec icône
            HStack {
                // Affichage de l'icône personnalisée ou par défaut
                if hasLoadedIcon, let icon = scriptIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: script.name.hasSuffix(".scpt") ? "applescript" : "doc.text.fill")
                        .font(.system(size: 20))
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
                .fill(isSelected
                      ? DesignSystem.accentColor(for: isDarkMode).opacity(isDarkMode ? 0.3 : 0.1)
                      : DesignSystem.cardBackground(for: isDarkMode))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                        .stroke(
                            isSelected
                                ? DesignSystem.accentColor(for: isDarkMode).opacity(0.5)
                                : Color.gray.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
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
#Preview("Vue Grille - Mode clair") {
    ScriptGridView(
        scripts: [
            ScriptFile(name: "script1.scpt", path: "/path/1", isFavorite: true, lastExecuted: Date()),
            ScriptFile(name: "script2.applescript", path: "/path/2", isFavorite: false, lastExecuted: nil),
            ScriptFile(name: "script3.scpt", path: "/path/3", isFavorite: false, lastExecuted: Date().addingTimeInterval(-3600)),
            ScriptFile(name: "script_with_very_long_name.scpt", path: "/path/4", isFavorite: true, lastExecuted: Date().addingTimeInterval(-86400)),
            ScriptFile(name: "script5.scpt", path: "/path/5", isFavorite: false, lastExecuted: Date()),
            ScriptFile(name: "script6.applescript", path: "/path/6", isFavorite: true, lastExecuted: Date()),
            ScriptFile(name: "script7.scpt", path: "/path/7", isFavorite: false, lastExecuted: nil),
            ScriptFile(name: "script8.scpt", path: "/path/8", isFavorite: true, lastExecuted: Date())
        ],
        selectedScript: nil,
        isDarkMode: false,
        showFavoritesOnly: false,
        searchText: "",
        onScriptSelect: { _ in },
        onToggleFavorite: { _ in }
    )
    .frame(width: 600, height: 400)
    .background(Color.white)
}
