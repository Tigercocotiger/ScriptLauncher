//
//  DMGInstallerCreator.swift
//  ScriptLauncher
//
//  Created on 10/03/2025.
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
    func mountAndExtractInfo(dmgPath: String, completion: @escaping (String?, String?) -> Void) {
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
                    
                    // Si nous avons trouvé un point de montage, chercher les applications
                    if let mountPoint = mountPoint {
                        // Chercher les applications .app dans le volume monté
                        let appPath = self.findAppInMountedVolume(mountPoint)
                        
                        // Extraire seulement le nom du volume à partir du chemin complet
                        let volumeName = mountPoint.replacingOccurrences(of: "/Volumes/", with: "")
                        
                        // Démonter l'image
                        self.unmountDMG(mountPoint)
                        
                        // Appeler le callback avec les informations
                        DispatchQueue.main.async {
                            completion(volumeName, appPath)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(nil, nil)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil, nil)
                    }
                }
            } catch {
                print("Erreur lors du montage du DMG: \(error)")
                DispatchQueue.main.async {
                    completion(nil, nil)
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

// Vue pour créer un script d'installation DMG
struct DMGInstallerCreatorView: View {
    @Binding var isPresented: Bool
    let targetFolder: String
    let onScriptCreated: () -> Void
    
    // État pour le thème
    let isDarkMode: Bool
    
    // Accès au TagsViewModel pour obtenir les tags existants
    @ObservedObject var tagsViewModel = ConfigManager.shared.getTagsViewModel()
    
    // Paramètres du template
    @State private var appName: String = ""
    @State private var description: String = "Script d'installation automatique"
    @State private var author: String = ""
    @State private var sourcePath: String = ""
    @State private var volumeName: String = ""
    @State private var appPath: String = ""
    @State private var createBackup: Bool = false
    
    // État pour les alertes et messages
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isAnalyzingDMG: Bool = false
    
    // Créer une instance du DMGInfoExtractor
    private let dmgExtractor = DMGInfoExtractor()
    
    var body: some View {
        VStack(spacing: 0) {
            // En-tête
            HStack {
                Text("Créer un script d'installation DMG")
                    .font(.headline)
                    .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(DesignSystem.cardBackground(for: isDarkMode))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Description du template
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "arrow.down.app")
                                .font(.title2)
                                .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
                            
                            Text("Installateur d'application DMG")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                        }
                        
                        Text("Ce template permet de créer un script qui automatise l'installation d'une application à partir d'un fichier DMG. Le script montera l'image, copiera l'application dans le dossier Applications, puis démontera l'image.")
                            .font(.body)
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            .padding(.top, 2)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.cardBackground(for: isDarkMode))
                    .cornerRadius(8)
                    
                    // Sélection du fichier DMG
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fichier DMG source")
                            .font(.headline)
                            .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                        
                        HStack {
                            Text(sourcePath.isEmpty ? "Aucun fichier sélectionné" : sourcePath)
                                .font(.subheadline)
                                .foregroundColor(sourcePath.isEmpty ? DesignSystem.textSecondary(for: isDarkMode) : DesignSystem.textPrimary(for: isDarkMode))
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(isDarkMode ? Color(white: 0.2) : Color(white: 0.95))
                                .cornerRadius(6)
                            
                            Button(action: selectDMGFile) {
                                Text("Parcourir")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(DesignSystem.accentColor(for: isDarkMode))
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if isAnalyzingDMG {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                                
                                Text("Analyse du DMG en cours...")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(DesignSystem.cardBackground(for: isDarkMode))
                    .cornerRadius(8)
                    
                    // Paramètres du script
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Paramètres du script")
                            .font(.headline)
                            .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                        
                        // Nom de l'application
                        ParameterTextField(
                            label: "Nom de l'application",
                            placeholder: "Ex: Focusrite Control 2",
                            value: $appName,
                            isDarkMode: isDarkMode
                        )
                        
                        // Description
                        ParameterTextField(
                            label: "Description",
                            placeholder: "Description de ce script d'installation",
                            value: $description,
                            isDarkMode: isDarkMode
                        )
                        
                        // Auteur
                        ParameterTextField(
                            label: "Auteur",
                            placeholder: "Votre nom",
                            value: $author,
                            isDarkMode: isDarkMode
                        )
                        
                        // Nom du volume
                        ParameterTextField(
                            label: "Nom du volume monté",
                            placeholder: "Ex: Focusrite Control 2",
                            value: $volumeName,
                            isDarkMode: isDarkMode
                        )
                        
                        // Chemin de l'application
                        ParameterTextField(
                            label: "Chemin relatif de l'application",
                            placeholder: "Ex: /Focusrite Control 2.app",
                            value: $appPath,
                            isDarkMode: isDarkMode
                        )
                        
                        // Option de sauvegarde
                        Toggle(isOn: $createBackup) {
                            Text("Créer une copie de sauvegarde du DMG dans Documents")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                        }
                        .toggleStyle(SwitchToggleStyle(tint: DesignSystem.accentColor(for: isDarkMode)))
                    }
                    .padding()
                    .background(DesignSystem.cardBackground(for: isDarkMode))
                    .cornerRadius(8)
                    
                    // Bouton pour créer le script
                    Button(action: createScript) {
                        HStack {
                            Image(systemName: "plus.square")
                            Text("Créer le script d'installation")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid() ? DesignSystem.accentColor(for: isDarkMode) : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isFormValid())
                    .padding(.top, 10)
                }
                .padding()
            }
        }
        .frame(width: 700, height: 650)
        .background(DesignSystem.backgroundColor(for: isDarkMode))
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Script créé avec succès"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertMessage.contains("succès") {
                        isPresented = false
                        onScriptCreated()
                    }
                }
            )
        }
    }
    
    // Composant pour un champ de paramètre avec label
    struct ParameterTextField: View {
        let label: String
        let placeholder: String
        var value: Binding<String>
        let isDarkMode: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                
                TextField(placeholder, text: value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // Fonction pour vérifier si le formulaire est valide
    private func isFormValid() -> Bool {
        return !appName.isEmpty &&
               !sourcePath.isEmpty &&
               !volumeName.isEmpty &&
               !appPath.isEmpty
    }
    
    // Fonction pour sélectionner un fichier DMG et extraire ses informations
    private func selectDMGFile() {
        if let dmgPath = dmgExtractor.selectDMGFile() {
            sourcePath = dmgPath
            
            // Extraire le nom de l'application du chemin du DMG
            let url = URL(fileURLWithPath: dmgPath)
            let fileName = url.deletingPathExtension().lastPathComponent
            if appName.isEmpty {
                appName = fileName
            }
            
            // Essayer de deviner le nom du volume
            if let guessedVolumeName = dmgExtractor.getVolumeName(fromDMGPath: dmgPath) {
                volumeName = guessedVolumeName
            }
            
            // Analyser le DMG pour extraire plus d'informations
            isAnalyzingDMG = true
            dmgExtractor.mountAndExtractInfo(dmgPath: dmgPath) { (detectedVolumeName, detectedAppPath) in
                isAnalyzingDMG = false
                
                if let detectedVolumeName = detectedVolumeName {
                    volumeName = detectedVolumeName
                }
                
                if let detectedAppPath = detectedAppPath {
                    appPath = detectedAppPath
                }
            }
        }
    }
    
    // Fonction simplifiée pour créer le script d'installation DMG
    private func createScript() {
        // Générer le contenu du script
        let scriptContent = createDMGInstallerContent()
        
        // Générer le nom de fichier avec extension .scpt
        let fileName = appName.replacingOccurrences(of: " ", with: "_") + "_Installer.scpt"
        let filePath = (targetFolder as NSString).appendingPathComponent(fileName)
        
        // Vérifier si le fichier existe déjà
        if FileManager.default.fileExists(atPath: filePath) {
            // Demander confirmation pour écraser le fichier
            let alert = NSAlert()
            alert.messageText = "Fichier déjà existant"
            alert.informativeText = "Un script nommé '\(fileName)' existe déjà. Voulez-vous l'écraser ?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Écraser")
            alert.addButton(withTitle: "Annuler")
            
            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                return
            }
            
            // Supprimer l'ancien fichier
            do {
                try FileManager.default.removeItem(atPath: filePath)
            } catch {
                print("Erreur lors de la suppression de l'ancien fichier: \(error)")
            }
        }
        
        // Créer le fichier AppleScript
        do {
            // Créer un fichier temporaire pour le contenu
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempFilePath = tempDirectory.appendingPathComponent(UUID().uuidString + ".applescript")
            
            // Écrire le contenu dans le fichier temporaire
            try scriptContent.write(to: tempFilePath, atomically: true, encoding: .utf8)
            
            // Compiler le script AppleScript
            let task = Process()
            task.launchPath = "/usr/bin/osacompile"
            task.arguments = ["-o", filePath, tempFilePath.path]
            
            try task.run()
            task.waitUntilExit()
            
            // Vérifier si la compilation a réussi
            if task.terminationStatus == 0 {
                // Afficher un message de succès
                alertMessage = "Le script d'installation pour \(appName) a été créé avec succès. Vous pouvez maintenant ajouter des tags au script dans la liste principale."
                showAlert = true
                
                // Recharger la liste des scripts
                onScriptCreated()
            } else {
                alertMessage = "Erreur lors de la compilation du script. Vérifiez les paramètres et réessayez."
                showAlert = true
            }
        } catch {
            print("Erreur lors de la création du script: \(error)")
            alertMessage = "Erreur lors de la création du script: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    // Génère le contenu du script d'installation DMG
    private func createDMGInstallerContent() -> String {
        // Formatage de la date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let currentDate = dateFormatter.string(from: Date())
        
        // Code de sauvegarde en fonction de l'option choisie
        let backupCode = createBackup ? "my copyDMGToDocuments()" : "-- Sauvegarde désactivée"
        
        return """
        -- Script d'installation \(appName)
        -- Créé le \(currentDate)
        -- Créé par \(author)
        -- Description: \(description)

        -- Chemin vers le fichier DMG source
        property sourcePath : "\(sourcePath)"

        -- Nom attendu du volume monté
        property mountedVolumeName : "\(volumeName)"

        -- Chemin vers l'application dans le DMG
        property applicationPath : "\(appPath)"

        -- Chemin vers le dossier Documents
        property documentsPath : ""

        -- Chemin vers le dossier Applications
        property appsPath : ""

        -- Fonction pour afficher un log coloré
        on logMessage(message, logType)
            set prefix to ""
            if logType is "info" then
                set prefix to "ℹ️ [INFO] "
            else if logType is "success" then
                set prefix to "✅ [SUCCÈS] "
            else if logType is "warning" then
                set prefix to "⚠️ [ATTENTION] "
            else if logType is "error" then
                set prefix to "❌ [ERREUR] "
            else if logType is "start" then
                set prefix to "🚀 [DÉMARRAGE] "
            else if logType is "process" then
                set prefix to "⏳ [PROCESSUS] "
            end if
            
            log prefix & message
        end logMessage

        -- Initialiser les chemins
        on run
            my logMessage("Démarrage de l'installation de " & "\(appName)" & "...", "start")
            
            -- Obtenir le chemin vers Documents
            tell application "Finder"
                set documentsPath to (path to documents folder as string)
            end tell
            
            -- Obtenir le chemin vers Applications
            tell application "Finder"
                set appsPath to (path to applications folder as string)
            end tell
            
            -- Monter l'image disque
            my logMessage("Lancement du processus d'installation...", "info")
            
            -- Monter l'image disque
            my mountDiskImage()
            
            -- Copier l'application dans le dossier Applications
            my copyApplicationToApplications()
            
            -- Créer une copie de sauvegarde dans Documents (optionnel)
            \(backupCode)
            
            -- Démonter l'image disque
            my unmountDiskImage()
            
            -- Message de confirmation
            my logMessage("Installation terminée avec succès!", "success")
        end run

        -- Fonction pour exécuter des commandes shell avec gestion d'erreur
        on runShellCommand(theCommand)
            try
                do shell script theCommand
                return true
            on error errMsg number errNum
                my logMessage("Erreur " & errNum & " : " & errMsg, "error")
                return false
            end try
        end runShellCommand

        -- Monter l'image disque
        on mountDiskImage()
            my logMessage("Montage de l'image disque...", "process")
            
            set mountCommand to "hdiutil attach '" & sourcePath & "'"
            if not runShellCommand(mountCommand) then
                error "Impossible de monter l'image disque."
            end if
            
            my logMessage("Image disque montée avec succès", "success")
        end mountDiskImage

        -- Copier l'application dans le dossier Applications
        on copyApplicationToApplications()
            my logMessage("Copie de l'application dans le dossier Applications...", "process")
            
            set sourceApp to "/Volumes/" & mountedVolumeName & applicationPath
            set copyCommand to "cp -R '" & sourceApp & "' " & quoted form of (POSIX path of appsPath)
            
            if not runShellCommand(copyCommand) then
                -- Tenter de démonter l'image avant de quitter
                my unmountDiskImage()
                error "Impossible de copier l'application dans le dossier Applications."
            end if
            
            my logMessage("Application copiée avec succès dans " & POSIX path of appsPath, "success")
        end copyApplicationToApplications

        -- Copier le DMG dans Documents pour sauvegarde
        on copyDMGToDocuments()
            my logMessage("Création d'une copie de sauvegarde du DMG dans Documents...", "process")
            
            set copyCommand to "cp '" & sourcePath & "' " & quoted form of (POSIX path of documentsPath)
            
            if not runShellCommand(copyCommand) then
                my logMessage("Impossible de copier le fichier DMG dans Documents. L'installation continue.", "warning")
            else
                my logMessage("Copie de sauvegarde créée avec succès dans " & POSIX path of documentsPath, "success")
            end if
        end copyDMGToDocuments

        -- Démonter l'image disque
        on unmountDiskImage()
            my logMessage("Démontage de l'image disque...", "process")
            try
                do shell script "hdiutil detach '/Volumes/" & mountedVolumeName & "'"
                my logMessage("Image disque démontée avec succès", "success")
            on error
                my logMessage("Impossible de démonter automatiquement l'image disque. Veuillez l'éjecter manuellement.", "warning")
            end try
        end unmountDiskImage
        """
    }
}

// Bouton pour créer un installateur DMG
struct CreateDMGInstallerButton: View {
    @State private var showCreator = false
    let isDarkMode: Bool
    let targetFolder: String
    let onScriptCreated: () -> Void
    
    var body: some View {
        Button(action: {
            showCreator = true
        }) {
            HStack {
                Image(systemName: "arrow.down.app")
                    .font(.system(size: 16))
                Text("Créer installateur DMG")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.buttonHeight)
            .background(DesignSystem.accentColor(for: isDarkMode).opacity(0.85))
            .foregroundColor(.white)
            .cornerRadius(DesignSystem.smallCornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
        .keyboardShortcut("n", modifiers: [.command, .shift])
        .padding(.horizontal, DesignSystem.spacing)
        .padding(.bottom, DesignSystem.spacing)
        .sheet(isPresented: $showCreator) {
            DMGInstallerCreatorView(
                isPresented: $showCreator,
                targetFolder: targetFolder,
                onScriptCreated: onScriptCreated,
                isDarkMode: isDarkMode
            )
        }
    }
}
