//
//  ConfigButton.swift
//  ScriptLauncher
//
//  Created on 06/03/2025.
//

import SwiftUI

struct ConfigButton: View {
    let isDarkMode: Bool
    var isEnabled: Bool = true // Nouvelle propriété avec une valeur par défaut
    // Callback pour l'action du bouton
    let onConfigPressed: () -> Void
    
    var body: some View {
        Button(action: onConfigPressed) {
            HStack(spacing: 8) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                
                Text("Configurator")
                    .font(.system(size: 14, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundColor(.white)
            .background(
                isEnabled
                ? DesignSystem.accentColor(for: isDarkMode)
                : Color.gray.opacity(0.5)
            )
            .cornerRadius(DesignSystem.smallCornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .padding(.horizontal, DesignSystem.spacing)
        .padding(.vertical, DesignSystem.smallSpacing)
        .background(DesignSystem.cardBackground(for: isDarkMode))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
        .shadow(
            color: Color.black.opacity(isEnabled ? DesignSystem.shadowOpacity(for: isDarkMode) : 0.05),
            radius: DesignSystem.shadowRadius,
            x: 0,
            y: DesignSystem.shadowY
        )
    }
}

// MARK: - Preview
#Preview("Config Button - Enabled") {
    ConfigButton(
        isDarkMode: false,
        isEnabled: true,
        onConfigPressed: {}
    )
    .frame(width: 400)
    .padding()
}

#Preview("Config Button - Disabled") {
    ConfigButton(
        isDarkMode: false,
        isEnabled: false,
        onConfigPressed: {}
    )
    .frame(width: 400)
    .padding()
}

#Preview("Config Button - Dark Mode Disabled") {
    ConfigButton(
        isDarkMode: true,
        isEnabled: false,
        onConfigPressed: {}
    )
    .frame(width: 400)
    .padding()
    .background(Color.black)
}
