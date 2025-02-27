import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    @Binding var showFavoritesOnly: Bool
    @Binding var isDarkMode: Bool
    @Binding var showHelp: Bool
    @Binding var isGridView: Bool
    @FocusState private var isSearchFieldFocused: Bool
    
    var isFocused: Bool
    var onFocusChange: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.smallSpacing) {
            // Champ de recherche - maintenant avec taille fixe
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                    .padding(.leading, 8)
                    .frame(width: 30)
                
                ZStack(alignment: .leading) {
                    if searchText.isEmpty {
                        Text("Rechercher un script...")
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            .padding(.leading, 4)
                    }
                    
                    TextField("", text: $searchText)
                        .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                        .focused($isSearchFieldFocused)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(4)
                        .onExitCommand {
                            searchText = ""
                            isSearchFieldFocused = false
                        }
                        .onChange(of: isSearchFieldFocused) { newValue in
                            onFocusChange(newValue)
                        }
                }
                .frame(maxWidth: .infinity)
                .onChange(of: isFocused) { newValue in
                    if newValue != isSearchFieldFocused {
                        isSearchFieldFocused = newValue
                    }
                }
                
                // Conteneur de taille fixe pour le bouton ou l'espace
                ZStack {
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .frame(width: 30)
                .padding(.trailing, 8)
            }
            .frame(height: 36)
            .background(isDarkMode ? Color(white: 0.3) : Color(red: 0.95, green: 0.95, blue: 0.97))
            .cornerRadius(DesignSystem.smallCornerRadius)
            
            // Boîte de taille fixe pour les boutons
            HStack(spacing: DesignSystem.smallSpacing) {
                // Toggle favoris
                Toggle("", isOn: $showFavoritesOnly)
                    .toggleStyle(StarToggleStyle(isDarkMode: isDarkMode))
                    .help("Afficher uniquement les favoris")
                    .frame(width: 36)
                
                // Bouton pour basculer entre liste et grille
                Button(action: { isGridView.toggle() }) {
                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
                }
                .buttonStyle(IconButtonStyle(isDarkMode: isDarkMode))
                .help(isGridView ? "Passer en vue liste" : "Passer en vue grille")
                .frame(width: 36)
                
                // Bouton mode sombre
                Button(action: { isDarkMode.toggle() }) {
                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isDarkMode ? .yellow : .indigo)
                }
                .buttonStyle(IconButtonStyle(isDarkMode: isDarkMode))
                .help("Changer de thème")
                .frame(width: 36)
                
                // Bouton aide
                Button(action: { showHelp.toggle() }) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
                }
                .buttonStyle(IconButtonStyle(isDarkMode: isDarkMode))
                .help("Afficher l'aide")
                .frame(width: 36)
            }
        }
        .padding(DesignSystem.spacing)
    }
}

// MARK: - Preview
#Preview("Mode clair") {
    SearchBar(
        searchText: .constant(""),
        showFavoritesOnly: .constant(false),
        isDarkMode: .constant(false),
        showHelp: .constant(false),
        isGridView: .constant(false),
        isFocused: false,
        onFocusChange: { _ in }
    )
    .padding()
    .frame(width: 600)
}

#Preview("Mode sombre avec texte") {
    SearchBar(
        searchText: .constant("Test"),
        showFavoritesOnly: .constant(true),
        isDarkMode: .constant(true),
        showHelp: .constant(false),
        isGridView: .constant(true),
        isFocused: true,
        onFocusChange: { _ in }
    )
    .padding()
    .frame(width: 600)
}
