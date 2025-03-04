//
//  RunningScriptsView.swift
//  ScriptLauncher
//
//  Created for ScriptLauncher on 04/03/2025.
//

import SwiftUI

import SwiftUI

struct RunningScriptsView: View {
    let runningScripts: [RunningScript]
    let isDarkMode: Bool
    let onScriptSelect: (UUID) -> Void
    let onScriptCancel: (UUID) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // En-tête
            HStack {
                Spacer()
                
                Text("Scripts en cours d'exécution (\(runningScripts.count))")
                    .font(.headline)
                    .foregroundColor(DesignSystem.textPrimary(for: isDarkMode))
                
                Spacer()
                
                // Bouton pour annuler tous les scripts
                if !runningScripts.isEmpty {
                    Button(action: {
                        // Annuler tous les scripts
                        runningScripts.forEach { script in
                            onScriptCancel(script.id)
                        }
                    }) {
                        Text("Tout arrêter")
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
            .padding(.horizontal, DesignSystem.spacing)
            .padding(.vertical, 8)
            .background(isDarkMode ? Color(red: 0.18, green: 0.18, blue: 0.2) : Color(white: 0.97))
            
            if runningScripts.isEmpty {
                VStack(spacing: DesignSystem.spacing) {
                    Image(systemName: "play.slash.fill")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode).opacity(0.5))
                    
                    Text("Aucun script en cours d'exécution")
                        .foregroundColor(DesignSystem.textSecondary(for: isDarkMode))
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(DesignSystem.cardBackground(for: isDarkMode))
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(runningScripts) { script in
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
                            
                            if script.id != runningScripts.last?.id {
                                Divider()
                                    .padding(.leading, 40)
                            }
                        }
                    }
                }
            }
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
        .padding(.trailing, DesignSystem.spacing) // Ajout de la marge à droite
    }
}

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
            
            // Temps d'exécution écoulé
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
    RunningScriptsView(
        runningScripts: [
            RunningScript(id: UUID(), name: "Backup Script", startTime: Date().addingTimeInterval(-65), output: "Processing...", isSelected: true, status: .running),
            RunningScript(id: UUID(), name: "Export Data", startTime: Date().addingTimeInterval(-120), output: "Exporting data...", status: .completed, endTime: Date())
        ],
        isDarkMode: false,
        onScriptSelect: { _ in },
        onScriptCancel: { _ in }
    )
    .frame(width: 400, height: 200)
    .padding()
}

#Preview("Running Scripts - Empty") {
    RunningScriptsView(
        runningScripts: [],
        isDarkMode: true,
        onScriptSelect: { _ in },
        onScriptCancel: { _ in }
    )
    .frame(width: 400, height: 100)
    .padding()
}
