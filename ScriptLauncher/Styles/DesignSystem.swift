//
//  DesignSystem.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 25/02/2025.
//


import SwiftUI

struct DesignSystem {
    // Couleurs
    static func backgroundColor(for isDarkMode: Bool) -> Color {
        isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.14) : Color(red: 0.98, green: 0.98, blue: 0.98)
    }
    
    static func cardBackground(for isDarkMode: Bool) -> Color {
        isDarkMode ? Color(red: 0.18, green: 0.18, blue: 0.2) : Color.white
    }
    
    static func textPrimary(for isDarkMode: Bool) -> Color {
        isDarkMode ? Color.white : Color.black
    }
    
    static func textSecondary(for isDarkMode: Bool) -> Color {
        isDarkMode ? Color(white: 0.7) : Color.gray
    }
    
    static func accentColor(for isDarkMode: Bool) -> Color {
        // #ff7400 (orange vif)
        isDarkMode ? Color(red: 1.0, green: 0.455, blue: 0.0) : Color(red: 1.0, green: 0.455, blue: 0.0)
    }
    
    static func favoriteColor() -> Color {
        Color(red: 1.0, green: 0.72, blue: 0.25) // Jaune doré
    }
    
    // Dimensions
    static let cornerRadius: CGFloat = 12
    static let buttonHeight: CGFloat = 44
    static let smallCornerRadius: CGFloat = 8
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    
    // Ombres
    static func shadowOpacity(for isDarkMode: Bool) -> Double {
        isDarkMode ? 0.4 : 0.1
    }
    static let shadowRadius: CGFloat = 5
    static let shadowY: CGFloat = 2
}
