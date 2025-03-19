import SwiftUI
import Combine
import Cocoa

struct ContentView: View {
    // MARK: - Properties
    @StateObject private var viewModel = ContentViewModel()
    @FocusState private var isSearchFieldFocused: Bool
    
    // Binding vers la propriété du ViewModel pour le panneau de résultats
    private var isResultsPanelExpanded: Binding<Bool> {
        Binding(
            get: { viewModel.isResultsPanelExpanded },
            set: { viewModel.isResultsPanelExpanded = $0 }
        )
    }
    
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
                        // Marge constante à gauche
                        Spacer()
                            .frame(width: DesignSystem.spacing)
                        
                        // Panel principal pour les scripts avec bouton de bascule intégré
                        ZStack(alignment: .trailing) {
                            // Panneau des scripts
                            ScriptsListPanel(
                                viewModel: viewModel,
                                isSearchFocused: isSearchFieldFocused,
                                onSearchFocusChange: { newValue in
                                    isSearchFieldFocused = newValue
                                }
                            )
                            .id(viewModel.viewRefreshID)
                            
                            // Bouton de bascule positionné sur la bordure droite
                            PanelToggleButton(
                                isDarkMode: viewModel.isDarkMode,
                                isExpanded: isResultsPanelExpanded
                            )
                            .padding(.vertical, geometry.size.height / 3)
                        }
                        .frame(width: calculateMainPanelWidth(totalWidth: geometry.size.width))
                        .padding(.vertical, DesignSystem.spacing)
                        
                        // Espacement entre les panneaux
                        Spacer()
                            .frame(width: DesignSystem.spacing)
                        
                        // Panneau de résultats avec animation
                        if isResultsPanelExpanded.wrappedValue {
                            ResultsPanel(viewModel: viewModel)
                                .frame(width: calculateResultsPanelWidth(totalWidth: geometry.size.width))
                                .transition(.move(edge: .trailing))
                                .padding(.vertical, DesignSystem.spacing)
                            
                            // Marge droite fixe
                            Spacer()
                                .frame(width: DesignSystem.spacing)
                        } else {
                            // Marge droite fixe quand le panneau est fermé
                            Spacer()
                                .frame(width: DesignSystem.spacing)
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
        if isResultsPanelExpanded.wrappedValue {
            // Quand le panneau est ouvert: 60% de l'espace disponible après marges
            let usableWidth = totalWidth - (DesignSystem.spacing * 3)
            return usableWidth * 0.6 // Modifié à 60% comme demandé
        } else {
            // Quand le panneau est fermé: tout l'espace disponible moins marges
            return totalWidth - (DesignSystem.spacing * 2)
        }
    }
    
    // Fonction pour calculer la largeur du panneau de résultats
    private func calculateResultsPanelWidth(totalWidth: CGFloat) -> CGFloat {
        // 40% de l'espace disponible après marges (correspondant aux 60% du panneau principal)
        let usableWidth = totalWidth - (DesignSystem.spacing * 3)
        return usableWidth * 0.4
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
        
        // Notification pour basculer le panneau de résultats
        // Cette notification est maintenant traitée par le ViewModel,
        // mais nous la conservons ici pour l'animation
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ToggleResultsPanel"),
            object: nil,
            queue: .main
        ) { _ in
            // La notification est maintenant traitée par le ViewModel
            // Rien à faire ici car l'animation est gérée dans le ViewModel
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
