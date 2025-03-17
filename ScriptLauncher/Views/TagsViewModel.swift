import SwiftUI
import Combine

class TagsViewModel: ObservableObject {
    // Les tags visibles dans l'interface
    @Published var tags: [Tag] = []
    // Copie de sauvegarde des tags pour l'édition temporaire
    private var originalTags: [Tag] = []
    @Published var scriptTags: [String: Set<String>] = [:] // path -> tags
    
    private let configManager = ConfigManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadTags()
    }
    
    func loadTags() {
        // Chargement des tags depuis ConfigManager
        tags = configManager.tags.map { tagConfig in
            Tag(
                id: tagConfig.id,
                name: tagConfig.name,
                color: Color.fromHex(tagConfig.colorHex) ?? .blue
            )
        }
        
        // Faire une copie des tags originaux
        originalTags = tags
        
        // Chargement des associations script-tags
        scriptTags = configManager.scriptTags
        
        // Nettoyer les chemins absolus pour les transformer en chemins simples ou relatifs
        cleanupScriptPaths()
    }
    
    // Nouvelle méthode pour nettoyer les chemins absolus
    private func cleanupScriptPaths() {
        var updatedScriptTags: [String: Set<String>] = [:]
        
        // Pour chaque chemin absolu, extraire juste le nom du fichier
        for (path, tagSet) in scriptTags {
            // Obtenez juste le nom du fichier à partir du chemin complet
            let lastPathComponent = URL(fileURLWithPath: path).lastPathComponent
            
            // Convertir en chemin relatif si possible
            let simplifiedPath = configManager.convertToRelativePath(path) ?? lastPathComponent
            
            // Stockez les tags avec le chemin simplifié
            updatedScriptTags[simplifiedPath] = tagSet
        }
        
        // Remplacer les anciens chemins par les nouveaux
        scriptTags = updatedScriptTags
        
        // Sauvegarder les changements
        configManager.scriptTags = scriptTags
    }
    
    // Sauvegarde l'état actuel des tags comme sauvegarde
    func saveCurrentTagsState() {
        originalTags = tags
    }
    
    // Restaure les tags à leur état sauvegardé
    func restoreOriginalTags() {
        tags = originalTags
        objectWillChange.send()
    }
    
    // Valide les modifications et sauvegarde l'état actuel
    func saveChanges() {
        // Sauvegarde dans le ConfigManager
        saveTags()
        
        // Met à jour la sauvegarde
        originalTags = tags
        
        // Notifie pour la mise à jour globale
        NotificationCenter.default.post(name: NSNotification.Name("GlobalTagsChanged"), object: nil)
    }
    
    func addTag(name: String, color: Color) {
        // Vérifier que le nom n'existe pas déjà
        guard !tags.contains(where: { $0.name.lowercased() == name.lowercased() }),
              !name.isEmpty else {
            return
        }
        
        let newTag = Tag(id: UUID(), name: name, color: color)
        tags.append(newTag)
    }
    
    func removeTag(_ tag: Tag) {
        tags.removeAll { $0.id == tag.id }
        
        // Supprimer ce tag de tous les scripts
        for scriptPath in scriptTags.keys {
            scriptTags[scriptPath]?.remove(tag.name)
        }
        
        // Notifier les changements
        objectWillChange.send()
    }
    
    // Mise à jour d'un tag en mémoire uniquement
    func updateTagInMemory(_ tag: Tag, newName: String, newColor: Color) {
        if let index = tags.firstIndex(where: { $0.id == tag.id }) {
            let oldName = tags[index].name
            
            // Créer le tag mis à jour
            let updatedTag = Tag(id: tag.id, name: newName, color: newColor)
            tags[index] = updatedTag
            
            // Mettre à jour les références de nom si le nom a changé
            if oldName != newName {
                for scriptPath in scriptTags.keys {
                    if scriptTags[scriptPath]?.contains(oldName) == true {
                        scriptTags[scriptPath]?.remove(oldName)
                        scriptTags[scriptPath]?.insert(newName)
                    }
                }
            }
            
            // Notifier pour rafraîchir l'interface locale
            objectWillChange.send()
        }
    }
    
    func getTag(name: String) -> Tag? {
        return tags.first { $0.name == name }
    }
    
    func getTagsForScript(path: String) -> Set<String> {
        // Obtenir juste le nom du fichier à partir du chemin
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        
        // Vérifier d'abord si le chemin absolu existe
        if let tags = scriptTags[path] {
            return tags
        }
        
        // Ensuite vérifier si un chemin relatif existe
        let relativePath = configManager.convertToRelativePath(path) ?? path
        if let tags = scriptTags[relativePath] {
            return tags
        }
        
        // Enfin, vérifier si le nom du fichier seul existe
        if let tags = scriptTags[fileName] {
            return tags
        }
        
        return []
    }
    
    func updateScriptTags(scriptPath: String, tags: Set<String>) {
        // Simplifier le chemin pour le stockage
        let fileName = URL(fileURLWithPath: scriptPath).lastPathComponent
        
        // Essayer d'abord de convertir en chemin relatif pour le stockage si possible
        let storagePath = configManager.convertToRelativePath(scriptPath) ?? fileName
        
        scriptTags[storagePath] = tags
        saveScriptTags()
    }
    
    private func saveTags() {
        // Convertir les tags en TagConfig pour la sauvegarde
        let tagConfigs = tags.compactMap { tag -> TagConfig? in
            guard let colorHex = tag.color.toHex() else { return nil }
            return TagConfig(id: tag.id, name: tag.name, colorHex: colorHex)
        }
        
        // Sauvegarder dans ConfigManager
        configManager.tags = tagConfigs
    }
    
    private func saveScriptTags() {
        // Sauvegarder les associations script-tags
        configManager.scriptTags = scriptTags
    }
}
