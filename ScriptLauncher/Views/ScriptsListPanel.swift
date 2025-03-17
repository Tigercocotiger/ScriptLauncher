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
            
            // Ajouter le filtre par tag avec les marges ajustées
            if !viewModel.tagsViewModel.tags.isEmpty {
                TagFilterControl(
                    tagsViewModel: viewModel.tagsViewModel,
                    selectedTag: $viewModel.selectedTag,
                    isDarkMode: viewModel.isDarkMode,
                    scripts: viewModel.scripts
                )
                .padding(.horizontal, DesignSystem.spacing)
                .padding(.bottom, 8) // Marge inférieure augmentée
            }
            
            // Conditionnellement afficher la vue liste ou grille avec sélection multiple
            if viewModel.isGridView {
                MultiselectScriptGridView(
                    scripts: viewModel.scripts,
                    isDarkMode: viewModel.isDarkMode,
                    showFavoritesOnly: viewModel.showFavoritesOnly,
                    searchText: viewModel.searchText,
                    selectedTag: viewModel.selectedTag,  // Nouveau paramètre
                    tagsViewModel: viewModel.tagsViewModel,
                    onToggleSelect: viewModel.toggleScriptSelection,
                    onToggleFavorite: viewModel.toggleFavorite,
                    onUpdateTags: viewModel.updateScriptTags,
                    onSelectAll: viewModel.selectAllScripts,
                    onUnselectAll: viewModel.unselectAllScripts,
                    onTagClick: viewModel.filterByTag,  // Passer la méthode
                    onScriptUpdated: { updatedScript in
                        // Appeler la méthode updateScriptProperties du ViewModel
                        viewModel.updateScriptProperties(updatedScript)
                    }
                )
            } else {
                MultiselectScriptsList(
                    scripts: viewModel.scripts,
                    isDarkMode: viewModel.isDarkMode,
                    showFavoritesOnly: viewModel.showFavoritesOnly,
                    searchText: viewModel.searchText,
                    selectedTag: viewModel.selectedTag,  // Nouveau paramètre
                    tagsViewModel: viewModel.tagsViewModel,
                    onToggleSelect: viewModel.toggleScriptSelection,
                    onToggleFavorite: viewModel.toggleFavorite,
                    onUpdateTags: viewModel.updateScriptTags,
                    onSelectAll: viewModel.selectAllScripts,
                    onUnselectAll: viewModel.unselectAllScripts,
                    onTagClick: viewModel.filterByTag,  // Passer la méthode
                    onScriptUpdated: { updatedScript in
                        // Appeler la méthode updateScriptProperties du ViewModel
                        viewModel.updateScriptProperties(updatedScript)
                    }
                )
            }
            
            // Bouton pour exécuter tous les scripts sélectionnés
            ExecuteSelectedScriptsButton(
                selectedScriptsCount: viewModel.selectedScriptsCount,
                isAnyScriptRunning: false,
                isDarkMode: viewModel.isDarkMode,
                onExecute: viewModel.executeSelectedScripts
            ).padding(.top, DesignSystem.spacing)
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
