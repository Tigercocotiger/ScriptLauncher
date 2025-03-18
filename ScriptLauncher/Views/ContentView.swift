import SwiftUI
import Combine
import Cocoa

struct ContentView: View {
    // MARK: - Properties
    @StateObject private var viewModel = ContentViewModel()
    @FocusState private var isSearchFieldFocused: Bool
    @State private var isResultsPanelExpanded = true // État pour le panneau de résultats
    @State private var resultsPanelWidth: CGFloat = 0 // Stocke la largeur du panneau
    
    // Constante pour les marges uniformes
    private let standardMargin: CGFloat = 15
    private let toggleButtonWidth: CGFloat = 16
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fond d'écran global
                DesignSystem.backgroundColor(for: viewModel.isDarkMode)
                    .ignoresSafeArea()
                
                if geometry.size.width > 700 {
                    // Vue horizontale pour les grandes fenêtres
                    HStack(alignment: .top, spacing: 0) {
                        // Marge gauche fixe
                        Spacer()
                            .frame(width: standardMargin)
                        
                        // Panel principal pour les scripts
                        ScriptsListPanel(
                            viewModel: viewModel,
                            isSearchFocused: isSearchFieldFocused,
                            onSearchFocusChange: { newValue in
                                isSearchFieldFocused = newValue
                            }
                        )
                        .frame(width: calculateMainPanelWidth(totalWidth: geometry.size.width))
                        .id(viewModel.viewRefreshID)
                        .padding(.vertical, DesignSystem.spacing)
                        
                        // Bouton de bascule
                        PanelToggleButton(
                            isDarkMode: viewModel.isDarkMode,
                            isExpanded: $isResultsPanelExpanded
                        )
                        .padding(.vertical, geometry.size.height / 3)
                        
                        // Panneau de résultats avec animation
                        if isResultsPanelExpanded {
                            // Espacement entre le bouton et le panneau de résultats
                            Spacer()
                                .frame(width: 0) // Pas d'espace supplémentaire après le bouton
                            
                            ResultsPanel(viewModel: viewModel)
                                .frame(width: calculateResultsPanelWidth(totalWidth: geometry.size.width))
                                .transition(.move(edge: .trailing))
                                .padding(.vertical, DesignSystem.spacing)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .preference(key: WidthPreferenceKey.self, value: geo.size.width)
                                            .onAppear {
                                                // Stocker la largeur initiale
                                                if resultsPanelWidth == 0 {
                                                    resultsPanelWidth = geo.size.width
                                                }
                                            }
                                    }
                                )
                            
                            // Marge droite fixe
                            Spacer()
                                .frame(width: standardMargin)
                        } else {
                        }
                    }
                    .onPreferenceChange(WidthPreferenceKey.self) { width in
                        if width > 0 {
                            resultsPanelWidth = width
                        }
                    }
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
        .onReceive(Just(viewModel.isEditMode)) { newValue in
            // Sauvegarde la préférence du mode d'édition
            ConfigManager.shared.isEditMode = newValue
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
    
    // Fonction pour calculer la largeur du panneau principal
    private func calculateMainPanelWidth(totalWidth: CGFloat) -> CGFloat {
        if isResultsPanelExpanded {
            // Quand le panneau est ouvert: environ 55% de l'espace disponible après marges
            let usableWidth = totalWidth - (standardMargin * 3) - toggleButtonWidth
            return usableWidth * 0.55
        } else {
            // Quand le panneau est fermé: tout l'espace disponible moins marges et bouton
            return totalWidth - (standardMargin * 2) - toggleButtonWidth
        }
    }
    
    // Fonction pour calculer la largeur du panneau de résultats
    private func calculateResultsPanelWidth(totalWidth: CGFloat) -> CGFloat {
        // Environ 45% de l'espace disponible après marges
        let usableWidth = totalWidth - (standardMargin * 3) - toggleButtonWidth
        return usableWidth * 0.45
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
        
        // Nouvelle notification pour le mode d'édition
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ToggleEditMode"),
            object: nil,
            queue: .main
        ) { [weak viewModel] _ in
            guard let viewModel = viewModel else { return }
            viewModel.isEditMode.toggle()
        }
        
        // Nouvelle notification pour basculer le panneau de résultats
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ToggleResultsPanel"),
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.isResultsPanelExpanded.toggle()
            }
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

// Clé de préférence pour capturer la largeur
struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
