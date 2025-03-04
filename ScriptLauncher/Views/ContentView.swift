import SwiftUI
import Combine
import Cocoa

struct ContentView: View {
    // MARK: - Properties
    private let folderPath = "/Volumes/Marco/Dév/Fonctionnel"
    @State private var scripts: [ScriptFile] = []
    @State private var selectedScript: ScriptFile?
    @State private var errorMessage: String = ""
    @State private var searchText: String = ""
    @State private var showFavoritesOnly: Bool = false
    @State private var showHelp: Bool = false
    @State private var isDarkMode: Bool = false
    @State private var isGridView: Bool = false
    @FocusState private var isSearchFieldFocused: Bool
    
    // Nouvelles propriétés pour l'exécution multiple
    @StateObject private var scriptManager = ScriptProcessManager()
    @State private var runningScripts: [RunningScript] = []
    @State private var selectedRunningScriptId: UUID?
    @State private var cancellables = Set<AnyCancellable>()
    
    // Liste des sections d'aide
    private let helpSections = [
        HelpSection(
            title: "Raccourcis clavier",
            content: """
            • ⌘ + Entrée : Exécuter le script sélectionné
            • ⌘ + I : Afficher/masquer l'aide
            • ⌘ + S : Ajouter/retirer des favoris
            • ⌘ + G : Basculer entre vue liste et grille
            • ⌘ + D : Basculer entre mode clair et sombre
            • ⌘ + . : Arrêter tous les scripts en cours
            • Échap : Annuler la recherche
            """
        ),
        HelpSection(
            title: "Gestion des favoris",
            content: """
            Pour ajouter un script aux favoris :
            1. Clic droit sur le script
            2. Sélectionner "Ajouter aux favoris"
            ou
            • Sélectionner le script et utiliser ⌘ + S
            
            Les favoris sont automatiquement sauvegardés dans les préférences de l'application.
            """
        ),
        HelpSection(
            title: "Exécution multiple",
            content: """
            ScriptLauncher vous permet désormais d'exécuter plusieurs scripts simultanément :
            1. Sélectionnez un script dans la liste
            2. Cliquez sur "Exécuter"
            3. Répétez pour lancer d'autres scripts
            
            Vous pouvez suivre la progression et voir les résultats de tous vos scripts en cours
            dans la section "Scripts en cours d'exécution".
            """
        ),
        HelpSection(
            title: "Utilisation",
            content: """
            1. Sélectionnez un script dans la liste
            2. Cliquez sur "Exécuter" ou utilisez ⌘ + Entrée
            3. Le résultat s'affichera dans la section de droite
            
            Utilisez la barre de recherche pour filtrer les scripts.
            Activez "Favoris" pour n'afficher que vos scripts favoris.
            Basculez entre vue liste et grille selon vos préférences.
            """
        )
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
                    HStack(spacing: DesignSystem.spacing) { // Rétablissement de l'espacement pour la marge entre les colonnes
                        scriptsSection
                            .frame(width: geometry.size.width * 0.62 - DesignSystem.spacing) // Soustraction de l'espacement pour la marge à droite
                        
                        VStack(spacing: DesignSystem.spacing) {
                            // Section des scripts en cours d'exécution avec ajustement de position pour s'aligner avec la div principale
                            RunningScriptsView(
                                runningScripts: runningScripts,
                                isDarkMode: isDarkMode,
                                onScriptSelect: { scriptId in
                                    selectedRunningScriptId = scriptId
                                    // Mettre à jour l'état "isSelected" de chaque script
                                    for i in 0..<runningScripts.count {
                                        runningScripts[i].isSelected = (runningScripts[i].id == scriptId)
                                    }
                                },
                                onScriptCancel: cancelScript
                            )
                            .frame(height: min(150, max(80, geometry.size.height * 0.25)))
                            
                            // Section des résultats
                            MultiResultSection(
                                runningScripts: runningScripts,
                                selectedScriptId: selectedRunningScriptId,
                                isDarkMode: isDarkMode
                            )
                        }
                        .frame(width: geometry.size.width * 0.38 - DesignSystem.spacing)
                    }
                    .padding(DesignSystem.spacing)
                } else {
                    // Vue verticale pour les petites fenêtres reste inchangée
                    VStack(spacing: DesignSystem.spacing) {
                        scriptsSection
                            .frame(height: geometry.size.height * 0.5)
                        
                        VStack(spacing: DesignSystem.spacing) {
                            // Section des scripts en cours d'exécution
                            RunningScriptsView(
                                runningScripts: runningScripts,
                                isDarkMode: isDarkMode,
                                onScriptSelect: { scriptId in
                                    selectedRunningScriptId = scriptId
                                    // Mettre à jour l'état "isSelected" de chaque script
                                    for i in 0..<runningScripts.count {
                                        runningScripts[i].isSelected = (runningScripts[i].id == scriptId)
                                    }
                                },
                                onScriptCancel: cancelScript
                            )
                            .frame(height: min(120, geometry.size.height * 0.2))
                            
                            // Section des résultats
                            MultiResultSection(
                                runningScripts: runningScripts,
                                selectedScriptId: selectedRunningScriptId,
                                isDarkMode: isDarkMode
                            )
                            .frame(height: geometry.size.height * 0.3 - DesignSystem.spacing)
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
            
            // Conditionnellement afficher la vue liste ou grille
            if isGridView {
                ScriptGridView(
                    scripts: scripts,
                    selectedScript: selectedScript,
                    isDarkMode: isDarkMode,
                    showFavoritesOnly: showFavoritesOnly,
                    searchText: searchText,
                    onScriptSelect: { script in
                        selectedScript = script
                    },
                    onToggleFavorite: toggleFavorite
                )
            } else {
                ScriptsList(
                    scripts: scripts,
                    selectedScript: selectedScript,
                    isDarkMode: isDarkMode,
                    showFavoritesOnly: showFavoritesOnly,
                    searchText: searchText,
                    onScriptSelect: { script in
                        selectedScript = script
                    },
                    onToggleFavorite: toggleFavorite
                )
            }
            
            ExecuteMultipleButton(
                selectedScript: selectedScript,
                isScriptRunning: false, // Nous ne bloquons plus l'interface pendant l'exécution
                isDarkMode: isDarkMode,
                onExecute: executeSelectedScript
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
            executeSelectedScript()
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
    }
    
    // Annule tous les scripts en cours d'exécution
    private func cancelAllScripts() {
        scriptManager.cancelAllScripts()
        runningScripts = []
        selectedRunningScriptId = nil
    }
    
    // Annule un script spécifique
    private func cancelScript(id: UUID) {
        scriptManager.cancelScript(id: id)
        
        // Supprimer le script de la liste des scripts en cours
        runningScripts.removeAll { $0.id == id }
        
        // Si le script annulé était sélectionné, sélectionner un autre script si disponible
        if selectedRunningScriptId == id {
            selectedRunningScriptId = runningScripts.first?.id
            
            // Mettre à jour l'état "isSelected" du nouveau script sélectionné
            if let newSelectedId = selectedRunningScriptId {
                for i in 0..<runningScripts.count {
                    runningScripts[i].isSelected = (runningScripts[i].id == newSelectedId)
                }
            }
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
                    lastExecuted: nil
                )}
                .sorted { $0.name < $1.name }
        } catch {
            errorMessage = "Erreur lors de la lecture du dossier: \(error.localizedDescription)"
            scripts = []
        }
    }
    
    // Exécute le script sélectionné avec sortie en temps réel et support multi-exécution
    private func executeSelectedScript() {
        guard let script = selectedScript else { return }
        
        // Créer un nouvel objet RunningScript
        let newRunningScript = RunningScript(
            id: script.id,
            name: script.name,
            startTime: Date(),
            output: "Démarrage de l'exécution...\n"
        )
        
        // Ajouter le script à la liste des scripts en cours
        runningScripts.append(newRunningScript)
        
        // Si c'est le premier script en cours, le sélectionner automatiquement
        if runningScripts.count == 1 {
            selectedRunningScriptId = newRunningScript.id
            runningScripts[0].isSelected = true
        }
        
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
                if let index = self.runningScripts.firstIndex(where: { $0.id == scriptId }) {
                    self.runningScripts[index].output = output
                    
                    // Mettre à jour le statut et l'heure de fin si fournis
                    if let newStatus = status {
                        self.runningScripts[index].status = newStatus
                        self.runningScripts[index].endTime = endTime
                        
                        // Si le script est terminé, le supprimer après un délai
                        if newStatus != .running {
                            // D'abord, attendre 2 secondes pour que l'utilisateur voie le changement d'état
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                // Vérifier si le script est toujours dans la liste (il pourrait avoir été enlevé manuellement)
                                if let stillIndex = self.runningScripts.firstIndex(where: { $0.id == scriptId }) {
                                    // Si c'était le script sélectionné, sélectionner un autre
                                    if self.selectedRunningScriptId == scriptId {
                                        self.selectedRunningScriptId = self.runningScripts.first(where: { $0.id != scriptId })?.id
                                    }
                                    
                                    // Supprimer le script de la liste
                                    self.runningScripts.remove(at: stillIndex)
                                    
                                    // Mettre à jour isSelected pour le nouveau script sélectionné
                                    if let newSelectedId = self.selectedRunningScriptId {
                                        for i in 0..<self.runningScripts.count {
                                            self.runningScripts[i].isSelected = (self.runningScripts[i].id == newSelectedId)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Preview
#Preview("Content View") {
    ContentView()
        .frame(width: 1000, height: 650)
}

#Preview("Content View - Dark Mode") {
    ContentView()
        .frame(width: 1000, height: 650)
        .preferredColorScheme(.dark)
}
