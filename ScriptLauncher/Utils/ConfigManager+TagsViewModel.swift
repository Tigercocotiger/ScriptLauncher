//
//  ConfigManager+TagsViewModel.swift
//  ScriptLauncher
//
//  Created on 10/03/2025.
//  Updated on 25/03/2025. - Fixed path handling
//

import SwiftUI

// Étendre ConfigManager pour ajouter l'accès au TagsViewModel global
extension ConfigManager {
    // Instance partagée du TagsViewModel
    private static var globalTagsViewModel: TagsViewModel?
    
    // Méthode pour accéder au TagsViewModel global
    func getTagsViewModel() -> TagsViewModel {
        if ConfigManager.globalTagsViewModel == nil {
            ConfigManager.globalTagsViewModel = TagsViewModel()
            // Charge les tags actuels depuis la configuration
            ConfigManager.globalTagsViewModel?.loadTags()
        }
        return ConfigManager.globalTagsViewModel!
    }
}
