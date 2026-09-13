import SwiftUI

/// File system folder browser allowing users to play music structured in directories
public struct FolderBrowserView: View {
    @ObservedObject var folderVM = FolderBrowserViewModel.shared
    @ObservedObject var audioService = AudioPlayerService.shared
    @ObservedObject var playerVM = PlayerViewModel.shared
    @ObservedObject var fileManager = LocalFileManager.shared
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        if !folderVM.folderPathStack.isEmpty {
                            Button {
                                folderVM.navigateBack()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                                    .frame(width: 36, height: 36)
                            }
                        }
                        
                        Text(folderVM.currentFolder?.name ?? "Folders")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    if let folder = folderVM.currentFolder ?? fileManager.rootFolder {
                        // Quick Action Play / Shuffle Folder
                        if folder.totalSongCount > 0 {
                            HStack(spacing: 12) {
                                Button {
                                    folderVM.playAll(in: folder, shuffle: false)
                                } label: {
                                    HStack {
                                        Image(systemName: "play.fill")
                                        Text("Play Folder")
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .crystalGlass(cornerRadius: 12)
                                }
                                
                                Button {
                                    folderVM.playAll(in: folder, shuffle: true)
                                } label: {
                                    HStack {
                                        Image(systemName: "shuffle")
                                        Text("Shuffle")
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .crystalGlass(cornerRadius: 12)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                        
                        ScrollView {
                            VStack(spacing: 16) {
                                // Subfolders List
                                if !folder.subfolders.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Folders")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.white.opacity(0.5))
                                            .padding(.horizontal, 20)
                                        
                                        ForEach(folder.subfolders) { subfolder in
                                            Button {
                                                folderVM.navigateTo(folder: subfolder)
                                            } label: {
                                                HStack(spacing: 14) {
                                                    Image(systemName: "folder.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundStyle(
                                                            LinearGradient(
                                                                colors: [
                                                                    Color(red: 0.4, green: 0.8, blue: 1.0),
                                                                    Color(red: 0.25, green: 0.55, blue: 0.95)
                                                                ],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            )
                                                        )
                                                    
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(subfolder.name)
                                                            .font(.system(size: 16, weight: .semibold))
                                                            .foregroundStyle(Color.white)
                                                        Text("\(subfolder.totalSongCount) tracks")
                                                            .font(.system(size: 12))
                                                            .foregroundStyle(Color.white.opacity(0.5))
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 13, weight: .semibold))
                                                        .foregroundStyle(Color.white.opacity(0.3))
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .crystalGlass(cornerRadius: 14, specularIntensity: 0.4)
                                                .padding(.horizontal, 20)
                                            }
                                        }
                                    }
                                }
                                
                                // Songs in current folder
                                if !folder.songs.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Tracks")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.white.opacity(0.5))
                                            .padding(.horizontal, 20)
                                        
                                        LazyVStack(spacing: 4) {
                                            ForEach(Array(folder.songs.enumerated()), id: \.element.id) { index, song in
                                                let isCurrent = (audioService.currentSong?.id == song.id)
                                                SongRowView(
                                                    song: song,
                                                    isPlaying: audioService.isPlaying,
                                                    isCurrentSong: isCurrent,
                                                    onTap: {
                                                        audioService.play(songs: folder.songs, startingAt: index)
                                                    },
                                                    onPlayNext: { playerVM.audioService.playNext(song: song) },
                                                    onAppendQueue: { playerVM.audioService.appendToQueue(song: song) },
                                                    onToggleFavorite: { playerVM.toggleFavorite(for: song) },
                                                    onDelete: { fileManager.deleteSong(song) }
                                                )
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                    }
                                }
                                
                                if folder.subfolders.isEmpty && folder.songs.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "folder.badge.plus")
                                            .font(.system(size: 44, weight: .light))
                                            .foregroundStyle(Color.white.opacity(0.3))
                                            .padding(.top, 40)
                                        Text("This folder is empty")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(Color.white.opacity(0.5))
                                    }
                                }
                            }
                            .padding(.bottom, 120)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}
