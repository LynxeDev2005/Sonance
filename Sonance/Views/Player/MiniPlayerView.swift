import SwiftUI

/// Floating Crystal Glass MiniPlayer docked above the navigation tab bar
public struct MiniPlayerView: View {
    @ObservedObject var playerVM = PlayerViewModel.shared
    @ObservedObject var audioService = AudioPlayerService.shared
    
    public init() {}
    
    private var progress: Double {
        guard audioService.duration > 0 else { return 0 }
        return min(max(audioService.currentTime / audioService.duration, 0), 1)
    }
    
    public var body: some View {
        if let song = audioService.currentSong {
            Button {
                playerVM.showFullPlayer = true
            } label: {
                HStack(spacing: 12) {
                    // Circular Thumbnail with Progress Ring
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 2.5)
                            .frame(width: 44, height: 44)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.8, blue: 1.0),
                                        Color(red: 0.7, green: 0.4, blue: 0.95)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 44, height: 44)
                        
                        ArtworkImageView(artworkURL: song.artworkURL, cornerRadius: 20, showBloom: false)
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    }
                    
                    // Track Title & Artist
                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                        
                        Text(song.artist)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Dancing Frequency Bars
                    AnimatedVisualizerView(isPlaying: audioService.isPlaying, barCount: 3)
                        .padding(.trailing, 4)
                    
                    // Play / Pause Button
                    Button {
                        playerVM.togglePlayPause()
                    } label: {
                        Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 36, height: 36)
                    }
                    
                    // Skip Next Button
                    Button {
                        playerVM.next()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .crystalGlass(cornerRadius: 28, specularIntensity: 0.85, elevation: 14)
                .padding(.horizontal, 12)
            }
            .buttonStyle(PlainButtonStyle())
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
