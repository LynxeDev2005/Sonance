import SwiftUI

/// Detailed view showing album artwork header, metadata, and tracklist
public struct AlbumDetailView: View {
    public var album: Album
    @ObservedObject var audioService = AudioPlayerService.shared
    @ObservedObject var playerVM = PlayerViewModel.shared
    
    public init(album: Album) {
        self.album = album
    }
    
    public var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Album Cover Header
                    ArtworkImageView(artworkURL: album.songs.first?.artworkURL, cornerRadius: 24, showBloom: true)
                        .frame(width: 220, height: 220)
                        .padding(.top, 24)
                    
                    VStack(spacing: 6) {
                        Text(album.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.white)
                            .multilineTextAlignment(.center)
                        
                        Text(album.artist)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                        
                        HStack(spacing: 8) {
                            if let year = album.year {
                                Text("\(year)")
                                Text("•")
                            }
                            Text("\(album.trackCount) songs")
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.5))
                    }
                    
                    // Action Buttons (Play All & Shuffle)
                    HStack(spacing: 16) {
                        Button {
                            audioService.isShuffleEnabled = false
                            audioService.play(songs: album.songs, startingAt: 0)
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Play All")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .crystalGlass(cornerRadius: 14)
                        }
                        
                        Button {
                            audioService.isShuffleEnabled = true
                            var shuffled = album.songs
                            shuffled.shuffle()
                            audioService.play(songs: shuffled, startingAt: 0)
                        } label: {
                            HStack {
                                Image(systemName: "shuffle")
                                Text("Shuffle")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .crystalGlass(cornerRadius: 14)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    
                    // Songs Tracklist
                    LazyVStack(spacing: 4) {
                        ForEach(Array(album.songs.enumerated()), id: \.element.id) { index, song in
                            let isCurrent = (audioService.currentSong?.id == song.id)
                            SongRowView(
                                song: song,
                                isPlaying: audioService.isPlaying,
                                isCurrentSong: isCurrent,
                                onTap: {
                                    audioService.play(songs: album.songs, startingAt: index)
                                },
                                onPlayNext: { playerVM.audioService.playNext(song: song) },
                                onAppendQueue: { playerVM.audioService.appendToQueue(song: song) },
                                onToggleFavorite: { playerVM.toggleFavorite(for: song) }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 120) // Clearance for floating MiniPlayer
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
