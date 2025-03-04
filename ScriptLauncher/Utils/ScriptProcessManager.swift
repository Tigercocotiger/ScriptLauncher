//
//  ScriptProcessManager.swift
//  ScriptLauncher
//
//  Created for ScriptLauncher on 04/03/2025.
//

import Foundation
import Combine

class ScriptProcessManager: ObservableObject {
    @Published var runningProcesses: [UUID: Process] = [:]
    
    // Exécute un script et retourne un publisher avec sa sortie
    func executeScript(script: ScriptFile) -> AnyPublisher<(UUID, String), Never> {
        let id = script.id
        let outputSubject = PassthroughSubject<(UUID, String), Never>()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            let pipe = Pipe()
            
            // Configuration pour la lecture en temps réel
            let outputHandle = pipe.fileHandleForReading
            
            // Configurer la notification de disponibilité des données
            var fullOutput = ""
            
            // Configurer un handler pour lire les données disponibles
            outputHandle.readabilityHandler = { fileHandle in
                let data = fileHandle.availableData
                if data.count > 0, let string = String(data: data, encoding: .utf8) {
                    // Ajouter le nouveau contenu à la sortie complète
                    fullOutput += string
                    
                    // Envoyer la mise à jour via le subject
                    DispatchQueue.main.async {
                        outputSubject.send((id, fullOutput))
                    }
                }
            }
            
            task.standardOutput = pipe
            task.standardError = pipe
            task.launchPath = "/usr/bin/osascript"
            task.arguments = [script.path]
            
            // Enregistrer le processus en cours d'exécution
            DispatchQueue.main.async {
                self.runningProcesses[id] = task
            }
            
            do {
                try task.run()
                
                // Attendre la fin de l'exécution
                task.waitUntilExit()
                
                // Nettoyer le handler de lecture une fois terminé
                outputHandle.readabilityHandler = nil
                
                DispatchQueue.main.async {
                    // S'assurer que la sortie finale est envoyée
                    if fullOutput.isEmpty {
                        outputSubject.send((id, "Exécution terminée avec succès."))
                    }
                    
                    // Supprimer le processus de la liste des processus en cours
                    self.runningProcesses.removeValue(forKey: id)
                    
                    // Compléter le sujet
                    outputSubject.send(completion: .finished)
                }
            } catch {
                // Nettoyer le handler en cas d'erreur
                outputHandle.readabilityHandler = nil
                
                DispatchQueue.main.async {
                    outputSubject.send((id, "Erreur lors de l'exécution: \(error.localizedDescription)"))
                    
                    // Supprimer le processus de la liste des processus en cours
                    self.runningProcesses.removeValue(forKey: id)
                    
                    // Compléter le sujet
                    outputSubject.send(completion: .finished)
                }
            }
        }
        
        return outputSubject.eraseToAnyPublisher()
    }
    
    // Annule l'exécution d'un script
    func cancelScript(id: UUID) {
        if let process = runningProcesses[id] {
            process.terminate()
            runningProcesses.removeValue(forKey: id)
        }
    }
    
    // Vérifie si un script est en cours d'exécution
    func isScriptRunning(id: UUID) -> Bool {
        return runningProcesses[id] != nil
    }
    
    // Annule tous les scripts en cours d'exécution
    func cancelAllScripts() {
        for (_, process) in runningProcesses {
            process.terminate()
        }
        runningProcesses.removeAll()
    }
}