//
//  RunningScriptsView.swift
//  ScriptLauncher
//
//  Created for ScriptLauncher on 04/03/2025.
//  Updated on 05/03/2025.
//  Updated on 14/03/2025. - Fixed log display issues
//

import SwiftUI

struct RunningScriptsView: View {
    @ObservedObject var viewModel: RunningScriptsViewModel
    let isDarkMode: Bool
    let onScriptSelect: (UUID) -> Void
    let onScriptCancel: (UUID) -> Void
    
    // Forcer le rafraîchissement
    @State private var refreshID = UUID()
    
    var body: some View {
        VStack(spacing: 0) {
            // En-tête
            Text("Scripts en cours d'exécution (\(viewModel.scripts.count))")
                .font(.headline)
                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, DesignSystem.spacing)
                .padding(.bottom, 8)
            
            if viewModel.scripts.isEmpty {
                VStack(spacing: DesignSystem.spacing) {
                    Image(systemName: "play.slash.fill")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode).opacity(0.5))
                    
                    Text("Aucun script en cours d'exécution")
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Prend toute la hauteur disponible
            } else {
                HStack {
                    Spacer()
                    // Bouton pour annuler les scripts en cours
                    Button(action: {
                        // Annuler uniquement les scripts encore en cours
                        viewModel.scripts.filter { $0.status == .running }.forEach { script in
                            onScriptCancel(script.id)
                        }
                    }) {
                        Text("Stop")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
                }
                .padding(.horizontal, DesignSystem.spacing)
                .padding(.bottom, 4)
                
                // Zone de liste des scripts
                ZStack {
                    // Couleur de fond pour la zone de contenu
                    RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                        .fill(isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color.white)
                        .padding(.horizontal, DesignSystem.spacing)
                    
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.scripts) { script in
                                RunningScriptRow(
                                    script: script,
                                    isDarkMode: isDarkMode,
                                    onSelect: { onScriptSelect(script.id) },
                                    onCancel: { onScriptCancel(script.id) }
                                )
                                .background(
                                    script.isSelected
                                    ? (isDarkMode
                                       ? DesignSystem.accentColor(for: isDarkMode).opacity(0.3)
                                       : DesignSystem.accentColor(for: isDarkMode).opacity(0.1))
                                    : Color.clear
                                )
                                
                                if script.id != viewModel.scripts.last?.id {
                                    Divider()
                                        .padding(.leading, 40)
                                }
                            }
                        }
                        .padding(.bottom, 20) // Ajoute un espace en bas pour le défilement
                    }
                    .padding(.horizontal, DesignSystem.spacing)
                }
                .frame(maxHeight: .infinity) // Prend toute la hauteur disponible
                // IMPORTANT: ID pour forcer le rafraîchissement
                .id("running-scripts-list-\(refreshID)")
            }
            
            Spacer()
        }
        .background(DesignSystem.cardBackground(for: isDarkMode))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(DesignSystem.shadowOpacity(for: isDarkMode)),
            radius: DesignSystem.shadowRadius,
            x: 0,
            y: DesignSystem.shadowY
        )
        // IMPORTANT: S'abonner aux changements du viewModel
        .onReceive(viewModel.objectWillChange) { _ in
            // Forcer le rafraîchissement de la vue
            refreshID = UUID()
            print("[RunningScriptsView] Rafraîchissement forcé")
        }
    }
}

// Structure pour une ligne représentant un script en cours d'exécution
struct RunningScriptRow: View {
    let script: RunningScript
    let isDarkMode: Bool
    let onSelect: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.smallSpacing) {
            // Indicateur d'exécution
            if script.status == .running {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .padding(4)
            } else if script.status == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 10))
                    .padding(3)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 10))
                    .padding(3)
            }
            
            // Nom du script
            Text(script.name)
                .font(.system(size: 13))
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
            
            Spacer()
            
            // DEBUG: Affichage de l'ID (temporaire)
            Text("ID: \(script.id.uuidString.prefix(8))...")
                .font(.system(size: 8))
                .foregroundColor(.gray)
                .padding(.trailing, 4)
            
            // Temps d'exécution écoulé - s'actualise automatiquement grâce au ViewModel
            Text(script.elapsedTime)
                .font(.caption)
                .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                .frame(width: 60, alignment: .trailing)
            
            // Bouton d'annulation (uniquement pour les scripts en cours)
            if script.status == .running {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red.opacity(0.7))
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Arrêter ce script")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, DesignSystem.spacing)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}

// MARK: - Preview
#Preview("Running Scripts - Light Mode") {
    // Créer un ViewModel pour la prévisualisation
    let viewModel = RunningScriptsViewModel()
    viewModel.addScript(RunningScript(id: UUID(), name: "Backup Script", startTime: Date().addingTimeInterval(-65), output: "Processing...", isSelected: true, status: .running))
    viewModel.addScript(RunningScript(id: UUID(), name: "Export Data", startTime: Date().addingTimeInterval(-120), output: "Exporting data...", status: .completed, endTime: Date()))
    
    return RunningScriptsView(
        viewModel: viewModel,
        isDarkMode: false,
        onScriptSelect: { _ in },
        onScriptCancel: { _ in }
    )
    .frame(width: 400, height: 200)
    .padding()
}

#Preview("Running Scripts - Empty") {
    RunningScriptsView(
        viewModel: RunningScriptsViewModel(),
        isDarkMode: true,
        onScriptSelect: { _ in },
        onScriptCancel: { _ in }
    )
    .frame(width: 400, height: 100)
    .padding()
}
