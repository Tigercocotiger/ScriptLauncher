//
//  IconButtonStyle.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 25/02/2025.
//


import SwiftUI

// Style de bouton icône
struct IconButtonStyle: ButtonStyle {
    let isDarkMode: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(6)
            .background(
                configuration.isPressed 
                ? (isDarkMode ? Color.white.opacity(0.2) : Color.gray.opacity(0.2))
                : Color.clear
            )
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Style de toggle en forme d'étoile
struct StarToggleStyle: ToggleStyle {
    let isDarkMode: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            Image(systemName: configuration.isOn ? "star.fill" : "star")
                .foregroundColor(configuration.isOn 
                                 ? DesignSystem.favoriteColor() 
                                 : DesignSystem.textSecondary(for: isDarkMode))
                .font(.system(size: 16))
                .padding(6)
                .background(
                    configuration.isOn
                    ? (isDarkMode 
                       ? DesignSystem.favoriteColor().opacity(0.2) 
                       : DesignSystem.favoriteColor().opacity(0.1))
                    : Color.clear
                )
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}