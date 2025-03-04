//
//  ExecuteMultipleButton.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 04/03/2025.
//


//
//  ExecuteMultipleButton.swift
//  ScriptLauncher
//
//  Created for ScriptLauncher on 04/03/2025.
//

import SwiftUI

struct ExecuteMultipleButton: View {
    let selectedScript: ScriptFile?
    let isScriptRunning: Bool
    let isDarkMode: Bool
    let onExecute: () -> Void
    
    var body: some View {
        Button(action: onExecute) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.system(size: 16))
                Text("Exécuter")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.buttonHeight)
            .background(
                selectedScript == nil
                    ? Color.gray 
                    : DesignSystem.accentColor(for: isDarkMode)
            )
            .foregroundColor(.white)
            .cornerRadius(DesignSystem.smallCornerRadius)
            .shadow(
                color: (selectedScript == nil) 
                    ? Color.clear 
                    : DesignSystem.accentColor(for: isDarkMode).opacity(0.3),
                radius: 4, 
                x: 0, 
                y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(selectedScript == nil)
        .keyboardShortcut(.return, modifiers: .command)
        .padding(.horizontal, DesignSystem.spacing)
        .padding(.bottom, DesignSystem.spacing)
    }
}

// MARK: - Preview
#Preview("Execute Button - Has Selection") {
    ExecuteMultipleButton(
        selectedScript: ScriptFile(name: "test.scpt", path: "/path", isFavorite: false, lastExecuted: nil),
        isScriptRunning: false,
        isDarkMode: false,
        onExecute: {}
    )
    .frame(width: 300)
    .padding()
}

#Preview("Execute Button - No Selection") {
    ExecuteMultipleButton(
        selectedScript: nil,
        isScriptRunning: false,
        isDarkMode: true,
        onExecute: {}
    )
    .frame(width: 300)
    .padding()
}