import SwiftUI
import AppKit

struct ScriptPropertiesEditor: View {
    @Binding var isPresented: Bool
    let script: ScriptFile
    let isDarkMode: Bool
    var onSave: (ScriptFile, String, NSImage?) -> Void
    
    // État pour le formulaire
    @State private var scriptName: String
    @State private var hasChanges: Bool = false
    @State private var newIcon: NSImage?
    @State private var initialScriptName: String
    @State private var showIconPicker = false
    
    // Initialiser avec les valeurs actuelles du script
    init(isPresented: Binding<Bool>, script: ScriptFile, isDarkMode: Bool, onSave: @escaping (ScriptFile, String, NSImage?) -> Void) {
        self._isPresented = isPresented
        self.script = script
        self.isDarkMode = isDarkMode
        self.onSave = onSave
        
        // Extraire le nom du script sans l'extension
        let fullName = script.name
        let nameWithoutExtension = (fullName as NSString).deletingPathExtension
        
        // Initialiser les états
        _scriptName = State(initialValue: nameWithoutExtension)
        _initialScriptName = State(initialValue: nameWithoutExtension)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacing) {
            // En-tête
            HStack {
                Text("Modifier les propriétés de")
                    .font(.headline)
                    .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                Text(script.name)
                    .font(.headline)
                    .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 8)
            
            // Affichage de l'icône actuelle avec option de modification
            HStack {
                Spacer()
                
                VStack(spacing: 8) {
                    // Zone d'icône interactive
                    ZStack {
                        if let newIcon = newIcon {
                            // Afficher la nouvelle icône si elle existe
                            Image(nsImage: newIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                        } else {
                            // Charger l'icône actuelle en utilisant NSWorkspace
                            IconDisplayView(filePath: script.path)
                                .frame(width: 80, height: 80)
                        }
                        
                        // Bouton de superposition pour changer l'icône
                        Button(action: {
                            showIconPicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 30, height: 30)
                                
                                Image(systemName: "photo")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .offset(x: 28, y: 28)
                    }
                    .frame(width: 90, height: 90)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DesignSystem.textSecondary(for: isDarkMode).opacity(0.3), lineWidth: 1)
                    )
                    
                    Text("Cliquez pour changer l'icône")
                        .font(.caption)
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                }
                
                Spacer()
            }
            .padding(.bottom, 16)
            
            // Champ pour le nom du script
            VStack(alignment: .leading, spacing: 4) {
                Text("Nom du script (sans extension)")
                    .font(.caption)
                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                
                // TextField personnalisé avec adaptation au thème
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isDarkMode ? Color(red: 0.3, green: 0.3, blue: 0.32) : Color.white)
                        .frame(height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isDarkMode ? Color(red: 0.4, green: 0.4, blue: 0.42) : Color.gray.opacity(0.5), lineWidth: 1)
                        )
                    
                    TextField("Nom du script", text: $scriptName)
                        .padding(.horizontal, 8)
                        .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                        .colorScheme(isDarkMode ? .dark : .light) // Forcer le thème du TextField
                        .onChange(of: scriptName) { newValue in
                            hasChanges = newValue != initialScriptName || newIcon != nil
                        }
                }
                .frame(height: 30)
            }
            
            // Informations sur le fichier
            VStack(alignment: .leading, spacing: 4) {
                Text("Informations du fichier")
                    .font(.caption)
                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                
                // Afficher le chemin complet
                Text("Chemin: \(script.path)")
                    .font(.caption)
                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(.top, 8)
            
            Spacer()
            
            // Boutons d'action
            HStack {
                Spacer()
                
                // Bouton "Annuler"
                Button(action: {
                    isPresented = false
                }) {
                    Text("Annuler")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .foregroundColor(isDarkMode ? .white : .primary)
                        .background(isDarkMode ? Color(red: 0.28, green: 0.28, blue: 0.3) : Color(red: 0.94, green: 0.94, blue: 0.96))
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut(.escape, modifiers: [])
                
                // Bouton "Enregistrer"
                Button(action: {
                    saveChanges()
                }) {
                    Text("Enregistrer")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .foregroundColor(.white)
                        .background(hasChanges
                                    ? DesignSystem.accentColor(for: isDarkMode)
                                    : Color.gray.opacity(0.5))
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut(.return, modifiers: [])
                .disabled(!hasChanges || scriptName.isEmpty)
            }
        }
        .padding()
        .frame(width: 350, height: 400)
        .background(DesignSystem.backgroundColor(for: isDarkMode))
        .onChange(of: showIconPicker) { show in
            if show {
                openIconPicker()
            }
        }
    }
    
    // Fonction pour ouvrir le sélecteur d'icônes
    private func openIconPicker() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.png, .jpeg, .tiff, .gif, .icns]
        openPanel.message = "Sélectionnez une image pour l'icône"
        openPanel.prompt = "Choisir"
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            if let image = NSImage(contentsOf: url) {
                self.newIcon = image
                self.hasChanges = true
            }
        }
        
        showIconPicker = false
    }
    
    // Fonction pour enregistrer les modifications
    private func saveChanges() {
        // Récupérer l'extension du script original
        let fileExtension = (script.name as NSString).pathExtension
        
        // Créer le nouveau nom avec l'extension d'origine
        let newScriptName = "\(scriptName).\(fileExtension)"
        
        // Appeler le callback avec les modifications
        onSave(script, newScriptName, newIcon)
    }
}

// Vue pour afficher l'icône actuelle d'un fichier
struct IconDisplayView: View {
    let filePath: String
    @State private var icon: NSImage?
    
    var body: some View {
        Group {
            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // Icône par défaut en attendant le chargement
                Image(systemName: "doc.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadIcon()
        }
    }
    
    private func loadIcon() {
        DispatchQueue.global(qos: .userInitiated).async {
            let workspace = NSWorkspace.shared
            let icon = workspace.icon(forFile: filePath)
            
            DispatchQueue.main.async {
                self.icon = icon
            }
        }
    }
}

// MARK: - Preview
#Preview("ScriptPropertiesEditor - Mode clair") {
    ScriptPropertiesEditor(
        isPresented: .constant(true),
        script: ScriptFile(
            name: "test_script.scpt",
            path: "/Applications/Utilities/Script Editor.app",
            isFavorite: true,
            lastExecuted: Date()
        ),
        isDarkMode: false,
        onSave: { _, _, _ in }
    )
}

#Preview("ScriptPropertiesEditor - Mode sombre") {
    ScriptPropertiesEditor(
        isPresented: .constant(true),
        script: ScriptFile(
            name: "test_script.scpt",
            path: "/Applications/Utilities/Script Editor.app",
            isFavorite: true,
            lastExecuted: Date()
        ),
        isDarkMode: true,
        onSave: { _, _, _ in }
    )
    .preferredColorScheme(.dark)
}
