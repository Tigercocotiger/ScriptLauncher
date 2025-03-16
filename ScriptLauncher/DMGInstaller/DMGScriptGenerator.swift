//
//  DMGScriptGenerator.swift
//  ScriptLauncher
//
//  Created on 15/03/2025.
//  Updated on 16/03/2025. - Added PKG installation support
//

import Foundation

// Classe responsable de la génération du contenu du script AppleScript
class DMGScriptGenerator {
    
    // Type d'installation
    enum InstallationType {
        case application
        case package
        case unknown
    }
    
    // Structure pour stocker les paramètres du script
    struct ScriptParameters {
        let appName: String
        let description: String
        let author: String
        let volumeName: String
        let targetPath: String  // Chemin de l'app ou du pkg
        let dmgFileName: String
        let createBackup: Bool
        let installationType: InstallationType
    }
    
    // Fonction principale pour générer le contenu du script
    static func generateScript(params: ScriptParameters) -> String {
        switch params.installationType {
        case .application:
            return generateAppInstallScript(params: params)
        case .package:
            return generatePkgInstallScript(params: params)
        case .unknown:
            // Par défaut, utiliser le template d'application
            return generateAppInstallScript(params: params)
        }
    }
    
    // Génère un script pour installer une application
    private static func generateAppInstallScript(params: ScriptParameters) -> String {
        // Formatage de la date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let currentDate = dateFormatter.string(from: Date())
        
        // Variable booléenne sous forme de chaîne
        let createBackupStr = params.createBackup ? "true" : "false"
        
        // Génération du script pour application
        return """
        -- Script d'installation \(params.appName)
        -- Créé le \(currentDate)
        -- Créé par \(params.author)
        -- Description: \(params.description)
        
        -- Variables et fonctions définies pour ce script
        property mountedVolumeName : "\(params.volumeName)"
        property applicationPath : "\(params.targetPath)"
        property dmgFileName : "\(params.dmgFileName)"
        
        -- Exécution principale du script
        on run
        \t-- Variables locales à l'exécution
        \tset dmgPath to ""
        \tset documentsPath to ""
        \tset appsPath to ""
        \t
        \ttry
        \t\tmy logMessage("Démarrage de l'installation de " & "\(params.appName)" & "...", "start")
        \t\t\t\t
        \t\t-- Trouver le fichier DMG
        \t\tset dmgPath to my findDMGFile()
        \t\tif dmgPath is false or dmgPath is "" then
        \t\t\terror "Installation annulée: Impossible de trouver le fichier DMG."
        \t\tend if
        \t\t\t\t
        \t\t-- Chemins standards
        \t\tset documentsPath to POSIX path of (path to documents folder)
        \t\tset appsPath to POSIX path of (path to applications folder)
        \t\t\t\t
        \t\t-- Monter l'image disque en utilisant la méthode de conversion
        \t\tmy logMessage("Montage de l'image disque: " & dmgPath, "process")
        \t\tset mountResult to my mountDMGWithConversion(dmgPath)
        \t\tif mountResult is false then
        \t\t\terror "Impossible de monter l'image disque."
        \t\tend if
        \t\t\t\t
        \t\t-- Copier l'application
        \t\tmy logMessage("Copie de l'application dans Applications...", "process")
        \t\tset sourceApp to "/Volumes/" & mountedVolumeName & applicationPath
        \t\tset copyResult to my copyApp(sourceApp, appsPath)
        \t\tif copyResult is false then
        \t\t\tmy unmountDMG(mountedVolumeName)
        \t\t\terror "Impossible de copier l'application dans le dossier Applications."
        \t\tend if
        \t\t\t\t
        \t\t-- Sauvegarde optionnelle
        \t\tif "\(createBackupStr)" is "true" then
        \t\t\tmy logMessage("Sauvegarde du DMG dans Documents...", "process")
        \t\t\tmy copyDMGToDocuments(dmgPath, documentsPath)
        \t\tend if
        \t\t\t\t
        \t\t-- Démonter l'image
        \t\tmy unmountDMG(mountedVolumeName)
        \t\t\t\t
        \t\t-- Nettoyer les fichiers temporaires
        \t\tmy cleanupTemporaryFiles()
        \t\t\t\t
        \t\t-- Succès !
        \t\tmy logMessage("Installation terminée avec succès!", "success")
        \t\treturn "Installation terminée."
        \ton error errMsg
        \t\tmy logMessage("Erreur: " & errMsg, "error")
        \t\tmy cleanupTemporaryFiles()
        \t\tdisplay dialog "L'installation a échoué: " & errMsg buttons {"OK"} default button "OK" with icon stop
        \t\treturn "Installation échouée."
        \tend try
        end run
        
        -- Fonction pour monter le DMG avec conversion pour éviter la licence
        on mountDMGWithConversion(dmgPath)
        \ttry
        \t\t-- Convertir et monter le DMG en une seule étape
        \t\tmy logMessage("Conversion du DMG pour contourner la licence...", "process")
        \t\tdo shell script "rm -f /tmp/dmg_converted.dmg && hdiutil convert " & quoted form of dmgPath & " -format UDRW -o \\"/tmp/dmg_converted\\" && hdiutil attach \\"/tmp/dmg_converted.dmg\\""
        \t\t\t\t
        \t\t-- Attendre un peu que le système monte le volume
        \t\tdelay 2
        \t\t\t\t
        \t\t-- Vérifier si le volume est monté
        \t\tset volumePath to "/Volumes/" & mountedVolumeName
        \t\tset isVolumeMounted to my fileExists(volumePath)
        \t\t\t\t
        \t\tif isVolumeMounted then
        \t\t\tmy logMessage("Volume monté avec succès à " & volumePath, "success")
        \t\t\treturn true
        \t\telse
        \t\t\terror "Le volume n'a pas été monté correctement après conversion."
        \t\tend if
        \ton error errMsg
        \t\tmy logMessage("Erreur de montage: " & errMsg, "error")
        \t\treturn false
        \tend try
        end mountDMGWithConversion
        
        -- Fonction pour nettoyer les fichiers temporaires
        on cleanupTemporaryFiles()
        \ttry
        \t\tdo shell script "rm -f /tmp/dmg_converted.dmg"
        \t\tmy logMessage("Fichiers temporaires nettoyés", "info")
        \ton error
        \t\tmy logMessage("Impossible de nettoyer certains fichiers temporaires", "warning")
        \tend try
        end cleanupTemporaryFiles
        
        -- Fonction pour trouver le fichier DMG
        on findDMGFile()
        \t-- Obtenir le dossier du script
        \tset myPath to POSIX path of (path to me)
        \tset lastSlash to my lastIndexOf(myPath, "/")
        \tif lastSlash is not false then
        \t\tset scriptFolder to text 1 thru lastSlash of myPath
        \t\t\t\t
        \t\t-- Essayer dans le sous-dossier DMG
        \t\tset dmgInSubfolder to scriptFolder & "DMG/" & dmgFileName
        \t\tif my fileExists(dmgInSubfolder) then
        \t\t\treturn dmgInSubfolder
        \t\tend if
        \t\t\t\t
        \t\t-- Essayer dans le même dossier que le script
        \t\tset dmgInSameFolder to scriptFolder & dmgFileName
        \t\tif my fileExists(dmgInSameFolder) then
        \t\t\treturn dmgInSameFolder
        \t\tend if
        \tend if
        \t\t
        \t-- Demander à l'utilisateur
        \tmy logMessage("DMG non trouvé automatiquement. Sélection manuelle requise.", "warning")
        \t\t
        \tset userPrompt to "Le fichier DMG n'a pas été trouvé automatiquement. Voulez-vous le sélectionner manuellement?"
        \tset userChoice to button returned of (display dialog userPrompt buttons {"Annuler", "Sélectionner"} default button "Sélectionner")
        \t\t
        \tif userChoice is "Sélectionner" then
        \t\ttry
        \t\t\tset selectedFile to POSIX path of (choose file with prompt "Sélectionnez le fichier DMG à installer:" of type {"com.apple.disk-image"})
        \t\t\treturn selectedFile
        \t\ton error
        \t\t\treturn false
        \t\tend try
        \telse
        \t\treturn false
        \tend if
        end findDMGFile
        
        -- Fonction pour monter le DMG (gardée pour compatibilité, mais non utilisée)
        on mountDMG(dmgPath)
        \ttry
        \t\tdo shell script "hdiutil attach " & quoted form of dmgPath
        \t\treturn true
        \ton error errMsg
        \t\tmy logMessage("Erreur de montage: " & errMsg, "error")
        \t\treturn false
        \tend try
        end mountDMG
        
        -- Fonction pour copier l'application
        on copyApp(sourceApp, appsPath)
        \ttry
        \t\tdo shell script "cp -R " & quoted form of sourceApp & " " & quoted form of appsPath
        \t\treturn true
        \ton error errMsg
        \t\tmy logMessage("Erreur de copie: " & errMsg, "error")
        \t\treturn false
        \tend try
        end copyApp
        
        -- Fonction pour créer une copie de sauvegarde du DMG
        on copyDMGToDocuments(dmgPath, documentsPath)
        \ttry
        \t\tdo shell script "cp " & quoted form of dmgPath & " " & quoted form of documentsPath
        \t\tmy logMessage("Copie de sauvegarde créée avec succès dans Documents", "success")
        \t\treturn true
        \ton error errMsg
        \t\tmy logMessage("Erreur de sauvegarde: " & errMsg, "warning")
        \t\treturn false
        \tend try
        end copyDMGToDocuments
        
        -- Fonction pour démonter le volume
        on unmountDMG(volumeName)
        \ttry
        \t\tdo shell script "hdiutil detach '/Volumes/" & volumeName & "' -force"
        \t\tmy logMessage("Image disque démontée avec succès", "success")
        \t\treturn true
        \ton error
        \t\tmy logMessage("Impossible de démonter automatiquement l'image disque. Veuillez l'éjecter manuellement.", "warning")
        \t\treturn false
        \tend try
        end unmountDMG
        
        -- Utilitaire pour trouver la dernière occurrence d'un caractère dans une chaîne
        on lastIndexOf(inputString, searchChar)
        \tset AppleScript's text item delimiters to searchChar
        \tset itemList to text items of inputString
        \tif (count of itemList) is 1 then
        \t\treturn false -- Le caractère n'existe pas dans la chaîne
        \telse
        \t\tset textLength to length of inputString
        \t\tset lastItem to last item of itemList
        \t\treturn textLength - (length of lastItem) - (length of searchChar) + 1
        \tend if
        end lastIndexOf
        
        -- Vérifie si un fichier existe
        on fileExists(filePath)
        \ttry
        \t\tdo shell script "test -e " & quoted form of filePath
        \t\treturn true
        \ton error
        \t\treturn false
        \tend try
        end fileExists
        
        -- Fonction pour afficher un log coloré
        on logMessage(message, logType)
        \tset prefix to ""
        \tif logType is "info" then
        \t\tset prefix to "ℹ️ [INFO] "
        \telse if logType is "success" then
        \t\tset prefix to "✅ [SUCCÈS] "
        \telse if logType is "warning" then
        \t\tset prefix to "⚠️ [ATTENTION] "
        \telse if logType is "error" then
        \t\tset prefix to "❌ [ERREUR] "
        \telse if logType is "start" then
        \t\tset prefix to "🚀 [DÉMARRAGE] "
        \telse if logType is "process" then
        \t\tset prefix to "⏳ [PROCESSUS] "
        \tend if
        \t\t
        \tlog prefix & message
        \t-- Ajouter cette ligne pour imprimer également à stdout
        \tdo shell script "echo " & quoted form of (prefix & message)
        end logMessage
        """
    }
    
    // Génère un script pour installer un package
    private static func generatePkgInstallScript(params: ScriptParameters) -> String {
        // Formatage de la date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let currentDate = dateFormatter.string(from: Date())
        
        // Variable booléenne sous forme de chaîne
        let createBackupStr = params.createBackup ? "true" : "false"
        
        // Génération du script pour package
        return """
        -- Script d'installation package \(params.appName)
        -- Créé le \(currentDate)
        -- Créé par \(params.author)
        -- Description: \(params.description)
        
        -- Variables et fonctions définies pour ce script
        property mountedVolumeName : "\(params.volumeName)"
        property packagePath : "\(params.targetPath)"
        property dmgFileName : "\(params.dmgFileName)"
        
        -- Exécution principale du script
        on run
        \t-- Variables locales à l'exécution
        \tset dmgPath to ""
        \tset documentsPath to ""
        \t
        \ttry
        \t\tmy logMessage("Démarrage de l'installation du package " & "\(params.appName)" & "...", "start")
        \t\t\t\t
        \t\t-- Trouver le fichier DMG
        \t\tset dmgPath to my findDMGFile()
        \t\tif dmgPath is false or dmgPath is "" then
        \t\t\terror "Installation annulée: Impossible de trouver le fichier DMG."
        \t\tend if
        \t\t\t\t
        \t\t-- Chemins standards
        \t\tset documentsPath to POSIX path of (path to documents folder)
        \t\t\t\t
        \t\t-- Monter l'image disque en utilisant la méthode de conversion
        \t\tmy logMessage("Montage de l'image disque: " & dmgPath, "process")
        \t\tset mountResult to my mountDMGWithConversion(dmgPath)
        \t\tif mountResult is false then
        \t\t\terror "Impossible de monter l'image disque."
        \t\tend if
        \t\t\t\t
        \t\t-- Installer le package
        \t\tmy logMessage("Installation du package...", "process")
        \t\tset sourcePkg to "/Volumes/" & mountedVolumeName & packagePath
        \t\tset installResult to my installPackage(sourcePkg)
        \t\tif installResult is false then
        \t\t\tmy unmountDMG(mountedVolumeName)
        \t\t\terror "Impossible d'installer le package."
        \t\tend if
        \t\t\t\t
        \t\t-- Sauvegarde optionnelle
        \t\tif "\(createBackupStr)" is "true" then
        \t\t\tmy logMessage("Sauvegarde du DMG dans Documents...", "process")
        \t\t\tmy copyDMGToDocuments(dmgPath, documentsPath)
        \t\tend if
        \t\t\t\t
        \t\t-- Démonter l'image
        \t\tmy unmountDMG(mountedVolumeName)
        \t\t\t\t
        \t\t-- Nettoyer les fichiers temporaires
        \t\tmy cleanupTemporaryFiles()
        \t\t\t\t
        \t\t-- Succès !
        \t\tmy logMessage("Installation terminée avec succès!", "success")
        \t\treturn "Installation terminée."
        \ton error errMsg
        \t\tmy logMessage("Erreur: " & errMsg, "error")
        \t\tmy cleanupTemporaryFiles()
        \t\tdisplay dialog "L'installation a échoué: " & errMsg buttons {"OK"} default button "OK" with icon stop
        \t\treturn "Installation échouée."
        \tend try
        end run
        
        -- Fonction pour monter le DMG avec conversion pour éviter la licence
        on mountDMGWithConversion(dmgPath)
        \ttry
        \t\t-- Convertir et monter le DMG en une seule étape
        \t\tmy logMessage("Conversion du DMG pour contourner la licence...", "process")
        \t\tdo shell script "rm -f /tmp/dmg_converted.dmg && hdiutil convert " & quoted form of dmgPath & " -format UDRW -o \\"/tmp/dmg_converted\\" && hdiutil attach \\"/tmp/dmg_converted.dmg\\""
        \t\t\t\t
        \t\t-- Attendre un peu que le système monte le volume
        \t\tdelay 2
        \t\t\t\t
        \t\t-- Vérifier si le volume est monté
        \t\tset volumePath to "/Volumes/" & mountedVolumeName
        \t\tset isVolumeMounted to my fileExists(volumePath)
        \t\t\t\t
        \t\tif isVolumeMounted then
        \t\t\tmy logMessage("Volume monté avec succès à " & volumePath, "success")
        \t\t\treturn true
        \t\telse
        \t\t\terror "Le volume n'a pas été monté correctement après conversion."
        \t\tend if
        \ton error errMsg
        \t\tmy logMessage("Erreur de montage: " & errMsg, "error")
        \t\treturn false
        \tend try
        end mountDMGWithConversion
        
        -- Fonction pour nettoyer les fichiers temporaires
        on cleanupTemporaryFiles()
        \ttry
        \t\tdo shell script "rm -f /tmp/dmg_converted.dmg"
        \t\tmy logMessage("Fichiers temporaires nettoyés", "info")
        \ton error
        \t\tmy logMessage("Impossible de nettoyer certains fichiers temporaires", "warning")
        \tend try
        end cleanupTemporaryFiles
        
        -- Fonction pour trouver le fichier DMG
        on findDMGFile()
        \t-- Obtenir le dossier du script
        \tset myPath to POSIX path of (path to me)
        \tset lastSlash to my lastIndexOf(myPath, "/")
        \tif lastSlash is not false then
        \t\tset scriptFolder to text 1 thru lastSlash of myPath
        \t\t\t\t
        \t\t-- Essayer dans le sous-dossier DMG
        \t\tset dmgInSubfolder to scriptFolder & "DMG/" & dmgFileName
        \t\tif my fileExists(dmgInSubfolder) then
        \t\t\treturn dmgInSubfolder
        \t\tend if
        \t\t\t\t
        \t\t-- Essayer dans le même dossier que le script
        \t\tset dmgInSameFolder to scriptFolder & dmgFileName
        \t\tif my fileExists(dmgInSameFolder) then
        \t\t\treturn dmgInSameFolder
        \t\tend if
        \tend if
        \t\t
        \t-- Demander à l'utilisateur
        \tmy logMessage("DMG non trouvé automatiquement. Sélection manuelle requise.", "warning")
        \t\t
        \tset userPrompt to "Le fichier DMG n'a pas été trouvé automatiquement. Voulez-vous le sélectionner manuellement?"
        \tset userChoice to button returned of (display dialog userPrompt buttons {"Annuler", "Sélectionner"} default button "Sélectionner")
        \t\t
        \tif userChoice is "Sélectionner" then
        \t\ttry
        \t\t\tset selectedFile to POSIX path of (choose file with prompt "Sélectionnez le fichier DMG à installer:" of type {"com.apple.disk-image"})
        \t\t\treturn selectedFile
        \t\ton error
        \t\t\treturn false
        \t\tend try
        \telse
        \t\treturn false
        \tend if
        end findDMGFile
        
        -- Fonction pour installer le package avec mot de passe prédéfini
        on installPackage(packagePath)
            try
                -- Définir le mot de passe administrateur directement dans le script
                set adminPassword to "    " -- Mot de passe composé de 4 espaces
                
                my logMessage("Installation du package...", "process")
                
                -- Exécuter la commande d'installation avec le mot de passe fourni
                do shell script "installer -pkg " & quoted form of packagePath & " -target /" password adminPassword with administrator privileges
                
                my logMessage("Package installé avec succès", "success")
                return true
            on error errMsg
                my logMessage("Erreur lors de l'installation du package: " & errMsg, "error")
                return false
            end try
        end installPackage
        
        -- Fonction pour créer une copie de sauvegarde du DMG
        on copyDMGToDocuments(dmgPath, documentsPath)
        \ttry
        \t\tdo shell script "cp " & quoted form of dmgPath & " " & quoted form of documentsPath
        \t\tmy logMessage("Copie de sauvegarde créée avec succès dans Documents", "success")
        \t\treturn true
        \ton error errMsg
        \t\tmy logMessage("Erreur de sauvegarde: " & errMsg, "warning")
        \t\treturn false
        \tend try
        end copyDMGToDocuments
        
        -- Fonction pour démonter le volume
        on unmountDMG(volumeName)
        \ttry
        \t\tdo shell script "hdiutil detach '/Volumes/" & volumeName & "' -force"
        \t\tmy logMessage("Image disque démontée avec succès", "success")
        \t\treturn true
        \ton error
        \t\tmy logMessage("Impossible de démonter automatiquement l'image disque. Veuillez l'éjecter manuellement.", "warning")
        \t\treturn false
        \tend try
        end unmountDMG
        
        -- Utilitaire pour trouver la dernière occurrence d'un caractère dans une chaîne
        on lastIndexOf(inputString, searchChar)
        \tset AppleScript's text item delimiters to searchChar
        \tset itemList to text items of inputString
        \tif (count of itemList) is 1 then
        \t\treturn false -- Le caractère n'existe pas dans la chaîne
        \telse
        \t\tset textLength to length of inputString
        \t\tset lastItem to last item of itemList
        \t\treturn textLength - (length of lastItem) - (length of searchChar) + 1
        \tend if
        end lastIndexOf
        
        -- Vérifie si un fichier existe
        on fileExists(filePath)
        \ttry
        \t\tdo shell script "test -e " & quoted form of filePath
        \t\treturn true
        \ton error
        \t\treturn false
        \tend try
        end fileExists
        
        -- Fonction pour afficher un log coloré
        on logMessage(message, logType)
        \tset prefix to ""
        \tif logType is "info" then
        \t\tset prefix to "ℹ️ [INFO] "
        \telse if logType is "success" then
        \t\tset prefix to "✅ [SUCCÈS] "
        \telse if logType is "warning" then
        \t\tset prefix to "⚠️ [ATTENTION] "
        \telse if logType is "error" then
        \t\tset prefix to "❌ [ERREUR] "
        \telse if logType is "start" then
        \t\tset prefix to "🚀 [DÉMARRAGE] "
        \telse if logType is "process" then
        \t\tset prefix to "⏳ [PROCESSUS] "
        \tend if
        \t\t
        \tlog prefix & message
        \t-- Ajouter cette ligne pour imprimer également à stdout
        \tdo shell script "echo " & quoted form of (prefix & message)
        end logMessage
        """
    }
    
    // Fonction pour compiler et enregistrer le script AppleScript
    static func compileAndSaveScript(content: String, filePath: String) async throws -> Bool {
        // Créer un fichier temporaire pour le contenu
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFilePath = tempDirectory.appendingPathComponent(UUID().uuidString + ".applescript")
        
        // Écrire le contenu dans le fichier temporaire
        try content.write(to: tempFilePath, atomically: true, encoding: .utf8)
        
        // Compiler le script AppleScript
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osacompile")
        task.arguments = ["-o", filePath, tempFilePath.path]
        
        let pipe = Pipe()
        task.standardError = pipe
        
        try task.run()
        task.waitUntilExit()
        
        // Capturer toute erreur de sortie
        let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
        let errorText = String(data: errorData, encoding: .utf8) ?? ""
        
        // Vérifier si la compilation a réussi
        let compilationSuccess = (task.terminationStatus == 0)
        
        // Nettoyer les fichiers temporaires
        try FileManager.default.removeItem(at: tempFilePath)
        
        // Si la compilation a échoué et qu'il y a un message d'erreur, lancer une exception
        if !compilationSuccess && !errorText.isEmpty {
            throw NSError(
                domain: "DMGScriptGenerator",
                code: Int(task.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "Erreur de compilation: \(errorText)"]
            )
        }
        
        return compilationSuccess
    }
}
