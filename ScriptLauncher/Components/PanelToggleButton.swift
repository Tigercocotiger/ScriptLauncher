import SwiftUI

struct PanelToggleButton: View {
    let isDarkMode: Bool
    @Binding var isExpanded: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }) {
            ZStack {
                // Fond du bouton
                RoundedRectangle(cornerRadius: 4)
                    .fill(isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color.white)
                    .frame(width: 16, height: 60)
                    .shadow(
                        color: Color.black.opacity(isDarkMode ? 0.3 : 0.1),
                        radius: 2,
                        x: 0,
                        y: 1
                    )
                
                // Icône de flèche
                Image(systemName: isExpanded ? "chevron.right" : "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isDarkMode
                        ? Color.white.opacity(0.8)
                        : DesignSystem.accentColor(for: isDarkMode))
            }
        }
        .buttonStyle(PlainButtonStyle())
        // Aucun padding supplémentaire pour éviter d'affecter le layout
    }
}

// MARK: - Preview
#Preview("Toggle Button - Light") {
    PanelToggleButton(isDarkMode: false, isExpanded: .constant(true))
        .padding()
        .background(Color.gray.opacity(0.1))
}

#Preview("Toggle Button - Dark") {
    PanelToggleButton(isDarkMode: true, isExpanded: .constant(false))
        .padding()
        .background(Color.black)
}
