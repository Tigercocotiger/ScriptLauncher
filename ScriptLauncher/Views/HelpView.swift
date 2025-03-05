//
//  HelpView.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 25/02/2025.
//  Updated on 05/03/2025.
//

import SwiftUI

// Vue d'aide avec taille responsive
struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    let helpSections: [HelpSection]
    let isDarkMode: Bool
    
    // Version de l'application
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        GeometryReader { geometry in
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
                .background(isDarkMode ? Color(red: 0.18, green: 0.18, blue: 0.2).opacity(0.8) : Color(white: 0.97))
                .cornerRadius(DesignSystem.smallCornerRadius)
                
                // Contenu
                ScrollView {
                    VStack(spacing: DesignSystem.spacing) {
                        ForEach(helpSections) { section in
                            VStack(alignment: .leading, spacing: DesignSystem.smallSpacing) {
                                Text(section.title)
                                    .font(.headline)
                                    .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
                                
                                Divider()
                                    .padding(.vertical, 4)
                                
                                Text(section.content)
                                    .font(.body)
                                    .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.bottom, 8)
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
                            
                            // Disposition horizontale pour la bulle et l'image
                            HStack(alignment: .center, spacing: 0) {
                                // Bulle de texte avec citation pointant vers la droite
                                ZStack(alignment: .trailing) {
                                    // Bulle
                                    VStack {
                                        Text("« Ce qui compte c'est pas d'avoir du temps mais de savoir s'en servir »")
                                            .font(.system(size: 14, weight: .medium))
                                            .italic()
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    }
                                    .background(
                                        isDarkMode ? Color(red: 0.3, green: 0.3, blue: 0.35) : Color(white: 0.97)
                                    )
                                    .clipShape(RightPointingBubble())
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    .frame(height: 80)
                                    .padding(.trailing, 10) // Espace pour la pointe à droite
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Image d'Ekko
                                Image("Ekkoo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                            
                            Divider()
                                .padding(.bottom, 12)
                            
                            Text("ScriptLauncher")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                            
                            Text("Version \(appVersion) (\(buildNumber))")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                                .padding(.bottom, 12)
                            
                            Divider()
                                .padding(.bottom, 12)
                                
                            HStack(spacing: 8) {
                                Text("© 2025")
                                    .font(.footnote)
                                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                                
                                Text("Marco SIMON")
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                                
                                Text("•")
                                    .font(.footnote)
                                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                                
                                Text("Tous droits réservés")
                                    .font(.footnote)
                                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            }
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
                    .frame(maxWidth: min(600, geometry.size.width * 0.9)) // Responsive width
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(DesignSystem.backgroundColor(for: isDarkMode))
        }
        .onAppear {
            // Ajuste la taille de la fenêtre d'aide quand elle apparaît
            DispatchQueue.main.async {
                if let helpWindow = NSApplication.shared.windows.first(where: { $0.isKeyWindow }),
                   let mainWindow = NSApplication.shared.windows.first(where: { $0 != helpWindow }) {
                    let screenSize = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
                    
                    // Calcul des dimensions
                    let width = min(650, screenSize.width * 0.8)
                    let height = min(680, screenSize.height * 0.8)
                    
                    // Calcul de la position pour centrer sur la fenêtre principale
                    let xPos = mainWindow.frame.origin.x + (mainWindow.frame.width - width) / 2
                    let yPos = mainWindow.frame.origin.y + (mainWindow.frame.height - height) / 2
                    
                    // Application des dimensions sans changer la position de la fenêtre principale
                    helpWindow.setFrame(
                        NSRect(
                            x: xPos,
                            y: yPos,
                            width: width,
                            height: height
                        ),
                        display: true,
                        animate: false
                    )
                }
            }
        }
    }
}

// Forme personnalisée pour la bulle de texte avec pointe à droite
struct RightPointingBubble: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Rayon des coins arrondis
        let cornerRadius: CGFloat = 8
        
        // Taille de la pointe
        let triangleSize: CGFloat = 10
        
        // Position de la pointe (centrée à droite)
        let triangleY = rect.height / 2
        
        // Dessiner la bulle rectangulaire avec coins arrondis
        path.addRoundedRect(in: CGRect(x: 0, y: 0, width: rect.width - triangleSize, height: rect.height), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        
        // Dessiner la pointe (triangle) pointant vers la droite
        path.move(to: CGPoint(x: rect.width - triangleSize, y: triangleY - triangleSize))
        path.addLine(to: CGPoint(x: rect.width, y: triangleY))
        path.addLine(to: CGPoint(x: rect.width - triangleSize, y: triangleY + triangleSize))
        
        return path
    }
}
