//
//  RunningScriptsViewModel.swift
//  ScriptLauncher
//
//  Created by MPM on 13/03/2025.
//


//
//  RunningScriptsViewModel.swift
//  ScriptLauncher
//
//  Created for ScriptLauncher on 04/03/2025.
//  Updated on 05/03/2025.
//  Updated on 14/03/2025. - Fixed log display issues
//

import SwiftUI
import Combine

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
                guard let self = self else { return }
                
                // N'envoyer des notifications que si des scripts sont en cours d'exécution
                let hasRunningScripts = self.scripts.contains { $0.status == .running }
                if hasRunningScripts {
                    self.objectWillChange.send()
                }
            }
    }
    
    // Ajouter un script à la liste
    func addScript(_ script: RunningScript) {
        // DEBUG: Vérifier l'ID du script avant de l'ajouter
        print("[ViewModel] Ajout du script: \(script.name) avec ID: \(script.id)")
        
        // Vérifier si le script existe déjà
        if let existingIndex = scripts.firstIndex(where: { $0.id == script.id }) {
            print("[ViewModel] Le script existe déjà - mise à jour au lieu d'ajout")
            scripts[existingIndex] = script
        } else {
            scripts.append(script)
        }
        
        // Sélectionner automatiquement le script si c'est le premier
        if scripts.count == 1 {
            selectedScriptId = script.id
            for i in 0..<scripts.count {
                scripts[i].isSelected = (scripts[i].id == script.id)
            }
        }
        
        // DEBUG: Afficher tous les scripts actifs après l'ajout
        logActiveScripts()
        
        // Notifier explicitement les observateurs que l'objet a changé
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // Sélectionner un script
    func selectScript(id: UUID) {
        print("[ViewModel] Sélection du script avec ID: \(id)")
        selectedScriptId = id
        for i in 0..<scripts.count {
            scripts[i].isSelected = (scripts[i].id == id)
        }
        
        // Notifier explicitement des changements
        objectWillChange.send()
    }
    
    // Mettre à jour la sortie d'un script
    func updateScript(id: UUID, output: String, status: ScriptStatus? = nil, endTime: Date? = nil) {
        // DEBUG: Vérifier l'ID reçu
        print("[ViewModel] Tentative de mise à jour du script avec ID: \(id)")
        
        if let index = scripts.firstIndex(where: { $0.id == id }) {
            // IMPORTANT: Vérifier si il y a eu un changement réel
            let existingOutput = scripts[index].output
            let hasNewContent = existingOutput != output
            
            // Mise à jour debug dans la console
            if hasNewContent {
                print("[ViewModel] Mise à jour de la sortie pour \(scripts[index].name): +\(output.count - existingOutput.count) caractères")
            }
            
            // Mettre à jour la sortie
            scripts[index].output = output
            
            // Mettre à jour le statut si fourni
            if let newStatus = status {
                let oldStatus = scripts[index].status
                scripts[index].status = newStatus
                
                // Debug changement de statut
                if oldStatus != newStatus {
                    print("[ViewModel] Changement de statut pour \(scripts[index].name): \(oldStatus) -> \(newStatus)")
                }
            }
            
            // Mettre à jour l'heure de fin si fournie
            if let newEndTime = endTime {
                scripts[index].endTime = newEndTime
            }
            
            // TRÈS IMPORTANT: Notifier explicitement les observateurs que l'objet a changé
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } else {
            print("[ViewModel] ERREUR: Impossible de trouver le script avec ID \(id) pour mise à jour")
            
            // DEBUG: Afficher tous les scripts actifs pour débogage
            logActiveScripts()
        }
    }
    
    // Réinitialise le temps de démarrage d'un script
    func resetScriptStartTime(id: UUID, startTime: Date) {
        if let index = scripts.firstIndex(where: { $0.id == id }) {
            scripts[index].startTime = startTime
            // Réinitialiser aussi l'heure de fin et le statut
            scripts[index].endTime = nil
            scripts[index].status = .running
            objectWillChange.send()
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
        
        // Notifier des changements
        objectWillChange.send()
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
        
        // Notifier des changements
        objectWillChange.send()
    }
    
    // Annuler tous les scripts
    func removeAllScripts() {
        scripts.removeAll()
        selectedScriptId = nil
        objectWillChange.send()
    }
    
    // Méthode d'utilitaire pour déboguer les scripts actifs
    func logActiveScripts() {
        print("---- SCRIPTS ACTIFS [\(scripts.count)] ----")
        for script in scripts {
            print("  Script: \(script.name), ID: \(script.id), Sélectionné: \(script.isSelected), Status: \(script.status)")
        }
        print("-------------------------------")
    }
    
    deinit {
        timer?.cancel()
    }
}
