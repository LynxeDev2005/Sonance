import Foundation

/// User-created or smart dynamic playlist
public struct Playlist: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var songIds: [UUID]
    public var createdAt: Date
    public var modifiedAt: Date
    public var isSmartPlaylist: Bool
    public var artworkRelativePath: String?
    
    public init(
        id: UUID = UUID(),
        name: String,
        songIds: [UUID] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        isSmartPlaylist: Bool = false,
        artworkRelativePath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.songIds = songIds
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isSmartPlaylist = isSmartPlaylist
        self.artworkRelativePath = artworkRelativePath
    }
}
