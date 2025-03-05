import SwiftUI
// Ajout d'un commentaire de test
@main
struct ScriptLauncherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    setupAppAppearance()
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandMenu("Scripts") {
                Button("Exécuter") {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ExecuteSelectedScript"),
                        object: nil
                    )
                }
                .keyboardShortcut(.return, modifiers: .command)
                
                Button("Exécuter scripts sélectionnés") {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ExecuteSelectedScript"),
                        object: nil
                    )
                }
                .keyboardShortcut(.return, modifiers: [.command, .shift])
                
                Divider()
                
                Button("Sélectionner tous les scripts") {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SelectAllScripts"),
                        object: nil
                    )
                }
                .keyboardShortcut("a", modifiers: [.command, .option])
                
                Divider()
                
                Button("Ajouter aux favoris") {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ToggleFavorite"),
                        object: nil
                    )
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Divider()
                
                Button("Arrêter tous les scripts") {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("CancelAllScripts"),
                        object: nil
                    )
                }
                .keyboardShortcut(".", modifiers: .command)
            }
            
            CommandMenu("Affichage") {
                Button("Basculer vue liste/grille") {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ToggleViewMode"),
                        object: nil
                    )
                }
                .keyboardShortcut("g", modifiers: .command)
                
                Button("Mode clair/sombre") {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ToggleDarkMode"),
                        object: nil
                    )
                }
                .keyboardShortcut("d", modifiers: .command)
                
                Divider()
                
                Button("Afficher l'aide") {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ToggleHelp"),
                        object: nil
                    )
                }
                .keyboardShortcut("i", modifiers: .command)
            }
        }
    }
    
    // Configuration de l'apparence de l'application
    private func setupAppAppearance() {
        // Personnalisation de la barre de titre
        NSWindow.allowsAutomaticWindowTabbing = false
        
        // Configuration de l'apparence par défaut
        if let savedAppearance = UserDefaults.standard.string(forKey: "AppAppearance") {
            if savedAppearance == "dark" {
                NSApp.appearance = NSAppearance(named: .darkAqua)
            } else {
                NSApp.appearance = NSAppearance(named: .aqua)
            }
        }
    }
}
