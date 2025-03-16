import SwiftUI

struct Tag: Identifiable, Hashable {
    let id: UUID
    let name: String
    let color: Color
    
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Extension pour encoder/décoder Color
extension Color {
    func toHex() -> String? {
        guard let components = NSColor(self).cgColor.components else { return nil }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
    
    static func fromHex(_ hex: String) -> Color? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        return Color(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}

// Structure pour stocker les configurations de tag
struct TagConfig: Codable {
    let id: UUID
    let name: String
    let colorHex: String
}

// Composant pour afficher les tags d'un script dans la vue liste/grille
struct ScriptTagsDisplay: View {
    let tags: Set<String>
    let tagsViewModel: TagsViewModel
    var onTagClick: ((String) -> Void)? = nil  // Callback optionnel pour le clic sur un tag
    
    // Identifiant de la vue pour forcer la mise à jour
    @State private var viewID = UUID()
    
    var body: some View {
        if !tags.isEmpty {
            HStack(spacing: 4) {
                ForEach(Array(tags).prefix(3).sorted(), id: \.self) { tagName in
                    if let tag = tagsViewModel.getTag(name: tagName) {
                        Circle()
                            .fill(tag.color)
                            .frame(width: 6, height: 6)
                            .contentShape(Rectangle())  // Pour rendre la zone cliquable plus grande
                            .onTapGesture {
                                if let onTagClick = onTagClick {
                                    onTagClick(tagName)
                                }
                            }
                    }
                }
                
                if tags.count > 3 {
                    Text("+\(tags.count - 3)")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                }
            }
            .id(viewID) // Force le rafraîchissement
            .onAppear {
                // S'abonner aux notifications de changement de tags
                NotificationCenter.default.addObserver(forName: NSNotification.Name("GlobalTagsChanged"), object: nil, queue: .main) { _ in
                    // Forcer le rafraîchissement
                    viewID = UUID()
                }
            }
            .onDisappear {
                // Se désabonner des notifications
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name("GlobalTagsChanged"), object: nil)
            }
        } else {
            EmptyView()
        }
    }
}
