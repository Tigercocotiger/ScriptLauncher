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
            // En-tête avec titre et bouton
            HeaderView(
                viewModel: viewModel,
                isDarkMode: isDarkMode,
                onCancelAll: {
                    cancelRunningScripts()
                }
            )
            
            // Zone de contenu
            ContentAreaView(
                viewModel: viewModel,
                isDarkMode: isDarkMode,
                refreshID: refreshID,
                onScriptSelect: onScriptSelect,
                onScriptCancel: onScriptCancel
            )
            
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
        // IMPORTANT: S'abonner aux changements du viewModel
        .onReceive(viewModel.objectWillChange) { _ in
            // Forcer le rafraîchissement de la vue
            refreshID = UUID()
            print("[RunningScriptsView] Rafraîchissement forcé")
        }
    }
    
    // Fonction pour annuler tous les scripts en cours
    private func cancelRunningScripts() {
        viewModel.scripts.filter { $0.status == .running }.forEach { script in
            onScriptCancel(script.id)
        }
    }
}

// Vue d'en-tête extraite
struct HeaderView: View {
    @ObservedObject var viewModel: RunningScriptsViewModel
    let isDarkMode: Bool
    let onCancelAll: () -> Void
    
    var body: some View {
        ZStack {
            // Titre centré
            Text("Scripts en cours d'exécution (\(viewModel.scripts.count))")
                .font(.headline)
                .foregroundColor(DesignSystem.accentColor(for: isDarkMode))
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Bouton Stop à droite (uniquement si des scripts sont en cours)
            if !viewModel.scripts.isEmpty {
                HStack {
                    Spacer()
                    StopButton(onCancelAll: onCancelAll)
                }
            }
        }
        .padding(.top, DesignSystem.spacing)
        .padding(.bottom, 8)
        .padding(.horizontal, DesignSystem.spacing)
    }
}

// Bouton Stop extrait
struct StopButton: View {
    let onCancelAll: () -> Void
    
    var body: some View {
        Button(action: onCancelAll) {
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
}

// Zone de contenu extraite
struct ContentAreaView: View {
    @ObservedObject var viewModel: RunningScriptsViewModel
    let isDarkMode: Bool
    let refreshID: UUID
    let onScriptSelect: (UUID) -> Void
    let onScriptCancel: (UUID) -> Void
    
    var body: some View {
        ZStack {
            // Affichage quand aucun script n'est en cours
            if viewModel.scripts.isEmpty {
                EmptyStateView(isDarkMode: isDarkMode)
            } else {
                // Liste des scripts en cours
                ScriptListView(
                    viewModel: viewModel,
                    isDarkMode: isDarkMode,
                    refreshID: refreshID,
                    onScriptSelect: onScriptSelect,
                    onScriptCancel: onScriptCancel
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color.white)
        .cornerRadius(DesignSystem.smallCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(DesignSystem.spacing)
    }
}

// Vue d'état vide extraite
struct EmptyStateView: View {
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.spacing) {
            Image(systemName: "play.slash.fill")
                .font(.system(size: 32))
                .foregroundColor(DesignSystem.textSecondary(for: isDarkMode).opacity(0.5))
            
            Text("Aucun script en cours d'exécution")
                .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
        }
    }
}

// Vue de liste de scripts extraite
struct ScriptListView: View {
    @ObservedObject var viewModel: RunningScriptsViewModel
    let isDarkMode: Bool
    let refreshID: UUID
    let onScriptSelect: (UUID) -> Void
    let onScriptCancel: (UUID) -> Void
    
    // État pour suivre les scripts précédents pour comparaison
    @State private var previousScripts: [RunningScript] = []
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.scripts) { script in
                        RunningScriptRow(
                            script: script,
                            isDarkMode: isDarkMode,
                            onSelect: { onScriptSelect(script.id) },
                            onCancel: { onScriptCancel(script.id) }
                        )
                        .id(script.id) // ID stable pour chaque élément
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
                    
                    // Marque la fin de la liste
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.bottom, 20)
            }
            .onChange(of: viewModel.scripts) { scripts in
                // Vérifier si seulement les temps ont changé
                let structureChanged = scriptsStructureChanged(old: previousScripts, new: scripts)
                
                // Si la structure a changé (scripts ajoutés/supprimés/statut changé)
                if structureChanged {
                    withAnimation {
                        scrollProxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                
                // Mettre à jour la référence
                previousScripts = scripts
            }
        }
    }
    
    // Fonction pour déterminer si la structure a changé ou seulement les temps
    private func scriptsStructureChanged(old: [RunningScript], new: [RunningScript]) -> Bool {
        // Si le nombre de scripts a changé
        if old.count != new.count {
            return true
        }
        
        // Vérifier si les scripts sont les mêmes
        for i in 0..<old.count {
            if old[i].id != new[i].id || old[i].status != new[i].status {
                return true
            }
        }
        
        return false
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
            StatusIndicator(status: script.status)
            
            // Nom du script
            Text(script.name)
                .font(.system(size: 13))
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
            
            Spacer()
            
            // Temps d'exécution écoulé
            Text(script.elapsedTime)
                .font(.caption)
                .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                .frame(width: 60, alignment: .trailing)
                .transaction { transaction in
                    // Désactiver l'animation pour éviter les sauts
                    transaction.animation = nil
                }
            
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

// Indicateur de statut extrait
struct StatusIndicator: View {
    let status: ScriptStatus
    
    var body: some View {
        Group {
            if status == .running {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .padding(4)
            } else if status == .completed {
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
        }
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

#Preview("Running Scripts - With 10 Scripts (Dark Mode)") {
    // Créer un ViewModel pour la prévisualisation avec 10 scripts
    let viewModel = RunningScriptsViewModel()
    
    // Ajouter 10 scripts avec différents états
    viewModel.addScript(RunningScript(id: UUID(), name: "Backup Script", startTime: Date().addingTimeInterval(-65), output: "Processing...", isSelected: true, status: .running))
    viewModel.addScript(RunningScript(id: UUID(), name: "Export Data", startTime: Date().addingTimeInterval(-120), output: "Exporting data...", status: .completed, endTime: Date()))
    viewModel.addScript(RunningScript(id: UUID(), name: "Database Cleanup", startTime: Date().addingTimeInterval(-240), output: "Cleaning old records...", status: .running))
    viewModel.addScript(RunningScript(id: UUID(), name: "File Conversion", startTime: Date().addingTimeInterval(-350), output: "Converting files...", status: .running))
    viewModel.addScript(RunningScript(id: UUID(), name: "Network Diagnostics", startTime: Date().addingTimeInterval(-430), output: "Testing connection...", status: .failed, endTime: Date().addingTimeInterval(-10)))
    viewModel.addScript(RunningScript(id: UUID(), name: "System Update", startTime: Date().addingTimeInterval(-510), output: "Updating system files...", status: .running))
    viewModel.addScript(RunningScript(id: UUID(), name: "Log Analyzer", startTime: Date().addingTimeInterval(-620), output: "Analyzing logs...", status: .completed, endTime: Date().addingTimeInterval(-60)))
    viewModel.addScript(RunningScript(id: UUID(), name: "Security Scan", startTime: Date().addingTimeInterval(-730), output: "Scanning for vulnerabilities...", status: .running))
    viewModel.addScript(RunningScript(id: UUID(), name: "Configuration Backup", startTime: Date().addingTimeInterval(-860), output: "Backing up configurations...", status: .completed, endTime: Date().addingTimeInterval(-120)))
    viewModel.addScript(RunningScript(id: UUID(), name: "Media Indexer", startTime: Date().addingTimeInterval(-950), output: "Indexing media files...", status: .running))
    
    // Composant avec les 10 scripts en mode sombre
    return RunningScriptsView(
        viewModel: viewModel,
        isDarkMode: true,
        onScriptSelect: { _ in },
        onScriptCancel: { _ in }
    )
    .frame(width: 400, height: 300)
    .padding()
    .background(Color.black)
}
