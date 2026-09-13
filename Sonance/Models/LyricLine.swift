import Foundation

/// Represents a single synchronized timestamped line of lyrics
public struct LyricLine: Identifiable, Codable, Hashable {
    public let id: UUID
    public let timestamp: TimeInterval // in seconds
    public let text: String
    
    public init(id: UUID = UUID(), timestamp: TimeInterval, text: String) {
        self.id = id
        self.timestamp = timestamp
        self.text = text
    }
}
