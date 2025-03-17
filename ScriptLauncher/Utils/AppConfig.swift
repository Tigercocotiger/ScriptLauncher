//
//  ConfigManager.swift
//  ScriptLauncher
//
//  Created on 05/03/2025.
//  Updated on 06/03/2025. - Added tags support
//  Updated on 10/03/2025. - Added root USB drive resources lookup
//  Updated on 13/03/2025. - Added support for scripts in Resources folder
//  Updated on 25/03/2025. - Added method to get config file path
//

import Foundation
import AppKit

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
    
    // Méthode publique pour obtenir le chemin du fichier de configuration
    func getConfigFilePath() -> URL {
        return configFilePath
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
    
    // Retourne le chemin vers le dossier des scripts dans Resources
    func getScriptsFolderPath() -> String {
        // Calculer le chemin de base vers le dossier Resources/ScriptLauncher
        let baseURL = configFilePath.deletingLastPathComponent()
        
        // Définir le chemin du dossier des scripts
        let scriptsFolderURL = baseURL.appendingPathComponent("Scripts", isDirectory: true)
        
        // Créer le dossier s'il n'existe pas
        if !FileManager.default.fileExists(atPath: scriptsFolderURL.path) {
            do {
                try FileManager.default.createDirectory(at: scriptsFolderURL, withIntermediateDirectories: true)
            } catch {
                print("Erreur lors de la création du dossier Scripts: \(error)")
            }
        }
        
        return scriptsFolderURL.path
    }
    
    // Initialise le dossier de scripts avec les valeurs par défaut si nécessaire
    func initializeScriptsFolder() {
        let scriptsPath = getScriptsFolderPath()
        
        // Si le dossier de scripts est vide, proposer de copier des scripts depuis le dossier par défaut
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(atPath: scriptsPath)
            let scriptFiles = files.filter { $0.hasSuffix(".scpt") || $0.hasSuffix(".applescript") }
            
            if scriptFiles.isEmpty {
                // Le dossier est vide, utiliser le dossier par défaut
                if config.lastOpenedFolderPath != scriptsPath && isValidScriptFolder(config.lastOpenedFolderPath) {
                    // Demander à l'utilisateur s'il souhaite copier les scripts existants
                    let alert = NSAlert()
                    alert.messageText = "Configuration des scripts"
                    alert.informativeText = "Le dossier de scripts dans Resources est vide. Souhaitez-vous y copier les scripts depuis \(config.lastOpenedFolderPath)?"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "Oui")
                    alert.addButton(withTitle: "Non")
                    
                    let response = alert.runModal()
                    if response == .alertFirstButtonReturn {
                        // Copier les scripts existants
                        copyScriptsToResourcesFolder(from: config.lastOpenedFolderPath)
                    }
                }
            }
        } catch {
            print("Erreur lors de la vérification du dossier de scripts: \(error)")
        }
        
        // Mettre à jour le chemin de dossier par défaut
        config.lastOpenedFolderPath = scriptsPath
        saveConfig()
    }
    
    // Copie les scripts existants vers le dossier Resources/ScriptLauncher/Scripts
    private func copyScriptsToResourcesFolder(from sourcePath: String) {
        let destinationPath = getScriptsFolderPath()
        let fileManager = FileManager.default
        
        do {
            // Résoudre le chemin source si c'est un chemin relatif
            let resolvedSourcePath = resolveRelativePath(sourcePath)
            
            // Obtenir tous les fichiers scripts du dossier source
            let files = try fileManager.contentsOfDirectory(atPath: resolvedSourcePath)
            let scriptFiles = files.filter { $0.hasSuffix(".scpt") || $0.hasSuffix(".applescript") }
            
            // Copier chaque script
            for file in scriptFiles {
                let sourceFile = (resolvedSourcePath as NSString).appendingPathComponent(file)
                let destinationFile = (destinationPath as NSString).appendingPathComponent(file)
                
                // Vérifier si la destination existe déjà
                if fileManager.fileExists(atPath: destinationFile) {
                    try fileManager.removeItem(atPath: destinationFile)
                }
                
                // Copier le fichier
                try fileManager.copyItem(atPath: sourceFile, toPath: destinationFile)
            }
            
            // Vérifier si le dossier DMG existe et le copier également
            let sourceDMGFolder = (resolvedSourcePath as NSString).appendingPathComponent("DMG")
            let destinationDMGFolder = (destinationPath as NSString).appendingPathComponent("DMG")
            
            if fileManager.fileExists(atPath: sourceDMGFolder) {
                // Créer le dossier DMG dans la destination s'il n'existe pas
                if !fileManager.fileExists(atPath: destinationDMGFolder) {
                    try fileManager.createDirectory(at: URL(fileURLWithPath: destinationDMGFolder),
                                                   withIntermediateDirectories: true)
                }
                
                // Copier tous les fichiers DMG
                let dmgFiles = try fileManager.contentsOfDirectory(atPath: sourceDMGFolder)
                for file in dmgFiles {
                    let sourceDMGFile = (sourceDMGFolder as NSString).appendingPathComponent(file)
                    let destinationDMGFile = (destinationDMGFolder as NSString).appendingPathComponent(file)
                    
                    // Vérifier si la destination existe déjà
                    if fileManager.fileExists(atPath: destinationDMGFile) {
                        try fileManager.removeItem(atPath: destinationDMGFile)
                    }
                    
                    // Copier le fichier DMG
                    try fileManager.copyItem(atPath: sourceDMGFile, toPath: destinationDMGFile)
                }
            }
            
            print("Scripts copiés avec succès vers \(destinationPath)")
        } catch {
            print("Erreur lors de la copie des scripts: \(error)")
        }
    }
    
    // Ajoute un script au dossier Resources/ScriptLauncher/Scripts
    func addScriptToResourcesFolder(scriptPath: String, scriptName: String? = nil) -> Bool {
        let destinationPath = getScriptsFolderPath()
        let fileManager = FileManager.default
        
        // Utiliser le nom fourni ou extraire le nom du fichier
        let fileName = scriptName ?? URL(fileURLWithPath: scriptPath).lastPathComponent
        
        // Construire le chemin de destination
        let destinationFile = (destinationPath as NSString).appendingPathComponent(fileName)
        
        do {
            // Vérifier si la destination existe déjà
            if fileManager.fileExists(atPath: destinationFile) {
                try fileManager.removeItem(atPath: destinationFile)
            }
            
            // Copier le fichier
            try fileManager.copyItem(atPath: scriptPath, toPath: destinationFile)
            return true
        } catch {
            print("Erreur lors de l'ajout du script: \(error)")
            return false
        }
    }
}
