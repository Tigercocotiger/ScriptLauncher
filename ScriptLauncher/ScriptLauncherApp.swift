import SwiftUI

@main
struct ScriptLauncherApp: App {
    // Variable pour suivre si c'est la première exécution sur cette clé USB
    @AppStorage("hasRunOnThisDevice") private var hasRunOnThisDevice = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
                .onAppear {
                    setupAppAppearance()
                    centerWindow()
                    
                    // Initialiser le dossier Scripts dans Resources
                    ConfigManager.shared.initializeScriptsFolder()
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshScriptsList"), object: nil)
                    
                    // Exécuter l'adaptation aux chemins de la clé USB actuelle
                    if !hasRunOnThisDevice {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // Réparer les chemins si nous sommes sur une nouvelle clé
                            if let _ = ConfigManager.shared.getCurrentUSBDriveName() {
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("RepairPaths"),
                                    object: nil
                                )
                            }
                            hasRunOnThisDevice = true
                        }
                    }
                }
        }
               .windowStyle(HiddenTitleBarWindowStyle())
               .commands {
                   CommandGroup(replacing: .newItem) { }
                   
                   // Menu Fichier avec option pour changer de dossier
                   CommandMenu("Fichier") {
                       Button("Changer de dossier cible...") {
                           NotificationCenter.default.post(
                               name: NSNotification.Name("ChangeFolderCommand"),
                               object: nil
                           )
                       }
                       .keyboardShortcut("o", modifiers: .command)
                       
                       Divider()
                       
                       Button("Réparer les chemins") {
                           NotificationCenter.default.post(
                               name: NSNotification.Name("RepairPaths"),
                               object: nil
                           )
                       }
                       .keyboardShortcut("r", modifiers: [.command, .shift])
                   }
                   
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
                       
                       Button("Afficher/masquer panneau de résultats") {
                           NotificationCenter.default.post(
                               name: NSNotification.Name("ToggleResultsPanel"),
                               object: nil
                           )
                       }
                       .keyboardShortcut("p", modifiers: .command)
                       
                       Divider()
                       
                       // Nouveau menu pour le mode d'édition
                       Button("Afficher/masquer boutons d'édition") {
                           NotificationCenter.default.post(
                               name: NSNotification.Name("ToggleEditMode"),
                               object: nil
                           )
                       }
                       .keyboardShortcut("e", modifiers: .command)
                       
                       Divider()
                       
                       Button("Afficher l'aide") {
                           NotificationCenter.default.post(
                               name: NSNotification.Name("ToggleHelp"),
                               object: nil
                           )
                       }
                       .keyboardShortcut("i", modifiers: .command)
                   }
                   
                   // Nouveau menu DMG pour créer des installateurs
                   CommandMenu("DMG") {
                       Button("Créer un installateur DMG") {
                           NotificationCenter.default.post(
                               name: NSNotification.Name("CreateDMGInstaller"),
                               object: nil
                           )
                       }
                       .keyboardShortcut("n", modifiers: [.command, .shift])
                   }
                   
                   CommandMenu("Outils") {
                       Button("Nettoyer la configuration") {
                           NotificationCenter.default.post(
                               name: NSNotification.Name("CleanupConfig"),
                               object: nil
                           )
                       }
                       .keyboardShortcut("c", modifiers: [.command, .shift])
                   }
               }
           }
           
           // Configuration de l'apparence de l'application
           private func setupAppAppearance() {
               // Personnalisation de la barre de titre
               NSWindow.allowsAutomaticWindowTabbing = false
               
               // Configuration de l'apparence par défaut basée sur le gestionnaire de configuration
               NSApp.appearance = NSAppearance(named: ConfigManager.shared.isDarkMode ? .darkAqua : .aqua)
           }
           
           // Fonction pour centrer la fenêtre au lancement et définir sa taille initiale
           private func centerWindow() {
               // Attendre un court délai pour s'assurer que la fenêtre est créée
               DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                   if let window = NSApplication.shared.windows.first {
                       // Obtenir le cadre visible de l'écran principal
                       let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
                       
                       // Définir la taille initiale (80% de l'écran, mais max 1200x800)
                       let initialWidth: CGFloat = min(1200, screenFrame.width * 0.8)
                       let initialHeight: CGFloat = min(800, screenFrame.height * 0.8)
                       
                       // Calculer la position pour centrer la fenêtre
                       let xPos = screenFrame.origin.x + (screenFrame.width - initialWidth) / 2
                       let yPos = screenFrame.origin.y + (screenFrame.height - initialHeight) / 2
                       
                       // Définir le cadre de la fenêtre (position + taille)
                       let frame = NSRect(
                           x: xPos,
                           y: yPos,
                           width: initialWidth,
                           height: initialHeight
                       )
                       
                       // Appliquer la taille et la position
                       window.setFrame(frame, display: true, animate: false)
                   }
               }
           }
        }
