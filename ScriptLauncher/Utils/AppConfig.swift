//
//  ConfigManager.swift
//  ScriptLauncher
//
//  Created on 05/03/2025.
//

import Foundation

struct AppConfig: Codable {
    var favorites: Set<String> = []
    var isDarkMode: Bool = false
    var isGridView: Bool = false
    var lastOpenedFolderPath: String = "/Volumes/Marco/Dév/Fonctionnel"
}

class ConfigManager {
    static let shared = ConfigManager()
    
    private var config = AppConfig()
    
    // Chemin relatif vers le fichier de configuration
    private var configFilePath: URL {
        // Obtenir le dossier contenant l'application
        let appURL = Bundle.main.bundleURL.deletingLastPathComponent()
        
        // Créer le chemin vers le dossier Resources/ScriptLauncher
        let resourcesDir = appURL.appendingPathComponent("Resources/ScriptLauncher", isDirectory: true)
        
        // Créer le dossier s'il n'existe pas
        try? FileManager.default.createDirectory(at: resourcesDir, withIntermediateDirectories: true)
        
        // Retourner le chemin complet vers le fichier de configuration
        return resourcesDir.appendingPathComponent("ScriptLauncher_config.json")
    }
    
    init() {
        loadConfig()
    }
    
    func loadConfig() {
        let configPath = configFilePath
        
        if FileManager.default.fileExists(atPath: configPath.path) {
            do {
                let data = try Data(contentsOf: configPath)
                let loadedConfig = try JSONDecoder().decode(AppConfig.self, from: data)
                config = loadedConfig
                print("Configuration chargée depuis: \(configPath.path)")
            } catch {
                print("Erreur lors du chargement de la configuration: \(error)")
            }
        } else {
            // Créer un fichier de configuration par défaut
            saveConfig()
            print("Fichier de configuration créé à: \(configPath.path)")
        }
    }
    
    func saveConfig() {
        let configPath = configFilePath
        
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: configPath)
        } catch {
            print("Erreur lors de l'enregistrement de la configuration: \(error)")
        }
    }
    
    // Vérifie si le dossier est valide pour les scripts
    func isValidScriptFolder(_ path: String) -> Bool {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        
        // Vérifier si le chemin existe et est un dossier
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return false
        }
        
        // Vérifier les permissions
        guard fileManager.isReadableFile(atPath: path) else {
            return false
        }
        
        // Vérifier si le dossier contient des scripts
        do {
            let files = try fileManager.contentsOfDirectory(atPath: path)
            let hasScriptFiles = files.contains { $0.hasSuffix(".scpt") || $0.hasSuffix(".applescript") }
            return hasScriptFiles
        } catch {
            return false
        }
    }
    
    // Accesseurs pour les différentes préférences
    var favorites: Set<String> {
        get { config.favorites }
        set {
            config.favorites = newValue
            saveConfig()
        }
    }
    
    var isDarkMode: Bool {
        get { config.isDarkMode }
        set {
            config.isDarkMode = newValue
            saveConfig()
        }
    }
    
    var isGridView: Bool {
        get { config.isGridView }
        set {
            config.isGridView = newValue
            saveConfig()
        }
    }
    
    var folderPath: String {
        get { config.lastOpenedFolderPath }
        set {
            // Vérifier si le nouveau chemin est valide
            if FileManager.default.fileExists(atPath: newValue) {
                config.lastOpenedFolderPath = newValue
                
                // Nettoyer les favoris qui ne sont plus dans le bon dossier
                favorites = favorites.filter { favPath in
                    favPath.starts(with: newValue)
                }
                
                saveConfig()
            }
        }
    }
}
