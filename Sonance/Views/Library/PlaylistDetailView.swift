import SwiftUI

/// Detailed view showing playlist songs with editing and play actions
public struct PlaylistDetailView: View {
    public var playlist: Playlist
    @ObservedObject var databaseService = DatabaseService.shared
    @ObservedObject var audioService = AudioPlayerService.shared
    @ObservedObject var playerVM = PlayerViewModel.shared
    
    public init(playlist: Playlist) {
        self.playlist = playlist
    }
    
    private var songs: [Song] {
        databaseService.getSongs(for: playlist)
    }
    
    public var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.2, green: 0.5, blue: 0.9),
                                            Color(red: 0.6, green: 0.2, blue: 0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 160, height: 160)
                                .crystalGlass(cornerRadius: 24, specularIntensity: 0.8)
                            
                            Image(systemName: playlist.isSmartPlaylist ? "sparkles" : "music.note.list")
                                .font(.system(size: 54, weight: .semibold))
                                .foregroundStyle(Color.white)
                        }
                        .padding(.top, 24)
                        
                        Text(playlist.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.white)
                        
                        Text("\(songs.count) songs")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                    
                    // Play & Shuffle
                    if !songs.isEmpty {
                        HStack(spacing: 16) {
                            Button {
                                audioService.isShuffleEnabled = false
                                audioService.play(songs: songs, startingAt: 0)
                            } label: {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Play")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .crystalGlass(cornerRadius: 14)
                            }
                            
                            Button {
                                audioService.isShuffleEnabled = true
                                var shuffled = songs
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
                    }
                    
                    // Track list
                    LazyVStack(spacing: 4) {
                        ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                            let isCurrent = (audioService.currentSong?.id == song.id)
                            SongRowView(
                                song: song,
                                isPlaying: audioService.isPlaying,
                                isCurrentSong: isCurrent,
                                onTap: {
                                    audioService.play(songs: songs, startingAt: index)
                                },
                                onPlayNext: { playerVM.audioService.playNext(song: song) },
                                onAppendQueue: { playerVM.audioService.appendToQueue(song: song) },
                                onToggleFavorite: { playerVM.toggleFavorite(for: song) }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
