//
//  FolderSelector.swift
//  ScriptLauncher
//
//  Created on 05/03/2025.
//

import SwiftUI
import AppKit

struct FolderSelector: View {
    let currentPath: String
    let isDarkMode: Bool
    let onFolderSelected: (String) -> Void
    
    var body: some View {
        HStack {
            Text("Dossier cible:")
                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                .font(.system(size: 14))
            
            Text(currentPath)
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
        if let url = URL(string: "file://" + currentPath), FileManager.default.fileExists(atPath: currentPath) {
            openPanel.directoryURL = url
        }
        
        openPanel.message = "Sélectionnez un dossier contenant des scripts AppleScript"
        openPanel.prompt = "Sélectionner"
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            // Vérifier que le dossier contient des scripts
            if ConfigManager.shared.isValidScriptFolder(url.path) {
                onFolderSelected(url.path)
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
