//
//  MultiResultSection.swift
//  ScriptLauncher
//
//  Created for ScriptLauncher on 04/03/2025.
//  Updated on 05/03/2025.
//

import SwiftUI

struct MultiResultSection: View {
    @ObservedObject var viewModel: RunningScriptsViewModel
    let isDarkMode: Bool
    
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
            
            // Zone de résultat
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
                    ScrollView {
                        Text(script.output)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(DesignSystem.spacing)
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
            
            // Barre d'état du script
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
    }
    
    // Format de l'heure pour l'affichage
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview("MultiResultSection - With Script") {
    // Créer un ViewModel pour la prévisualisation
    let viewModel = RunningScriptsViewModel()
    let scriptId = UUID()
    viewModel.addScript(RunningScript(id: scriptId, name: "Backup Script", startTime: Date().addingTimeInterval(-65), output: "Processing...\nStep 1 complete\nStep 2 in progress...", isSelected: true, status: .running))
    viewModel.addScript(RunningScript(id: UUID(), name: "Export Data", startTime: Date().addingTimeInterval(-120), output: "Exporting data..."))
    viewModel.selectScript(id: scriptId)
    
    return MultiResultSection(
        viewModel: viewModel,
        isDarkMode: false
    )
    .frame(height: 300)
    .padding()
}

#Preview("MultiResultSection - Empty") {
    MultiResultSection(
        viewModel: RunningScriptsViewModel(),
        isDarkMode: true
    )
    .frame(height: 300)
    .padding()
}
