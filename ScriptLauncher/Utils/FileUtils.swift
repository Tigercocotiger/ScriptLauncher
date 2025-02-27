//
//  FileUtils.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 25/02/2025.
//


import Foundation

// Utilitaires pour la gestion des fichiers
struct FileUtils {
    
    // Retourne le nom du fichier sans l'extension
    static func nameWithoutExtension(_ fileName: String) -> String {
        if let dotIndex = fileName.lastIndex(of: ".") {
            return String(fileName[..<dotIndex])
        }
        return fileName
    }
    
    // Retourne l'extension du fichier
    static func fileExtension(_ fileName: String) -> String {
        if let dotIndex = fileName.lastIndex(of: ".") {
            return String(fileName[fileName.index(after: dotIndex)...])
        }
        return ""
    }
    
    // Vérifie si le fichier est un script AppleScript
    static func isAppleScriptFile(_ fileName: String) -> Bool {
        let ext = fileExtension(fileName).lowercased()
        return ext == "scpt" || ext == "applescript"
    }
}