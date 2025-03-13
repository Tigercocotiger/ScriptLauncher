//
//  MultiResultSection.swift
//  ScriptLauncher
//
//  Created for ScriptLauncher on 04/03/2025.
//  Updated on 05/03/2025.
//  Updated on 14/03/2025. - Fixed log display issues
//

import SwiftUI

struct MultiResultSection: View {
    @ObservedObject var viewModel: RunningScriptsViewModel
    let isDarkMode: Bool
    
    // Pour forcer le rafraîchissement
    @State private var refreshID = UUID()
    
    private var selectedScript: RunningScript? {
        viewModel.scripts.first { $0.id == viewModel.selectedScriptId }
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.spacing) {
            // En-tête
            Text("Résultat")
                .font(.headline)
                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, DesignSystem.spacing)
                .padding(.bottom, 8)
            
            // Zone de résultat avec console de logs
            ZStack {
                if viewModel.scripts.isEmpty {
                    VStack(spacing: DesignSystem.smallSpacing) {
                        Image(systemName: "terminal")
                            .font(.system(size: 32))
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode).opacity(0.5))
                        
                        Text("Aucun script en cours d'exécution")
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            .multilineTextAlignment(.center)
                    }
                } else if selectedScript == nil {
                    VStack(spacing: DesignSystem.smallSpacing) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 32))
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode).opacity(0.5))
                        
                        Text("Sélectionnez un script pour voir son résultat")
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                            .multilineTextAlignment(.center)
                    }
                } else if let script = selectedScript {
                    // Utilisation d'un ScrollViewReader pour l'auto-défilement
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                // Affichage de la sortie du script
                                Text(script.output)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(DesignSystem.spacing)
                                    .id("output-end") // ID pour le défilement automatique
                            }
                        }
                        .onChange(of: script.output) { _ in
                            // Défilement automatique à chaque mise à jour
                            withAnimation {
                                scrollProxy.scrollTo("output-end", anchor: .bottom)
                            }
                        }
                        // IMPORTANT: Forcer le rafraîchissement avec un ID unique qui change lorsque le contenu change
                        .id("scroll-container-\(script.id)-\(script.output.hashValue)")
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color.white)
            .cornerRadius(DesignSystem.smallCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, DesignSystem.spacing)
            
            // Barre d'état du script - SANS le bouton de rafraîchissement
            if let script = selectedScript {
                HStack(spacing: DesignSystem.smallSpacing) {
                    // Indicateur de statut
                    if script.status == .running {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                    } else if script.status == .completed {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    } else {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(script.name)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                    
                    Spacer()
                    
                    // Taille du texte
                    Text("\(script.output.count) caractères")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                        .padding(.horizontal, 4)
                    
                    // Temps d'exécution - s'actualise automatiquement grâce au ViewModel
                    if script.status == .running {
                        Text("Démarré: \(formattedTime(script.startTime)) (\(script.elapsedTime))")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                    } else if let endTime = script.endTime {
                        Text("Terminé: \(formattedTime(endTime)) (\(script.elapsedTime))")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                    }
                }
                .padding(DesignSystem.smallSpacing)
                .background(isDarkMode ? Color.black.opacity(0.2) : Color.gray.opacity(0.1))
                .cornerRadius(DesignSystem.smallCornerRadius / 2)
                .padding(.horizontal, DesignSystem.spacing)
            }
            
            Spacer()
        }
        .background(DesignSystem.cardBackground(for: isDarkMode))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
        .shadow(
            color: Color.black.opacity(DesignSystem.shadowOpacity(for: isDarkMode)),
            radius: DesignSystem.shadowRadius,
            x: 0,
            y: DesignSystem.shadowY
        )
        // IMPORTANT: ForceUpdate à chaque changement du ViewModel
        .onReceive(viewModel.objectWillChange) { _ in
            self.refreshID = UUID()
        }
        // S'actualiser périodiquement uniquement pour les scripts en cours d'exécution
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            // Forcer la mise à jour uniquement si un script est en cours d'exécution
            if let script = selectedScript, script.status == .running {
                self.refreshID = UUID()
            }
        }
    }
    
    // Format de l'heure pour l'affichage
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
