import Foundation
import ActivityKit

/// Attributes defining the Sonance Live Activity and Dynamic Island widget
public struct SonanceActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var songTitle: String
        public var artistName: String
        public var albumName: String
        public var duration: TimeInterval
        public var currentTime: TimeInterval
        public var isPlaying: Bool
        public var artworkData: Data?
        
        public init(
            songTitle: String,
            artistName: String,
            albumName: String,
            duration: TimeInterval,
            currentTime: TimeInterval,
            isPlaying: Bool,
            artworkData: Data? = nil
        ) {
            self.songTitle = songTitle
            self.artistName = artistName
            self.albumName = albumName
            self.duration = duration
            self.currentTime = currentTime
            self.isPlaying = isPlaying
            self.artworkData = artworkData
        }
    }
    
    public var trackId: String
    
    public init(trackId: String) {
        self.trackId = trackId
    }
}
