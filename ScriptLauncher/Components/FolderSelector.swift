//
//  FolderSelector.swift
//  ScriptLauncher
//
//  Created on 05/03/2025.
//  Updated on 10/03/2025. - Added support for relative paths
//

import SwiftUI
import AppKit

struct FolderSelector: View {
    let currentPath: String
    let isDarkMode: Bool
    let onFolderSelected: (String) -> Void
    
    // Propriété calculée pour afficher le chemin
    private var displayPath: String {
        // Si c'est un chemin relatif USB, l'afficher de manière plus lisible
        if currentPath.hasPrefix("$USB") {
            return "[RACINE CLÉ USB]" + currentPath.dropFirst(4)
        }
        return currentPath
    }
    
    var body: some View {
        HStack {
            Text("Dossier cible:")
                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                .font(.system(size: 14))
            
            Text(displayPath)
                .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isDarkMode ? Color(white: 0.3) : Color(red: 0.95, green: 0.95, blue: 0.97))
                .cornerRadius(4)
            
            Button(action: selectFolder) {
                Image(systemName: "folder.badge.gearshape")
                    .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
            }
            .buttonStyle(IconButtonStyle(isDarkMode: isDarkMode))
            .help("Changer de dossier cible")
            
            // Nouveau bouton pour détecter la racine de la clé USB
            Button(action: detectUSBRoot) {
                Image(systemName: "externaldrive.fill")
                    .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
            }
            .buttonStyle(IconButtonStyle(isDarkMode: isDarkMode))
            .help("Utiliser la racine de la clé USB")
        }
        .padding(.horizontal, DesignSystem.spacing)
        .padding(.vertical, 8)
        .background(isDarkMode ? Color.black.opacity(0.2) : Color.gray.opacity(0.05))
    }
    
    private func selectFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        
        // Commencer dans le dossier actuel si possible
                // Résoudre le chemin si c'est un chemin relatif
                let resolvedPath = ConfigManager.shared.resolveRelativePath(currentPath)
                if let url = URL(string: "file://" + resolvedPath), FileManager.default.fileExists(atPath: resolvedPath) {
                    openPanel.directoryURL = url
                }
                
                openPanel.message = "Sélectionnez un dossier contenant des scripts AppleScript"
                openPanel.prompt = "Sélectionner"
                
                if openPanel.runModal() == .OK, let url = openPanel.url {
                    // Vérifier que le dossier contient des scripts
                    if ConfigManager.shared.isValidScriptFolder(url.path) {
                        // Convertir en chemin relatif si possible pour le stockage
                        let pathToStore = ConfigManager.shared.convertToRelativePath(url.path) ?? url.path
                        onFolderSelected(pathToStore)
                    } else {
                        // Afficher une alerte si le dossier ne contient pas de scripts
                        let alert = NSAlert()
                        alert.messageText = "Dossier invalide"
                        alert.informativeText = "Le dossier sélectionné ne contient pas de scripts (.scpt ou .applescript). Veuillez choisir un autre dossier."
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
            }
            
            // Nouvelle fonction pour utiliser la racine de la clé USB automatiquement
            private func detectUSBRoot() {
                // Vérifier si nous sommes sur une clé USB
                if let usbName = ConfigManager.shared.getCurrentUSBDriveName() {
                    let usbRootPath = "/Volumes/\(usbName)"
                    
                    // Vérifier si le dossier contient des scripts
                    if ConfigManager.shared.isValidScriptFolder(usbRootPath) {
                        // Utiliser le format spécial pour les chemins relatifs à la racine USB
                        onFolderSelected("$USB")
                    } else {
                        // Vérifier s'il y a un dossier Scripts à la racine
                        let scriptsFolder = usbRootPath + "/Scripts"
                        if FileManager.default.fileExists(atPath: scriptsFolder) &&
                           ConfigManager.shared.isValidScriptFolder(scriptsFolder) {
                            onFolderSelected("$USB/Scripts")
                        } else {
                            // Afficher une alerte si aucun script n'est trouvé
                            let alert = NSAlert()
                            alert.messageText = "Aucun script trouvé"
                            alert.informativeText = "Aucun script n'a été trouvé à la racine de la clé USB. Voulez-vous créer un dossier Scripts?"
                            alert.alertStyle = .informational
                            alert.addButton(withTitle: "Oui")
                            alert.addButton(withTitle: "Non")
                            
                            let response = alert.runModal()
                            if response == .alertFirstButtonReturn {
                                // Créer le dossier Scripts
                                do {
                                    try FileManager.default.createDirectory(
                                        at: URL(fileURLWithPath: scriptsFolder),
                                        withIntermediateDirectories: true)
                                    
                                    onFolderSelected("$USB/Scripts")
                                } catch {
                                    let errorAlert = NSAlert()
                                    errorAlert.messageText = "Erreur"
                                    errorAlert.informativeText = "Impossible de créer le dossier: \(error.localizedDescription)"
                                    errorAlert.alertStyle = .warning
                                    errorAlert.addButton(withTitle: "OK")
                                    errorAlert.runModal()
                                }
                            }
                        }
                    }
                } else {
                    // Afficher une alerte si nous ne sommes pas sur une clé USB
                    let alert = NSAlert()
                    alert.messageText = "Non exécuté sur une clé USB"
                    alert.informativeText = "L'application ne semble pas être exécutée depuis une clé USB."
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }

        #Preview("FolderSelector - Light Mode") {
            FolderSelector(
                currentPath: "/Volumes/Marco/Dév/Fonctionnel",
                isDarkMode: false,
                onFolderSelected: { _ in }
            )
            .padding()
            .frame(width: 500)
        }

        #Preview("FolderSelector - Dark Mode") {
            FolderSelector(
                currentPath: "/Volumes/Marco/Dév/Fonctionnel",
                isDarkMode: true,
                onFolderSelected: { _ in }
            )
            .padding()
            .frame(width: 500)
            .background(Color.black)
        }
