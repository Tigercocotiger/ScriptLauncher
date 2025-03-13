//
//  DMGInstallerCreator.swift
//  ScriptLauncher
//
//  Created on 10/03/2025.
//  Updated on 10/03/2025. - Added support for USB relative paths
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
    @State private var createBackup: Bool = true
    
    // Nouveau champ pour le nom du fichier script
    @State private var scriptFileName: String = ""
    @State private var scriptFileNameEdited: Bool = false
    
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
                        .onChange(of: appName) { newValue in
                            // Mettre à jour le nom du fichier seulement si l'utilisateur ne l'a pas modifié
                            if !scriptFileNameEdited && !newValue.isEmpty {
                                scriptFileName = newValue.replacingOccurrences(of: " ", with: "_") + "_Installer"
                            }
                        }
                        
                        // Nouveau champ: Nom du fichier script
                        ParameterTextField(
                            label: "Nom du fichier script (sans extension)",
                            placeholder: "Ex: Focusrite_Control_2_Installer",
                            value: $scriptFileName,
                            isDarkMode: isDarkMode
                        )
                        .onChange(of: scriptFileName) { _ in
                            // Marquer que l'utilisateur a édité ce champ
                            scriptFileNameEdited = true
                        }
                        
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
    
    // Composant TextField personnalisé avec placeholder visible en mode sombre
    struct CustomTextField: View {
        var placeholder: String
        @Binding var text: String
        var isDarkMode: Bool
        
        var body: some View {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(isDarkMode ? Color.white.opacity(0.5) : Color.gray)
                        .padding(.leading, 6)
                }
                
                TextField("", text: $text)
                    .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .background(isDarkMode ? Color(red: 0.3, green: 0.3, blue: 0.32) : Color.white)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isDarkMode ? Color(red: 0.4, green: 0.4, blue: 0.42) : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
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
                
                CustomTextField(placeholder: placeholder, text: value, isDarkMode: isDarkMode)
                    .frame(height: 30)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // Fonction pour vérifier si le formulaire est valide
    private func isFormValid() -> Bool {
        return !appName.isEmpty &&
        !sourcePath.isEmpty &&
        !volumeName.isEmpty &&
        !appPath.isEmpty &&
        !scriptFileName.isEmpty  // Ajouter vérification du nom de fichier
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
            
            // Générer un nom de fichier par défaut si non édité
            if !scriptFileNameEdited && scriptFileName.isEmpty {
                scriptFileName = appName.replacingOccurrences(of: " ", with: "_") + "_Installer"
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
    
    // Fonction pour créer le script d'installation DMG
    private func createScript() {
        // Générer le contenu du script
        let scriptContent = createDMGInstallerContent()
        
        // Générer le nom de fichier avec extension .scpt (maintenant personnalisable)
        let fileName = scriptFileName.replacingOccurrences(of: " ", with: "_") + ".scpt"
        
        // Utiliser le dossier de scripts dans Resources
        let scriptsFolderPath = ConfigManager.shared.getScriptsFolderPath()
        let filePath = (scriptsFolderPath as NSString).appendingPathComponent(fileName)
        
        // Créer un dossier DMG pour stocker les images disques
        let dmgFolderPath = (scriptsFolderPath as NSString).appendingPathComponent("DMG")
        if !FileManager.default.fileExists(atPath: dmgFolderPath) {
            do {
                try FileManager.default.createDirectory(at: URL(fileURLWithPath: dmgFolderPath),
                                                        withIntermediateDirectories: true)
            } catch {
                print("Erreur lors de la création du dossier DMG: \(error)")
            }
        }
        
        // Copier le DMG dans le dossier DMG si nécessaire
        let dmgFileName = URL(fileURLWithPath: sourcePath).lastPathComponent
        let destDMGPath = (dmgFolderPath as NSString).appendingPathComponent(dmgFileName)
        
        if sourcePath != destDMGPath {
            do {
                // Si le fichier existe déjà, le supprimer d'abord
                if FileManager.default.fileExists(atPath: destDMGPath) {
                    try FileManager.default.removeItem(atPath: destDMGPath)
                }
                
                // Copier le fichier
                try FileManager.default.copyItem(atPath: sourcePath, toPath: destDMGPath)
            } catch {
                print("Erreur lors de la copie du DMG: \(error)")
                
                // Afficher un avertissement mais continuer
                let alert = NSAlert()
                alert.messageText = "Avertissement"
                alert.informativeText = "Le fichier DMG source n'a pas pu être copié dans le dossier de scripts. Le script créé utilisera le chemin original."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Continuer")
                alert.runModal()
            }
        }
        
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
                alertMessage = "Le script d'installation pour \(appName) a été créé avec succès sous le nom '\(fileName)'. Vous pouvez maintenant ajouter des tags au script dans la liste principale."
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
    
    // Génère le contenu du script d'installation DMG avec des chemins relatifs
    // Génère le contenu du script d'installation DMG avec des chemins relatifs
    private func createDMGInstallerContent() -> String {
        // Formatage de la date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let currentDate = dateFormatter.string(from: Date())
        
        // Nom du fichier DMG sans le chemin complet
        let dmgFileName = URL(fileURLWithPath: sourcePath).lastPathComponent
        
        return """
        -- Script d'installation \(appName)
        -- Créé le \(currentDate)
        -- Créé par \(author)
        -- Description: \(description)

        -- Variables et fonctions définies pour ce script
        property mountedVolumeName : "\(volumeName)"
        property applicationPath : "\(appPath)"
        property dmgFileName : "\(dmgFileName)"

        -- Exécution principale du script
        on run
            -- Variables locales à l'exécution
            set dmgPath to ""
            set documentsPath to ""
            set appsPath to ""
            
            try
                my logMessage("Démarrage de l'installation de " & "\(appName)" & "...", "start")
                
                -- Trouver le fichier DMG
                set dmgPath to my findDMGFile()
                if dmgPath is false or dmgPath is "" then
                    error "Installation annulée: Impossible de trouver le fichier DMG."
                end if
                
                -- Chemins standards
                set documentsPath to POSIX path of (path to documents folder)
                set appsPath to POSIX path of (path to applications folder)
                
                -- Monter l'image disque
                my logMessage("Montage de l'image disque: " & dmgPath, "process")
                set mountResult to my mountDMG(dmgPath)
                if mountResult is false then
                    error "Impossible de monter l'image disque."
                end if
                
                -- Copier l'application
                my logMessage("Copie de l'application dans Applications...", "process")
                set sourceApp to "/Volumes/" & mountedVolumeName & applicationPath
                set copyResult to my copyApp(sourceApp, appsPath)
                if copyResult is false then
                    my unmountDMG(mountedVolumeName)
                    error "Impossible de copier l'application dans le dossier Applications."
                end if
                
                -- Sauvegarde optionnelle
                if "\(createBackup)" is "true" then
                    my logMessage("Sauvegarde du DMG dans Documents...", "process")
                    my copyDMGToDocuments(dmgPath, documentsPath)
                end if
                
                -- Démonter l'image
                my unmountDMG(mountedVolumeName)
                
                -- Nettoyer les fichiers temporaires
                my cleanupTemporaryFiles()
                
                -- Succès !
                my logMessage("Installation terminée avec succès!", "success")
                return "Installation terminée."
            on error errMsg
                my logMessage("Erreur: " & errMsg, "error")
                
                -- Tenter de nettoyer
                my cleanupTemporaryFiles()
                
                display dialog "L'installation a échoué: " & errMsg buttons {"OK"} default button "OK" with icon stop
                return "Installation échouée."
            end try
        end run

        -- Fonction pour trouver le fichier DMG
        on findDMGFile()
            -- Obtenir le dossier du script
            set myPath to POSIX path of (path to me)
            set lastSlash to my lastIndexOf(myPath, "/")
            if lastSlash is not false then
                set scriptFolder to text 1 thru lastSlash of myPath
                
                -- Essayer dans le sous-dossier DMG
                set dmgInSubfolder to scriptFolder & "DMG/" & dmgFileName
                if my fileExists(dmgInSubfolder) then
                    return dmgInSubfolder
                end if
                
                -- Essayer dans le même dossier que le script
                set dmgInSameFolder to scriptFolder & dmgFileName
                if my fileExists(dmgInSameFolder) then
                    return dmgInSameFolder
                end if
            end if
            
            -- Demander à l'utilisateur
            my logMessage("DMG non trouvé automatiquement. Sélection manuelle requise.", "warning")
            
            set userPrompt to "Le fichier DMG n'a pas été trouvé automatiquement. Voulez-vous le sélectionner manuellement?"
            set userChoice to button returned of (display dialog userPrompt buttons {"Annuler", "Sélectionner"} default button "Sélectionner")
            
            if userChoice is "Sélectionner" then
                try
                    set selectedFile to POSIX path of (choose file with prompt "Sélectionnez le fichier DMG à installer:" of type {"com.apple.disk-image"})
                    return selectedFile
                on error
                    return false
                end try
            else
                return false
            end if
        end findDMGFile
        
        -- Fonction améliorée pour monter le DMG avec repli
        on mountDMG(dmgPath)
            try
                -- Essayer d'abord la méthode simple avec agreeToLicense
                my logMessage("Tentative de montage direct avec acceptation de licence...", "process")
                do shell script "hdiutil attach " & quoted form of dmgPath & " -nobrowse -noverify -agreeToLicense"
                
                -- Vérifier si le volume est monté
                delay 2
                set volumePath to "/Volumes/" & mountedVolumeName
                if my fileExists(volumePath) then
                    my logMessage("Montage réussi avec la méthode simple", "success")
                    return true
                end if
                
                -- Si on arrive ici, c'est que le volume n'est pas monté malgré la commande réussie
                error "Volume non trouvé après montage simple"
            on error errMsg
                -- Méthode simple a échoué, passer à la méthode de conversion
                my logMessage("Montage simple échoué: " & errMsg, "warning")
                my logMessage("Tentative avec conversion du DMG...", "process")
                
                try
                    -- Nettoyage préventif
                    do shell script "rm -f /tmp/converted_dmg.dmg"
                    
                    -- Convertir et monter
                    do shell script "hdiutil convert " & quoted form of dmgPath & " -format UDRW -o \"/tmp/converted_dmg\" && hdiutil attach \"/tmp/converted_dmg.dmg\""
                    
                    -- Vérifier si le volume est monté
                    delay 2
                    set volumePath to "/Volumes/" & mountedVolumeName
                    if my fileExists(volumePath) then
                        my logMessage("Montage réussi avec la méthode de conversion", "success")
                        return true
                    else
                        error "Volume non trouvé après conversion et montage"
                    end if
                on error conversionErr
                    my logMessage("Échec de toutes les méthodes de montage: " & conversionErr, "error")
                    return false
                end try
            end try
        end mountDMG
        
        -- Fonction pour copier l'application
        on copyApp(sourceApp, appsPath)
            try
                do shell script "cp -R " & quoted form of sourceApp & " " & quoted form of appsPath
                return true
            on error errMsg
                my logMessage("Erreur de copie: " & errMsg, "error")
                return false
            end try
        end copyApp
        
        -- Fonction pour créer une copie de sauvegarde du DMG
        on copyDMGToDocuments(dmgPath, documentsPath)
            try
                do shell script "cp " & quoted form of dmgPath & " " & quoted form of documentsPath
                my logMessage("Copie de sauvegarde créée avec succès dans Documents", "success")
                return true
            on error errMsg
                my logMessage("Erreur de sauvegarde: " & errMsg, "warning")
                return false
            end try
        end copyDMGToDocuments
        
        -- Fonction pour démonter le volume
        on unmountDMG(volumeName)
            try
                do shell script "hdiutil detach '/Volumes/" & volumeName & "' -force"
                my logMessage("Image disque démontée avec succès", "success")
                return true
            on error
                my logMessage("Impossible de démonter automatiquement l'image disque. Veuillez l'éjecter manuellement.", "warning")
                return false
            end try
        end unmountDMG
        
        -- Fonction pour nettoyer les fichiers temporaires
        on cleanupTemporaryFiles()
            try
                do shell script "rm -f /tmp/converted_dmg.dmg"
                my logMessage("Fichiers temporaires nettoyés", "info")
            on error
                -- Ignorer les erreurs de nettoyage
            end try
        end cleanupTemporaryFiles
        
        -- Utilitaire pour trouver la dernière occurrence d'un caractère dans une chaîne
        on lastIndexOf(inputString, searchChar)
            set AppleScript's text item delimiters to searchChar
            set itemList to text items of inputString
            if (count of itemList) is 1 then
                return false -- Le caractère n'existe pas dans la chaîne
            else
                set textLength to length of inputString
                set lastItem to last item of itemList
                return textLength - (length of lastItem) - (length of searchChar) + 1
            end if
        end lastIndexOf
        
        -- Vérifie si un fichier existe
        on fileExists(filePath)
            try
                do shell script "test -e " & quoted form of filePath
                return true
            on error
                return false
            end try
        end fileExists

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
            -- Ajouter cette ligne pour imprimer également à stdout
            do shell script "echo " & quoted form of (prefix & message)
        end logMessage
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
