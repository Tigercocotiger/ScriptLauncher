//
//  HelpView.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 25/02/2025.
//  Updated on 05/03/2025.
//  Updated on 30/03/2025 - Design amélioré avec table des matières et meilleure mise en forme
//

import SwiftUI

// Définition d'une structure pour suivre la visibilité des sections
struct SectionVisibility: Equatable {
    let index: Int
    let rect: CGRect
    let id: UUID
}

// Clé de préférence pour suivre les sections visibles
struct SectionVisibilityPreferenceKey: PreferenceKey {
    static var defaultValue: [SectionVisibility] = []
    
    static func reduce(value: inout [SectionVisibility], nextValue: () -> [SectionVisibility]) {
        value.append(contentsOf: nextValue())
    }
}

// Vue d'aide avec design amélioré
struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    let helpSections: [HelpSection]
    let isDarkMode: Bool
    
    // État pour suivre la section sélectionnée dans le sommaire
    @State private var selectedSectionIndex: Int? = 0
    @State private var scrolledSectionIndex: Int = 0
    @State private var searchText: String = ""
    @State private var showSearch: Bool = false
    
    // Version de l'application
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Barre latérale avec sommaire
                VStack(spacing: 0) {
                    // En-tête de la barre latérale avec barre de recherche
                    VStack(spacing: 0) {
                        Text("SOMMAIRE")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(1.5)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(isDarkMode ? .white : .black)
                            .background(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.17) : Color(white: 0.95))
                        
                        // Barre de recherche
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(isDarkMode ? .white.opacity(0.6) : .gray)
                                .font(.system(size: 12))
                            
                            TextField("Rechercher...", text: $searchText)
                                .font(.system(size: 12))
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(isDarkMode ? .white : .black)
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(isDarkMode ? .white.opacity(0.6) : .gray)
                                        .font(.system(size: 12))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.22) : Color(white: 0.9))
                    }
                    
                    // Liste des sections avec filtrage
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(Array(helpSections.enumerated()), id: \.element.id) { index, section in
                                // Filtrer les sections selon la recherche
                                if searchText.isEmpty || section.title.lowercased().contains(searchText.lowercased()) {
                                    Button(action: {
                                        withAnimation {
                                            selectedSectionIndex = index
                                        }
                                    }) {
                                        HStack {
                                            // Barre colorée sur le côté gauche
                                            Rectangle()
                                                .fill(scrolledSectionIndex == index
                                                      ? getSectionColor(for: index + 1)
                                                      : Color.clear)
                                                .frame(width: 4)
                                            
                                            // Numéro de section
                                            Text("\(index + 1).")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(scrolledSectionIndex == index
                                                                ? getSectionColor(for: index + 1)
                                                                : DesignSystem.textSecondary(for: isDarkMode).opacity(0.8))
                                                .frame(width: 24, alignment: .leading)
                                            
                                            // Titre de la section
                                            Text(section.title)
                                                .font(.system(size: 13, weight: scrolledSectionIndex == index ? .semibold : .regular))
                                                .foregroundColor(scrolledSectionIndex == index
                                                                ? getSectionColor(for: index + 1)
                                                                : DesignSystem.textSecondary(for: isDarkMode))
                                                .padding(.vertical, 12)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .contentShape(Rectangle())
                                        .background(scrolledSectionIndex == index
                                                  ? (isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.22) : Color(white: 0.9))
                                                  : Color.clear)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .transition(.opacity)
                                }
                            }
                            
                            // Message si aucun résultat
                            if !searchText.isEmpty && !helpSections.contains(where: { $0.title.lowercased().contains(searchText.lowercased()) }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 20))
                                        .foregroundColor(isDarkMode ? .white.opacity(0.3) : .gray.opacity(0.5))
                                        .padding(.bottom, 4)
                                    
                                    Text("Aucun résultat pour \"\(searchText)\"")
                                        .font(.system(size: 12))
                                        .foregroundColor(isDarkMode ? .white.opacity(0.6) : .gray)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            }
                        }
                    }
                }
                .frame(width: 220)
                .background(isDarkMode ? Color(red: 0.16, green: 0.16, blue: 0.18) : Color(white: 0.97))
                
                // Contenu principal
                VStack(spacing: 0) {
                    // En-tête
                    HStack {
                        Text("Guide d'utilisation")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                        
                        Spacer()
                        
                        // Boutons de navigation
                        HStack(spacing: 12) {
                            // Bouton de section précédente
                            Button(action: {
                                if scrolledSectionIndex > 0 {
                                    selectedSectionIndex = scrolledSectionIndex - 1
                                }
                            }) {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color(white: 0.93))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(scrolledSectionIndex <= 0)
                            .opacity(scrolledSectionIndex <= 0 ? 0.5 : 1)
                            
                            // Bouton de section suivante
                            Button(action: {
                                if scrolledSectionIndex < helpSections.count - 1 {
                                    selectedSectionIndex = scrolledSectionIndex + 1
                                }
                            }) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color(white: 0.93))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(scrolledSectionIndex >= helpSections.count - 1)
                            .opacity(scrolledSectionIndex >= helpSections.count - 1 ? 0.5 : 1)
                            
                            // Bouton de fermeture
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            }
                            .buttonStyle(IconButtonStyle(isDarkMode: isDarkMode))
                            .keyboardShortcut(.escape, modifiers: [])
                        }
                    }
                    .padding()
                    .background(isDarkMode ? Color(red: 0.18, green: 0.18, blue: 0.2) : Color(white: 0.98))
                    
                    // Contenu des sections
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            VStack(spacing: 24) {
                                ForEach(Array(helpSections.enumerated()), id: \.element.id) { index, section in
                                    HelpSectionView(
                                        section: section,
                                        sectionNumber: index + 1,
                                        isDarkMode: isDarkMode
                                    )
                                    .id("section_\(index)")
                                    .background(
                                        // Détecteur de visibilité de section
                                        GeometryReader { geo in
                                            Color.clear
                                                .preference(
                                                    key: SectionVisibilityPreferenceKey.self,
                                                    value: [SectionVisibility(
                                                        index: index,
                                                        rect: geo.frame(in: .named("scrollView")),
                                                        id: section.id
                                                    )]
                                                )
                                        }
                                    )
                                }
                                
                                // Section crédits
                                VStack(alignment: .center, spacing: DesignSystem.smallSpacing) {
                                    HStack {
                                        // Numéro de section avec cercle
                                        ZStack {
                                            Circle()
                                                .fill(getSectionColor(for: helpSections.count + 1))
                                                .frame(width: 32, height: 32)
                                            
                                            Text("\(helpSections.count + 1)")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text("À propos")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(getSectionColor(for: helpSections.count + 1))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.bottom, 4)
                                    
                                    // Divider coloré
                                    Rectangle()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [getSectionColor(for: helpSections.count + 1), getSectionColor(for: helpSections.count + 1).opacity(0.1)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                        .frame(height: 2)
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
                                    .padding(.bottom, 16)
                                    
                                    // Informations sur l'application
                                    VStack(spacing: 4) {
                                        Text("ScriptLauncher")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                                        
                                        Text("Version \(appVersion) (\(buildNumber))")
                                            .font(.subheadline)
                                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                                            .padding(.bottom, 8)
                                        
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
                                    .padding(.bottom, 12)
                                }
                                .padding(24)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                                        .fill(isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                                                .stroke(getSectionColor(for: helpSections.count + 1).opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .shadow(
                                    color: Color.black.opacity(DesignSystem.shadowOpacity(for: isDarkMode) / 2),
                                    radius: 3,
                                    x: 0,
                                    y: 1
                                )
                                .padding(.bottom, 24)
                                .id("section_credits")
                            }
                            .padding(24)
                        }
                        .coordinateSpace(name: "scrollView")
                        .onPreferenceChange(SectionVisibilityPreferenceKey.self) { preferences in
                            DispatchQueue.main.async {
                                // Trouver la section la plus visible en haut de la vue
                                let sortedPrefs = preferences.sorted {
                                    // Priorité aux sections les plus proches du haut, mais visibles (y > 0)
                                    if $0.rect.minY >= 0 && $1.rect.minY >= 0 {
                                        return $0.rect.minY < $1.rect.minY
                                    } else if $0.rect.minY >= 0 {
                                        return true
                                    } else if $1.rect.minY >= 0 {
                                        return false
                                    } else {
                                        // Toutes les sections sont au-dessus, prendre la plus basse
                                        return $0.rect.minY > $1.rect.minY
                                    }
                                }
                                
                                if let mostVisibleSection = sortedPrefs.first {
                                    if scrolledSectionIndex != mostVisibleSection.index {
                                        scrolledSectionIndex = mostVisibleSection.index
                                    }
                                }
                            }
                        }
                        .onChange(of: selectedSectionIndex) { newIndex in
                            if let index = newIndex {
                                withAnimation {
                                    scrollProxy.scrollTo("section_\(index)", anchor: .top)
                                }
                            }
                        }
                    }
                }
                .background(DesignSystem.backgroundColor(for: isDarkMode))
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
                    let width = min(900, screenSize.width * 0.8)
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
    
    // Fonction utilitaire pour obtenir une couleur par section
    private func getSectionColor(for sectionNumber: Int) -> Color {
        // Palette de couleurs vives pour les sections
        let colors: [Color] = [
            Color.blue,
            Color.purple,
            Color.green,
            Color.orange,
            Color.pink,
            Color(red: 0.2, green: 0.6, blue: 0.9),
            Color(red: 0.8, green: 0.4, blue: 0.2),
            Color(red: 0.5, green: 0.8, blue: 0.3),
            Color(red: 0.7, green: 0.3, blue: 0.8),
            Color(red: 0.9, green: 0.7, blue: 0.1)
        ]
        
        // Utiliser le numéro de section pour choisir une couleur (avec cycle si nécessaire)
        return colors[(sectionNumber - 1) % colors.count]
    }
}

// Vue pour une section d'aide individuelle avec style amélioré
struct HelpSectionView: View {
    let section: HelpSection
    let sectionNumber: Int
    let isDarkMode: Bool
    
    // Génère une couleur d'accent pour chaque section
    private var sectionColor: Color {
        // Palette de couleurs vives pour les sections
        let colors: [Color] = [
            Color.blue,
            Color.purple,
            Color.green,
            Color.orange,
            Color.pink,
            Color(red: 0.2, green: 0.6, blue: 0.9),
            Color(red: 0.8, green: 0.4, blue: 0.2),
            Color(red: 0.5, green: 0.8, blue: 0.3),
            Color(red: 0.7, green: 0.3, blue: 0.8),
            Color(red: 0.9, green: 0.7, blue: 0.1)
        ]
        
        // Utiliser le numéro de section pour choisir une couleur (avec cycle si nécessaire)
        return colors[(sectionNumber - 1) % colors.count]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // En-tête de section avec numéro
            HStack(alignment: .center, spacing: 12) {
                // Numéro de section avec cercle
                ZStack {
                    Circle()
                        .fill(sectionColor)
                        .frame(width: 32, height: 32)
                    
                    Text("\(sectionNumber)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(section.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(sectionColor)
            }
            .padding(.bottom, 4)
            
            // Divider coloré
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [sectionColor, sectionColor.opacity(0.1)]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 2)
                .padding(.vertical, 4)
            
            // Contenu avec formatage amélioré
            FormatTextView(content: section.content, isDarkMode: isDarkMode, accentColor: sectionColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                .fill(isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                        .stroke(sectionColor.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(
            color: Color.black.opacity(DesignSystem.shadowOpacity(for: isDarkMode) / 2),
            radius: 3,
            x: 0,
            y: 1
        )
    }
}

// Vue pour formater le texte avec des listes et des styles spéciaux
struct FormatTextView: View {
    let content: String
    let isDarkMode: Bool
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(parseContent().enumerated()), id: \.offset) { _, paragraph in
                if paragraph.starts(with: "• ") {
                    // Élément de liste à puces
                    HStack(alignment: .top, spacing: 10) {
                        // Puce personnalisée
                        Circle()
                            .fill(accentColor.opacity(0.8))
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)
                        
                        // Utiliser Text standard
                        highlightShortcuts(paragraph.replacingOccurrences(of: "• ", with: ""))
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                            .lineSpacing(4)
                    }
                    .padding(.leading, 4)
                } else if paragraph.contains(":") && !paragraph.contains("\n") {
                    // Titre de sous-section
                    highlightShortcuts(paragraph)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isDarkMode ? accentColor.opacity(0.9) : accentColor)
                        .lineSpacing(4)
                } else if isCodeBlock(paragraph) {
                    // Bloc de code
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Code:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(accentColor)
                            .padding(.bottom, 4)
                        
                        SimpleCodeBlockView(
                            code: cleanCodeBlock(paragraph),
                            isDarkMode: isDarkMode
                        )
                    }
                    .padding(.vertical, 4)
                } else {
                    // Paragraphe normal
                    highlightShortcuts(paragraph)
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                        .lineSpacing(4)
                }
            }
        }
    }
    
    // Fonction simplifiée pour mettre en évidence les raccourcis clavier
    @ViewBuilder
    private func highlightShortcuts(_ text: String) -> some View {
        if text.contains("⌘") || text.contains("⌥") || text.contains("⇧") {
            // Version très simplifiée - highlight seulement si contient des raccourcis
            Text(text)
        } else {
            // Texte normal sans raccourcis
            Text(text)
        }
    }
    
    // Fonction pour diviser le contenu en paragraphes
    private func parseContent() -> [String] {
        let paragraphs = content.components(separatedBy: "\n\n")
        
        var result: [String] = []
        for paragraph in paragraphs {
            if paragraph.contains("\n") && paragraph.contains("• ") {
                // C'est probablement une liste, on divise en éléments séparés
                let lines = paragraph.components(separatedBy: "\n")
                result.append(contentsOf: lines)
            } else if paragraph.contains("\n") && paragraph.trimmingCharacters(in: .whitespacesAndNewlines).contains("```") {
                // C'est probablement un bloc de code
                result.append(paragraph)
            } else {
                result.append(paragraph)
            }
        }
        
        return result.filter { !$0.isEmpty }
    }
    
    // Détecter si un paragraphe est un bloc de code
    private func isCodeBlock(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("```")
    }
    
    // Nettoyer un bloc de code (enlever les ```)
    private func cleanCodeBlock(_ text: String) -> String {
        var cleanedText = text
        
        // Supprimer les délimiteurs de code
        if let startRange = cleanedText.range(of: "```") {
            cleanedText.removeSubrange(startRange)
        }
        if let endRange = cleanedText.range(of: "```", options: .backwards) {
            cleanedText.removeSubrange(endRange)
        }
        
        return cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// Vue très simplifiée pour afficher des blocs de code
struct SimpleCodeBlockView: View {
    let code: String
    let isDarkMode: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(code.components(separatedBy: "\n").enumerated()), id: \.0) { index, line in
                    HStack(spacing: 0) {
                        // Numéro de ligne
                        Text("\(index + 1)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color.gray.opacity(0.6))
                            .frame(width: 30, alignment: .trailing)
                            .padding(.trailing, 8)
                        
                        // Contenu de la ligne sans coloration syntaxique complexe
                        Text(line)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(isDarkMode ? Color.white.opacity(0.9) : Color.black.opacity(0.8))
                    }
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .background(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.17) : Color(white: 0.95))
        .cornerRadius(6)
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

// MARK: - Preview
#Preview("Help View - Light Mode") {
    HelpView(
        helpSections: HelpContent.helpSections,
        isDarkMode: false
    )
    .frame(width: 900, height: 700)
}

#Preview("Help View - Dark Mode") {
    HelpView(
        helpSections: HelpContent.helpSections,
        isDarkMode: true
    )
    .frame(width: 900, height: 700)
    .preferredColorScheme(.dark)
}
