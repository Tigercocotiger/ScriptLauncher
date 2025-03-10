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
                   
                   // Ajouter un menu spécifique pour la gestion des clés USB
                   CommandMenu("Clés USB") {
                       Button("Réparer les chemins") {
                           NotificationCenter.default.post(
                               name: NSNotification.Name("RepairPaths"),
                               object: nil
                           )
                           
                           // Afficher une notification de succès
                           let alert = NSAlert()
                           alert.messageText = "Réparation terminée"
                           alert.informativeText = "Les chemins ont été adaptés à la clé USB actuelle."
                           alert.alertStyle = .informational
                           alert.addButton(withTitle: "OK")
                           alert.runModal()
                           
                           // Recharger les scripts
                           NotificationCenter.default.post(
                               name: NSNotification.Name("RefreshScriptsList"),
                               object: nil
                           )
                       }
                       .keyboardShortcut("r", modifiers: [.command, .shift])
                       
                       Button("Utiliser dossier racine") {
                           if let usbName = ConfigManager.shared.getCurrentUSBDriveName() {
                               let usbRootPath = "/Volumes/\(usbName)"
                               
                               // Vérifier si le dossier contient des scripts
                               if ConfigManager.shared.isValidScriptFolder(usbRootPath) {
                                   ConfigManager.shared.folderPath = "$USB"
                                   
                                   // Recharger les scripts
                                   NotificationCenter.default.post(
                                       name: NSNotification.Name("RefreshScriptsList"),
                                       object: nil
                                   )
                               } else {
                                   let alert = NSAlert()
                                   alert.messageText = "Aucun script trouvé"
                                   alert.informativeText = "Aucun script n'a été trouvé à la racine de la clé USB."
                                   alert.alertStyle = .warning
                                   alert.addButton(withTitle: "OK")
                                   alert.runModal()
                               }
                           } else {
                               let alert = NSAlert()
                               alert.messageText = "Non exécuté sur une clé USB"
                               alert.informativeText = "L'application ne semble pas être exécutée depuis une clé USB."
                               alert.alertStyle = .warning
                               alert.addButton(withTitle: "OK")
                               alert.runModal()
                           }
                       }
                       .keyboardShortcut("u", modifiers: [.command, .shift])
                       
                       Button("Informations sur la clé USB") {
                           if let usbName = ConfigManager.shared.getCurrentUSBDriveName() {
                               let alert = NSAlert()
                               alert.messageText = "Informations sur la clé USB"
                               alert.informativeText = """
                               Nom de la clé USB : \(usbName)
                               Chemin complet : /Volumes/\(usbName)
                               
                               L'application utilise le dossier Resources à la racine de cette clé USB pour stocker sa configuration.
                               """
                               alert.alertStyle = .informational
                               alert.addButton(withTitle: "OK")
                               alert.runModal()
                           } else {
                               let alert = NSAlert()
                               alert.messageText = "Non exécuté sur une clé USB"
                               alert.informativeText = "L'application ne semble pas être exécutée depuis une clé USB."
                               alert.alertStyle = .warning
                               alert.addButton(withTitle: "OK")
                               alert.runModal()
                           }
                       }
                       .keyboardShortcut("i", modifiers: [.command, .shift])
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
