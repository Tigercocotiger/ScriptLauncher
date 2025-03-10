//
//  ResultsPanel.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 10/03/2025.
//


import SwiftUI

struct ResultsPanel: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(spacing: DesignSystem.spacing) {
            // Bouton de configuration
            ConfigButton(
                isDarkMode: viewModel.isDarkMode,
                isEnabled: viewModel.isConfiguratorAvailable,
                onConfigPressed: {
                    // Lancer le script Configurator3000
                    viewModel.launchConfiguratorScript()
                    
                    // Déclencher le feu d'artifice centré
                    viewModel.showGlobalFirework = true
                }
            )
            
            // Section des scripts en cours d'exécution
            RunningScriptsView(
                viewModel: viewModel.runningScriptsVM,
                isDarkMode: viewModel.isDarkMode,
                onScriptSelect: { scriptId in
                    viewModel.runningScriptsVM.selectScript(id: scriptId)
                },
                onScriptCancel: viewModel.cancelScript
            )
            .frame(height: 300)
            .padding(0)
            
            // Section des résultats
            MultiResultSection(
                viewModel: viewModel.runningScriptsVM,
                isDarkMode: viewModel.isDarkMode
            )
            .frame(maxHeight: .infinity)
        }
    }
}

#Preview("ResultsPanel") {
    let viewModel = ContentViewModel()
    viewModel.isDarkMode = false
    
    return ResultsPanel(viewModel: viewModel)
        .frame(width: 400, height: 600)
}