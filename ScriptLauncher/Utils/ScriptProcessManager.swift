//
//  ScriptProcessManager.swift
//  ScriptLauncher
//
//  Updated for ScriptLauncher on 04/03/2025.
//  Updated on 10/03/2025. - Added support for relative paths
//  Updated on 13/03/2025. - Added support for capturing AppleScript logs
//

import Foundation
import Combine

class ScriptProcessManager: ObservableObject {
    @Published var runningProcesses: [UUID: Process] = [:]
    
    // Exécute un script et retourne un publisher avec sa sortie et son statut
    func executeScript(script: ScriptFile) -> AnyPublisher<(UUID, String, ScriptStatus?, Date?), Never> {
        let id = script.id
        let outputSubject = PassthroughSubject<(UUID, String, ScriptStatus?, Date?), Never>()
        
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
                    
                    // Envoyer la mise à jour via le subject sans changer l'état
                    DispatchQueue.main.async {
                        outputSubject.send((id, fullOutput, nil, nil))
                    }
                }
            }
            
            task.standardOutput = pipe
            task.standardError = pipe
            
            // Résoudre le chemin du script si c'est un chemin relatif
            let scriptPath = ConfigManager.shared.resolveRelativePath(script.path)
            
            // Utiliser osascript avec l'option -s o pour afficher les logs
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-s", "o", scriptPath] // "o" pour output les logs à stdout
            
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
                    // Déterminer le statut final basé sur le code de sortie
                    let finalStatus: ScriptStatus = task.terminationStatus == 0 ? .completed : .failed
                    let endTime = Date()
                    
                    // S'assurer que la sortie finale est envoyée
                    if fullOutput.isEmpty {
                        fullOutput = finalStatus == .completed
                            ? "Exécution terminée avec succès."
                            : "Script terminé avec des erreurs (code: \(task.terminationStatus))"
                    }
                    
                    // Envoyer la mise à jour finale avec le statut et l'heure de fin
                    outputSubject.send((id, fullOutput, finalStatus, endTime))
                    
                    // Supprimer le processus de la liste des processus en cours
                    self.runningProcesses.removeValue(forKey: id)
                    
                    // Compléter le sujet
                    outputSubject.send(completion: .finished)
                }
            } catch {
                // Nettoyer le handler en cas d'erreur
                outputHandle.readabilityHandler = nil
                
                DispatchQueue.main.async {
                    let errorOutput = "Erreur lors de l'exécution: \(error.localizedDescription)"
                    let endTime = Date()
                    
                    outputSubject.send((id, errorOutput, .failed, endTime))
                    
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
