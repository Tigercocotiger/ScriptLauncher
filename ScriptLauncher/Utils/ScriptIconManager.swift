import Foundation
import AppKit

// Gestionnaire pour la manipulation des icônes et noms de fichiers scripts
class ScriptIconManager {
    // Modifie l'icône d'un fichier
    static func setCustomIcon(for filePath: String, icon: NSImage) async throws -> Bool {
        // Vérifier si le fichier existe
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: filePath) else {
            throw NSError(domain: "ScriptIconManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Le fichier n'existe pas"])
        }
        
        // Convertir l'image en données pour éviter les problèmes de Sendable
        guard let tiffData = icon.tiffRepresentation else {
            throw NSError(domain: "ScriptIconManager", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Impossible de convertir l'image en données"
            ])
        }
        
        // Utiliser uniquement l'API NSWorkspace pour définir l'icône
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Recréer l'image à partir des données
                    let iconFromData = NSImage(data: tiffData)
                    
                    // Définir directement l'icône via NSWorkspace
                    let success = NSWorkspace.shared.setIcon(iconFromData, forFile: filePath, options: [])
                    
                    if !success {
                        throw NSError(domain: "ScriptIconManager", code: 2, userInfo: [
                            NSLocalizedDescriptionKey: "Impossible d'appliquer l'icône au fichier"
                        ])
                    }
                    
                    continuation.resume(returning: true)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // Renomme un fichier script
    static func renameScript(at filePath: String, to newName: String) async throws -> String {
        // Vérifier si le fichier existe
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: filePath) else {
            throw NSError(domain: "ScriptIconManager", code: 5, userInfo: [NSLocalizedDescriptionKey: "Le fichier n'existe pas"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                // Obtenir le dossier du fichier
                let fileURL = URL(fileURLWithPath: filePath)
                let directory = fileURL.deletingLastPathComponent().path
                
                // Construire le nouveau chemin
                let newPath = (directory as NSString).appendingPathComponent(newName)
                
                // Vérifier si le nouveau chemin existe déjà
                if fileManager.fileExists(atPath: newPath) {
                    throw NSError(domain: "ScriptIconManager", code: 6, userInfo: [
                        NSLocalizedDescriptionKey: "Un fichier avec ce nom existe déjà"
                    ])
                }
                
                // Renommer le fichier
                try fileManager.moveItem(atPath: filePath, toPath: newPath)
                
                continuation.resume(returning: newPath)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // Applique à la fois un changement d'icône et de nom si nécessaire
    static func applyChanges(for script: ScriptFile, newName: String? = nil, newIcon: NSImage? = nil, completion: @escaping (Result<ScriptFile, Error>) -> Void) {
        Task {
            do {
                var updatedScript = script
                
                // Si un nouveau nom est spécifié qui diffère de l'actuel, renommer le fichier
                if let newName = newName, newName != script.name {
                    let newPath = try await renameScript(at: script.path, to: newName)
                    
                    // Mettre à jour le script avec le nouveau chemin et nom
                    updatedScript = ScriptFile(
                        id: script.id,
                        name: newName,
                        path: newPath,
                        isFavorite: script.isFavorite,
                        lastExecuted: script.lastExecuted,
                        isSelected: script.isSelected,
                        tags: script.tags
                    )
                }
                
                // Si une nouvelle icône est spécifiée, la définir
                if let newIcon = newIcon {
                    // Utiliser le chemin mis à jour si le fichier a été renommé
                    let path = newName != nil ? updatedScript.path : script.path
                    
                    // Appliquer l'icône directement via NSWorkspace
                    let success = try await setCustomIcon(for: path, icon: newIcon)
                    
                    if !success {
                        throw NSError(domain: "ScriptIconManager", code: 7, userInfo: [
                            NSLocalizedDescriptionKey: "Impossible de définir l'icône personnalisée"
                        ])
                    }
                }
                
                // Envoyer le résultat avec le script mis à jour
                DispatchQueue.main.async {
                    completion(.success(updatedScript))
                }
            } catch {
                // Envoyer l'erreur
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
