import SwiftUI
import Combine
import Cocoa

struct ContentView: View {
    // MARK: - Properties
    private let folderPath = "/Volumes/Marco/Dév/Fonctionnel"
    @State private var scripts: [ScriptFile] = []
    @State private var selectedScript: ScriptFile? // Maintenu pour la compatibilité
    @State private var errorMessage: String = ""
    @State private var searchText: String = ""
    @State private var showFavoritesOnly: Bool = false
    @State private var showHelp: Bool = false
    @State private var isDarkMode: Bool = false
    @State private var isGridView: Bool = false
    @FocusState private var isSearchFieldFocused: Bool
    
    // Nouvelles propriétés pour la sélection multiple
    @State private var selectedScripts: [UUID] = []
    
    // Propriétés pour l'exécution multiple avec timer
    @StateObject private var runningScriptsVM = RunningScriptsViewModel()
    @StateObject private var scriptManager = ScriptProcessManager()
    @State private var cancellables = Set<AnyCancellable>()
    
    // Nombre de scripts sélectionnés
    private var selectedScriptsCount: Int {
        scripts.filter { $0.isSelected }.count
    }
    
    // Liste des sections d'aide
    private let helpSections = [
        HelpSection(
            title: "Raccourcis clavier",
            content: """
            • ⌘ + Entrée : Exécuter le script sélectionné
            • ⌘ + ⇧ + Entrée : Exécuter tous les scripts sélectionnés
            • ⌘ + ⌥ + A : Sélectionner tous les scripts visibles
            • ⌘ + I : Afficher/masquer l'aide
            • ⌘ + S : Ajouter/retirer des favoris
            • ⌘ + G : Basculer entre vue liste et grille
            • ⌘ + D : Basculer entre mode clair et sombre
            • ⌘ + . : Arrêter tous les scripts en cours
            • Échap : Annuler la recherche ou fermer l'aide
            """
        ),
        HelpSection(
            title: "Sélection multiple",
            content: """
            Vous pouvez sélectionner plusieurs scripts pour les exécuter en même temps :
            
            1. Cochez les cases à côté des scripts que vous souhaitez exécuter
            2. Utilisez le raccourci ⌘ + ⌥ + A pour sélectionner tous les scripts visibles
            3. Utilisez les boutons "Tout sélectionner" ou "Désélectionner tout" 
            4. Cliquez sur "Exécuter X scripts" pour lancer tous les scripts sélectionnés
            
            La sélection multiple vous permet d'automatiser plusieurs tâches simultanément.
            """
        ),
        HelpSection(
            title: "Gestion des favoris",
            content: """
            Pour ajouter un script aux favoris :
            • Cliquez sur l'icône d'étoile à côté du script
            • Sélectionnez le script et utilisez ⌘ + S
            
            Pour n'afficher que les favoris :
            • Activez le bouton d'étoile dans la barre de recherche
            
            Les favoris sont automatiquement sauvegardés dans les préférences de l'application.
            """
        ),
        HelpSection(
            title: "Scripts en cours d'exécution",
            content: """
            La section "Scripts en cours d'exécution" vous permet de :
            
            • Visualiser tous les scripts actuellement en exécution
            • Suivre leur progression et leur temps d'exécution
            • Arrêter un script spécifique ou tous les scripts
            • Consulter le résultat d'un script en le sélectionnant
            
            Le code couleur indique l'état de chaque script :
            🟠 En cours  🟢 Terminé  🔴 Erreur
            """
        ),
        HelpSection(
            title: "Recherche et filtrage",
            content: """
            La barre de recherche vous permet de filtrer rapidement vos scripts :
            
            • Tapez un terme pour filtrer les scripts par nom
            • Combinez la recherche avec le filtre de favoris
            • Appuyez sur Échap pour effacer la recherche
            
            Le résultat de la recherche s'affiche instantanément dans la liste des scripts.
            """
        ),
    ]
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fond d'écran global
                DesignSystem.backgroundColor(for: isDarkMode)
                    .ignoresSafeArea()
                
                if geometry.size.width > 700 {
                    // Vue horizontale pour les grandes fenêtres
                    HStack(alignment: .top, spacing: DesignSystem.spacing) {
                        scriptsSection
                            .frame(width: geometry.size.width * 0.62 - DesignSystem.spacing)
                        
                        VStack(spacing: 24) {
                            // Section des scripts en cours d'exécution
                            RunningScriptsView(
                                viewModel: runningScriptsVM,
                                isDarkMode: isDarkMode,
                                onScriptSelect: { scriptId in
                                    runningScriptsVM.selectScript(id: scriptId)
                                },
                                onScriptCancel: cancelScript
                            )
                            .frame(height: 300)
                            .padding(0)
                            
                            // Section des résultats
                            MultiResultSection(
                                viewModel: runningScriptsVM,
                                isDarkMode: isDarkMode
                            )
                            .frame(maxHeight: .infinity)
                        }
                        .padding(.top, 0)
                        .padding(.trailing, DesignSystem.spacing)
                        .frame(width: geometry.size.width * 0.38 - DesignSystem.spacing)
                    }
                    .padding(DesignSystem.spacing)
                } else {
                    // Vue verticale pour les petites fenêtres
                    VStack(alignment: .leading, spacing: DesignSystem.spacing) {
                        scriptsSection
                            .frame(height: geometry.size.height * 0.5)
                        
                        VStack(spacing: 24) {
                            // Section des scripts en cours d'exécution
                            RunningScriptsView(
                                viewModel: runningScriptsVM,
                                isDarkMode: isDarkMode,
                                onScriptSelect: { scriptId in
                                    runningScriptsVM.selectScript(id: scriptId)
                                },
                                onScriptCancel: cancelScript
                            )
                            .frame(height: 150)
                            
                            // Section des résultats
                            MultiResultSection(
                                viewModel: runningScriptsVM,
                                isDarkMode: isDarkMode
                            )
                            .frame(maxHeight: .infinity)
                        }
                    }
                    .padding(DesignSystem.spacing)
                }
            }
        }
        .onAppear {
            loadScripts()
            loadFavorites()
            loadViewPreferences()
            setupNotificationObservers()
            
            // Charge la préférence de thème si elle existe
            if let savedDarkMode = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool {
                isDarkMode = savedDarkMode
            }
        }
        .onReceive(Just(isDarkMode)) { newValue in
            // Sauvegarde la préférence de thème
            UserDefaults.standard.set(newValue, forKey: "isDarkMode")
        }
        .onReceive(Just(isGridView)) { newValue in
            // Sauvegarde la préférence de vue
            UserDefaults.standard.set(newValue, forKey: "isGridView")
        }
        .sheet(isPresented: $showHelp) {
            HelpView(helpSections: helpSections, isDarkMode: isDarkMode)
        }
    }
    
    // MARK: - Views
    
    // Section des scripts (barre de recherche + liste + bouton)
    private var scriptsSection: some View {
        VStack(spacing: DesignSystem.spacing) {
            SearchBar(
                searchText: $searchText,
                showFavoritesOnly: $showFavoritesOnly,
                isDarkMode: $isDarkMode,
                showHelp: $showHelp,
                isGridView: $isGridView,
                isFocused: isSearchFieldFocused,
                onFocusChange: { newValue in
                    isSearchFieldFocused = newValue
                }
            )
            
            // Conditionnellement afficher la vue liste ou grille avec sélection multiple
            if isGridView {
                MultiselectScriptGridView(
                    scripts: scripts,
                    isDarkMode: isDarkMode,
                    showFavoritesOnly: showFavoritesOnly,
                    searchText: searchText,
                    onToggleSelect: toggleScriptSelection,
                    onToggleFavorite: toggleFavorite,
                    onSelectAll: selectAllScripts,
                    onUnselectAll: unselectAllScripts
                )
            } else {
                MultiselectScriptsList(
                    scripts: scripts,
                    isDarkMode: isDarkMode,
                    showFavoritesOnly: showFavoritesOnly,
                    searchText: searchText,
                    onToggleSelect: toggleScriptSelection,
                    onToggleFavorite: toggleFavorite,
                    onSelectAll: selectAllScripts,
                    onUnselectAll: unselectAllScripts
                )
            }
            
            // Bouton pour exécuter tous les scripts sélectionnés
            ExecuteSelectedScriptsButton(
                selectedScriptsCount: selectedScriptsCount,
                isAnyScriptRunning: false,
                isDarkMode: isDarkMode,
                onExecute: executeSelectedScripts
            )
        }
        .background(DesignSystem.cardBackground(for: isDarkMode))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
        .shadow(
            color: Color.black.opacity(DesignSystem.shadowOpacity(for: isDarkMode)),
            radius: DesignSystem.shadowRadius,
            x: 0,
            y: DesignSystem.shadowY
        )
    }
    
    // MARK: - Functions
    
    // Configuration des observateurs de notifications
    private func setupNotificationObservers() {
        // Observateurs pour les commandes du menu
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ExecuteSelectedScript"),
            object: nil,
            queue: .main
        ) { _ in
            if let script = selectedScript {
                executeScript(script: script)
            } else if selectedScriptsCount > 0 {
                executeSelectedScripts()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ToggleFavorite"),
            object: nil,
            queue: .main
        ) { _ in
            if let script = selectedScript {
                toggleFavorite(script)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ToggleViewMode"),
            object: nil,
            queue: .main
        ) { _ in
            isGridView.toggle()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ToggleDarkMode"),
            object: nil,
            queue: .main
        ) { _ in
            isDarkMode.toggle()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ToggleHelp"),
            object: nil,
            queue: .main
        ) { _ in
            showHelp.toggle()
        }
        
        // Ajout d'un nouvel observateur pour annuler tous les scripts
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CancelAllScripts"),
            object: nil,
            queue: .main
        ) { _ in
            cancelAllScripts()
        }
        
        // Ajouter observateur pour la sélection de tous les scripts
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SelectAllScripts"),
            object: nil,
            queue: .main
        ) { _ in
            selectAllScripts()
        }
    }
    
    // Sélectionne tous les scripts visibles (filtres appliqués)
    private func selectAllScripts() {
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
    
    // Désélectionne tous les scripts
    private func unselectAllScripts() {
        for index in 0..<scripts.count {
            scripts[index].isSelected = false
        }
    }
    
    // Bascule la sélection d'un script
    private func toggleScriptSelection(_ script: ScriptFile) {
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
    
    // Annule tous les scripts en cours d'exécution
    private func cancelAllScripts() {
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
    
    // Annule un script spécifique
    private func cancelScript(id: UUID) {
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
    
    // Charge les préférences de vue
    private func loadViewPreferences() {
        if let savedGridView = UserDefaults.standard.object(forKey: "isGridView") as? Bool {
            isGridView = savedGridView
        }
    }
    
    // Ajoute ou supprime un script des favoris
    private func toggleFavorite(_ script: ScriptFile) {
        if let index = scripts.firstIndex(where: { $0.id == script.id }) {
            let wasSelected = selectedScript?.id == scripts[index].id
            scripts[index].isFavorite.toggle()
            saveFavorites()
            
            if wasSelected {
                selectedScript = scripts[index]
            }
        }
    }
    
    // Sauvegarde les favoris dans UserDefaults
    private func saveFavorites() {
        let favorites = Favorites(scriptPaths: Set(scripts.filter { $0.isFavorite }.map { $0.path }))
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: "ScriptFavorites")
        }
    }
    
    // Charge les favoris depuis UserDefaults
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "ScriptFavorites"),
           let favorites = try? JSONDecoder().decode(Favorites.self, from: data) {
            for (index, script) in scripts.enumerated() where favorites.scriptPaths.contains(script.path) {
                scripts[index].isFavorite = true
            }
        }
    }
    
    // Charge les scripts depuis le dossier
    private func loadScripts() {
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(atPath: folderPath)
            scripts = files
                .filter { $0.hasSuffix(".scpt") || $0.hasSuffix(".applescript") }
                .map { ScriptFile(
                    name: $0,
                    path: (folderPath as NSString).appendingPathComponent($0),
                    isFavorite: false,
                    lastExecuted: nil,
                    isSelected: false
                )}
                .sorted { $0.name < $1.name }
        } catch {
            errorMessage = "Erreur lors de la lecture du dossier: \(error.localizedDescription)"
            scripts = []
        }
    }
    
    // Exécute un script spécifique
    private func executeScript(script: ScriptFile) {
        // Créer un nouvel objet RunningScript
        let newRunningScript = RunningScript(
            id: script.id,
            name: script.name,
            startTime: Date(),
            output: "Démarrage de l'exécution...\n"
        )
        
        // Ajouter le script à la liste des scripts en cours
        runningScriptsVM.addScript(newRunningScript)
        
        // Mise à jour de la date d'exécution du script dans la liste principale
        if let index = self.scripts.firstIndex(where: { $0.id == script.id }) {
            self.scripts[index].lastExecuted = Date()
        }
        
        // Exécuter le script et s'abonner aux mises à jour
        let outputPublisher = scriptManager.executeScript(script: script)
        
        outputPublisher
            .receive(on: DispatchQueue.main)
            .sink { (scriptId, output, status, endTime) in
                // Mettre à jour la sortie du script correspondant
                runningScriptsVM.updateScript(id: scriptId, output: output, status: status, endTime: endTime)
                
                // Ne plus supprimer les scripts terminés
                // Les scripts restent dans la liste même après leur exécution
            }
            .store(in: &cancellables)
    }
    
    // Exécute tous les scripts sélectionnés
    private func executeSelectedScripts() {
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
        
        // Optionnel: désélectionner tous les scripts après leur lancement
        // unselectAllScripts()
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
