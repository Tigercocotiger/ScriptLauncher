import SwiftUI
import Combine
import Cocoa

struct ContentView: View {
    // MARK: - Properties
    @StateObject private var viewModel = ContentViewModel()
    @FocusState private var isSearchFieldFocused: Bool
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fond d'écran global
                DesignSystem.backgroundColor(for: viewModel.isDarkMode)
                    .ignoresSafeArea()
                
                if geometry.size.width > 700 {
                    // Vue horizontale pour les grandes fenêtres
                    HStack(alignment: .top, spacing: DesignSystem.spacing) {
                        ScriptsListPanel(
                            viewModel: viewModel,
                            isSearchFocused: isSearchFieldFocused,
                            onSearchFocusChange: { newValue in
                                isSearchFieldFocused = newValue
                            }
                        )
                        .frame(width: geometry.size.width * 0.62 - DesignSystem.spacing)
                        .id(viewModel.viewRefreshID) // Forcer le rechargement lors des modifications de tags
                        
                        ResultsPanel(viewModel: viewModel)
                            .padding(.top, 0)
                            .padding(.trailing, DesignSystem.spacing)
                            .frame(width: geometry.size.width * 0.38 - DesignSystem.spacing)
                    }
                    .padding(DesignSystem.spacing)
                } else {
                    // Vue verticale pour les petites fenêtres
                    VStack(alignment: .leading, spacing: DesignSystem.spacing) {
                        ScriptsListPanel(
                            viewModel: viewModel,
                            isSearchFocused: isSearchFieldFocused,
                            onSearchFocusChange: { newValue in
                                isSearchFieldFocused = newValue
                            }
                        )
                        .frame(height: geometry.size.height * 0.5)
                        .id(viewModel.viewRefreshID)
                        
                        ResultsPanel(viewModel: viewModel)
                    }
                    .padding(DesignSystem.spacing)
                }
            }
            .overlay(
                SimpleCenteredFirework(isVisible: $viewModel.showGlobalFirework)
            )
        }
        .onAppear {
            viewModel.initialize()
        }
        .onReceive(Just(viewModel.isDarkMode)) { newValue in
            // Sauvegarde la préférence de thème
            ConfigManager.shared.isDarkMode = newValue
        }
        .onReceive(Just(viewModel.isGridView)) { newValue in
            // Sauvegarde la préférence de vue
            ConfigManager.shared.isGridView = newValue
        }
        .sheet(isPresented: $viewModel.showHelp) {
            HelpView(
                helpSections: HelpContent.helpSections,
                isDarkMode: viewModel.isDarkMode
            )
        }
        .sheet(isPresented: $viewModel.showDMGInstallerCreator) {
            DMGInstallerCreatorView(
                isPresented: $viewModel.showDMGInstallerCreator,
                targetFolder: viewModel.targetFolderPath,
                onScriptCreated: viewModel.loadScripts,
                isDarkMode: viewModel.isDarkMode
            )
        }
    }
}

// MARK: - Preview
#Preview("Content View - Multi Select") {
    ContentView()
        .frame(width: 1000, height: 650)
}

#Preview("Content View - Dark Mode") {
    ContentView()
        .frame(width: 1000, height: 650)
        .preferredColorScheme(.dark)
}
