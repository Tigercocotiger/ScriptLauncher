import SwiftUI

struct ScriptPropertiesButton: View {
    let script: ScriptFile
    let isDarkMode: Bool
    @Binding var showPropertiesEditor: Bool
    let onSuccess: (ScriptFile) -> Void
    
    // État pour la fenêtre d'édition
    @State private var isShowingEditor = false
    
    var body: some View {
        Button(action: {
            isShowingEditor = true
        }) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 12))
                .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(0.6)
        .help("Modifier le nom et l'icône")
        .sheet(isPresented: $isShowingEditor) {
            ScriptPropertiesEditor(
                isPresented: $isShowingEditor,
                script: script,
                isDarkMode: isDarkMode,
                onSave: { script, newName, newIcon in
                    // Appliquer les modifications via ScriptIconManager
                    ScriptIconManager.applyChanges(for: script, newName: newName, newIcon: newIcon) { result in
                        // Fermer la fenêtre d'édition
                        isShowingEditor = false
                        
                        // Mettre à jour le binding parent
                        showPropertiesEditor = false
                        
                        // Traiter le résultat
                        switch result {
                        case .success(let updatedScript):
                            // Callback avec le script mis à jour
                            onSuccess(updatedScript)
                        case .failure(let error):
                            // Afficher l'erreur
                            let alert = NSAlert()
                            alert.messageText = "Erreur lors de la modification"
                            alert.informativeText = error.localizedDescription
                            alert.alertStyle = .critical
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    }
                }
            )
        }
    }
}

// MARK: - Preview
#Preview("ScriptPropertiesButton") {
    let script = ScriptFile(
        name: "test_script.scpt",
        path: "/path/to/script",
        isFavorite: false,
        lastExecuted: nil
    )
    
    return ScriptPropertiesButton(
        script: script,
        isDarkMode: false,
        showPropertiesEditor: .constant(false),
        onSuccess: { _ in }
    )
    .padding()
    .background(Color.white)
}
