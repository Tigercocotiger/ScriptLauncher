//
//  HelpView.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 25/02/2025.
//


import SwiftUI

// Vue d'aide
struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    let helpSections: [HelpSection]
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.spacing) {
            // En-tête
            HStack {
                Text("Guide d'utilisation")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                }
                .buttonStyle(IconButtonStyle(isDarkMode: isDarkMode))
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            
            // Contenu
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.spacing) {
                    ForEach(helpSections) { section in
                        VStack(alignment: .leading, spacing: DesignSystem.smallSpacing) {
                            Text(section.title)
                                .font(.headline)
                                .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
                            
                            Text(section.content)
                                .font(.body)
                                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color.white)
                        .cornerRadius(DesignSystem.smallCornerRadius)
                        .shadow(
                            color: Color.black.opacity(DesignSystem.shadowOpacity(for: isDarkMode) / 2),
                            radius: 3,
                            x: 0,
                            y: 1
                        )
                    }
                }
                .padding()
            }
        }
        .frame(width: 550, height: 450)
        .background(DesignSystem.backgroundColor(for: isDarkMode))
    }
}