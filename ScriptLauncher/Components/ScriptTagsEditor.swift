import SwiftUI
import AppKit

struct ScriptTagsEditor: View {
    @ObservedObject var tagsViewModel: TagsViewModel
    let script: ScriptFile
    @Binding var isPresented: Bool
    var onSave: (ScriptFile) -> Void
    
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
    
    init(tagsViewModel: TagsViewModel, script: ScriptFile, isPresented: Binding<Bool>, onSave: @escaping (ScriptFile) -> Void) {
        self.tagsViewModel = tagsViewModel
        self.script = script
        self._isPresented = isPresented
        self.onSave = onSave
        self._selectedTags = State(initialValue: script.tags)
        self._initialTags = State(initialValue: script.tags) // Stocker la valeur initiale
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacing) {
            HStack {
                Text("Modifier les tags pour")
                    .font(.headline)
                Text(script.name)
                    .font(.headline)
                    .foregroundColor(.accentColor)
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
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 8)
            
            if tagToEdit != nil {
                // Interface d'édition de tag
                VStack(alignment: .leading, spacing: 8) {
                    Text("Modifier le tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
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
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .id(refreshID) // Forcer le rafraîchissement de la vue
                        
                        TextField("Nom du tag", text: $editTagName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            saveTagEdit()
                        }) {
                            Text("Mettre à jour")
                                .font(.caption)
                        }
                        .disabled(editTagName.isEmpty)
                        
                        Button(action: {
                            cancelTagEdit()
                        }) {
                            Text("Annuler")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.bottom, 8)
                .id(refreshID) // Forcer le rafraîchissement de la vue
            } else if showAddTag {
                // Interface d'ajout de tag
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nouveau tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
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
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .id(refreshID) // Forcer le rafraîchissement de la vue
                        
                        TextField("Nom du tag", text: $newTagName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
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
                        }
                        .disabled(newTagName.isEmpty)
                        
                        Button(action: {
                            closeNewTagColorPicker()
                            showAddTag = false
                        }) {
                            Text("Annuler")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
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
                }
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
                                        .foregroundColor(selectedTags.contains(tag.name) ? tag.color : .gray)
                                    
                                    Circle()
                                        .fill(tag.color)
                                        .frame(width: 12, height: 12)
                                    
                                    Text(tag.name)
                                        .foregroundColor(.primary)
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
                                    .foregroundColor(.gray)
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
                .background(Color.gray.opacity(0.05))
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
                .disabled(!hasChanges) // Désactiver si aucun changement
            }
        }
        .padding()
        .frame(width: 350, height: 400)
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

// Composant pour afficher les tags d'un script dans la vue liste/grille
struct ScriptTagsDisplay: View {
    let tags: Set<String>
    let tagsViewModel: TagsViewModel
    
    // Identifiant de la vue pour forcer la mise à jour
    @State private var viewID = UUID()
    
    var body: some View {
        if !tags.isEmpty {
            HStack(spacing: 2) {
                ForEach(Array(tags).prefix(3), id: \.self) { tagName in
                    if let tag = tagsViewModel.getTag(name: tagName) {
                        Circle()
                            .fill(tag.color)
                            .frame(width: 6, height: 6)
                    }
                }
                
                if tags.count > 3 {
                    Text("+\(tags.count - 3)")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                }
            }
            .id(viewID) // Force le rafraîchissement
            .onAppear {
                // S'abonner aux notifications de changement de tags
                NotificationCenter.default.addObserver(forName: NSNotification.Name("GlobalTagsChanged"), object: nil, queue: .main) { _ in
                    // Forcer le rafraîchissement
                    viewID = UUID()
                }
            }
            .onDisappear {
                // Se désabonner des notifications
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name("GlobalTagsChanged"), object: nil)
            }
        } else {
            EmptyView()
        }
    }
}

// MARK: - Preview
#Preview("ScriptTagsEditor") {
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
        onSave: { _ in }
    )
    .padding()
}
