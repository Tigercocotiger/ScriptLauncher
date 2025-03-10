import SwiftUI

struct ScriptsListPanel: View {
    @ObservedObject var viewModel: ContentViewModel
    // Utiliser une valeur Bool simple au lieu d'un binding
    var isSearchFocused: Bool
    var onSearchFocusChange: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Sélecteur de dossier cible
            FolderSelector(
                currentPath: viewModel.targetFolderPath,
                isDarkMode: viewModel.isDarkMode,
                onFolderSelected: { newPath in
                    // Mettre à jour le chemin dans ConfigManager
                    ConfigManager.shared.folderPath = newPath
                    
                    // Mettre à jour l'état local
                    viewModel.targetFolderPath = newPath
                    
                    // Recharger les scripts
                    viewModel.loadScripts()
                }
            )
            
            SearchBar(
                searchText: $viewModel.searchText,
                showFavoritesOnly: $viewModel.showFavoritesOnly,
                isDarkMode: $viewModel.isDarkMode,
                showHelp: $viewModel.showHelp,
                isGridView: $viewModel.isGridView,
                isFocused: isSearchFocused,
                onFocusChange: onSearchFocusChange
            )
            
            // Conditionnellement afficher la vue liste ou grille avec sélection multiple
            if viewModel.isGridView {
                MultiselectScriptGridView(
                    scripts: viewModel.scripts,
                    isDarkMode: viewModel.isDarkMode,
                    showFavoritesOnly: viewModel.showFavoritesOnly,
                    searchText: viewModel.searchText,
                    tagsViewModel: viewModel.tagsViewModel,
                    onToggleSelect: viewModel.toggleScriptSelection,
                    onToggleFavorite: viewModel.toggleFavorite,
                    onUpdateTags: viewModel.updateScriptTags,
                    onSelectAll: viewModel.selectAllScripts,
                    onUnselectAll: viewModel.unselectAllScripts
                )
            } else {
                MultiselectScriptsList(
                    scripts: viewModel.scripts,
                    isDarkMode: viewModel.isDarkMode,
                    showFavoritesOnly: viewModel.showFavoritesOnly,
                    searchText: viewModel.searchText,
                    tagsViewModel: viewModel.tagsViewModel,
                    onToggleSelect: viewModel.toggleScriptSelection,
                    onToggleFavorite: viewModel.toggleFavorite,
                    onUpdateTags: viewModel.updateScriptTags,
                    onSelectAll: viewModel.selectAllScripts,
                    onUnselectAll: viewModel.unselectAllScripts
                )
            }
            
            // Boutons d'action
            VStack(spacing: DesignSystem.smallSpacing) {
                // Bouton pour exécuter tous les scripts sélectionnés
                ExecuteSelectedScriptsButton(
                    selectedScriptsCount: viewModel.selectedScriptsCount,
                    isAnyScriptRunning: false,
                    isDarkMode: viewModel.isDarkMode,
                    onExecute: viewModel.executeSelectedScripts
                )
                
                // Bouton pour créer un installateur DMG
                CreateDMGInstallerButton(
                    isDarkMode: viewModel.isDarkMode,
                    targetFolder: viewModel.targetFolderPath,
                    onScriptCreated: viewModel.loadScripts
                )
            }
        }
        .background(DesignSystem.cardBackground(for: viewModel.isDarkMode))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
        .shadow(
            color: Color.black.opacity(DesignSystem.shadowOpacity(for: viewModel.isDarkMode)),
            radius: DesignSystem.shadowRadius,
            x: 0,
            y: DesignSystem.shadowY
        )
    }
}

#Preview("ScriptsListPanel") {
    let viewModel = ContentViewModel()
    viewModel.isDarkMode = false
    viewModel.scripts = [
        ScriptFile(name: "script1.scpt", path: "/path/1", isFavorite: true, lastExecuted: Date()),
        ScriptFile(name: "script2.applescript", path: "/path/2", isFavorite: false, lastExecuted: nil)
    ]
    
    return ScriptsListPanel(
        viewModel: viewModel,
        isSearchFocused: false,
        onSearchFocusChange: { _ in }
    )
    .frame(width: 500, height: 600)
}
