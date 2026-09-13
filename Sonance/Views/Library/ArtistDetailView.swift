import SwiftUI

/// Detailed view showing artist discography, albums, and tracks
public struct ArtistDetailView: View {
    public var artist: Artist
    @ObservedObject var audioService = AudioPlayerService.shared
    @ObservedObject var playerVM = PlayerViewModel.shared
    
    public init(artist: Artist) {
        self.artist = artist
    }
    
    public var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Artist Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(artist.name)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color.white)
                        
                        Text("\(artist.trackCount) songs • \(artist.albumCount) albums")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Albums Section
                    if !artist.albums.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Albums")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(artist.albums) { album in
                                        NavigationLink {
                                            AlbumDetailView(album: album)
                                        } label: {
                                            VStack(alignment: .leading, spacing: 8) {
                                                ArtworkImageView(artworkURL: album.songs.first?.artworkURL, cornerRadius: 16, showBloom: false)
                                                    .frame(width: 140, height: 140)
                                                
                                                Text(album.title)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(Color.white)
                                                    .lineLimit(1)
                                                    .frame(width: 140, alignment: .leading)
                                                
                                                Text("\(album.trackCount) songs")
                                                    .font(.system(size: 12, weight: .regular))
                                                    .foregroundStyle(Color.white.opacity(0.5))
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    // All Songs Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Songs")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 20)
                        
                        LazyVStack(spacing: 4) {
                            ForEach(Array(artist.songs.enumerated()), id: \.element.id) { index, song in
                                let isCurrent = (audioService.currentSong?.id == song.id)
                                SongRowView(
                                    song: song,
                                    isPlaying: audioService.isPlaying,
                                    isCurrentSong: isCurrent,
                                    onTap: {
                                        audioService.play(songs: artist.songs, startingAt: index)
                                    },
                                    onPlayNext: { playerVM.audioService.playNext(song: song) },
                                    onAppendQueue: { playerVM.audioService.appendToQueue(song: song) },
                                    onToggleFavorite: { playerVM.toggleFavorite(for: song) }
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
