import SwiftUI

/// Tactile crystal glass playback controls with specular light bounce and haptics
public struct ReflectiveControls: View {
    public var isPlaying: Bool
    public var isShuffleEnabled: Bool
    public var repeatMode: RepeatMode
    public var onPlayPause: () -> Void
    public var onNext: () -> Void
    public var onPrevious: () -> Void
    public var onToggleShuffle: () -> Void
    public var onCycleRepeat: () -> Void
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    public init(
        isPlaying: Bool,
        isShuffleEnabled: Bool,
        repeatMode: RepeatMode,
        onPlayPause: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onPrevious: @escaping () -> Void,
        onToggleShuffle: @escaping () -> Void,
        onCycleRepeat: @escaping () -> Void
    ) {
        self.isPlaying = isPlaying
        self.isShuffleEnabled = isShuffleEnabled
        self.repeatMode = repeatMode
        self.onPlayPause = onPlayPause
        self.onNext = onNext
        self.onPrevious = onPrevious
        self.onToggleShuffle = onToggleShuffle
        self.onCycleRepeat = onCycleRepeat
    }
    
    public var body: some View {
        HStack(spacing: 28) {
            // Shuffle Button
            Button {
                impactFeedback.impactOccurred()
                onToggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isShuffleEnabled ? Color(red: 0.4, green: 0.8, blue: 1.0) : Color.white.opacity(0.45))
                    .frame(width: 44, height: 44)
                    .background {
                        if isShuffleEnabled {
                            Circle().fill(Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.15))
                        }
                    }
            }
            .buttonStyle(SpringScaleButtonStyle())
            
            // Previous Track
            Button {
                impactFeedback.impactOccurred()
                onPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color.white)
                    .frame(width: 52, height: 52)
            }
            .buttonStyle(SpringScaleButtonStyle())
            
            // Large Play / Pause Crystal Orb
            Button {
                impactFeedback.impactOccurred()
                onPlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .crystalGlass(cornerRadius: 36, specularIntensity: 0.9, elevation: 12)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color.white)
                        .offset(x: isPlaying ? 0 : 2) // Visual center adjustment for play triangle
                }
            }
            .buttonStyle(SpringScaleButtonStyle())
            
            // Next Track
            Button {
                impactFeedback.impactOccurred()
                onNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color.white)
                    .frame(width: 52, height: 52)
            }
            .buttonStyle(SpringScaleButtonStyle())
            
            // Repeat Button
            Button {
                impactFeedback.impactOccurred()
                onCycleRepeat()
            } label: {
                Image(systemName: repeatMode.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(repeatMode != .off ? Color(red: 0.4, green: 0.8, blue: 1.0) : Color.white.opacity(0.45))
                    .frame(width: 44, height: 44)
                    .background {
                        if repeatMode != .off {
                            Circle().fill(Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.15))
                        }
                    }
            }
            .buttonStyle(SpringScaleButtonStyle())
        }
    }
}

/// Spring scale effect on button press
public struct SpringScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
