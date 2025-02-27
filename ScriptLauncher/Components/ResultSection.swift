import SwiftUI

struct ResultSection: View {
    let scriptOutput: String
    let selectedScript: ScriptFile?
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.spacing) {
            // En-tête
            Text("Résultat")
                .font(.headline)
                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, DesignSystem.spacing)
            
            // Zone de résultat
            ZStack {
                if scriptOutput.isEmpty {
                    VStack(spacing: DesignSystem.smallSpacing) {
                        Image(systemName: "terminal")
                            .font(.system(size: 32))
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode).opacity(0.5))
                        
                        Text("Exécutez un script pour voir le résultat")
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            .multilineTextAlignment(.center)
                    }
                }
                
                if !scriptOutput.isEmpty {
                    ScrollView {
                        Text(scriptOutput)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(DesignSystem.spacing)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color.white)
            .cornerRadius(DesignSystem.smallCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, DesignSystem.spacing)
            
            // Barre d'état du script
            if let selectedScript = selectedScript {
                HStack(spacing: DesignSystem.smallSpacing) {
                    if selectedScript.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(DesignSystem.favoriteColor())
                            .font(.system(size: 12))
                    }
                    
                    Text(selectedScript.name)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                    
                    Spacer()
                    
                    if let lastExec = selectedScript.lastExecuted {
                        Text("Exécuté: \(formattedDate(lastExec))")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                    }
                }
                .padding(DesignSystem.smallSpacing)
                .background(isDarkMode ? Color.black.opacity(0.2) : Color.gray.opacity(0.1))
                .cornerRadius(DesignSystem.smallCornerRadius / 2)
                .padding(.horizontal, DesignSystem.spacing)
            }
            
            Spacer()
        }
        .background(DesignSystem.cardBackground(for: isDarkMode))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
        .shadow(
            color: Color.black.opacity(DesignSystem.shadowOpacity(for: isDarkMode)),
            radius: DesignSystem.shadowRadius,
            x: 0,
            y: DesignSystem.shadowY
        )
        .padding(.trailing, DesignSystem.spacing) // Ajout de la marge à droite
    }
    
    // Format de date pour l'affichage détaillé
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview("Mode clair - Vide") {
    ResultSection(
        scriptOutput: "",
        selectedScript: nil,
        isDarkMode: false
    )
    .frame(height: 200)
    .padding()
}

#Preview("Mode sombre - Avec contenu") {
    ResultSection(
        scriptOutput: "Hello, world!\nThis is a sample output.\n> Command executed successfully.",
        selectedScript: ScriptFile(
            name: "test_script.scpt",
            path: "/path/to/script",
            isFavorite: true,
            lastExecuted: Date()
        ),
        isDarkMode: true
    )
    .frame(height: 200)
    .padding()
}
