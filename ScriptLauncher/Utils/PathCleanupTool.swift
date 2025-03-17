//
//  PathCleanupTool.swift
//  ScriptLauncher
//
//  Utilitaire pour nettoyer le fichier de configuration
//  Créé le 25/03/2025
//

import Foundation
import AppKit

class PathCleanupTool {
    static func cleanupConfigFile() {
        let alert = NSAlert()
        alert.messageText = "Nettoyer la configuration"
        alert.informativeText = "Voulez-vous nettoyer les chemins absolus dans le fichier de configuration ? Cette opération simplifiera les références aux scripts."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Nettoyer")
        alert.addButton(withTitle: "Annuler")
        
        if alert.runModal() == .alertFirstButtonReturn {
            performCleanup()
        }
    }
    
    private static func performCleanup() {
        let configManager = ConfigManager.shared
        
        // Chemin vers le fichier de configuration
        let configPath = configManager.getConfigFilePath()
        
        do {
            // Lire le fichier JSON
            let data = try Data(contentsOf: configPath)
            var json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            
            // Vérifier si scriptTags est présent
            if var scriptTags = json["scriptTags"] as? [String: Any] {
                var updatedScriptTags: [String: Any] = [:]
                
                // Pour chaque chemin, extraire juste le nom du fichier
                for (path, tagSet) in scriptTags {
                    let url = URL(fileURLWithPath: path)
                    let fileName = url.lastPathComponent
                    
                    // Utiliser le nom du fichier comme nouvelle clé
                    updatedScriptTags[fileName] = tagSet
                }
                
                // Remplacer les scriptTags par la version simplifiée
                json["scriptTags"] = updatedScriptTags
                
                // Convertir en JSON
                let updatedData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
                
                // Écrire dans le fichier
                try updatedData.write(to: configPath)
                
                // Recharger la configuration
                configManager.loadConfig()
                
                // Notification de succès
                let successAlert = NSAlert()
                successAlert.messageText = "Configuration nettoyée"
                successAlert.informativeText = "Les chemins ont été simplifiés dans le fichier de configuration."
                successAlert.alertStyle = .informational
                successAlert.addButton(withTitle: "OK")
                successAlert.runModal()
                
                // Rafraîchir l'interface
                NotificationCenter.default.post(name: NSNotification.Name("RefreshScriptsList"), object: nil)
            }
        } catch {
            // Notification d'erreur
            let errorAlert = NSAlert()
            errorAlert.messageText = "Erreur"
            errorAlert.informativeText = "Une erreur est survenue lors du nettoyage de la configuration: \(error.localizedDescription)"
            errorAlert.alertStyle = .critical
            errorAlert.addButton(withTitle: "OK")
            errorAlert.runModal()
        }
    }
}