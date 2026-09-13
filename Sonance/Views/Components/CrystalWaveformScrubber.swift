import SwiftUI

/// Liquid Crystal Waveform and Progress Scrubber with tactile drag feedback
public struct CrystalWaveformScrubber: View {
    public var currentTime: TimeInterval
    public var duration: TimeInterval
    public var onSeek: (TimeInterval) -> Void
    
    @State private var isDragging: Bool = false
    @State private var dragTime: TimeInterval = 0
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    public init(currentTime: TimeInterval, duration: TimeInterval, onSeek: @escaping (TimeInterval) -> Void) {
        self.currentTime = currentTime
        self.duration = duration
        self.onSeek = onSeek
    }
    
    private var progress: Double {
        guard duration > 0 else { return 0 }
        let time = isDragging ? dragTime : currentTime
        return min(max(time / duration, 0), 1)
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                let width = geometry.size.width
                
                ZStack(alignment: .leading) {
                    // Track Background (Frosted Glass Groove)
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 6)
                    
                    // Liquid Glowing Fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.35, green: 0.75, blue: 1.0),
                                    Color(red: 0.7, green: 0.45, blue: 0.95)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, width * CGFloat(progress)), height: 6)
                        .shadow(color: Color(red: 0.4, green: 0.75, blue: 1.0).opacity(0.5), radius: 6, x: 0, y: 0)
                    
                    // Floating Crystal Playhead Bead
                    Circle()
                        .fill(Color.white)
                        .frame(width: isDragging ? 18 : 12, height: isDragging ? 18 : 12)
                        .overlay {
                            Circle()
                                .stroke(Color(red: 0.35, green: 0.75, blue: 1.0), lineWidth: 2)
                        }
                        .shadow(color: .white.opacity(0.8), radius: 6, x: 0, y: 0)
                        .offset(x: max(0, min(width * CGFloat(progress) - (isDragging ? 9 : 6), width - (isDragging ? 18 : 12))))
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDragging)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                impactFeedback.impactOccurred()
                            }
                            let fraction = max(0, min(value.location.x / width, 1.0))
                            dragTime = fraction * duration
                        }
                        .onEnded { value in
                            let fraction = max(0, min(value.location.x / width, 1.0))
                            let finalTime = fraction * duration
                            onSeek(finalTime)
                            isDragging = false
                            impactFeedback.impactOccurred()
                        }
                )
            }
            .frame(height: 18)
            
            // Time Labels
            HStack {
                Text(formatTime(isDragging ? dragTime : currentTime))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.7))
                
                Spacer()
                
                let remaining = max(0, duration - (isDragging ? dragTime : currentTime))
                Text("-\(formatTime(remaining))")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        guard !time.isNaN && !time.isInfinite && time >= 0 else { return "00:00" }
        let total = Int(time.rounded())
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
