import Foundation

/// Data container serialized to disk
private struct DatabaseContainer: Codable {
    var songs: [Song]
    var playlists: [Playlist]
    var favoriteSongIds: Set<UUID>
    var playHistoryIds: [UUID]
}

/// Persistent local database managing playlists, song metadata, favorites, and history
public final class DatabaseService: ObservableObject {
    public static let shared = DatabaseService()
    
    @Published public var songs: [Song] = []
    @Published public var playlists: [Playlist] = []
    @Published public var favoriteSongIds: Set<UUID> = []
    @Published public var playHistory: [Song] = []
    
    private let databaseURL: URL
    private let queue = DispatchQueue(label: "com.sonance.databaseservice", qos: .utility)
    
    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.databaseURL = docs.appendingPathComponent(AppConstants.Directories.databaseFile)
        loadFromDisk()
    }
    
    // MARK: - Persistence IO
    
    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: databaseURL.path),
              let data = try? Data(contentsOf: databaseURL) else {
            createDefaultPlaylists()
            return
        }
        
        do {
            let container = try JSONDecoder().decode(DatabaseContainer.self, from: data)
            self.songs = container.songs
            self.playlists = container.playlists
            self.favoriteSongIds = container.favoriteSongIds
            
            // Reconstruct history
            let songMap = Dictionary(uniqueKeysWithValues: songs.map { ($0.id, $0) })
            self.playHistory = container.playHistoryIds.compactMap { songMap[$0] }
        } catch {
            print("[DatabaseService] Failed to decode database: \(error)")
            createDefaultPlaylists()
        }
    }
    
    public func saveToDisk() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let container = DatabaseContainer(
                songs: self.songs,
                playlists: self.playlists,
                favoriteSongIds: self.favoriteSongIds,
                playHistoryIds: self.playHistory.map { $0.id }
            )
            
            do {
                let data = try JSONEncoder().encode(container)
                try data.write(to: self.databaseURL, options: .atomic)
            } catch {
                print("[DatabaseService] Failed to save database: \(error)")
            }
        }
    }
    
    private func createDefaultPlaylists() {
        self.playlists = [
            Playlist(name: "Favorites", isSmartPlaylist: true),
            Playlist(name: "Recently Added", isSmartPlaylist: true),
            Playlist(name: "Most Played", isSmartPlaylist: true)
        ]
        saveToDisk()
    }
    
    // MARK: - Song Mutations
    
    public func updateSongs(_ newSongs: [Song]) {
        // Merge existing favorites & play counts
        var merged: [Song] = []
        let existingMap = Dictionary(uniqueKeysWithValues: self.songs.map { ($0.relativePath, $0) })
        
        for var song in newSongs {
            if let existing = existingMap[song.relativePath] {
                song.isFavorite = existing.isFavorite
                song.playCount = existing.playCount
                if song.isFavorite {
                    favoriteSongIds.insert(song.id)
                }
            }
            merged.append(song)
        }
        
        DispatchQueue.main.async {
            self.songs = merged
            self.saveToDisk()
        }
    }
    
    public func toggleFavorite(for song: Song) {
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            songs[index].isFavorite.toggle()
            if songs[index].isFavorite {
                favoriteSongIds.insert(song.id)
            } else {
                favoriteSongIds.remove(song.id)
            }
            saveToDisk()
        }
    }
    
    public func recordPlay(for song: Song) {
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            songs[index].playCount += 1
        }
        
        // Update history (keep last 50 tracks)
        playHistory.removeAll(where: { $0.id == song.id })
        playHistory.insert(song, at: 0)
        if playHistory.count > 50 {
            playHistory.removeLast()
        }
        
        saveToDisk()
    }
    
    // MARK: - Playlist CRUD
    
    public func createPlaylist(name: String) -> Playlist {
        let playlist = Playlist(name: name)
        playlists.append(playlist)
        saveToDisk()
        return playlist
    }
    
    public func deletePlaylist(id: UUID) {
        playlists.removeAll(where: { $0.id == id && !$0.isSmartPlaylist })
        saveToDisk()
    }
    
    public func addSongToPlaylist(songId: UUID, playlistId: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        if !playlists[index].songIds.contains(songId) {
            playlists[index].songIds.append(songId)
            playlists[index].modifiedAt = Date()
            saveToDisk()
        }
    }
    
    public func removeSongFromPlaylist(songId: UUID, playlistId: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        playlists[index].songIds.removeAll(where: { $0 == songId })
        playlists[index].modifiedAt = Date()
        saveToDisk()
    }
    
    public func getSongs(for playlist: Playlist) -> [Song] {
        if playlist.name == "Favorites" && playlist.isSmartPlaylist {
            return songs.filter { $0.isFavorite }
        } else if playlist.name == "Recently Added" && playlist.isSmartPlaylist {
            return songs.sorted { $0.dateAdded > $1.dateAdded }
        } else if playlist.name == "Most Played" && playlist.isSmartPlaylist {
            return songs.filter { $0.playCount > 0 }.sorted { $0.playCount > $1.playCount }
        } else {
            let songMap = Dictionary(uniqueKeysWithValues: songs.map { ($0.id, $0) })
            return playlist.songIds.compactMap { songMap[$0] }
        }
    }
}
