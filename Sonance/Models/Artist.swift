import Foundation

/// Represents a music artist with associated albums and songs
public struct Artist: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public var songs: [Song]
    public var albums: [Album]
    
    public init(name: String, songs: [Song] = [], albums: [Album] = []) {
        self.name = name
        self.songs = songs
        self.albums = albums
    }
    
    public var trackCount: Int {
        songs.count
    }
    
    public var albumCount: Int {
        albums.count
    }
    
    public var artworkRelativePath: String? {
        songs.first(where: { $0.artworkRelativePath != nil })?.artworkRelativePath
    }
}
