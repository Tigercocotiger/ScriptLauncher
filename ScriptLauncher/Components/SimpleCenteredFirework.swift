//
//  SimpleCenteredFirework.swift
//  ScriptLauncher
//
//  Created on 06/03/2025.
//

import SwiftUI

struct SimpleCenteredFirework: View {
    @Binding var isVisible: Bool
    
    // Couleurs vives pour les feux d'artifice
    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    @State private var particles: [SimpleParticle] = []
    
    // Structure pour définir une particule
    struct SimpleParticle: Identifiable {
        let id = UUID()
        var color: Color
        var xOffset: CGFloat
        var yOffset: CGFloat
        var scale: CGFloat
        var opacity: Double
        var rotation: Double
    }
    
    var body: some View {
        ZStack {
            if isVisible {
                // Conteneur pour les particules
                ForEach(particles) { particle in
                    Image(systemName: "sparkle")
                        .foregroundColor(particle.color)
                        .scaleEffect(particle.scale)
                        .opacity(particle.opacity)
                        .rotationEffect(Angle(degrees: particle.rotation))
                        .offset(x: particle.xOffset, y: particle.yOffset)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .onChange(of: isVisible) { newValue in
            if newValue {
                // Lancer les feux d'artifice quand isVisible devient true
                startFireworks()
                
                // Masquer après un certain délai
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    isVisible = false
                }
            } else {
                // Nettoyer les particules quand l'animation se termine
                particles = []
            }
        }
    }
    
    // Fonction principale pour lancer plusieurs feux d'artifice
    private func startFireworks() {
        // Créer 3 feux d'artifice avec des délais
        for i in 0...2 {
            let delay = Double(i) * 0.3
            let xPos = CGFloat.random(in: -150...150)
            let yPos = CGFloat.random(in: -100...100)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                launchFirework(at: CGPoint(x: xPos, y: yPos))
            }
        }
    }
    
    // Fonction pour créer un feu d'artifice à une position spécifique
    private func launchFirework(at position: CGPoint) {
        // Nombre de particules pour ce feu d'artifice
        let numberOfParticles = 40
        
        // Couleur principale pour ce feu d'artifice
        let mainColor = colors.randomElement() ?? .orange
        
        // Créer les particules
        for _ in 0..<numberOfParticles {
            // Angle et distance aléatoires
            let angle = Double.random(in: 0...360)
            let distance = CGFloat.random(in: 50...150)
            
            // Position finale calculée
            let finalX = position.x + cos(angle * .pi / 180) * distance
            let finalY = position.y + sin(angle * .pi / 180) * distance
            
            // Alternance entre la couleur principale et des couleurs aléatoires
            let particleColor = Bool.random() ? mainColor : colors.randomElement()!
            
            // Créer une particule à la position de départ
            let particle = SimpleParticle(
                color: particleColor,
                xOffset: position.x,
                yOffset: position.y,
                scale: 0.1,
                opacity: 0,
                rotation: Double.random(in: 0...360)
            )
            
            // Ajouter à la liste
            particles.append(particle)
            
            // Index de la particule ajoutée
            let index = particles.count - 1
            
            // Animer l'apparition
            withAnimation(.easeOut(duration: 0.1)) {
                particles[index].opacity = 1.0
                particles[index].scale = CGFloat.random(in: 0.4...0.8)
            }
            
            // Animer l'explosion
            withAnimation(.easeOut(duration: 0.7)) {
                particles[index].xOffset = finalX
                particles[index].yOffset = finalY
                particles[index].opacity = 0
                particles[index].rotation += 180
            }
        }
    }
}

// MARK: - Preview
#Preview("Firework Preview") {
    ZStack {
        Color.black.opacity(0.5)
            .edgesIgnoringSafeArea(.all)
        
        SimpleCenteredFirework(isVisible: .constant(true))
    }
    .frame(width: 400, height: 400)
}
