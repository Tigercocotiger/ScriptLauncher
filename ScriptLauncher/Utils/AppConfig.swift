//
//  ConfigManager.swift
//  ScriptLauncher
//
//  Created on 05/03/2025.
//  Updated on 06/03/2025. - Added tags support
//  Updated on 10/03/2025. - Added root USB drive resources lookup
//

import Foundation

struct AppConfig: Codable {
    var favorites: Set<String> = []
    var isDarkMode: Bool = false
    var isGridView: Bool = false
    var lastOpenedFolderPath: String = "/Volumes/Marco/Dév/Fonctionnel"
    var tags: [TagConfig] = [] // Liste des tags disponibles
    var scriptTags: [String: Set<String>] = [:] // Associations script path -> tags
}

class ConfigManager {
    static let shared = ConfigManager()
    
    private var config = AppConfig()
    
    // Chemin relatif vers le fichier de configuration
    private var configFilePath: URL {
        // Obtenir le dossier contenant l'application
        let appURL = Bundle.main.bundleURL.deletingLastPathComponent()
        
        // Déterminer si nous sommes sur une clé USB
        let isOnUSBDrive = appURL.path.contains("/Volumes/")
        var resourcesDir: URL
        
        if isOnUSBDrive {
            // Si l'app est sur une clé USB, extraire le chemin de la racine de la clé
            let pathComponents = appURL.path.components(separatedBy: "/Volumes/")
            if pathComponents.count > 1 {
                let usbPathPart = pathComponents[1]
                if let slashIndex = usbPathPart.firstIndex(of: "/") {
                    let usbName = String(usbPathPart[..<slashIndex])
                    
                    // Construire le chemin vers la racine de la clé USB
                    let usbRootPath = "/Volumes/\(usbName)"
                    resourcesDir = URL(fileURLWithPath: usbRootPath).appendingPathComponent("Resources/ScriptLauncher", isDirectory: true)
                } else {
                    // Si pas de slash, on est directement à la racine de la clé
                    resourcesDir = URL(fileURLWithPath: "/Volumes/\(usbPathPart)").appendingPathComponent("Resources/ScriptLauncher", isDirectory: true)
                }
            } else {
                // Fallback au comportement par défaut si quelque chose ne va pas
                resourcesDir = appURL.appendingPathComponent("Resources/ScriptLauncher", isDirectory: true)
            }
        } else {
            // Comportement par défaut si nous ne sommes pas sur une clé USB
            resourcesDir = appURL.appendingPathComponent("Resources/ScriptLauncher", isDirectory: true)
        }
        
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
    
    // Accesseurs pour les tags
    var tags: [TagConfig] {
        get { config.tags }
        set {
            config.tags = newValue
            saveConfig()
        }
    }
    
    var scriptTags: [String: Set<String>] {
        get { config.scriptTags }
        set {
            config.scriptTags = newValue
            saveConfig()
        }
    }
    
    // Détecte le nom de la clé USB actuelle où se trouve l'application
    func getCurrentUSBDriveName() -> String? {
        let appURL = Bundle.main.bundleURL.deletingLastPathComponent()
        
        if appURL.path.contains("/Volumes/") {
            let pathComponents = appURL.path.components(separatedBy: "/Volumes/")
            if pathComponents.count > 1 {
                let usbPathPart = pathComponents[1]
                if let slashIndex = usbPathPart.firstIndex(of: "/") {
                    return String(usbPathPart[..<slashIndex])
                } else {
                    return usbPathPart
                }
            }
        }
        
        return nil
    }
    
    // Convertit les chemins absolus en chemins relatifs (par rapport à la clé USB)
    func convertToRelativePath(_ path: String) -> String? {
        guard let usbName = getCurrentUSBDriveName() else {
            return nil
        }
        
        let usbPrefix = "/Volumes/\(usbName)"
        if path.hasPrefix(usbPrefix) {
            return "$USB" + path.dropFirst(usbPrefix.count)
        }
        
        return path
    }
    
    // Résout les chemins relatifs en chemins absolus
    func resolveRelativePath(_ path: String) -> String {
        if path.hasPrefix("$USB") {
            if let usbName = getCurrentUSBDriveName() {
                return "/Volumes/\(usbName)" + path.dropFirst(4) // Supprimer "$USB"
            }
        }
        
        return path
    }
}
