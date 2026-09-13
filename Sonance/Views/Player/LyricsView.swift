import SwiftUI

/// Real-time scrolling karaoke lyrics viewer with tap-to-seek and crystal glowing typography
public struct LyricsView: View {
    public var song: Song
    public var currentTime: TimeInterval
    public var activeIndex: Int?
    public var onSeekToLine: (TimeInterval) -> Void
    
    public init(
        song: Song,
        currentTime: TimeInterval,
        activeIndex: Int?,
        onSeekToLine: @escaping (TimeInterval) -> Void
    ) {
        self.song = song
        self.currentTime = currentTime
        self.activeIndex = activeIndex
        self.onSeekToLine = onSeekToLine
    }
    
    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    if let lyrics = song.lyrics, !lyrics.isEmpty {
                        ForEach(Array(lyrics.enumerated()), id: \.element.id) { index, line in
                            let isActive = (index == activeIndex)
                            
                            Button {
                                onSeekToLine(line.timestamp)
                            } label: {
                                Text(line.text)
                                    .font(.system(size: isActive ? 28 : 20, weight: isActive ? .bold : .medium))
                                    .foregroundStyle(isActive ? Color.white : Color.white.opacity(0.35))
                                    .shadow(color: isActive ? Color.white.opacity(0.6) : .clear, radius: 10, x: 0, y: 0)
                                    .scaleEffect(isActive ? 1.05 : 1.0, anchor: .leading)
                                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isActive)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .id(index)
                        }
                    } else if let plain = song.plainLyrics, !plain.isEmpty {
                        Text(plain)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.8))
                            .lineSpacing(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "quote.bubble")
                                .font(.system(size: 44, weight: .light))
                                .foregroundStyle(Color.white.opacity(0.3))
                            Text("No Lyrics Available")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.5))
                            Text("Place a .lrc file next to this song to enable synchronized lyrics.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(Color.white.opacity(0.3))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 80)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 40)
            }
            .onChange(of: activeIndex) { newIndex in
                if let newIndex = newIndex {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
    }
}
