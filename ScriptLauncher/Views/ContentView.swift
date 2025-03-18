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
            setupNotifications()
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
    
    // MARK: - Configuration des notifications
    private func setupNotifications() {
        // Écouter la commande de changement de dossier
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ChangeFolderCommand"),
            object: nil,
            queue: .main
        ) { [weak viewModel] _ in
            guard let viewModel = viewModel else { return }
            changeFolderTarget(viewModel: viewModel)
        }
    }
    
    // MARK: - Fonctions
    private func changeFolderTarget(viewModel: ContentViewModel) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        
        // Commencer dans le dossier actuel si possible
        let resolvedPath = ConfigManager.shared.resolveRelativePath(viewModel.targetFolderPath)
        if let url = URL(string: "file://" + resolvedPath), FileManager.default.fileExists(atPath: resolvedPath) {
            openPanel.directoryURL = url
        }
        
        openPanel.message = "Sélectionnez un dossier contenant des scripts AppleScript"
        openPanel.prompt = "Sélectionner"
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            // Vérifier que le dossier contient des scripts
            if ConfigManager.shared.isValidScriptFolder(url.path) {
                // Convertir en chemin relatif si possible pour le stockage
                let pathToStore = ConfigManager.shared.convertToRelativePath(url.path) ?? url.path
                
                // Mettre à jour le chemin dans ConfigManager
                ConfigManager.shared.folderPath = pathToStore
                
                // Mettre à jour l'état local
                viewModel.targetFolderPath = pathToStore
                
                // Recharger les scripts
                viewModel.loadScripts()
            } else {
                // Afficher une alerte si le dossier ne contient pas de scripts
                let alert = NSAlert()
                alert.messageText = "Dossier invalide"
                alert.informativeText = "Le dossier sélectionné ne contient pas de scripts (.scpt ou .applescript). Veuillez choisir un autre dossier."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
}
