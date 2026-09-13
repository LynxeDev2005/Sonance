import SwiftUI

/// Reusable crystal list row for displaying a song item
public struct SongRowView: View {
    public var song: Song
    public var isPlaying: Bool
    public var isCurrentSong: Bool
    public var onTap: () -> Void
    public var onPlayNext: () -> Void
    public var onAppendQueue: () -> Void
    public var onToggleFavorite: () -> Void
    public var onDelete: () -> Void
    
    public init(
        song: Song,
        isPlaying: Bool = false,
        isCurrentSong: Bool = false,
        onTap: @escaping () -> Void,
        onPlayNext: @escaping () -> Void = {},
        onAppendQueue: @escaping () -> Void = {},
        onToggleFavorite: @escaping () -> Void = {},
        onDelete: @escaping () -> Void = {}
    ) {
        self.song = song
        self.isPlaying = isPlaying
        self.isCurrentSong = isCurrentSong
        self.onTap = onTap
        self.onPlayNext = onPlayNext
        self.onAppendQueue = onAppendQueue
        self.onToggleFavorite = onToggleFavorite
        self.onDelete = onDelete
    }
    
    public var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 14) {
                // Artwork / Playing Indicator
                ZStack {
                    ArtworkImageView(artworkURL: song.artworkURL, cornerRadius: 10, showBloom: false)
                        .frame(width: 48, height: 48)
                    
                    if isCurrentSong {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.45))
                            .frame(width: 48, height: 48)
                        
                        AnimatedVisualizerView(isPlaying: isPlaying, barCount: 3)
                    }
                }
                
                // Track Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(.system(size: 15, weight: isCurrentSong ? .bold : .medium))
                        .foregroundStyle(isCurrentSong ? Color(red: 0.4, green: 0.8, blue: 1.0) : Color.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(song.artist)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .lineLimit(1)
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.3))
                        
                        Text(song.fileFormat)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                }
                
                Spacer()
                
                // Duration
                Text(song.formattedDuration)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.45))
                
                // Favorite Button
                Button {
                    onToggleFavorite()
                } label: {
                    Image(systemName: song.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundStyle(song.isFavorite ? Color(red: 1.0, green: 0.3, blue: 0.45) : Color.white.opacity(0.3))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isCurrentSong ? Color.white.opacity(0.06) : Color.clear
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button {
                onPlayNext()
            } label: {
                Label("Play Next", systemImage: "text.insert")
            }
            
            Button {
                onAppendQueue()
            } label: {
                Label("Add to End of Queue", systemImage: "text.append")
            }
            
            Button {
                onToggleFavorite()
            } label: {
                Label(song.isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: song.isFavorite ? "heart.slash" : "heart")
            }
            
            ShareLink(item: song.fileURL) {
                Label("Share Audio File", systemImage: "square.and.arrow.up")
            }
            
            Divider()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete from Device", systemImage: "trash")
            }
        }
    }
}
