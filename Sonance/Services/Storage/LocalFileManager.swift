import Foundation
import UIKit
import UniformTypeIdentifiers

/// Manages the local file system sandbox, directory scanning, and music ingestion
public final class LocalFileManager: ObservableObject {
    public static let shared = LocalFileManager()
    
    @Published public var isScanning: Bool = false
    @Published public var rootFolder: AudioFolder?
    
    public let documentsDirectory: URL
    public let musicDirectory: URL
    public let artworkDirectory: URL
    public let lyricsDirectory: URL
    
    private init() {
        self.documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.musicDirectory = documentsDirectory.appendingPathComponent(AppConstants.Directories.musicFolder, isDirectory: true)
        self.artworkDirectory = documentsDirectory.appendingPathComponent(AppConstants.Directories.artworkFolder, isDirectory: true)
        self.lyricsDirectory = documentsDirectory.appendingPathComponent(AppConstants.Directories.lyricsFolder, isDirectory: true)
        
        createDefaultDirectories()
    }
    
    private func createDefaultDirectories() {
        let fm = FileManager.default
        try? fm.createDirectory(at: musicDirectory, withIntermediateDirectories: true)
        try? fm.createDirectory(at: artworkDirectory, withIntermediateDirectories: true)
        try? fm.createDirectory(at: lyricsDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Directory Scanning
    
    /// Deep scans the entire Documents directory (including Music subfolder and direct Files app drops) and updates DatabaseService
    public func scanMusicDirectory() async {
        await MainActor.run { isScanning = true }
        
        let fm = FileManager.default
        let ignoredFolders: Set<String> = [
            AppConstants.Directories.artworkFolder.lowercased(),
            AppConstants.Directories.cacheFolder.lowercased()
        ]
        
        guard let enumerator = fm.enumerator(
            at: documentsDirectory,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            await MainActor.run { isScanning = false }
            return
        }
        
        var audioCandidateURLs: [URL] = []
        
        for case let fileURL as URL in enumerator {
            let pathLower = fileURL.path.lowercased()
            // Skip internal artwork and cache folders
            if ignoredFolders.contains(where: { pathLower.contains("/\($0)/") || pathLower.hasSuffix("/\($0)") }) {
                continue
            }
            if fileURL.lastPathComponent == AppConstants.Directories.databaseFile {
                continue
            }
            
            let ext = fileURL.pathExtension.lowercased()
            if AppConstants.SupportedFormats.audioExtensions.contains(ext) {
                audioCandidateURLs.append(fileURL)
            }
        }
        
        // Concurrently parse metadata for all candidate files
        var parsedSongs: [Song] = []
        await withTaskGroup(of: Song?.self) { group in
            for fileURL in audioCandidateURLs {
                group.addTask {
                    let relativePath = fileURL.path.replacingOccurrences(of: self.documentsDirectory.path + "/", with: "")
                    var song = await MetadataExtractor.shared.extractMetadata(relativePath: relativePath)
                    
                    // Look for paired .lrc file (e.g. Song.mp3 -> Song.lrc)
                    let lrcURL = fileURL.deletingPathExtension().appendingPathExtension("lrc")
                    if let parsedLyrics = LyricsParser.shared.parse(fileURL: lrcURL) {
                        song.lyrics = parsedLyrics
                    }
                    return song
                }
            }
            
            for await song in group {
                if let song = song {
                    parsedSongs.append(song)
                }
            }
        }
        
        // Update database
        DatabaseService.shared.updateSongs(parsedSongs)
        
        // Rebuild folder tree
        let folderTree = buildFolderTree(from: parsedSongs)
        
        await MainActor.run {
            self.rootFolder = folderTree
            self.isScanning = false
        }
    }
    
    // MARK: - File Ingestion (From Files app / iCloud / External Picker)
    
    /// Imports audio files or folders selected by the user into the local Documents/Music folder
    public func importFiles(from urls: [URL], destinationSubfolder: String? = nil) async -> Int {
        var importedCount = 0
        let targetDir: URL
        if let subfolder = destinationSubfolder, !subfolder.isEmpty {
            targetDir = musicDirectory.appendingPathComponent(subfolder, isDirectory: true)
        } else {
            targetDir = musicDirectory
        }
        try? FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
        
        for url in urls {
            let isAccessing = url.startAccessingSecurityScopedResource()
            
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
                if isDir.boolValue {
                    // Recursive directory copy
                    let folderName = url.lastPathComponent
                    let destFolder = targetDir.appendingPathComponent(folderName, isDirectory: true)
                    try? FileManager.default.createDirectory(at: destFolder, withIntermediateDirectories: true)
                    importedCount += await copyFolderContents(from: url, to: destFolder)
                } else {
                    let ext = url.pathExtension.lowercased()
                    if AppConstants.SupportedFormats.audioExtensions.contains(ext) ||
                       AppConstants.SupportedFormats.lyricsExtensions.contains(ext) ||
                       ext.isEmpty {
                        let destURL = targetDir.appendingPathComponent(url.lastPathComponent)
                        if FileManager.default.fileExists(atPath: destURL.path) {
                            try? FileManager.default.removeItem(at: destURL)
                        }
                        
                        do {
                            try FileManager.default.copyItem(at: url, to: destURL)
                            importedCount += 1
                        } catch {
                            // High-reliability direct byte stream fallback for sandbox transfers
                            if let data = try? Data(contentsOf: url) {
                                do {
                                    try data.write(to: destURL, options: .atomic)
                                    importedCount += 1
                                } catch {
                                    print("[LocalFileManager] Failed fallback write for \(url.lastPathComponent): \(error)")
                                }
                            } else {
                                print("[LocalFileManager] Failed to copy item: \(error)")
                            }
                        }
                    }
                }
            }
            
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        await scanMusicDirectory()
        return importedCount
    }
    
    private func copyFolderContents(from source: URL, to destination: URL) async -> Int {
        var count = 0
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: source, includingPropertiesForKeys: nil) else {
            return 0
        }
        
        for item in contents {
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: item.path, isDirectory: &isDir) {
                if isDir.boolValue {
                    let subDest = destination.appendingPathComponent(item.lastPathComponent, isDirectory: true)
                    try? fm.createDirectory(at: subDest, withIntermediateDirectories: true)
                    count += await copyFolderContents(from: item, to: subDest)
                } else {
                    let ext = item.pathExtension.lowercased()
                    if AppConstants.SupportedFormats.audioExtensions.contains(ext) ||
                       AppConstants.SupportedFormats.lyricsExtensions.contains(ext) {
                        let destURL = destination.appendingPathComponent(item.lastPathComponent)
                        try? fm.removeItem(at: destURL)
                        try? fm.copyItem(at: item, to: destURL)
                        count += 1
                    }
                }
            }
        }
        return count
    }
    
    /// Deletes a song physically from the disk
    public func deleteSong(_ song: Song) {
        let fileURL = song.fileURL
        try? FileManager.default.removeItem(at: fileURL)
        
        // Remove paired lyrics if present
        let lrcURL = fileURL.deletingPathExtension().appendingPathExtension("lrc")
        try? FileManager.default.removeItem(at: lrcURL)
        
        Task {
            await scanMusicDirectory()
        }
    }
    
    // MARK: - Folder Tree Builder
    
    private func buildFolderTree(from songs: [Song]) -> AudioFolder {
        var folderMap: [String: [Song]] = [:]
        
        for song in songs {
            let components = song.relativePath.components(separatedBy: "/")
            let folderPath: String
            if components.count > 1 {
                folderPath = components.dropLast().joined(separator: "/")
            } else {
                folderPath = AppConstants.Directories.musicFolder
            }
            folderMap[folderPath, default: []].append(song)
        }
        
        let rootSongs = folderMap[AppConstants.Directories.musicFolder] ?? []
        var subfolders: [AudioFolder] = []
        
        for (path, songsInFolder) in folderMap where path != AppConstants.Directories.musicFolder {
            let folderName = path.components(separatedBy: "/").last ?? path
            subfolders.append(AudioFolder(name: folderName, relativePath: path, songs: songsInFolder))
        }
        
        return AudioFolder(
            name: "Music",
            relativePath: AppConstants.Directories.musicFolder,
            subfolders: subfolders.sorted { $0.name < $1.name },
            songs: rootSongs
        )
    }
}
