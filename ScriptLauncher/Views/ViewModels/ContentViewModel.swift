//
//  ContentViewModel.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 10/03/2025.
//


import SwiftUI
import Combine

class ContentViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var scripts: [ScriptFile] = []
    @Published var selectedScript: ScriptFile?
    @Published var errorMessage: String = ""
    @Published var searchText: String = ""
    @Published var showFavoritesOnly: Bool = false
    @Published var showHelp: Bool = false
    @Published var isDarkMode: Bool = false
    @Published var isGridView: Bool = false
    @Published var targetFolderPath: String = ConfigManager.shared.folderPath
    
    // Animation
    @Published var showGlobalFirework: Bool = false
    
    // Configurator
    @Published var isConfiguratorAvailable: Bool = false
    
    // Sélection
    @Published var selectedScripts: [UUID] = []
    
    // Vues auxiliaires
    @Published var showDMGInstallerCreator = false
    
    // ID de rafraîchissement pour forcer la mise à jour des vues
    @Published var viewRefreshID = UUID()
    
    // MARK: - Internal Properties
    // Tags
    let tagsViewModel = TagsViewModel()
    
    // Execution
    let runningScriptsVM = RunningScriptsViewModel()
    let scriptManager = ScriptProcessManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var selectedScriptsCount: Int {
        scripts.filter { $0.isSelected }.count
    }
    
    // MARK: - Initialization
    func initialize() {
        loadScripts()
        loadFavorites()
        loadScriptTags()
        
        // Chargement des préférences
        isDarkMode = ConfigManager.shared.isDarkMode
        isGridView = ConfigManager.shared.isGridView
        targetFolderPath = ConfigManager.shared.folderPath
        
        setupNotificationObservers()
    }
    
    // MARK: - Script Management
    func loadScripts() {
        let folderPath = targetFolderPath
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(atPath: folderPath)
            
            // Filtrer les scripts AppleScript mais exclure Configurator3000.scpt
            scripts = files
                .filter {
                    // Inclure seulement les fichiers .scpt et .applescript
                    ($0.hasSuffix(".scpt") || $0.hasSuffix(".applescript")) &&
                    // Mais exclure Configurator3000.scpt
                    $0 != "Configurator3000.scpt"
                }
                .map { ScriptFile(
                    name: $0,
                    path: (folderPath as NSString).appendingPathComponent($0),
                    isFavorite: false,
                    lastExecuted: nil,
                    isSelected: false
                )}
                .sorted { $0.name < $1.name }
            
            // Vérifier si le configurateur est présent dans ce dossier
            let configuratorPath = (folderPath as NSString).appendingPathComponent("Configurator3000.scpt")
            isConfiguratorAvailable = fileManager.fileExists(atPath: configuratorPath)
            print("Configurateur trouvé: \(isConfiguratorAvailable) à \(configuratorPath)")
            
        } catch {
            errorMessage = "Erreur lors de la lecture du dossier: \(error.localizedDescription)"
            scripts = []
            isConfiguratorAvailable = false
        }
        
        // Charger les tags et favoris après avoir chargé les scripts
        loadFavorites()
        loadScriptTags()
    }
    
    func selectAllScripts() {
        let filtered = scripts.filter { script in
            let matchesSearch = searchText.isEmpty || script.name.localizedCaseInsensitiveContains(searchText)
            let matchesFavorite = !showFavoritesOnly || script.isFavorite
            return matchesSearch && matchesFavorite
        }
        
        for index in 0..<scripts.count {
            if filtered.contains(where: { $0.id == scripts[index].id }) {
                scripts[index].isSelected = true
            }
        }
    }
    
    func unselectAllScripts() {
        for index in 0..<scripts.count {
            scripts[index].isSelected = false
        }
    }
    
    func toggleScriptSelection(_ script: ScriptFile) {
        if let index = scripts.firstIndex(where: { $0.id == script.id }) {
            scripts[index].isSelected.toggle()
            
            // Maintenir la compatibilité avec selectedScript
            if scripts[index].isSelected && selectedScript == nil {
                selectedScript = scripts[index]
            } else if !scripts[index].isSelected && selectedScript?.id == script.id {
                // Si le script désélectionné était le selectedScript, trouver un autre script sélectionné
                selectedScript = scripts.first(where: { $0.isSelected })
            }
        }
    }
    
    // MARK: - Tag Management
    func updateScriptTags(_ updatedScript: ScriptFile) {
        if let index = scripts.firstIndex(where: { $0.id == updatedScript.id }) {
            scripts[index].tags = updatedScript.tags
            
            // Mettre à jour les tags dans le ViewModel
            tagsViewModel.updateScriptTags(scriptPath: updatedScript.path, tags: updatedScript.tags)
            
            // Forcer le rafraîchissement des vues
            viewRefreshID = UUID()
        }
    }
    
    func loadScriptTags() {
        // Mettre à jour chaque script avec ses tags
        for index in 0..<scripts.count {
            let scriptPath = scripts[index].path
            let tags = tagsViewModel.getTagsForScript(path: scriptPath)
            scripts[index].tags = tags
        }
    }
    
    // MARK: - Favorites Management
    func toggleFavorite(_ script: ScriptFile) {
        if let index = scripts.firstIndex(where: { $0.id == script.id }) {
            let wasSelected = selectedScript?.id == scripts[index].id
            scripts[index].isFavorite.toggle()
            saveFavorites()
            
            if wasSelected {
                selectedScript = scripts[index]
            }
        }
    }
    
    func saveFavorites() {
        let favoritePaths = Set(scripts.filter { $0.isFavorite }.map { $0.path })
        ConfigManager.shared.favorites = favoritePaths
    }
    
    func loadFavorites() {
        let favoritesPaths = ConfigManager.shared.favorites
        for (index, script) in scripts.enumerated() where favoritesPaths.contains(script.path) {
            scripts[index].isFavorite = true
        }
    }
    
    // MARK: - Script Execution
    func executeSelectedScripts() {
        let selectedScriptsList = scripts.filter { $0.isSelected }
        
        // Si aucun script n'est sélectionné mais qu'il y a un script "actif", l'exécuter
        if selectedScriptsList.isEmpty, let script = selectedScript {
            executeScript(script: script)
            return
        }
        
        // Exécuter chaque script sélectionné
        for script in selectedScriptsList {
            executeScript(script: script)
        }
    }
    
    func executeScript(script: ScriptFile) {
        // Vérifier si ce script est déjà dans la liste des scripts exécutés
        if runningScriptsVM.scripts.contains(where: { $0.id == script.id }) {
            // Le script existe déjà dans la liste, le réinitialiser
            let now = Date()
            runningScriptsVM.updateScript(
                id: script.id,
                output: "Démarrage d'une nouvelle exécution...\n",
                status: .running,
                endTime: nil
            )
            // Mettre à jour le temps de démarrage
            runningScriptsVM.resetScriptStartTime(id: script.id, startTime: now)
        } else {
            // Créer un nouvel objet RunningScript
            let newRunningScript = RunningScript(
                id: script.id,
                name: script.name,
                startTime: Date(),
                output: "Démarrage de l'exécution...\n"
            )
            
            // Ajouter le script à la liste des scripts en cours
            runningScriptsVM.addScript(newRunningScript)
        }
        
        // Mise à jour de la date d'exécution du script dans la liste principale
        if let index = self.scripts.firstIndex(where: { $0.id == script.id }) {
            self.scripts[index].lastExecuted = Date()
        }
        
        // Exécuter le script et s'abonner aux mises à jour
        let outputPublisher = scriptManager.executeScript(script: script)
        
        outputPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (scriptId, output, status, endTime) in
                // Mettre à jour la sortie du script correspondant
                self?.runningScriptsVM.updateScript(id: scriptId, output: output, status: status, endTime: endTime)
            }
            .store(in: &cancellables)
    }
    
    func cancelScript(id: UUID) {
        // Arrêter le processus d'exécution
        scriptManager.cancelScript(id: id)
        
        // Mettre à jour le statut du script au lieu de le supprimer
        if let script = runningScriptsVM.scripts.first(where: { $0.id == id && $0.status == .running }) {
            runningScriptsVM.updateScript(
                id: id,
                output: script.output + "\n\nScript arrêté par l'utilisateur.",
                status: .failed,
                endTime: Date()
            )
        }
    }
    
    func cancelAllScripts() {
        // Annuler tous les processus en cours
        scriptManager.cancelAllScripts()
        
        // Mettre à jour le statut des scripts en cours d'exécution
        for script in runningScriptsVM.scripts.filter({ $0.status == .running }) {
            runningScriptsVM.updateScript(
                id: script.id,
                output: script.output + "\n\nScript arrêté par l'utilisateur.",
                status: .failed,
                endTime: Date()
            )
        }
    }
    
    // MARK: - Special Scripts
    func launchConfiguratorScript() {
        let configuratorPath = (targetFolderPath as NSString).appendingPathComponent("Configurator3000.scpt")
        
        if FileManager.default.fileExists(atPath: configuratorPath) {
            // Créer un ScriptFile factice pour le configurateur
            let configScript = ScriptFile(
                name: "Configurator3000.scpt",
                path: configuratorPath,
                isFavorite: false,
                lastExecuted: nil
            )
            
            // Utiliser la fonction d'exécution existante
            executeScript(script: configScript)
        } else {
            print("Script Configurator3000 non trouvé à: \(configuratorPath)")
        }
    }
    
    // MARK: - Notification Observers
    private func setupNotificationObservers() {
        // Observateurs pour les commandes du menu
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ExecuteSelectedScript"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if let script = self.selectedScript {
                self.executeScript(script: script)
            } else if self.selectedScriptsCount > 0 {
                self.executeSelectedScripts()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ToggleFavorite"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, let script = self.selectedScript else { return }
            self.toggleFavorite(script)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ToggleViewMode"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.isGridView.toggle()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ToggleDarkMode"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.isDarkMode.toggle()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ToggleHelp"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.showHelp.toggle()
        }
        
        // Ajout d'un nouvel observateur pour annuler tous les scripts
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CancelAllScripts"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.cancelAllScripts()
        }
        
        // Ajouter observateur pour la sélection de tous les scripts
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SelectAllScripts"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.selectAllScripts()
        }
        
        // Observateur pour les modifications globales des tags
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("GlobalTagsChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Forcer le rafraîchissement de l'interface
            self?.viewRefreshID = UUID()
        }
        
        // Observateur pour la création d'un installateur DMG
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CreateDMGInstaller"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showDMGInstallerCreator = true
        }
    }
}