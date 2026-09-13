import SwiftUI
import UniformTypeIdentifiers

/// Primary Library tab featuring modern crystal segmented filtering, search, and import actions
public struct LibraryView: View {
    @ObservedObject var libraryVM = LibraryViewModel.shared
    @ObservedObject var audioService = AudioPlayerService.shared
    @ObservedObject var playerVM = PlayerViewModel.shared
    @ObservedObject var fileManager = LocalFileManager.shared
    
    @State private var showFileImporter = false
    @State private var showCreatePlaylistSheet = false
    @State private var newPlaylistName = ""
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Bar
                    HStack {
                        Text("Sonance")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.8, green: 0.9, blue: 1.0),
                                        Color(red: 0.4, green: 0.8, blue: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Spacer()
                        
                        // Import Button
                        Button {
                            showFileImporter = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Import")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .crystalGlass(cornerRadius: 16, specularIntensity: 0.8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.white.opacity(0.4))
                        
                        TextField("Search tracks, artists, albums...", text: $libraryVM.searchText)
                            .font(.system(size: 15))
                            .foregroundStyle(Color.white)
                        
                        if !libraryVM.searchText.isEmpty {
                            Button {
                                libraryVM.searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.white.opacity(0.4))
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .crystalGlass(cornerRadius: 14, specularIntensity: 0.5)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Segmented Control
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(LibrarySegment.allCases) { segment in
                                let isSelected = (libraryVM.selectedSegment == segment)
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        libraryVM.selectedSegment = segment
                                    }
                                } label: {
                                    Text(segment.rawValue)
                                        .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                                        .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.55))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background {
                                            if isSelected {
                                                Capsule()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [
                                                                Color(red: 0.35, green: 0.75, blue: 1.0).opacity(0.4),
                                                                Color(red: 0.7, green: 0.45, blue: 0.95).opacity(0.4)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .crystalGlass(cornerRadius: 20, specularIntensity: 0.7)
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    
                    // Main Content List
                    ScrollView {
                        if fileManager.isScanning {
                            HStack(spacing: 12) {
                                ProgressView()
                                    .tint(.white)
                                Text("Indexing local music files...")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.white.opacity(0.7))
                            }
                            .padding(.top, 40)
                        } else {
                            renderSegmentContent()
                        }
                    }
                    .refreshable {
                        await libraryVM.refreshLibrary()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.audio, .folder],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task {
                    _ = await fileManager.importFiles(from: urls)
                }
            case .failure(let error):
                print("[LibraryView] File import failed: \(error)")
            }
        }
        .sheet(isPresented: $showCreatePlaylistSheet) {
            createPlaylistSheetView
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func renderSegmentContent() -> some View {
        switch libraryVM.selectedSegment {
        case .songs:
            songsListView(songs: libraryVM.filteredSongs)
        case .albums:
            albumsGridView
        case .artists:
            artistsListView
        case .playlists:
            playlistsListView
        case .favorites:
            songsListView(songs: libraryVM.favoriteSongs)
        }
    }
    
    @ViewBuilder
    private func songsListView(songs: [Song]) -> some View {
        if songs.isEmpty {
            emptyStateView(
                icon: "music.note.list",
                title: "No Songs Found",
                subtitle: "Drop music into the Sonance folder via Files app / iTunes or tap Import."
            )
        } else {
            LazyVStack(spacing: 4) {
                // Quick Play All & Shuffle
                HStack {
                    Text("\(songs.count) tracks")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                    
                    Spacer()
                    
                    Menu {
                        ForEach(LibrarySortOption.allCases) { opt in
                            Button {
                                libraryVM.sortOption = opt
                            } label: {
                                HStack {
                                    Text(opt.rawValue)
                                    if libraryVM.sortOption == opt {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Sort: \(libraryVM.sortOption.rawValue)")
                                .font(.system(size: 13, weight: .semibold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                
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
                        onToggleFavorite: { playerVM.toggleFavorite(for: song) },
                        onDelete: { fileManager.deleteSong(song) }
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 120)
        }
    }
    
    private var albumsGridView: some View {
        let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        return LazyVGrid(columns: columns, spacing: 20) {
            ForEach(libraryVM.albums) { album in
                NavigationLink {
                    AlbumDetailView(album: album)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        ArtworkImageView(artworkURL: album.songs.first?.artworkURL, cornerRadius: 18, showBloom: false)
                            .aspectRatio(1, contentMode: .fit)
                        
                        Text(album.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                        
                        Text(album.artist)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 120)
    }
    
    private var artistsListView: some View {
        LazyVStack(spacing: 8) {
            ForEach(libraryVM.artists) { artist in
                NavigationLink {
                    ArtistDetailView(artist: artist)
                } label: {
                    HStack(spacing: 16) {
                        ArtworkImageView(artworkURL: artist.songs.first?.artworkURL, cornerRadius: 24, showBloom: false)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(artist.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.white)
                            Text("\(artist.trackCount) songs • \(artist.albumCount) albums")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(14)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 120)
    }
    
    private var playlistsListView: some View {
        VStack(spacing: 12) {
            // New Playlist Button
            Button {
                showCreatePlaylistSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("New Playlist")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .crystalGlass(cornerRadius: 16)
            }
            .padding(.horizontal, 20)
            
            LazyVStack(spacing: 8) {
                ForEach(DatabaseService.shared.playlists) { playlist in
                    NavigationLink {
                        PlaylistDetailView(playlist: playlist)
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.3))
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: playlist.isSmartPlaylist ? "sparkles" : "music.note.list")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(playlist.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.white)
                                Text("\(DatabaseService.shared.getSongs(for: playlist).count) songs")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.3))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(14)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 120)
        }
    }
    
    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.white.opacity(0.3))
                .padding(.top, 60)
            
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.white)
            
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var createPlaylistSheetView: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("New Playlist")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.top, 24)
                    
                    TextField("Playlist Name", text: $newPlaylistName)
                        .padding()
                        .crystalGlass(cornerRadius: 14)
                        .padding(.horizontal, 24)
                        .foregroundStyle(Color.white)
                    
                    Button {
                        if !newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty {
                            _ = DatabaseService.shared.createPlaylist(name: newPlaylistName)
                            newPlaylistName = ""
                            showCreatePlaylistSheet = false
                        }
                    } label: {
                        Text("Create")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.25, green: 0.55, blue: 0.95))
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}
