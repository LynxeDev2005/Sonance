import Foundation

/// Represents a folder on the device file system containing audio files or subfolders
public struct AudioFolder: Identifiable, Hashable {
    public var id: String { relativePath }
    public let name: String
    public let relativePath: String
    public var subfolders: [AudioFolder]
    public var songs: [Song]
    
    public init(
        name: String,
        relativePath: String,
        subfolders: [AudioFolder] = [],
        songs: [Song] = []
    ) {
        self.name = name
        self.relativePath = relativePath
        self.subfolders = subfolders
        self.songs = songs
    }
    
    public var totalSongCount: Int {
        songs.count + subfolders.reduce(0) { $0 + $1.totalSongCount }
    }
}
