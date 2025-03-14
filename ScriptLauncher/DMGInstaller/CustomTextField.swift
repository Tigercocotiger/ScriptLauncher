//
//  CustomTextField.swift
//  ScriptLauncher
//
//  Created by MPM on 14/03/2025.
//


//
//  DMGInstallerComponents.swift
//  ScriptLauncher
//
//  Created on 15/03/2025.
//

import SwiftUI

// Composants d'interface utilisateur réutilisables pour l'installateur DMG

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

// Composant pour les champs de paramètres avec label
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

// Composant pour les sections de la vue
struct InstallerSectionView<Content: View>: View {
    let title: String?
    let isDarkMode: Bool
    let content: Content
    
    init(title: String? = nil, isDarkMode: Bool, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isDarkMode = isDarkMode
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let sectionTitle = title {
                Text(sectionTitle)
                    .font(.headline)
                    .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
            }
            
            content
        }
        .padding()
        .background(DesignSystem.cardBackground(for: isDarkMode))
        .cornerRadius(8)
    }
}