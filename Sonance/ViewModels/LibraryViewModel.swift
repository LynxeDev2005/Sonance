import Foundation
import SwiftUI
import Combine

public enum LibrarySortOption: String, CaseIterable, Identifiable {
    case title = "Title"
    case artist = "Artist"
    case album = "Album"
    case dateAdded = "Recently Added"
    case duration = "Duration"
    
    public var id: String { rawValue }
}

public enum LibrarySegment: String, CaseIterable, Identifiable {
    case songs = "Songs"
    case albums = "Albums"
    case artists = "Artists"
    case playlists = "Playlists"
    case favorites = "Favorites"
    
    public var id: String { rawValue }
}

/// ViewModel for library browsing, sorting, searching, and playlist management
public final class LibraryViewModel: ObservableObject {
    public static let shared = LibraryViewModel()
    
    @ObservedObject public var databaseService = DatabaseService.shared
    @ObservedObject public var fileManager = LocalFileManager.shared
    
    @Published public var selectedSegment: LibrarySegment = .songs
    @Published public var sortOption: LibrarySortOption = .title
    @Published public var isAscending: Bool = true
    @Published public var searchText: String = ""
    @Published public var isImportingFiles: Bool = false
    
    private init() {}
    
    // MARK: - Computed Filtered Data
    
    public var filteredSongs: [Song] {
        var result = databaseService.songs
        
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.artist.lowercased().contains(query) ||
                $0.album.lowercased().contains(query) ||
                ($0.genre?.lowercased().contains(query) ?? false)
            }
        }
        
        switch sortOption {
        case .title:
            result.sort { isAscending ? $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending : $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .artist:
            result.sort { isAscending ? $0.artist.localizedCaseInsensitiveCompare($1.artist) == .orderedAscending : $0.artist.localizedCaseInsensitiveCompare($1.artist) == .orderedDescending }
        case .album:
            result.sort { isAscending ? $0.album.localizedCaseInsensitiveCompare($1.album) == .orderedAscending : $0.album.localizedCaseInsensitiveCompare($1.album) == .orderedDescending }
        case .dateAdded:
            result.sort { isAscending ? $0.dateAdded < $1.dateAdded : $0.dateAdded > $1.dateAdded }
        case .duration:
            result.sort { isAscending ? $0.duration < $1.duration : $0.duration > $1.duration }
        }
        
        return result
    }
    
    public var albums: [Album] {
        var albumDict: [String: [Song]] = [:]
        for song in databaseService.songs {
            let key = "\(song.artist) - \(song.album)"
            albumDict[key, default: []].append(song)
        }
        
        return albumDict.map { _, songs in
            let first = songs.first!
            return Album(
                title: first.album,
                artist: first.artist,
                year: first.year,
                songs: songs.sorted { ($0.trackNumber ?? 0) < ($1.trackNumber ?? 0) },
                artworkRelativePath: first.artworkRelativePath
            )
        }.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
    
    public var artists: [Artist] {
        var artistDict: [String: [Song]] = [:]
        for song in databaseService.songs {
            artistDict[song.artist, default: []].append(song)
        }
        
        return artistDict.map { artistName, songs in
            var albumDict: [String: [Song]] = [:]
            for song in songs {
                albumDict[song.album, default: []].append(song)
            }
            let albums = albumDict.map { Album(title: $0.key, artist: artistName, songs: $0.value) }
            return Artist(name: artistName, songs: songs, albums: albums)
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    public var favoriteSongs: [Song] {
        databaseService.songs.filter { $0.isFavorite }
    }
    
    public func refreshLibrary() async {
        await fileManager.scanMusicDirectory()
    }
}
