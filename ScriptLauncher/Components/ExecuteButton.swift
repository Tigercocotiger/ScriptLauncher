//
//  ExecuteButton.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 25/02/2025.
//


import SwiftUI

struct ExecuteButton: View {
    let selectedScript: ScriptFile?
    let isRunning: Bool
    let isDarkMode: Bool
    let onExecute: () -> Void
    
    var body: some View {
        Button(action: onExecute) {
            HStack {
                if isRunning {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                        .padding(.trailing, 4)
                    Text("Exécution en cours...")
                        .font(.headline)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16))
                    Text("Exécuter")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.buttonHeight)
            .background(
                selectedScript == nil || isRunning 
                    ? Color.gray 
                    : DesignSystem.accentColor(for: isDarkMode)
            )
            .foregroundColor(.white)
            .cornerRadius(DesignSystem.smallCornerRadius)
            .shadow(
                color: (selectedScript == nil || isRunning) 
                    ? Color.clear 
                    : DesignSystem.accentColor(for: isDarkMode).opacity(0.3),
                radius: 4, 
                x: 0, 
                y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(selectedScript == nil || isRunning)
        .keyboardShortcut(.return, modifiers: .command)
        .padding(.horizontal, DesignSystem.spacing)
        .padding(.bottom, DesignSystem.spacing)
    }
}