import SwiftUI

struct TagFilterControl: View {
    @ObservedObject var tagsViewModel: TagsViewModel
    @Binding var selectedTag: String?
    let isDarkMode: Bool
    let scripts: [ScriptFile]
    
    // État pour suivre la position de défilement
    @State private var scrollPosition: Int = 0
    // Référence pour le ScrollViewReader
    @Namespace private var scrollNamespace
    
    // Fonction pour calculer le nombre de scripts par tag
    private func scriptCountForTag(_ tagName: String) -> Int {
        return scripts.filter { $0.tags.contains(tagName) }.count
    }
    
    // Liste filtrée des tags ayant des scripts associés
    private var activeTags: [Tag] {
        return tagsViewModel.tags.sorted(by: { $0.name < $1.name })
            .filter { scriptCountForTag($0.name) > 0 }
    }
    
    var body: some View {
        ZStack {
            // Background pour le fond
            if isDarkMode {
                Color.black.opacity(0.3)
            } else {
                Color.gray.opacity(0.05)
            }
            
            // Conteneur principal avec les flèches de navigation et le défilement
            HStack(spacing: 0) {
                // Flèche de navigation gauche
                Button(action: {
                    withAnimation {
                        scrollPosition = max(0, scrollPosition - 300)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : .gray)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(isDarkMode ? Color.black.opacity(0.3) : Color.white.opacity(0.7))
                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 5) // Marge uniforme horizontale
                
                // Zone de défilement des tags avec GeometryReader pour accéder aux dimensions
                GeometryReader { geometry in
                    ScrollView(.horizontal, showsIndicators: false) {
                        ScrollViewReader { scrollView in
                            HStack(spacing: 8) {
                                // Option "Tous" (aucun tag sélectionné)
                                Button(action: {
                                    selectedTag = nil
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "tag")
                                            .font(.system(size: 10))
                                            .foregroundColor(isDarkMode ? .white : .black)
                                        
                                        Text("Tous")
                                            .font(.system(size: 12))
                                            .foregroundColor(isDarkMode ? .white : .black)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(selectedTag == nil
                                        ? DesignSystem.accentColor(for: isDarkMode).opacity(0.2)
                                        : (isDarkMode ? Color(white: 0.25) : Color(white: 0.95)))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedTag == nil
                                                ? DesignSystem.accentColor(for: isDarkMode)
                                                : Color.gray.opacity(0.3),
                                                lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .id(0)
                                
                                // Liste des tags disponibles
                                ForEach(Array(activeTags.enumerated()), id: \.element.id) { index, tag in
                                    Button(action: {
                                        if selectedTag == tag.name {
                                            selectedTag = nil
                                        } else {
                                            selectedTag = tag.name
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill(tag.color)
                                                .frame(width: 8, height: 8)
                                            
                                            Text(tag.name)
                                                .font(.system(size: 12))
                                                .foregroundColor(isDarkMode ? .white : .black)
                                            
                                            // Afficher le compteur de scripts
                                            TagStatistics(
                                                tagName: tag.name,
                                                count: scriptCountForTag(tag.name),
                                                color: tag.color,
                                                isDarkMode: isDarkMode
                                            )
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(selectedTag == tag.name
                                            ? tag.color.opacity(0.2)
                                            : (isDarkMode ? Color(white: 0.25) : Color(white: 0.95)))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedTag == tag.name
                                                    ? tag.color
                                                    : Color.gray.opacity(0.3),
                                                    lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .id(index + 1)
                                }
                                
                                // Espace de fin pour permettre le défilement jusqu'au dernier élément
                                Spacer(minLength: 20)
                                    .id(activeTags.count + 1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .onChange(of: scrollPosition) { newPosition in
                                withAnimation {
                                    // Faire défiler vers un élément spécifique basé sur la position
                                    let safeIndex = min(max(0, newPosition / 100), activeTags.count)
                                    scrollView.scrollTo(safeIndex, anchor: .leading)
                                }
                            }
                        }
                    }
                }
                
                // Flèche de navigation droite
                Button(action: {
                    withAnimation {
                        // Augmenter la position de défilement
                        scrollPosition = min(activeTags.count * 100, scrollPosition + 300)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : .gray)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(isDarkMode ? Color.black.opacity(0.3) : Color.white.opacity(0.7))
                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 5) // Marge uniforme horizontale
            }
        }
        .cornerRadius(DesignSystem.smallCornerRadius)
        .frame(height: 38)
    }
}

// Statistiques pour le nombre de scripts par tag
struct TagStatistics: View {
    let tagName: String
    let count: Int
    let color: Color
    let isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            
            Text("\(count)")
                .font(.system(size: 10))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.6))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}
