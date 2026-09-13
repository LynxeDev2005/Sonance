import Foundation

/// Represents a grouped music album
public struct Album: Identifiable, Hashable {
    public var id: String { "\(artist)-\(title)" }
    public let title: String
    public let artist: String
    public var year: Int?
    public var songs: [Song]
    public var artworkRelativePath: String?
    
    public init(
        title: String,
        artist: String,
        year: Int? = nil,
        songs: [Song] = [],
        artworkRelativePath: String? = nil
    ) {
        self.title = title
        self.artist = artist
        self.year = year
        self.songs = songs
        self.artworkRelativePath = artworkRelativePath ?? songs.first?.artworkRelativePath
    }
    
    public var totalDuration: TimeInterval {
        songs.reduce(0) { $0 + $1.duration }
    }
    
    public var trackCount: Int {
        songs.count
    }
}
