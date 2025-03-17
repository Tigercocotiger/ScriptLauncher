import SwiftUI
import AppKit

struct ProgressBarComponent: View {
    let isDarkMode: Bool
    let progress: CGFloat // 0.0 - 1.0
    let message: String
    let animation: Bool
    
    init(isDarkMode: Bool, progress: CGFloat = 0.3, message: String = "Traitement en cours...", animation: Bool = true) {
        self.isDarkMode = isDarkMode
        self.progress = min(max(progress, 0.0), 1.0) // Limiter entre 0 et 1
        self.message = message
        self.animation = animation
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Message d'état
            Text(message)
                .font(.caption)
                .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
            
            // Barre de progression
            ZStack(alignment: .leading) {
                // Fond de la barre
                RoundedRectangle(cornerRadius: 4)
                    .fill(isDarkMode ? Color(white: 0.2) : Color(white: 0.9))
                    .frame(height: 8)
                
                // Partie remplie de la barre
                if animation && progress < 1.0 {
                    // Version animée pour les opérations en cours
                    // IMPORTANT: Ajouter un clip ici pour éviter le débordement
                    IndeterminateProgressBar(isDarkMode: isDarkMode)
                        .frame(height: 8)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    // Version déterminée pour les valeurs spécifiques
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignSystem.accentColor(for: isDarkMode))
                            .frame(width: max(progress * geometry.size.width, 10), height: 8)
                            .animation(.linear(duration: 0.3), value: progress)
                    }
                    .frame(height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.17) : Color(white: 0.97))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// Composant pour la barre de progression indéterminée
struct IndeterminateProgressBar: View {
    let isDarkMode: Bool
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            // Créer un gradient qui se déplace
            let gradientWidth = geometry.size.width * 0.3 // Largeur du gradient (30% de la barre)
            let animationWidth = geometry.size.width // Largeur complète disponible
            
            LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.accentColor(for: isDarkMode).opacity(0.2),
                    DesignSystem.accentColor(for: isDarkMode),
                    DesignSystem.accentColor(for: isDarkMode).opacity(0.2)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: gradientWidth)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .offset(x: isAnimating ? animationWidth - gradientWidth : 0)
            .animation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                // Ajouter un léger délai pour s'assurer que la vue est complètement chargée
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isAnimating = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("ProgressBar - Light Mode") {
    VStack(spacing: 20) {
        ProgressBarComponent(
            isDarkMode: false,
            progress: 0.3,
            message: "Analyse du DMG en cours...",
            animation: true
        )
        .frame(width: 350)
        
        ProgressBarComponent(
            isDarkMode: false,
            progress: 0.7,
            message: "Extraction des informations...",
            animation: false
        )
        .frame(width: 350)
        
        ProgressBarComponent(
            isDarkMode: false,
            progress: 1.0,
            message: "Terminé !",
            animation: false
        )
        .frame(width: 350)
    }
    .padding()
}

#Preview("ProgressBar - Dark Mode") {
    VStack(spacing: 20) {
        ProgressBarComponent(
            isDarkMode: true,
            progress: 0.3,
            message: "Analyse du DMG en cours...",
            animation: true
        )
        .frame(width: 350)
        
        ProgressBarComponent(
            isDarkMode: true,
            progress: 0.7,
            message: "Extraction des informations...",
            animation: false
        )
        .frame(width: 350)
        
        ProgressBarComponent(
            isDarkMode: true,
            progress: 1.0,
            message: "Terminé !",
            animation: false
        )
        .frame(width: 350)
    }
    .padding()
    .background(Color.black)
}
