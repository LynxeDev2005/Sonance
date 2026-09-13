import SwiftUI

/// Ultra-Modern Liquid Crystal Glassmorphism View Modifier
/// Implements water-clear translucency, specular rim reflections, and prismatic cut-glass borders
public struct CrystalGlassModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var specularIntensity: Double
    public var elevation: CGFloat
    
    public init(cornerRadius: CGFloat = 20, specularIntensity: Double = 0.6, elevation: CGFloat = 8) {
        self.cornerRadius = cornerRadius
        self.specularIntensity = specularIntensity
        self.elevation = elevation
    }
    
    public func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // 1. Crystal Water-Clear Base (UltraThin Material)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // A subtle blue-white tint keeps glass legible over dark art.
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(red: 0.18, green: 0.28, blue: 0.42).opacity(0.16))
                    
                    // 2. Translucent Caustic Water Shimmer
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12 * specularIntensity),
                                    Color.white.opacity(0.03 * specularIntensity),
                                    Color.clear,
                                    Color.white.opacity(0.06 * specularIntensity)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // 3. Specular Prismatic Rim Edge (Cut-Glass Reflection)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.7 * specularIntensity), location: 0.0),
                                    .init(color: .white.opacity(0.2 * specularIntensity), location: 0.25),
                                    .init(color: Color(red: 0.7, green: 0.85, blue: 1.0).opacity(0.3 * specularIntensity), location: 0.5),
                                    .init(color: .clear, location: 0.7),
                                    .init(color: .white.opacity(0.4 * specularIntensity), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )

                    // A narrow top reflection makes each surface read as clear glass.
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.44 * specularIntensity), .clear],
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color.black.opacity(0.25), radius: elevation, x: 0, y: elevation * 0.5)
            }
    }
}

public extension View {
    /// Applies liquid crystal glassmorphic styling
    func crystalGlass(cornerRadius: CGFloat = 20, specularIntensity: Double = 0.6, elevation: CGFloat = 8) -> some View {
        modifier(CrystalGlassModifier(cornerRadius: cornerRadius, specularIntensity: specularIntensity, elevation: elevation))
    }
}

/// Standalone Liquid Crystal Glass Card Container
public struct CrystalGlassCard<Content: View>: View {
    public var cornerRadius: CGFloat
    public var content: Content
    
    public init(cornerRadius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding()
            .crystalGlass(cornerRadius: cornerRadius)
    }
}
