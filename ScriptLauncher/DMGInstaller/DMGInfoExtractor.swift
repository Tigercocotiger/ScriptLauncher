import SwiftUI
import AppKit
import UniformTypeIdentifiers
import Combine

// Structure pour les mises à jour de progression
struct DMGAnalysisProgress {
    let progress: CGFloat  // 0.0 - 1.0
    let message: String
    let completed: Bool
    let volumeName: String?
    let appPath: String?
    let installationType: DMGScriptGenerator.InstallationType?
}

// Classe pour extraire des informations de fichiers DMG
class DMGInfoExtractor: ObservableObject {
    // Publisher pour les mises à jour de progression
    @Published var analysisProgress = DMGAnalysisProgress(
        progress: 0,
        message: "Préparation...",
        completed: false,
        volumeName: nil,
        appPath: nil,
        installationType: nil
    )
    
    // Propriété pour garder trace des fichiers temporaires à nettoyer
    private var tempConvertedDMG: String?
    
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
        // Réinitialiser l'état de progression
        updateProgress(0.1, message: "Initialisation de l'analyse...")
        
        // Créer une tâche pour exécuter en arrière-plan
        DispatchQueue.global(qos: .userInitiated).async {
            // Obtenir le nom présumé du volume
            let presumedVolumeName = self.getVolumeName(fromDMGPath: dmgPath) ?? "UnknownVolume"
            
            // Mise à jour de la progression
            self.updateProgress(0.2, message: "Préparation du DMG...")
            
            // Utiliser la technique de conversion pour éviter les invites
            let randomID = UUID().uuidString
            let tempFileName = "/tmp/dmg_info_\(randomID)"
            let tempDMGPath = "\(tempFileName).dmg"
            
            do {
                print("🔍 Conversion du DMG pour analyse sans invite...")
                
                // Mise à jour de la progression
                self.updateProgress(0.3, message: "Conversion du DMG...")
                
                // Convertir le DMG en format UDRW et le monter
                let process = Process()
                process.launchPath = "/bin/bash"
                process.arguments = [
                    "-c",
                    "hdiutil convert \"\(dmgPath)\" -format UDRW -o \"\(tempFileName)\" && hdiutil attach \"\(tempDMGPath)\""
                ]
                
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe
                
                try process.run()
                process.waitUntilExit()
                
                // Sauvegarder le chemin du fichier temporaire pour le nettoyage
                self.tempConvertedDMG = tempDMGPath
                
                // Mise à jour de la progression
                self.updateProgress(0.5, message: "Montage du volume...")
                
                // Attendre que le montage soit complet
                Thread.sleep(forTimeInterval: 2.0)
                
                // Trouver le point de montage à partir de la sortie du processus
                let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                print("🔍 Sortie du montage: \(output)")
                
                // Variables pour stocker les informations de montage détectées
                var mountPoint: String? = nil
                var actualVolumeName: String? = nil
                
                // CORRECTION IMPORTANTE: Analyser la dernière ligne qui contient souvent le point de montage réel
                let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
                if let lastLine = lines.last {
                    // Chercher une ligne de forme "/dev/diskX /Volumes/VolumeName"
                    let components = lastLine.split(separator: " ").map { String($0) }
                    if components.count >= 2, components[0].contains("/dev/disk"),
                       components.last?.contains("/Volumes/") == true {
                        mountPoint = components.last ?? ""
                        actualVolumeName = mountPoint?.replacingOccurrences(of: "/Volumes/", with: "")
                        print("🔍 Point de montage détecté depuis la sortie: \(mountPoint ?? "inconnu")")
                    }
                }
                
                // Si nous n'avons pas trouvé le point de montage, utiliser des méthodes alternatives
                if mountPoint == nil {
                    // Mise à jour de la progression
                    self.updateProgress(0.6, message: "Recherche du volume monté...")
                    
                    // Option 1: Chercher le volume présumé
                    if FileManager.default.fileExists(atPath: "/Volumes/\(presumedVolumeName)") {
                        mountPoint = "/Volumes/\(presumedVolumeName)"
                        actualVolumeName = presumedVolumeName
                        print("🔍 Volume trouvé par nom présumé: \(mountPoint!)")
                    } else {
                        // Option 2: Lister tous les volumes et trouver le plus récent
                        do {
                            let volumesPath = "/Volumes"
                            let volumesContent = try FileManager.default.contentsOfDirectory(atPath: volumesPath)
                            
                            // Filtrer les volumes de système connus
                            let knownSystemVolumes = ["Macintosh HD", "Preboot", "Recovery", "VM", "Update"]
                            let possibleVolumes = volumesContent.filter {
                                !knownSystemVolumes.contains($0)
                            }
                            
                            if let volume = possibleVolumes.first {
                                mountPoint = "/Volumes/\(volume)"
                                actualVolumeName = volume
                                print("🔍 Volume trouvé en listant /Volumes: \(mountPoint!)")
                            }
                        } catch {
                            print("❌ Erreur lors de la liste des volumes: \(error)")
                        }
                    }
                }
                
                // Vérifier que le mountPoint est valide
                if let mountPoint = mountPoint, let volumeName = actualVolumeName,
                   FileManager.default.fileExists(atPath: mountPoint) {
                    print("🔍 Volume monté trouvé: \(volumeName) à \(mountPoint)")
                    
                    // Mise à jour de la progression
                    self.updateProgress(0.7, message: "Recherche d'applications et packages...")
                    
                    // Chercher d'abord les fichiers .pkg dans le volume monté
                    if let pkgPath = self.findPackageInMountedVolume(mountPoint) {
                        print("🔍 Fichier PKG détecté: \(pkgPath)")
                        
                        // Mise à jour de la progression
                        self.updateProgress(0.8, message: "Package détecté: " + (pkgPath.components(separatedBy: "/").last ?? ""))
                        
                        // Démonter l'image
                        self.unmountDMG(mountPoint)
                        
                        // Mise à jour finale de la progression et complétion
                        self.completeAnalysis(
                            progress: 1.0,
                            message: "Analyse terminée avec succès",
                            volumeName: volumeName,
                            appPath: pkgPath,
                            installationType: .package
                        )
                        
                        // Appeler le callback avec les informations et le type PACKAGE
                        DispatchQueue.main.async {
                            completion(volumeName, pkgPath, .package)
                        }
                    }
                    // Si pas de pkg, chercher les applications .app
                    else if let appPath = self.findAppInMountedVolume(mountPoint) {
                        print("🔍 Application détectée: \(appPath)")
                        
                        // Mise à jour de la progression
                        self.updateProgress(0.8, message: "Application détectée: " + (appPath.components(separatedBy: "/").last ?? ""))
                        
                        // Démonter l'image
                        self.unmountDMG(mountPoint)
                        
                        // Mise à jour finale de la progression et complétion
                        self.completeAnalysis(
                            progress: 1.0,
                            message: "Analyse terminée avec succès",
                            volumeName: volumeName,
                            appPath: appPath,
                            installationType: .application
                        )
                        
                        // Appeler le callback avec les informations et le type APPLICATION
                        DispatchQueue.main.async {
                            completion(volumeName, appPath, .application)
                        }
                    }
                    // Ni app ni pkg trouvé
                    else {
                        print("🔍 Aucune application ou package trouvé dans \(mountPoint)")
                        
                        // Mise à jour de la progression
                        self.updateProgress(0.8, message: "Aucune application ou package détecté")
                        
                        // Démonter l'image
                        self.unmountDMG(mountPoint)
                        
                        // Mise à jour finale de la progression et complétion
                        self.completeAnalysis(
                            progress: 1.0,
                            message: "Analyse terminée - aucune application trouvée",
                            volumeName: volumeName,
                            appPath: nil,
                            installationType: .unknown
                        )
                        
                        DispatchQueue.main.async {
                            completion(volumeName, nil, .unknown)
                        }
                    }
                } else {
                    print("❌ Impossible de déterminer le point de montage")
                    
                    // Mise à jour de la progression
                    self.updateProgress(0.8, message: "Erreur: impossible de monter le volume")
                    
                    // Nettoyer les fichiers temporaires
                    self.cleanupTemporaryFiles()
                    
                    // Tenter un nettoyage manuel des volumes potentiellement montés
                    self.cleanupOrphanedVolumes()
                    
                    // Mise à jour finale de la progression
                    self.completeAnalysis(
                        progress: 1.0,
                        message: "Erreur: échec du montage du DMG",
                        volumeName: nil,
                        appPath: nil,
                        installationType: nil
                    )
                    
                    DispatchQueue.main.async {
                        completion(nil, nil, .unknown)
                    }
                }
            } catch {
                print("❌ Erreur lors du montage du DMG: \(error)")
                
                // Mise à jour de la progression
                self.updateProgress(0.8, message: "Erreur: \(error.localizedDescription)")
                
                // Nettoyer les fichiers temporaires
                self.cleanupTemporaryFiles()
                
                // Tenter un nettoyage manuel des volumes potentiellement montés
                self.cleanupOrphanedVolumes()
                
                // Mise à jour finale de la progression
                self.completeAnalysis(
                    progress: 1.0,
                    message: "Erreur: échec de l'analyse",
                    volumeName: nil,
                    appPath: nil,
                    installationType: nil
                )
                
                DispatchQueue.main.async {
                    completion(nil, nil, .unknown)
                }
            }
        }
    }
    
    // Méthode pour mettre à jour la progression sur le thread principal
    private func updateProgress(_ progress: CGFloat, message: String) {
        DispatchQueue.main.async {
            self.analysisProgress = DMGAnalysisProgress(
                progress: progress,
                message: message,
                completed: false,
                volumeName: self.analysisProgress.volumeName,
                appPath: self.analysisProgress.appPath,
                installationType: self.analysisProgress.installationType
            )
        }
    }
    
    // Méthode pour compléter l'analyse avec les résultats
    private func completeAnalysis(progress: CGFloat, message: String, volumeName: String?, appPath: String?, installationType: DMGScriptGenerator.InstallationType?) {
        DispatchQueue.main.async {
            self.analysisProgress = DMGAnalysisProgress(
                progress: progress,
                message: message,
                completed: true,
                volumeName: volumeName,
                appPath: appPath,
                installationType: installationType
            )
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
                    print("🔍 Application trouvée dans le volume: \(file)")
                    // Retourner uniquement le chemin relatif de l'application
                    return "/" + file
                }
            }
            
            // Recherche dans les sous-dossiers communs
            let commonSubfolders = ["Applications", "app", "Installer", "Install"]
            for subfolder in commonSubfolders {
                let subfolderPath = "\(mountPoint)/\(subfolder)"
                if fileManager.fileExists(atPath: subfolderPath) {
                    do {
                        let subFiles = try fileManager.contentsOfDirectory(atPath: subfolderPath)
                        for file in subFiles {
                            if file.hasSuffix(".app") {
                                print("🔍 Application trouvée dans le sous-dossier \(subfolder): \(file)")
                                return "/\(subfolder)/\(file)"
                            }
                        }
                    } catch {
                        print("⚠️ Erreur lors de l'analyse du sous-dossier \(subfolder): \(error)")
                    }
                }
            }
            
            return nil
        } catch {
            print("❌ Erreur lors de l'analyse du volume monté: \(error)")
            return nil
        }
    }
    
    // Fonction pour trouver les packages .pkg dans un volume monté
    private func findPackageInMountedVolume(_ mountPoint: String) -> String? {
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(atPath: mountPoint)
            
            // Chercher les fichiers .pkg
            for file in files {
                if file.hasSuffix(".pkg") {
                    print("🔍 Package trouvé dans le volume: \(file)")
                    // Retourner uniquement le chemin relatif du package
                    return "/" + file
                }
            }
            
            // Recherche dans les sous-dossiers communs
            let commonSubfolders = ["Installer", "Install", "Packages"]
            for subfolder in commonSubfolders {
                let subfolderPath = "\(mountPoint)/\(subfolder)"
                if fileManager.fileExists(atPath: subfolderPath) {
                    do {
                        let subFiles = try fileManager.contentsOfDirectory(atPath: subfolderPath)
                        for file in subFiles {
                            if file.hasSuffix(".pkg") {
                                print("🔍 Package trouvé dans le sous-dossier \(subfolder): \(file)")
                                return "/\(subfolder)/\(file)"
                            }
                        }
                    } catch {
                        print("⚠️ Erreur lors de l'analyse du sous-dossier \(subfolder): \(error)")
                    }
                }
            }
            
            return nil
        } catch {
            print("❌ Erreur lors de l'analyse du volume monté pour les packages: \(error)")
            return nil
        }
    }
    
    // Fonction pour démonter le DMG
    private func unmountDMG(_ mountPoint: String) {
        // Mise à jour de la progression
        self.updateProgress(0.9, message: "Démontage du volume...")
        
        let task = Process()
        task.launchPath = "/usr/bin/hdiutil"
        task.arguments = ["detach", mountPoint, "-force"]
        
        do {
            try task.run()
            task.waitUntilExit()
            print("✅ Image démontée: \(mountPoint)")
            
            // Nettoyer les fichiers temporaires
            cleanupTemporaryFiles()
        } catch {
            print("⚠️ Erreur lors du démontage du DMG: \(error)")
            
            // En cas d'erreur, essayer une méthode plus agressive de démontage
            do {
                let forceProcess = Process()
                forceProcess.launchPath = "/usr/bin/hdiutil"
                forceProcess.arguments = ["unmount", "force", mountPoint]
                try forceProcess.run()
                forceProcess.waitUntilExit()
                print("✅ Image démontée avec force: \(mountPoint)")
            } catch {
                print("⚠️ Échec du démontage forcé: \(error)")
            }
            
            // Même en cas d'erreur, essayer de nettoyer
            cleanupTemporaryFiles()
        }
    }
    
    // Fonction pour nettoyer les volumes orphelins
    private func cleanupOrphanedVolumes() {
        do {
            let volumesPath = "/Volumes"
            let contents = try FileManager.default.contentsOfDirectory(atPath: volumesPath)
            
            // Systèmes de fichiers connus qui ne doivent pas être démontés
            let knownVolumes = ["Macintosh HD", "Preboot", "Recovery", "VM", "Update"]
            
            for item in contents {
                if !knownVolumes.contains(item) {
                    let volumePath = "\(volumesPath)/\(item)"
                    
                    // Tenter de démonter chaque volume non système
                    do {
                        let process = Process()
                        process.launchPath = "/usr/bin/hdiutil"
                        process.arguments = ["detach", volumePath, "-force"]
                        try process.run()
                        process.waitUntilExit()
                        print("🧹 Volume orphelin nettoyé: \(volumePath)")
                    } catch {
                        print("⚠️ Impossible de démonter le volume orphelin \(volumePath): \(error)")
                    }
                }
            }
        } catch {
            print("⚠️ Erreur lors de la tentative de nettoyage des volumes orphelins: \(error)")
        }
    }
    
    // Fonction pour nettoyer les fichiers temporaires
    private func cleanupTemporaryFiles() {
        if let tempPath = tempConvertedDMG {
            do {
                try FileManager.default.removeItem(atPath: tempPath)
                print("🧹 Fichier temporaire nettoyé: \(tempPath)")
            } catch {
                print("⚠️ Impossible de supprimer le fichier temporaire: \(error)")
            }
            
            // Réinitialiser la référence
            tempConvertedDMG = nil
        }
        
        // Nettoyage supplémentaire de tous les fichiers temporaires qui pourraient traîner
        do {
            let process = Process()
            process.launchPath = "/bin/bash"
            process.arguments = ["-c", "rm -f /tmp/dmg_info_*.dmg"]
            try process.run()
            process.waitUntilExit()
        } catch {
            print("⚠️ Erreur lors du nettoyage des fichiers temporaires supplémentaires: \(error)")
        }
    }
}
