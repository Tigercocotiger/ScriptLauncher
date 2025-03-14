//
//  DMGInfoExtractor.swift
//  ScriptLauncher
//
//  Created on 10/03/2025.
//  Updated on 16/03/2025. - Added package detection
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// Classe pour extraire des informations de fichiers DMG
class DMGInfoExtractor {
    // Fonction pour sélectionner un fichier DMG
    func selectDMGFile() -> String? {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [UTType.diskImage]
        openPanel.message = "Sélectionnez un fichier DMG à installer"
        openPanel.prompt = "Sélectionner"
        
        guard openPanel.runModal() == .OK, let dmgURL = openPanel.url else {
            return nil
        }
        
        return dmgURL.path
    }
    
    // Fonction pour obtenir le nom présumé du volume à partir du DMG
    func getVolumeName(fromDMGPath dmgPath: String) -> String? {
        // Extraire le nom de fichier sans extension
        let fileURL = URL(fileURLWithPath: dmgPath)
        let volumeName = fileURL.deletingPathExtension().lastPathComponent
        
        return volumeName
    }
    
    // Fonction pour monter temporairement le DMG et extraire des informations
    func mountAndExtractInfo(dmgPath: String, completion: @escaping (String?, String?, DMGScriptGenerator.InstallationType) -> Void) {
        // Créer une tâche pour monter l'image
        let task = Process()
        task.launchPath = "/usr/bin/hdiutil"
        task.arguments = ["attach", dmgPath]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        // Exécuter en arrière-plan pour ne pas bloquer l'interface
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try task.run()
                task.waitUntilExit()
                
                if task.terminationStatus == 0 {
                    // L'image a été montée avec succès
                    // Obtenir le nom du volume monté
                    let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                    
                    // Analyser la sortie pour trouver le point de montage
                    var mountPoint: String?
                    let lines = output.components(separatedBy: "\n")
                    for line in lines {
                        if line.contains("/Volumes/") {
                            let components = line.components(separatedBy: "/Volumes/")
                            if components.count > 1 {
                                mountPoint = "/Volumes/" + components[1]
                                break
                            }
                        }
                    }
                    
                    // Si nous avons trouvé un point de montage, chercher les applications ou packages
                    if let mountPoint = mountPoint {
                        // Extraire seulement le nom du volume à partir du chemin complet
                        let volumeName = mountPoint.replacingOccurrences(of: "/Volumes/", with: "")
                        
                        // Chercher d'abord les fichiers .pkg dans le volume monté
                        if let pkgPath = self.findPackageInMountedVolume(mountPoint) {
                            print("🔍 Fichier PKG détecté: \(pkgPath)")
                            
                            // Démonter l'image
                            self.unmountDMG(mountPoint)
                            
                            // Appeler le callback avec les informations et le type PACKAGE
                            DispatchQueue.main.async {
                                completion(volumeName, pkgPath, .package)
                            }
                        }
                        // Si pas de pkg, chercher les applications .app
                        else if let appPath = self.findAppInMountedVolume(mountPoint) {
                            // Démonter l'image
                            self.unmountDMG(mountPoint)
                            
                            // Appeler le callback avec les informations et le type APPLICATION
                            DispatchQueue.main.async {
                                completion(volumeName, appPath, .application)
                            }
                        }
                        // Ni app ni pkg trouvé
                        else {
                            // Démonter l'image
                            self.unmountDMG(mountPoint)
                            
                            DispatchQueue.main.async {
                                completion(volumeName, nil, .unknown)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(nil, nil, .unknown)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil, nil, .unknown)
                    }
                }
            } catch {
                print("Erreur lors du montage du DMG: \(error)")
                DispatchQueue.main.async {
                    completion(nil, nil, .unknown)
                }
            }
        }
    }
    
    // Fonction pour trouver les applications .app dans un volume monté
    private func findAppInMountedVolume(_ mountPoint: String) -> String? {
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(atPath: mountPoint)
            
            // Chercher les fichiers .app
            for file in files {
                if file.hasSuffix(".app") {
                    // Retourner uniquement le chemin relatif de l'application
                    return "/" + file
                }
            }
            
            return nil
        } catch {
            print("Erreur lors de l'analyse du volume monté: \(error)")
            return nil
        }
    }
    
    // Nouvelle fonction pour trouver les packages .pkg dans un volume monté
    private func findPackageInMountedVolume(_ mountPoint: String) -> String? {
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(atPath: mountPoint)
            
            // Chercher les fichiers .pkg
            for file in files {
                if file.hasSuffix(".pkg") {
                    // Retourner uniquement le chemin relatif du package
                    return "/" + file
                }
            }
            
            return nil
        } catch {
            print("Erreur lors de l'analyse du volume monté pour les packages: \(error)")
            return nil
        }
    }
    
    // Fonction pour démonter le DMG
    private func unmountDMG(_ mountPoint: String) {
        let task = Process()
        task.launchPath = "/usr/bin/hdiutil"
        task.arguments = ["detach", mountPoint]
        
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("Erreur lors du démontage du DMG: \(error)")
        }
    }
}
