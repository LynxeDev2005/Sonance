import Foundation
import AVFoundation
import UIKit

/// Asynchronously extracts audio metadata, embedded artwork, and lyrics using AVURLAsset
public final class MetadataExtractor {
    public static let shared = MetadataExtractor()
    
    private let artworkDirectory: URL
    
    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.artworkDirectory = docs.appendingPathComponent(AppConstants.Directories.artworkFolder, isDirectory: true)
        try? FileManager.default.createDirectory(at: artworkDirectory, withIntermediateDirectories: true)
    }
    
    /// Extracts full metadata from an audio file at the given relative path
    public func extractMetadata(relativePath: String) async -> Song {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = docs.appendingPathComponent(relativePath)
        
        let asset = AVURLAsset(url: fileURL)
        let fallbackTitle = fileURL.deletingPathExtension().lastPathComponent
        let fileExtension = fileURL.pathExtension.uppercased()
        
        var title = fallbackTitle
        var artist = "Unknown Artist"
        var album = "Unknown Album"
        var duration: TimeInterval = 0
        var trackNumber: Int?
        var genre: String?
        var year: Int?
        var artworkRelativePath: String?
        var plainLyrics: String?
        var fileSize: Int64 = 0
        
        // File attributes
        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let size = attrs[.size] as? Int64 {
            fileSize = size
        }
        
        // Async duration
        if let dur = try? await asset.load(.duration) {
            let seconds = CMTimeGetSeconds(dur)
            if !seconds.isNaN && !seconds.isInfinite && seconds > 0 {
                duration = seconds
            }
        }
        
        // Load metadata formats
        if let metadata = try? await asset.load(.metadata) {
            for item in metadata {
                guard let commonKey = item.commonKey else {
                    // Check non-common ID3 keys
                    if let keyString = item.key as? String {
                        if keyString == "USLT" || keyString == "ULT" {
                            plainLyrics = try? await item.load(.stringValue)
                        } else if keyString == "TRCK" || keyString == "trackNumber" {
                            if let str = try? await item.load(.stringValue) {
                                trackNumber = Int(str.components(separatedBy: "/").first ?? "")
                            }
                        } else if keyString == "TYER" || keyString == "TDRC" {
                            if let str = try? await item.load(.stringValue), let y = Int(str.prefix(4)) {
                                year = y
                            }
                        }
                    }
                    continue
                }
                
                switch commonKey {
                case .commonKeyTitle:
                    if let val = try? await item.load(.stringValue), !val.trimmingCharacters(in: .whitespaces).isEmpty {
                        title = val
                    }
                case .commonKeyArtist:
                    if let val = try? await item.load(.stringValue), !val.trimmingCharacters(in: .whitespaces).isEmpty {
                        artist = val
                    }
                case .commonKeyAlbumName:
                    if let val = try? await item.load(.stringValue), !val.trimmingCharacters(in: .whitespaces).isEmpty {
                        album = val
                    }
                case .commonKeyArtwork:
                    if let data = try? await item.load(.dataValue) {
                        artworkRelativePath = saveArtwork(data: data, identifier: "\(artist)-\(album)")
                    }
                case .commonKeyCreationDate:
                    if let str = try? await item.load(.stringValue), let y = Int(str.prefix(4)) {
                        year = y
                    }
                case .commonKeyType:
                    if let val = try? await item.load(.stringValue) {
                        genre = val
                    }
                default:
                    break
                }
            }
        }
        
        return Song(
            relativePath: relativePath,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            trackNumber: trackNumber,
            genre: genre,
            year: year,
            fileSize: fileSize,
            bitrate: nil,
            sampleRate: nil,
            fileFormat: fileExtension.isEmpty ? "AUDIO" : fileExtension,
            dateAdded: Date(),
            playCount: 0,
            isFavorite: false,
            lyrics: nil,
            plainLyrics: plainLyrics,
            artworkRelativePath: artworkRelativePath
        )
    }
    
    /// Caches extracted artwork image data to disk and returns the relative path
    private func saveArtwork(data: Data, identifier: String) -> String? {
        let safeName = identifier.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        let filename = "\(safeName).jpg"
        let fileURL = artworkDirectory.appendingPathComponent(filename)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return "\(AppConstants.Directories.artworkFolder)/\(filename)"
        }
        
        if let image = UIImage(data: data),
           let jpegData = image.jpegData(compressionQuality: 0.85) {
            do {
                try jpegData.write(to: fileURL)
                return "\(AppConstants.Directories.artworkFolder)/\(filename)"
            } catch {
                print("[MetadataExtractor] Failed to save artwork: \(error)")
            }
        }
        return nil
    }
}
