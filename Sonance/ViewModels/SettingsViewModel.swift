import Foundation
import SwiftUI

/// ViewModel managing application settings, storage diagnostics, equalizer presets, and server controls
public final class SettingsViewModel: ObservableObject {
    public static let shared = SettingsViewModel()
    
    @ObservedObject public var wifiServer = WiFiTransferServer.shared
    @ObservedObject public var equalizer = EqualizerService.shared
    @ObservedObject public var sleepTimer = SleepTimerService.shared
    
    @Published public var totalMusicSize: String = "0 MB"
    @Published public var cacheSize: String = "0 MB"
    @Published public var totalTrackCount: Int = 0
    
    private init() {
        calculateStorageUsage()
    }
    
    public func calculateStorageUsage() {
        let docs = LocalFileManager.shared.documentsDirectory
        let musicDir = LocalFileManager.shared.musicDirectory
        let artworkDir = LocalFileManager.shared.artworkDirectory
        
        let musicBytes = folderSize(at: musicDir)
        let artworkBytes = folderSize(at: artworkDir)
        
        self.totalMusicSize = ByteCountFormatter.string(fromByteCount: musicBytes, countStyle: .file)
        self.cacheSize = ByteCountFormatter.string(fromByteCount: artworkBytes, countStyle: .file)
        self.totalTrackCount = DatabaseService.shared.songs.count
    }
    
    public func clearArtworkCache() {
        let artworkDir = LocalFileManager.shared.artworkDirectory
        try? FileManager.default.removeItem(at: artworkDir)
        try? FileManager.default.createDirectory(at: artworkDir, withIntermediateDirectories: true)
        calculateStorageUsage()
    }
    
    private func folderSize(at url: URL) -> Int64 {
        var size: Int64 = 0
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        for case let fileURL as URL in enumerator {
            if let attrs = try? fm.attributesOfItem(atPath: fileURL.path),
               let s = attrs[.size] as? Int64 {
                size += s
            }
        }
        return size
    }
}
