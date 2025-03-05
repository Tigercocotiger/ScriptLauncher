//
//  ExecuteSelectedScriptsButton.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 05/03/2025.
//


//
//  ExecuteSelectedScriptsButton.swift
//  ScriptLauncher
//
//  Created on 05/03/2025.
//

import SwiftUI

struct ExecuteSelectedScriptsButton: View {
    let selectedScriptsCount: Int
    let isAnyScriptRunning: Bool
    let isDarkMode: Bool
    let onExecute: () -> Void
    
    var body: some View {
        Button(action: onExecute) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.system(size: 16))
                Text("Exécuter \(selectedScriptsCount) script\(selectedScriptsCount > 1 ? "s" : "")")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.buttonHeight)
            .background(
                selectedScriptsCount == 0
                    ? Color.gray 
                    : DesignSystem.accentColor(for: isDarkMode)
            )
            .foregroundColor(.white)
            .cornerRadius(DesignSystem.smallCornerRadius)
            .shadow(
                color: (selectedScriptsCount == 0) 
                    ? Color.clear 
                    : DesignSystem.accentColor(for: isDarkMode).opacity(0.3),
                radius: 4, 
                x: 0, 
                y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(selectedScriptsCount == 0)
        .keyboardShortcut(.return, modifiers: [.command, .shift])
        .padding(.horizontal, DesignSystem.spacing)
        .padding(.bottom, DesignSystem.spacing)
    }
}

// MARK: - Preview
#Preview("Execute Selected Scripts Button - Has Selection") {
    ExecuteSelectedScriptsButton(
        selectedScriptsCount: 3,
        isAnyScriptRunning: false,
        isDarkMode: false,
        onExecute: {}
    )
    .frame(width: 300)
    .padding()
}

#Preview("Execute Selected Scripts Button - No Selection") {
    ExecuteSelectedScriptsButton(
        selectedScriptsCount: 0,
        isAnyScriptRunning: false,
        isDarkMode: true,
        onExecute: {}
    )
    .frame(width: 300)
    .padding()
}