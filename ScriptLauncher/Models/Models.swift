//
//  Models.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 25/02/2025.
//  Modified on 05/03/2025.
//  Modified on 06/03/2025. - Added tags support
//

import SwiftUI
import Combine

// Modèle pour un fichier script
struct ScriptFile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    var isFavorite: Bool
    var lastExecuted: Date?
    var isSelected: Bool = false
    var tags: Set<String> = [] // Nouveau champ pour les tags
    
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
    var startTime: Date  // Modifié de 'let' à 'var' pour permettre la réinitialisation
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

// Observable object qui gère les scripts en cours avec un timer
class RunningScriptsViewModel: ObservableObject {
    @Published var scripts: [RunningScript] = []
    @Published var selectedScriptId: UUID?
    private var timer: AnyCancellable?
    
    init() {
        // Démarrer le timer pour mettre à jour le temps écoulé chaque seconde
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }
    
    // Ajouter un script à la liste
    func addScript(_ script: RunningScript) {
        scripts.append(script)
        if scripts.count == 1 {
            selectedScriptId = script.id
            for i in 0..<scripts.count {
                if scripts[i].id == script.id {
                    scripts[i].isSelected = true
                }
            }
        }
    }
    
    // Sélectionner un script
    func selectScript(id: UUID) {
        selectedScriptId = id
        for i in 0..<scripts.count {
            scripts[i].isSelected = (scripts[i].id == id)
        }
    }
    
    // Mettre à jour la sortie d'un script
    func updateScript(id: UUID, output: String, status: ScriptStatus? = nil, endTime: Date? = nil) {
        if let index = scripts.firstIndex(where: { $0.id == id }) {
            scripts[index].output = output
            
            if let newStatus = status {
                scripts[index].status = newStatus
                scripts[index].endTime = endTime
            }
        }
    }
    
    // Réinitialise le temps de démarrage d'un script
    func resetScriptStartTime(id: UUID, startTime: Date) {
        if let index = scripts.firstIndex(where: { $0.id == id }) {
            scripts[index].startTime = startTime
        }
    }
    
    // Supprimer un script
    func removeScript(id: UUID) {
        if selectedScriptId == id {
            selectedScriptId = scripts.first(where: { $0.id != id })?.id
        }
        scripts.removeAll { $0.id == id }
        
        // Mettre à jour isSelected pour le nouveau script sélectionné
        if let newSelectedId = selectedScriptId {
            for i in 0..<scripts.count {
                scripts[i].isSelected = (scripts[i].id == newSelectedId)
            }
        }
    }
    
    // Supprimer tous les scripts terminés (complétés ou échoués)
    func clearCompletedScripts() {
        // Conserver uniquement les scripts en cours d'exécution
        let runningScriptIds = scripts.filter { $0.status == .running }.map { $0.id }
        
        // Vérifier si le script sélectionné sera supprimé
        let selectedWillBeRemoved = selectedScriptId != nil && !runningScriptIds.contains(where: { $0 == selectedScriptId })
        
        // Filtrer les scripts pour ne garder que ceux en cours
        scripts = scripts.filter { $0.status == .running }
        
        // Si le script sélectionné a été supprimé, sélectionner un nouveau script si disponible
        if selectedWillBeRemoved {
            selectedScriptId = scripts.first?.id
            
            if let newSelectedId = selectedScriptId {
                for i in 0..<scripts.count {
                    scripts[i].isSelected = (scripts[i].id == newSelectedId)
                }
            }
        }
    }
    
    // Annuler tous les scripts
    func removeAllScripts() {
        scripts.removeAll()
        selectedScriptId = nil
    }
    
    deinit {
        timer?.cancel()
    }
}
