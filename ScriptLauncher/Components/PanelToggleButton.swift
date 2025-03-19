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
                // Fond du bouton avec bordure arrondie uniquement du côté gauche
                RoundedCornerShape(topLeft: 4, bottomLeft: 4, topRight: 0, bottomRight: 0)
                    .fill(isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color.white)
                    .frame(width: 16, height: 60)
                    .shadow(
                        color: Color.black.opacity(isDarkMode ? 0.3 : 0.1),
                        radius: 2,
                        x: -1,
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
    }
}

// Forme personnalisée pour des coins arrondis sélectifs
struct RoundedCornerShape: Shape {
    var topLeft: CGFloat = 0
    var bottomLeft: CGFloat = 0
    var topRight: CGFloat = 0
    var bottomRight: CGFloat = 0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let tr = min(min(topRight, rect.width/2), rect.height/2)
        let tl = min(min(topLeft, rect.width/2), rect.height/2)
        let bl = min(min(bottomLeft, rect.width/2), rect.height/2)
        let br = min(min(bottomRight, rect.width/2), rect.height/2)
        
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Preview
#Preview("Toggle Button - Light Mode") {
    PanelToggleButton(isDarkMode: false, isExpanded: .constant(true))
        .padding()
        .background(Color.gray.opacity(0.1))
}

#Preview("Toggle Button - Dark Mode") {
    PanelToggleButton(isDarkMode: true, isExpanded: .constant(false))
        .padding()
        .background(Color.black)
}
