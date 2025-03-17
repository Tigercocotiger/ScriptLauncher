import SwiftUI
import AppKit

// Define a struct for regular SwiftUI integration
struct ScriptPropertiesEditor: View {
    @Binding var isPresented: Bool
    let script: ScriptFile
    let isDarkMode: Bool
    var onSave: (ScriptFile, String?, NSImage?) -> Void
    
    // Use a button that appears in SwiftUI preview
    var body: some View {
        Button("Edit Properties") {
            // Just display an alert instead of trying to create a native window
            let alert = NSAlert()
            alert.messageText = "Edit Script Properties"
            alert.informativeText = "Script Name: \(script.name)\nPath: \(script.path)"
            alert.addButton(withTitle: "Cancel")
            alert.addButton(withTitle: "OK")
            
            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                // Just pass back the original script with no changes for now
                onSave(script, nil, nil)
            }
            
            // Close in all cases
            isPresented = false
        }
        .onAppear {
            if isPresented {
                // Display alert on appear if isPresented is true
                showAlert()
            }
        }
        .onChange(of: isPresented) { newValue in
            if newValue {
                showAlert()
            }
        }
    }
    
    private func showAlert() {
        let alert = NSAlert()
        alert.messageText = "Edit Script Properties"
        alert.informativeText = "Script Name: \(script.name)\nPath: \(script.path)"
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            // Just pass back the original script with no changes for now
            onSave(script, nil, nil)
        }
        
        // Close in all cases
        isPresented = false
    }
}

// MARK: - Preview
#Preview("ScriptPropertiesEditor") {
    let script = ScriptFile(
        name: "test_script.scpt",
        path: "/System/Applications/Utilities/Script Editor.app",
        isFavorite: true,
        lastExecuted: Date(),
        tags: ["Important"]
    )
    
    ScriptPropertiesEditor(
        isPresented: .constant(true),
        script: script,
        isDarkMode: false,
        onSave: { _, _, _ in }
    )
}
