import SwiftUI
import AppKit

struct ScriptTagsEditor: View {
    @ObservedObject var tagsViewModel: TagsViewModel
    let script: ScriptFile
    @Binding var isPresented: Bool
    var onSave: (ScriptFile) -> Void
    
    // Ajouter la propriété isDarkMode pour respecter le thème de l'application
    let isDarkMode: Bool
    
    @State private var selectedTags: Set<String>
    @State private var initialTags: Set<String> // Pour stocker les tags initiaux
    @State private var newTagName: String = ""
    @State private var newTagColor: Color = .blue
    @State private var showAddTag: Bool = false
    @State private var tagToEdit: Tag? = nil
    @State private var editTagName: String = ""
    @State private var editTagColor: Color = .blue
    @State private var tagsModified: Bool = false // Indique si un tag a été modifié
    
    // Variable pour forcer le rechargement de la vue
    @State private var refreshID = UUID()
    
    // Variables pour gérer l'état du ColorPicker
    @State private var isNewColorPickerVisible: Bool = false
    @State private var isEditColorPickerVisible: Bool = false
    
    // Variable calculée pour vérifier si des modifications ont été apportées
    private var hasChanges: Bool {
        // Changements si:
        // 1. La sélection de tags a changé
        // 2. Un tag a été modifié et la modification a été validée
        return selectedTags != initialTags || tagsModified
    }
    
    init(tagsViewModel: TagsViewModel, script: ScriptFile, isPresented: Binding<Bool>, isDarkMode: Bool, onSave: @escaping (ScriptFile) -> Void) {
        self.tagsViewModel = tagsViewModel
        self.script = script
        self._isPresented = isPresented
        self.isDarkMode = isDarkMode
        self.onSave = onSave
        self._selectedTags = State(initialValue: script.tags)
        self._initialTags = State(initialValue: script.tags) // Stocker la valeur initiale
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacing) {
            HStack {
                Text("Modifier les tags pour")
                    .font(.headline)
                    .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                Text(script.name)
                    .font(.headline)
                    .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: {
                    closeColorPickers()
                    // Restaurer l'état initial des tags
                    tagsViewModel.restoreOriginalTags()
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 8)
            
            if tagToEdit != nil {
                // Interface d'édition de tag
                VStack(alignment: .leading, spacing: 8) {
                    Text("Modifier le tag")
                        .font(.caption)
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                    
                    HStack {
                        // Bouton de couleur personnalisé avec l'ID de rafraîchissement
                        Button(action: {
                            if !isEditColorPickerVisible {
                                openColorPicker(for: $editTagColor, isVisible: $isEditColorPickerVisible)
                            }
                        }) {
                            Circle()
                                .fill(editTagColor)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(DesignSystem.textSecondary(for: isDarkMode).opacity(0.5), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .id(refreshID) // Forcer le rafraîchissement de la vue
                        
                        // TextField personnalisé pour le mode sombre
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isDarkMode ? Color(red: 0.3, green: 0.3, blue: 0.32) : Color.white)
                                .frame(height: 30)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isDarkMode ? Color(red: 0.4, green: 0.4, blue: 0.42) : Color.gray.opacity(0.5), lineWidth: 1)
                                )
                            
                            TextField("Nom du tag", text: $editTagName)
                                .padding(.horizontal, 8)
                                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                        }
                        .frame(height: 30)
                        
                        Button(action: {
                            saveTagEdit()
                        }) {
                            Text("Mettre à jour")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .foregroundColor(isDarkMode ? .white : DesignSystem.accentColor(for: isDarkMode))
                                .background(isDarkMode ? DesignSystem.accentColor(for: isDarkMode).opacity(0.8) : Color.clear)
                                .cornerRadius(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(editTagName.isEmpty)
                        
                        Button(action: {
                            cancelTagEdit()
                        }) {
                            Text("Annuler")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .foregroundColor(isDarkMode ? .white : .red)
                                .background(isDarkMode ? Color.red.opacity(0.8) : Color.clear)
                                .cornerRadius(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(8)
                .background(isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.bottom, 8)
                .id(refreshID) // Forcer le rafraîchissement de la vue
            } else if showAddTag {
                // Interface d'ajout de tag
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nouveau tag")
                        .font(.caption)
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                    
                    HStack {
                        // Bouton de couleur personnalisé
                        Button(action: {
                            if !isNewColorPickerVisible {
                                openColorPicker(for: $newTagColor, isVisible: $isNewColorPickerVisible)
                            }
                        }) {
                            Circle()
                                .fill(newTagColor)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(DesignSystem.textSecondary(for: isDarkMode).opacity(0.5), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .id(refreshID) // Forcer le rafraîchissement de la vue
                        
                        // TextField personnalisé pour le mode sombre
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isDarkMode ? Color(red: 0.3, green: 0.3, blue: 0.32) : Color.white)
                                .frame(height: 30)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isDarkMode ? Color(red: 0.4, green: 0.4, blue: 0.42) : Color.gray.opacity(0.5), lineWidth: 1)
                                )
                            
                            TextField("Nom du tag", text: $newTagName)
                                .padding(.horizontal, 8)
                                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                        }
                        .frame(height: 30)
                        
                        Button(action: {
                            if !newTagName.isEmpty {
                                tagsViewModel.addTag(name: newTagName, color: newTagColor)
                                selectedTags.insert(newTagName)
                                newTagName = ""
                                closeNewTagColorPicker()
                                showAddTag = false
                                tagsModified = true // Marquer comme modifié seulement après ajout
                            }
                        }) {
                            Text("Ajouter")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .foregroundColor(isDarkMode ? .white : DesignSystem.accentColor(for: isDarkMode))
                                .background(isDarkMode ? DesignSystem.accentColor(for: isDarkMode).opacity(0.8) : Color.clear)
                                .cornerRadius(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(newTagName.isEmpty)
                        
                        Button(action: {
                            closeNewTagColorPicker()
                            showAddTag = false
                        }) {
                            Text("Annuler")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .foregroundColor(isDarkMode ? .white : .red)
                                .background(isDarkMode ? Color.red.opacity(0.8) : Color.clear)
                                .cornerRadius(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(8)
                .background(isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.bottom, 8)
                .id(refreshID) // Forcer le rafraîchissement de la vue
            } else {
                // Bouton pour ajouter un nouveau tag
                Button(action: {
                    showAddTag = true
                }) {
                    Label("Ajouter un nouveau tag", systemImage: "plus.circle")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .foregroundColor(isDarkMode ? .white : DesignSystem.accentColor(for: isDarkMode))
                        .background(isDarkMode ? DesignSystem.accentColor(for: isDarkMode).opacity(0.7) : Color.clear)
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 8)
            }
            
            // Liste des tags disponibles
            ScrollView {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(tagsViewModel.tags) { tag in
                        HStack {
                            Button(action: {
                                if selectedTags.contains(tag.name) {
                                    selectedTags.remove(tag.name)
                                } else {
                                    selectedTags.insert(tag.name)
                                }
                            }) {
                                HStack {
                                    Image(systemName: selectedTags.contains(tag.name) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(selectedTags.contains(tag.name) ? tag.color : DesignSystem.textSecondary(for: isDarkMode))
                                    
                                    Circle()
                                        .fill(tag.color)
                                        .frame(width: 12, height: 12)
                                    
                                    Text(tag.name)
                                        .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                            
                            // Bouton pour éditer le tag
                            Button(action: {
                                startTagEdit(tag)
                            }) {
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .opacity(0.6)
                            
                            // Bouton pour supprimer le tag
                            Button(action: {
                                deleteTag(tag)
                            }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .opacity(0.6)
                            .padding(.leading, 4)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.clear)
                        .id("\(tag.id)-\(refreshID)") // Force le rafraîchissement des tags
                    }
                }
                .background(isDarkMode ? Color(red: 0.18, green: 0.18, blue: 0.2) : Color.gray.opacity(0.05))
                .cornerRadius(8)
                .id(refreshID) // Forcer le rafraîchissement de la vue
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Annuler") {
                    closeColorPickers()
                    // Restaurer l'état initial des tags
                    tagsViewModel.restoreOriginalTags()
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])
                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                .buttonStyle(BorderedButtonStyle())
                .background(isDarkMode ? Color(red: 0.25, green: 0.25, blue: 0.27) : Color.white)
                
                Button("Enregistrer") {
                    closeColorPickers()
                    
                    // Enregistrer les modifications des tags
                    tagsViewModel.saveChanges()
                    
                    // Sauvegarder les tags du script
                    var updatedScript = script
                    updatedScript.tags = selectedTags
                    onSave(updatedScript)
                    
                    isPresented = false
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.accentColor(for: isDarkMode))
                .disabled(!hasChanges) // Désactiver si aucun changement
            }
        }
        .padding()
        .frame(width: 350, height: 400)
        .background(DesignSystem.backgroundColor(for: isDarkMode))
        .id(refreshID) // Forcer le rafraîchissement de toute la vue
        .onAppear {
            // Sauvegarder l'état initial des tags
            tagsViewModel.saveCurrentTagsState()
        }
    }
    
    // Ferme tous les ColorPickers ouverts
    private func closeColorPickers() {
        closeEditTagColorPicker()
        closeNewTagColorPicker()
    }
    
    // Ferme le ColorPicker pour l'édition de tag
    private func closeEditTagColorPicker() {
        if isEditColorPickerVisible {
            NSColorPanel.shared.close()
            isEditColorPickerVisible = false
        }
    }
    
    // Ferme le ColorPicker pour le nouveau tag
    private func closeNewTagColorPicker() {
        if isNewColorPickerVisible {
            NSColorPanel.shared.close()
            isNewColorPickerVisible = false
        }
    }
    
    // Ouvre le sélecteur de couleur natif
    private func openColorPicker(for binding: Binding<Color>, isVisible: Binding<Bool>) {
        // Fermer les autres ColorPickers d'abord
        closeColorPickers()
        
        isVisible.wrappedValue = true
        
        let nsColor = NSColor(binding.wrappedValue)
        let colorPanel = NSColorPanel.shared
        colorPanel.color = nsColor
        colorPanel.mode = .wheel
        colorPanel.isContinuous = true
        colorPanel.showsAlpha = false
        colorPanel.orderFront(nil)
        
        // Observer les changements de couleur
        NotificationCenter.default.addObserver(forName: NSColorPanel.colorDidChangeNotification, object: nil, queue: .main) { _ in
            let newColor = colorPanel.color
            binding.wrappedValue = Color(newColor)
            
            // Forcer le rechargement de la vue
            refreshID = UUID()
        }
        
        // Fermer le ColorPicker quand la fenêtre est fermée
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: colorPanel, queue: .main) { _ in
            isVisible.wrappedValue = false
            NotificationCenter.default.removeObserver(self, name: NSColorPanel.colorDidChangeNotification, object: nil)
        }
    }
    
    // Fonction pour commencer l'édition d'un tag
    private func startTagEdit(_ tag: Tag) {
        tagToEdit = tag
        editTagName = tag.name
        editTagColor = tag.color
    }
    
    // Fonction pour annuler l'édition d'un tag
    private func cancelTagEdit() {
        closeEditTagColorPicker()
        tagToEdit = nil
        editTagName = ""
        refreshID = UUID() // Forcer le rafraîchissement
    }
    
    // Fonction pour sauvegarder l'édition d'un tag
    private func saveTagEdit() {
        guard let tag = tagToEdit, !editTagName.isEmpty else { return }
        
        let oldName = tag.name
        let oldColor = tag.color
        
        // Vérifier si le tag existe déjà (sauf s'il s'agit du même)
        if oldName.lowercased() != editTagName.lowercased() &&
           tagsViewModel.tags.contains(where: { $0.name.lowercased() == editTagName.lowercased() }) {
            // Gérer le cas où le nom existe déjà
            let alert = NSAlert()
            alert.messageText = "Nom de tag déjà utilisé"
            alert.informativeText = "Un tag avec ce nom existe déjà. Veuillez choisir un autre nom."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        
        // Déterminer si le tag a réellement été modifié
        let nameChanged = oldName != editTagName
        let colorChanged = oldColor != editTagColor
        
        // Mettre à jour le tag en mémoire uniquement
        tagsViewModel.updateTagInMemory(tag, newName: editTagName, newColor: editTagColor)
        
        // Mettre à jour les sélections si nécessaire
        if selectedTags.contains(oldName) {
            selectedTags.remove(oldName)
            selectedTags.insert(editTagName)
        }
        
        // Activer le bouton Enregistrer seulement si le tag a été modifié
        if nameChanged || colorChanged {
            tagsModified = true
        }
        
        // Fermer le ColorPanel si ouvert
        closeEditTagColorPicker()
        
        // Réinitialiser l'état d'édition
        tagToEdit = nil
        editTagName = ""
        
        // Forcer le rechargement de la vue
        refreshID = UUID()
    }
    
    // Fonction pour supprimer un tag
    private func deleteTag(_ tag: Tag) {
        // Demander confirmation avant de supprimer
        let alert = NSAlert()
        alert.messageText = "Supprimer le tag"
        alert.informativeText = "Êtes-vous sûr de vouloir supprimer le tag '\(tag.name)' ? Cette action est irréversible."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Supprimer")
        alert.addButton(withTitle: "Annuler")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Retirer le tag de la sélection actuelle
            if selectedTags.contains(tag.name) {
                selectedTags.remove(tag.name)
            }
            
            // Supprimer le tag du ViewModel
            tagsViewModel.removeTag(tag)
            
            // Marquer comme modifié seulement après confirmation de suppression
            tagsModified = true
            
            // Forcer le rechargement de la vue
            refreshID = UUID()
        }
    }
}

// MARK: - Preview
#Preview("ScriptTagsEditor - Mode clair") {
    let tagsViewModel = TagsViewModel()
    // Ajouter quelques tags de test
    tagsViewModel.addTag(name: "Important", color: .red)
    tagsViewModel.addTag(name: "Automatisation", color: .blue)
    tagsViewModel.addTag(name: "Maintenance", color: .green)
    
    let script = ScriptFile(
        name: "exemple_script.scpt",
        path: "/path/to/script",
        isFavorite: true,
        lastExecuted: Date(),
        tags: ["Important"]
    )
    
    return ScriptTagsEditor(
        tagsViewModel: tagsViewModel,
        script: script,
        isPresented: .constant(true),
        isDarkMode: false,
        onSave: { _ in }
    )
}

#Preview("ScriptTagsEditor - Mode sombre") {
    let tagsViewModel = TagsViewModel()
    // Ajouter quelques tags de test
    tagsViewModel.addTag(name: "Important", color: .red)
    tagsViewModel.addTag(name: "Automatisation", color: .blue)
    tagsViewModel.addTag(name: "Maintenance", color: .green)
    
    let script = ScriptFile(
        name: "exemple_script.scpt",
        path: "/path/to/script",
        isFavorite: true,
        lastExecuted: Date(),
        tags: ["Important", "Maintenance"]
    )
    
    return ScriptTagsEditor(
        tagsViewModel: tagsViewModel,
        script: script,
        isPresented: .constant(true),
        isDarkMode: true,
        onSave: { _ in }
    )
}
