//
//  ScriptProcessManager.swift
//  ScriptLauncher
//
//  Updated for ScriptLauncher on 04/03/2025.
//  Updated on 10/03/2025. - Added support for relative paths
//  Updated on 13/03/2025. - Added support for capturing AppleScript logs
//  Updated on 14/03/2025. - Fixed log capture issues and function organization
//

import Foundation
import Combine

class ScriptProcessManager: ObservableObject {
    @Published var runningProcesses: [UUID: Process] = [:]
    
    // Exécute un script et retourne un publisher avec sa sortie et son statut
    func executeScript(script: ScriptFile) -> AnyPublisher<(UUID, String, ScriptStatus?, Date?), Never> {
        // TRÈS IMPORTANT: Utiliser l'ID du ScriptFile original sans en créer un nouveau
        let id = script.id
        print("[ProcessManager] Exécution du script: \(script.name) avec ID: \(id)")
        
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
                
                // Si nous avons des données et qu'elles ne sont pas vides
                if data.count > 0, let string = String(data: data, encoding: .utf8) {
                    // Important: Utiliser DispatchQueue.main pour les mises à jour UI
                    DispatchQueue.main.async {
                        // Ajouter le nouveau contenu à la sortie complète
                        fullOutput += string
                        
                        // Debug pour voir les données reçues
                        print("[ProcessManager] Données reçues (\(data.count) octets): \(string.trimmingCharacters(in: .whitespacesAndNewlines))")
                        
                        // Envoyer la mise à jour via le subject sans changer l'état
                        // IMPORTANT: Utiliser l'ID d'origine ici
                        outputSubject.send((id, fullOutput, nil, nil))
                    }
                } else if data.count == 0 {
                    // Si data.count est 0, c'est généralement un signal de fin de pipe
                    // On ne fait rien ici car l'exécution se terminera normalement
                    print("[ProcessManager] Fin du flux de données détectée")
                    outputHandle.readabilityHandler = nil
                }
            }
            
            task.standardOutput = pipe
            task.standardError = pipe
            
            // Résoudre le chemin du script si c'est un chemin relatif
            let scriptPath = ConfigManager.shared.resolveRelativePath(script.path)
            
            // Utiliser osascript avec l'option -s o pour afficher les logs
            task.launchPath = "/usr/bin/osascript"
            
            // Utiliser des options différentes selon le type de fichier
            if scriptPath.hasSuffix(".scpt") {
                // Pour les fichiers compilés .scpt, utiliser -s o pour capturer les logs
                task.arguments = ["-s", "o", scriptPath]
            } else {
                // Pour les fichiers .applescript non compilés
                task.arguments = ["-s", "o", scriptPath]
            }
            
            // Enregistrer le processus en cours d'exécution
            DispatchQueue.main.async {
                self.runningProcesses[id] = task
            }
            
            do {
                // Ajouter un log pour debug
                print("[ProcessManager] Exécution du script: \(scriptPath) avec arguments: \(task.arguments ?? [])")
                
                try task.run()
                
                // Attendre la fin de l'exécution
                task.waitUntilExit()
                
                // Nettoyer le handler de lecture une fois terminé
                outputHandle.readabilityHandler = nil
                
                // Essayer de lire les dernières données disponibles
                let finalData = outputHandle.readDataToEndOfFile()
                if finalData.count > 0, let finalOutput = String(data: finalData, encoding: .utf8) {
                    fullOutput += finalOutput
                }
                
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
                    
                    print("[ProcessManager] Exécution terminée avec statut: \(finalStatus)")
                    
                    // Envoyer la mise à jour finale avec le statut et l'heure de fin
                    // IMPORTANT: Utiliser l'ID d'origine ici aussi
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
                    
                    print("[ProcessManager] Erreur d'exécution: \(error.localizedDescription)")
                    
                    // IMPORTANT: Utiliser l'ID d'origine ici aussi
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
            print("[ProcessManager] Script avec ID \(id) annulé")
        }
    }
    
    // Vérifie si un script est en cours d'exécution
    func isScriptRunning(id: UUID) -> Bool {
        return runningProcesses[id] != nil
    }
    
    // Annule tous les scripts en cours d'exécution
    func cancelAllScripts() {
        let count = runningProcesses.count
        for (_, process) in runningProcesses {
            process.terminate()
        }
        runningProcesses.removeAll()
        print("[ProcessManager] \(count) scripts annulés")
    }
}
