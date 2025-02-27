import SwiftUI
import Combine
import Cocoa

struct ContentView: View {
    // MARK: - Properties
    private let folderPath = "/Volumes/Marco/Dév/Fonctionnel"
    @State private var scripts: [ScriptFile] = []
    @State private var selectedScript: ScriptFile?
    @State private var scriptOutput: String = ""
    @State private var isRunning: Bool = false
    @State private var errorMessage: String = ""
    @State private var searchText: String = ""
    @State private var showFavoritesOnly: Bool = false
    @State private var showHelp: Bool = false
    @State private var isDarkMode: Bool = false
    @State private var isGridView: Bool = false // Nouveau state pour le mode d'affichage
    @FocusState private var isSearchFieldFocused: Bool
    
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
                    HStack(spacing: DesignSystem.spacing) {
                        scriptsSection
                            .frame(width: geometry.size.width * 0.62)
                        
                        ResultSection(
                            scriptOutput: scriptOutput,
                            selectedScript: selectedScript,
                            isDarkMode: isDarkMode
                        )
                        .frame(width: geometry.size.width * 0.38 - DesignSystem.spacing * 2)
                    }
                    .padding(DesignSystem.spacing)
                } else {
                    // Vue verticale pour les petites fenêtres
                    VStack(spacing: DesignSystem.spacing) {
                        scriptsSection
                            .frame(height: geometry.size.height * 0.6)
                        
                        ResultSection(
                            scriptOutput: scriptOutput,
                            selectedScript: selectedScript,
                            isDarkMode: isDarkMode
                        )
                        .frame(height: geometry.size.height * 0.4 - DesignSystem.spacing)
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
            
            ExecuteButton(
                selectedScript: selectedScript,
                isRunning: isRunning,
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
    
    // Exécute le script sélectionné avec sortie en temps réel
    private func executeSelectedScript() {
        guard let script = selectedScript else { return }
        
        isRunning = true
        scriptOutput = "Exécution en cours...\n"
        
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            let pipe = Pipe()
            
            // Configuration pour la lecture en temps réel
            let outputHandle = pipe.fileHandleForReading
            
            // Configurer la notification de disponibilité des données
            var fullOutput = ""
            
            // Configurer un handler pour lire les données disponibles
            outputHandle.readabilityHandler = { fileHandle in
                let data = fileHandle.availableData
                if data.count > 0, let string = String(data: data, encoding: .utf8) {
                    // Ajouter le nouveau contenu à la sortie complète
                    fullOutput += string
                    
                    // Mettre à jour l'interface sur le thread principal
                    DispatchQueue.main.async {
                        self.scriptOutput = fullOutput
                    }
                }
            }
            
            task.standardOutput = pipe
            task.standardError = pipe
            task.launchPath = "/usr/bin/osascript"
            task.arguments = [script.path]
            
            do {
                try task.run()
                
                // Attendre la fin de l'exécution
                task.waitUntilExit()
                
                // Nettoyer le handler de lecture une fois terminé
                outputHandle.readabilityHandler = nil
                
                DispatchQueue.main.async {
                    // S'assurer que le scriptOutput a bien toute la sortie
                    if fullOutput.isEmpty {
                        self.scriptOutput = "Exécution terminée avec succès."
                    }
                    
                    self.isRunning = false
                    
                    // Mise à jour de la date d'exécution
                    if let index = self.scripts.firstIndex(where: { $0.id == script.id }) {
                        self.scripts[index].lastExecuted = Date()
                        self.selectedScript = self.scripts[index]
                    }
                }
            } catch {
                // Nettoyer le handler en cas d'erreur
                outputHandle.readabilityHandler = nil
                
                DispatchQueue.main.async {
                    self.scriptOutput = "Erreur lors de l'exécution: \(error.localizedDescription)"
                    self.isRunning = false
                }
            }
        }
    }}

// MARK: - Preview
#Preview("Content View") {
    ContentView()
        .frame(width: 1000, height: 650)
}
