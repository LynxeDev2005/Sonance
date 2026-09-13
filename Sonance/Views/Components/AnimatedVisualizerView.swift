import SwiftUI

/// Animated audio frequency visualizer bars reacting to playback state
public struct AnimatedVisualizerView: View {
    public var isPlaying: Bool
    public var barCount: Int
    public var barColor: Color
    
    @State private var barHeights: [CGFloat]
    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()
    
    public init(
        isPlaying: Bool,
        barCount: Int = 4,
        barColor: Color = Color(red: 0.4, green: 0.8, blue: 1.0)
    ) {
        self.isPlaying = isPlaying
        self.barCount = barCount
        self.barColor = barColor
        _barHeights = State(initialValue: Array(repeating: 4.0, count: barCount))
    }
    
    public var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [barColor, barColor.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: barHeights[index])
                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: barHeights[index])
            }
        }
        .frame(height: 18)
        .onReceive(timer) { _ in
            if isPlaying {
                for i in 0..<barCount {
                    barHeights[i] = CGFloat.random(in: 4...18)
                }
            } else {
                for i in 0..<barCount {
                    barHeights[i] = 4.0
                }
            }
        }
    }
}
