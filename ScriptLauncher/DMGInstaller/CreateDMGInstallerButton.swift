//
//  CreateDMGInstallerButton.swift
//  ScriptLauncher
//
//  Created by MPM on 14/03/2025.
//


//
//  CreateDMGInstallerButton.swift
//  ScriptLauncher
//
//  Created on 15/03/2025.
//

import SwiftUI

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

// MARK: - Preview
#Preview("CreateDMGInstallerButton") {
    CreateDMGInstallerButton(
        isDarkMode: false,
        targetFolder: "/Users/test/Scripts",
        onScriptCreated: {}
    )
    .frame(width: 300)
    .padding()
}

#Preview("CreateDMGInstallerButton - Dark Mode") {
    CreateDMGInstallerButton(
        isDarkMode: true,
        targetFolder: "/Users/test/Scripts",
        onScriptCreated: {}
    )
    .frame(width: 300)
    .padding()
    .preferredColorScheme(.dark)
}