import SwiftUI

struct ScriptsList: View {
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
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredScripts) { script in
                    ScriptRowView(
                        script: script,
                        isSelected: selectedScript?.id == script.id,
                        isDarkMode: isDarkMode,
                        onTap: { onScriptSelect(script) },
                        onFavorite: { onToggleFavorite(script) }
                    )
                    .padding(.horizontal, DesignSystem.spacing)
                    .padding(.vertical, 4)
                    .background(
                        selectedScript?.id == script.id
                            ? (isDarkMode
                                ? DesignSystem.accentColor(for: isDarkMode).opacity(0.3)
                                : DesignSystem.accentColor(for: isDarkMode).opacity(0.1))
                            : Color.clear
                    )
                    .contentShape(Rectangle())
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

// MARK: - Preview
#Preview("Liste de scripts - Mode clair") {
    ScriptsList(
        scripts: [
            ScriptFile(name: "script1.scpt", path: "/path/1", isFavorite: true, lastExecuted: Date()),
            ScriptFile(name: "script2.applescript", path: "/path/2", isFavorite: false, lastExecuted: nil),
            ScriptFile(name: "script3.scpt", path: "/path/3", isFavorite: false, lastExecuted: Date().addingTimeInterval(-3600))
        ],
        selectedScript: nil,
        isDarkMode: false,
        showFavoritesOnly: false,
        searchText: "",
        onScriptSelect: { _ in },
        onToggleFavorite: { _ in }
    )
    .frame(width: 400, height: 300)
    .background(Color.white)
}
