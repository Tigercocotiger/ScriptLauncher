//
//  DMGInstallerCreatorView.swift
//  ScriptLauncher
//
//  Created on 10/03/2025.
//  Updated on 16/03/2025. - Added support for PKG installation
//

import SwiftUI
import AppKit
import Combine

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
    @State private var isCreatingScript: Bool = false
    
    // Stockage du dernier type d'installation détecté
    @State private var lastDetectedInstallationType: DMGScriptGenerator.InstallationType?
    @State private var installationTypeText: String = "Application (.app)"
    
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
                    InstallerSectionView(isDarkMode: isDarkMode) {
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
                                
                            // Afficher le type d'installation détecté
                            if let installationType = lastDetectedInstallationType {
                                HStack {
                                    Image(systemName: installationType == .application ? "app.badge" : "doc.badge")
                                        .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
                                    
                                    Text("Type détecté : \(installationTypeText)")
                                        .font(.callout)
                                        .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
                                        .fontWeight(.medium)
                                }
                                .padding(.top, 6)
                            }
                        }
                    }
                    
                    // Sélection du fichier DMG
                    InstallerSectionView(title: "Fichier DMG source", isDarkMode: isDarkMode) {
                        VStack(alignment: .leading, spacing: 12) {
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
                                .disabled(isAnalyzingDMG || isCreatingScript)
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
                    }
                    
                    // Paramètres du script
                    InstallerSectionView(title: "Paramètres du script", isDarkMode: isDarkMode) {
                        VStack(alignment: .leading, spacing: 16) {
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
                            
                            // Chemin de l'application ou du package
                            ParameterTextField(
                                label: lastDetectedInstallationType == .package ? "Chemin relatif du package" : "Chemin relatif de l'application",
                                placeholder: lastDetectedInstallationType == .package ? "Ex: /Install.pkg" : "Ex: /Focusrite Control 2.app",
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
                    }
                    
                    // Bouton pour créer le script
                    Button(action: createScript) {
                        HStack {
                            if isCreatingScript {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            } else {
                                Image(systemName: "plus.square")
                                    .padding(.trailing, 4)
                            }
                            
                            Text(isCreatingScript ? "Création en cours..." : "Créer le script d'installation")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid() && !isCreatingScript ? DesignSystem.accentColor(for: isDarkMode) : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isFormValid() || isCreatingScript || isAnalyzingDMG)
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
    
    // Fonction pour vérifier si le formulaire est valide
    private func isFormValid() -> Bool {
        return !appName.isEmpty &&
        !sourcePath.isEmpty &&
        !volumeName.isEmpty &&
        !appPath.isEmpty &&
        !scriptFileName.isEmpty
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
            dmgExtractor.mountAndExtractInfo(dmgPath: dmgPath) { (detectedVolumeName, detectedPath, installationType) in
                isAnalyzingDMG = false
                
                // Stocker le type d'installation détecté
                lastDetectedInstallationType = installationType
                
                // Mettre à jour le texte du type d'installation
                switch installationType {
                case .application:
                    installationTypeText = "Application (.app)"
                case .package:
                    installationTypeText = "Package d'installation (.pkg)"
                case .unknown:
                    installationTypeText = "Type inconnu"
                }
                
                if let detectedVolumeName = detectedVolumeName {
                    volumeName = detectedVolumeName
                }
                
                if let detectedPath = detectedPath {
                    appPath = detectedPath
                }
            }
        }
    }
    
    // Fonction pour créer le script d'installation DMG
    func createScript() {
        // Indiquer que la création est en cours
        isCreatingScript = true
        
        // Générer le nom de fichier avec extension .scpt
        let fileName = scriptFileName.replacingOccurrences(of: " ", with: "_") + ".scpt"
        
        // Utiliser le dossier de scripts dans Resources
        let scriptsFolderPath = ConfigManager.shared.getScriptsFolderPath()
        let filePath = (scriptsFolderPath as NSString).appendingPathComponent(fileName)
        
        // Créer un dossier DMG pour stocker les images disques
        let dmgFolderPath = (scriptsFolderPath as NSString).appendingPathComponent("DMG")
        
        // Exécuter la création du script en arrière-plan
        Task {
            // Créer le dossier DMG s'il n'existe pas déjà
            if !FileManager.default.fileExists(atPath: dmgFolderPath) {
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: dmgFolderPath),
                                                           withIntermediateDirectories: true)
                } catch {
                    print("Erreur lors de la création du dossier DMG: \(error)")
                    updateUIAfterFailure(with: "Erreur lors de la création du dossier DMG: \(error.localizedDescription)")
                    return
                }
            }
            
            // Copier le DMG dans le dossier DMG si nécessaire
            let dmgFileName = URL(fileURLWithPath: sourcePath).lastPathComponent
            let destDMGPath = (dmgFolderPath as NSString).appendingPathComponent(dmgFileName)
            
            var dmgCopySuccess = true
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
                    dmgCopySuccess = false
                }
            }
            
            // Vérifier si le fichier script existe déjà
            var shouldContinue = true
            if FileManager.default.fileExists(atPath: filePath) {
                // Demander confirmation pour écraser le fichier
                let alert = NSAlert()
                alert.messageText = "Fichier déjà existant"
                alert.informativeText = "Un script nommé '\(fileName)' existe déjà. Voulez-vous l'écraser ?"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Écraser")
                alert.addButton(withTitle: "Annuler")
                
                let response = alert.runModal()
                shouldContinue = (response == .alertFirstButtonReturn)
                
                // Si l'utilisateur a annulé, arrêter le processus
                if !shouldContinue {
                    updateUIAfterFailure(with: "")
                    return
                }
                
                // Supprimer l'ancien fichier
                do {
                    try FileManager.default.removeItem(atPath: filePath)
                } catch {
                    print("Erreur lors de la suppression de l'ancien fichier: \(error)")
                    updateUIAfterFailure(with: "Erreur lors de la suppression de l'ancien fichier: \(error.localizedDescription)")
                    return
                }
            }
            
            // Créer les paramètres du script en fonction du type d'installation détecté
            let installationType: DMGScriptGenerator.InstallationType
            if let detectedType = lastDetectedInstallationType {
                installationType = detectedType
            } else {
                // Par défaut, utiliser le type d'application
                installationType = .application
            }
            
            // Créer le contenu du script
            let scriptParams = DMGScriptGenerator.ScriptParameters(
                appName: appName,
                description: description,
                author: author,
                volumeName: volumeName,
                targetPath: appPath,
                dmgFileName: dmgFileName,
                createBackup: createBackup,
                installationType: installationType
            )
            
            let scriptContent = DMGScriptGenerator.generateScript(params: scriptParams)
            
            // Compiler et enregistrer le script
            do {
                let success = try await DMGScriptGenerator.compileAndSaveScript(content: scriptContent, filePath: filePath)
                
                if success {
                    // Afficher un message de succès
                    await MainActor.run {
                        let installTypeStr = (installationType == .application) ? "application" : "package"
                        alertMessage = "Le script d'installation pour \(appName) (\(installTypeStr)) a été créé avec succès sous le nom '\(fileName)'."
                        if !dmgCopySuccess {
                            alertMessage += "\n\nAttention: Le fichier DMG source n'a pas pu être copié dans le dossier de scripts."
                        }
                        showAlert = true
                        isCreatingScript = false
                    }
                } else {
                    updateUIAfterFailure(with: "La compilation du script a échoué sans erreur spécifique.")
                }
            } catch {
                updateUIAfterFailure(with: error.localizedDescription)
            }
        }
    }
    
    // Mettre à jour l'interface après un échec
    @MainActor
    private func updateUIAfterFailure(with errorMessage: String) {
        isCreatingScript = false
        
        if !errorMessage.isEmpty {
            let alert = NSAlert()
            alert.messageText = "Erreur lors de la création du script"
            alert.informativeText = errorMessage
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

// MARK: - Preview
#Preview("DMGInstallerCreatorView") {
    DMGInstallerCreatorView(
        isPresented: .constant(true),
        targetFolder: "/Users/test/Scripts",
        onScriptCreated: {},
        isDarkMode: false
    )
}

#Preview("DMGInstallerCreatorView - Dark Mode") {
    DMGInstallerCreatorView(
        isPresented: .constant(true),
        targetFolder: "/Users/test/Scripts",
        onScriptCreated: {},
        isDarkMode: true
    )
    .preferredColorScheme(.dark)
}
