//
//  Models.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 25/02/2025.
//  Modified on 05/03/2025.
//  Modified on 06/03/2025. - Added tags support
//  Modified on 14/03/2025. - Fixed RunningScript issues
//

import SwiftUI
import Combine

// Modèle pour un fichier script
struct ScriptFile: Identifiable, Hashable {
    let id: UUID  // Doit être un paramètre qui peut être transmis
    let name: String
    let path: String
    var isFavorite: Bool
    var lastExecuted: Date?
    var isSelected: Bool = false
    var tags: Set<String> = []
    
    // Initialisation avec ID optionnel
    init(id: UUID = UUID(), name: String, path: String, isFavorite: Bool, lastExecuted: Date?, isSelected: Bool = false, tags: Set<String> = []) {
        self.id = id
        self.name = name
        self.path = path
        self.isFavorite = isFavorite
        self.lastExecuted = lastExecuted
        self.isSelected = isSelected
        self.tags = tags
    }
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
struct RunningScript: Identifiable, Equatable {
    let id: UUID // IMPORTANT: Doit correspondre à l'ID du ScriptFile
    let name: String
    var startTime: Date  // 'var' pour permettre la réinitialisation
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
    
    // Conformité au protocole Equatable
    static func == (lhs: RunningScript, rhs: RunningScript) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.startTime == rhs.startTime &&
               lhs.output == rhs.output &&
               lhs.isSelected == rhs.isSelected &&
               lhs.status == rhs.status &&
               lhs.endTime == rhs.endTime
    }
}
