import SwiftUI

/// Animated fluid liquid backdrop providing ambient light refraction behind crystal glass panels
public struct FluidMeshBackground: View {
    public var song: Song?
    @State private var animateBlob1 = false
    @State private var animateBlob2 = false
    @State private var animateBlob3 = false
    
    public init(song: Song? = nil) {
        self.song = song
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Deep Obsidian Dark Base
                Color(red: 0.04, green: 0.06, blue: 0.10)
                    .ignoresSafeArea()
                
                // Floating Liquid Fluid Blobs
                ZStack {
                    // Blob 1: Vibrant Cyan / Sapphire
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.15, green: 0.55, blue: 0.95).opacity(0.45),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: proxy.size.width * 0.5
                            )
                        )
                        .frame(width: proxy.size.width * 0.9, height: proxy.size.width * 0.9)
                        .offset(
                            x: animateBlob1 ? -proxy.size.width * 0.2 : proxy.size.width * 0.2,
                            y: animateBlob1 ? -proxy.size.height * 0.2 : -proxy.size.height * 0.05
                        )
                        .blur(radius: 65)
                    
                    // Blob 2: Prismatic Violet / Amethyst
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.65, green: 0.25, blue: 0.95).opacity(0.40),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: proxy.size.width * 0.55
                            )
                        )
                        .frame(width: proxy.size.width * 0.85, height: proxy.size.width * 0.85)
                        .offset(
                            x: animateBlob2 ? proxy.size.width * 0.25 : -proxy.size.width * 0.15,
                            y: animateBlob2 ? proxy.size.height * 0.15 : proxy.size.height * 0.3
                        )
                        .blur(radius: 70)
                    
                    // Blob 3: Emerald / Turquoise Accent
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.1, green: 0.8, blue: 0.7).opacity(0.35),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: proxy.size.width * 0.4
                            )
                        )
                        .frame(width: proxy.size.width * 0.75, height: proxy.size.width * 0.75)
                        .offset(
                            x: animateBlob3 ? -proxy.size.width * 0.1 : proxy.size.width * 0.2,
                            y: animateBlob3 ? proxy.size.height * 0.05 : -proxy.size.height * 0.15
                        )
                        .blur(radius: 60)
                }
                .blendMode(.screen)
                
                // Subtle Caustic Vignette
                RadialGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.55)
                    ],
                    center: .center,
                    startRadius: proxy.size.width * 0.3,
                    endRadius: proxy.size.height * 0.8
                )
                .ignoresSafeArea()
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                    animateBlob1.toggle()
                }
                withAnimation(.easeInOut(duration: 11.0).repeatForever(autoreverses: true)) {
                    animateBlob2.toggle()
                }
                withAnimation(.easeInOut(duration: 9.5).repeatForever(autoreverses: true)) {
                    animateBlob3.toggle()
                }
            }
        }
    }
}
