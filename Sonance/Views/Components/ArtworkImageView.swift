import SwiftUI

/// High-fidelity artwork view with ambient colored bloom and crystal rim lighting
public struct ArtworkImageView: View {
    public var artworkURL: URL?
    public var cornerRadius: CGFloat
    public var showBloom: Bool
    
    public init(artworkURL: URL?, cornerRadius: CGFloat = 20, showBloom: Bool = true) {
        self.artworkURL = artworkURL
        self.cornerRadius = cornerRadius
        self.showBloom = showBloom
    }
    
    public var body: some View {
        ZStack {
            if let artworkURL = artworkURL,
               let uiImage = UIImage(contentsOfFile: artworkURL.path) {
                // Ambient Colored Bloom Underneath
                if showBloom {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 25)
                        .opacity(0.65)
                        .scaleEffect(1.08)
                }
                
                // Crisp Front Artwork
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.6),
                                        .white.opacity(0.1),
                                        .clear,
                                        .white.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    }
                    .shadow(color: .black.opacity(0.35), radius: 15, x: 0, y: 8)
            } else {
                // Crystal Vinyl Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.12, green: 0.16, blue: 0.24),
                                    Color(red: 0.08, green: 0.10, blue: 0.16)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Concentric Vinyl Grooves
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        .padding(24)
                    Circle()
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                        .padding(40)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.75, blue: 1.0),
                                    Color(red: 0.7, green: 0.4, blue: 0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.4), .clear, .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                }
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
            }
        }
    }
}
