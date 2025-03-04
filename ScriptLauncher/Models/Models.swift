//
//  Models.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 25/02/2025.
//  Modified on 04/03/2025.
//

import SwiftUI

// Modèle pour les favoris
struct Favorites: Codable {
    var scriptPaths: Set<String>
}

// Modèle pour un fichier script
struct ScriptFile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    var isFavorite: Bool
    var lastExecuted: Date?
    
    // Nouvelles propriétés pour l'exécution multiple
    var isRunning: Bool = false
    var currentOutput: String = ""
    var executionProgress: Double = 0.0 // Pour indiquer la progression (0.0 - 1.0)
}

// Modèle pour une section d'aide
struct HelpSection: Identifiable {
    let id = UUID()
    let title: String
    let content: String
}

// État d'un script
enum ScriptStatus {
    case running
    case completed
    case failed
}

// Modèle pour un script en cours d'exécution
struct RunningScript: Identifiable {
    let id: UUID
    let name: String
    let startTime: Date
    var output: String
    var isSelected: Bool = false
    var status: ScriptStatus = .running
    var endTime: Date? = nil
    
    // Calcul du temps écoulé
    var elapsedTime: String {
        let interval: TimeInterval
        if let end = endTime {
            interval = end.timeIntervalSince(startTime)
        } else {
            interval = Date().timeIntervalSince(startTime)
        }
        
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}
