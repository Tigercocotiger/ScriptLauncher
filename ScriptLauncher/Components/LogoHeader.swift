import SwiftUI

struct LogoHeader: View {
    let isDarkMode: Bool
    var isConfiguratorEnabled: Bool = true
    var onConfigPressed: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Logo aligné à gauche
            Image(isDarkMode ? "LogoW" : "LogoBlack")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 42)
                .padding(.vertical, 14)
                .padding(.leading, DesignSystem.spacing)
            
            Spacer()
            
            // Bouton Configurator déplacé à droite
            Button(action: onConfigPressed) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                    
                    Text("Configurator")
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundColor(.white)
                .background(
                    isConfiguratorEnabled
                    ? DesignSystem.accentColor(for: isDarkMode)
                    : Color.gray.opacity(0.5)
                )
                .cornerRadius(DesignSystem.smallCornerRadius)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!isConfiguratorEnabled)
            .padding(.trailing, DesignSystem.spacing)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .background(isDarkMode ? Color.black.opacity(0.2) : Color.white.opacity(0.7))
    }
}

// MARK: - Preview
#Preview("Logo Header with Configurator - Light Mode") {
    LogoHeader(
        isDarkMode: false,
        isConfiguratorEnabled: true,
        onConfigPressed: {}
    )
    .frame(width: 600)
    .background(Color.gray.opacity(0.1))
}

#Preview("Logo Header with Configurator - Dark Mode") {
    LogoHeader(
        isDarkMode: true,
        isConfiguratorEnabled: false,
        onConfigPressed: {}
    )
    .frame(width: 600)
    .background(Color.black)
}
