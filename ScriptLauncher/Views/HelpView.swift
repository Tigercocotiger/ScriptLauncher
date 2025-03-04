//
//  HelpView.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 25/02/2025.
//  Updated on 04/03/2025.
//


import SwiftUI

// Vue d'aide
struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    let helpSections: [HelpSection]
    let isDarkMode: Bool
    
    // Version de l'application
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
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
                VStack(spacing: DesignSystem.spacing) {
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
                        .frame(maxWidth: .infinity, alignment: .topLeading)
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
                    
                    // Section crédits
                    VStack(alignment: .center, spacing: DesignSystem.smallSpacing) {
                        Text("Crédits")
                            .font(.headline)
                            .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        // Bulle de texte avec citation
                        ZStack(alignment: .bottom) {
                            // Bulle
                            VStack {
                                Spacer()
                                Text("« Ce qui compte c'est pas d'avoir du temps mais de savoir s'en servir »")
                                    .font(.system(size: 14, weight: .medium))
                                    .italic()  // Utilisation du modificateur .italic() au lieu de design: .italic
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Pour centrer verticalement
                                Spacer()
                            }
                            .background(
                                isDarkMode ? Color(red: 0.3, green: 0.3, blue: 0.35) : Color(white: 0.97)
                            )
                            .clipShape(BubbleShape())
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .frame(height: 80) // Hauteur fixe pour la bulle
                            .padding(.bottom, 15) // Espace pour la pointe de la bulle
                        }
                        .padding(.bottom, 2)
                        
                        // Image d'Ekko à la place de l'icône Mac
                        Image("Ekkoo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .padding(.bottom, 8)
                        
                        Text("ScriptLauncher")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                        
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            .padding(.bottom, 4)
                        
                        Text("© 2025 Marco SIMON")
                            .font(.footnote)
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                        
                        Text("Tous droits réservés")
                            .font(.footnote)
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                    }
                    .frame(maxWidth: .infinity)
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
                .padding()
                .frame(maxWidth: 600) // Limiter la largeur pour éviter des sections trop larges
            }
        }
        .frame(width: 650, height: 680) // Augmenté la hauteur pour accommoder la bulle et l'image
        .background(DesignSystem.backgroundColor(for: isDarkMode))
    }
}

// Forme personnalisée pour la bulle de texte
struct BubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Rayon des coins arrondis
        let cornerRadius: CGFloat = 8
        
        // Taille de la pointe
        let triangleSize: CGFloat = 10
        
        // Position de la pointe (centrée en bas)
        let triangleX = rect.width / 2
        
        // Dessiner la bulle rectangulaire avec coins arrondis
        path.addRoundedRect(in: CGRect(x: 0, y: 0, width: rect.width, height: rect.height - triangleSize), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        
        // Dessiner la pointe (triangle)
        path.move(to: CGPoint(x: triangleX - triangleSize, y: rect.height - triangleSize))
        path.addLine(to: CGPoint(x: triangleX, y: rect.height))
        path.addLine(to: CGPoint(x: triangleX + triangleSize, y: rect.height - triangleSize))
        
        return path
    }
}
