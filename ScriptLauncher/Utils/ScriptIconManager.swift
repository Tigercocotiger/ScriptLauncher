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
        
        // Convertir l'image en données avant de l'utiliser dans les méthodes asynchrones
        // Cela évite les problèmes de non-sendable types
        let iconData = try convertImageToPNGData(icon)
        
        // Utiliser l'API Finder pour définir l'icône personnalisée
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    
                    // Utiliser AppleScript pour définir l'icône (meilleure compatibilité)
                    let tempIconPath = NSTemporaryDirectory() + UUID().uuidString + ".png"
                    try iconData.write(to: URL(fileURLWithPath: tempIconPath))
                    
                    let script = """
                    tell application "Finder"
                        set theFile to POSIX file "\(filePath)" as alias
                        set theIcon to POSIX file "\(tempIconPath)" as alias
                        set icon of theFile to icon of theIcon
                    end tell
                    """
                    
                    // Exécuter le script AppleScript
                    var error: NSDictionary?
                    NSAppleScript(source: script)?.executeAndReturnError(&error)
                    
                    // Nettoyer le fichier temporaire
                    try? FileManager.default.removeItem(atPath: tempIconPath)
                    
                    if let error = error {
                        throw NSError(domain: "ScriptIconManager", code: 2, userInfo: [
                            NSLocalizedDescriptionKey: "Erreur lors de la définition de l'icône: \(error)"
                        ])
                    }
                    
                    // Mettre à jour aussi l'icône dans le cache du système
                    // On recrée une image à partir des données PNG
                    if let tempImage = NSImage(data: iconData) {
                        NSWorkspace.shared.setIcon(tempImage, forFile: filePath, options: [])
                    }
                    
                    continuation.resume(returning: true)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // Conversion directe NSImage -> PNG Data (pour éviter les problèmes de sendable)
    // Cette méthode est maintenant synchrone pour éviter les problèmes de capture
    private static func convertImageToPNGData(_ image: NSImage) throws -> Data {
        // Créer un bitmap représentation pour l'icône
        guard let representation = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(image.size.width),
            pixelsHigh: Int(image.size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw NSError(
                domain: "ScriptIconManager",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Impossible de créer la représentation bitmap"]
            )
        }
        
        // Dessiner l'image dans la représentation
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: representation)
        image.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()
        
        // Convertir en PNG
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw NSError(
                domain: "ScriptIconManager",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Impossible de convertir l'image en PNG"]
            )
        }
        
        return data
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
                
                // Si un nouveau nom est spécifié, renommer le fichier
                if let newName = newName {
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
                    
                    // Appliquer l'icône sans capture de NSImage
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
