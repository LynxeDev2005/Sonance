import Foundation
import SwiftUI

/// Core track entity representing an audio file in Sonance
public struct Song: Identifiable, Codable, Hashable {
    /// Kept stable when a library scan refreshes metadata, so playlists, favorites,
    /// and the active queue continue to refer to the same track.
    public var id: UUID
    public var relativePath: String // Relative to Documents directory
    public var title: String
    public var artist: String
    public var album: String
    public var duration: TimeInterval
    public var trackNumber: Int?
    public var genre: String?
    public var year: Int?
    public var fileSize: Int64
    public var bitrate: Int?
    public var sampleRate: Double?
    public var fileFormat: String
    public var dateAdded: Date
    public var playCount: Int
    public var isFavorite: Bool
    public var lyrics: [LyricLine]?
    public var plainLyrics: String?
    public var artworkRelativePath: String? // Stored cached artwork path
    
    public init(
        id: UUID = UUID(),
        relativePath: String,
        title: String,
        artist: String = "Unknown Artist",
        album: String = "Unknown Album",
        duration: TimeInterval = 0,
        trackNumber: Int? = nil,
        genre: String? = nil,
        year: Int? = nil,
        fileSize: Int64 = 0,
        bitrate: Int? = nil,
        sampleRate: Double? = nil,
        fileFormat: String = "MP3",
        dateAdded: Date = Date(),
        playCount: Int = 0,
        isFavorite: Bool = false,
        lyrics: [LyricLine]? = nil,
        plainLyrics: String? = nil,
        artworkRelativePath: String? = nil
    ) {
        self.id = id
        self.relativePath = relativePath
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.trackNumber = trackNumber
        self.genre = genre
        self.year = year
        self.fileSize = fileSize
        self.bitrate = bitrate
        self.sampleRate = sampleRate
        self.fileFormat = fileFormat
        self.dateAdded = dateAdded
        self.playCount = playCount
        self.isFavorite = isFavorite
        self.lyrics = lyrics
        self.plainLyrics = plainLyrics
        self.artworkRelativePath = artworkRelativePath
    }
    
    /// Returns the absolute file URL in the current sandbox
    public var fileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(relativePath)
    }
    
    /// Returns the absolute artwork URL if available
    public var artworkURL: URL? {
        guard let artworkRelativePath = artworkRelativePath else { return nil }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(artworkRelativePath)
    }
    
    /// Formatted duration string e.g. "03:45"
    public var formattedDuration: String {
        guard duration > 0, !duration.isNaN, !duration.isInfinite else { return "00:00" }
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Formatted file size e.g. "9.4 MB"
    public var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    /// Audio quality badge text e.g. "FLAC • 24-bit/96kHz" or "MP3 • 320 kbps"
    public var audioQualityBadge: String {
        var parts: [String] = [fileFormat.uppercased()]
        if let bitrate = bitrate, bitrate > 0 {
            parts.append("\(bitrate / 1000) kbps")
        } else if let sampleRate = sampleRate, sampleRate > 0 {
            parts.append(String(format: "%.1f kHz", sampleRate / 1000.0))
        }
        return parts.joined(separator: " • ")
    }
}
