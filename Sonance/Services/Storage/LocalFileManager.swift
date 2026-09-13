import Foundation
import UIKit
import UniformTypeIdentifiers

public struct MusicImportResult: Sendable {
    public let importedCount: Int
    public let skippedCount: Int
    public let failedCount: Int
    public var summary: String {
        let fileLabel = importedCount == 1 ? "file" : "files"
        var parts = ["Imported \(importedCount) \(fileLabel)"]
        if skippedCount > 0 { parts.append("\(skippedCount) unsupported") }
        if failedCount > 0 { parts.append("\(failedCount) failed") }
        return parts.joined(separator: " • ")
    }
}

/// Manages the local file system sandbox, directory scanning, and music ingestion
public final class LocalFileManager: ObservableObject {
    public static let shared = LocalFileManager()
    
    @Published public var isScanning: Bool = false
    @Published public var rootFolder: AudioFolder?
    @Published public var latestImportResult: MusicImportResult?
    
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
        let docsPath = self.documentsDirectory.resolvingSymlinksInPath().path
        
        await withTaskGroup(of: Song?.self) { group in
            for fileURL in audioCandidateURLs {
                group.addTask {
                    let filePath = fileURL.resolvingSymlinksInPath().path
                    var relativePath = filePath
                    if filePath.hasPrefix(docsPath) {
                        relativePath = String(filePath.dropFirst(docsPath.count))
                        if relativePath.hasPrefix("/") { relativePath = String(relativePath.dropFirst()) }
                    }
                    
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
    public func importFiles(from urls: [URL], destinationSubfolder: String? = nil) async -> MusicImportResult {
        let targetDir: URL
        if let subfolder = destinationSubfolder, !subfolder.isEmpty {
            targetDir = musicDirectory.appendingPathComponent(subfolder, isDirectory: true)
        } else {
            targetDir = musicDirectory
        }
        let result = await Task.detached(priority: .utility) {
            Self.copySelectedItems(urls, to: targetDir)
        }.value
        await scanMusicDirectory()
        await MainActor.run { self.latestImportResult = result }
        return result
    }

    /// Runs away from the main actor: iCloud/File Provider copies can take seconds.
    private static func copySelectedItems(_ urls: [URL], to targetDir: URL) -> MusicImportResult {
        let fm = FileManager.default
        var imported = 0
        var skipped = 0
        var failed = 0
        do {
            try fm.createDirectory(at: targetDir, withIntermediateDirectories: true)
        } catch {
            return MusicImportResult(importedCount: 0, skippedCount: 0, failedCount: urls.count)
        }

        for source in urls {
            let isAccessing = source.startAccessingSecurityScopedResource()

            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: source.path, isDirectory: &isDir) else {
                failed += 1
                if isAccessing { source.stopAccessingSecurityScopedResource() }
                continue
            }

            if isDir.boolValue {
                let folderDestination = availableDirectory(for: source.lastPathComponent, in: targetDir)
                let report = copyFolderContents(from: source, to: folderDestination)
                imported += report.imported
                skipped += report.skipped
                failed += report.failed
            } else {
                switch copyFile(from: source, to: targetDir) {
                case .imported: imported += 1
                case .skipped: skipped += 1
                case .failed: failed += 1
                }
            }
            if isAccessing { source.stopAccessingSecurityScopedResource() }
        }
        return MusicImportResult(importedCount: imported, skippedCount: skipped, failedCount: failed)
    }

    private enum CopyOutcome { case imported, skipped, failed }

    private static func copyFolderContents(from source: URL, to destination: URL) -> (imported: Int, skipped: Int, failed: Int) {
        let fm = FileManager.default
        do { try fm.createDirectory(at: destination, withIntermediateDirectories: true) }
        catch { return (0, 0, 1) }
        guard let enumerator = fm.enumerator(at: source, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            return (0, 0, 1)
        }
        var report = (imported: 0, skipped: 0, failed: 0)
        let sourcePath = source.resolvingSymlinksInPath().path
        
        for case let item as URL in enumerator {
            let itemPath = item.resolvingSymlinksInPath().path
            var relativePath = itemPath
            if itemPath.hasPrefix(sourcePath) {
                relativePath = String(itemPath.dropFirst(sourcePath.count))
                if relativePath.hasPrefix("/") { relativePath = String(relativePath.dropFirst()) }
            }
            
            let destinationFolder = destination.appendingPathComponent(relativePath).deletingLastPathComponent()
            var isDirectory: ObjCBool = false
            guard fm.fileExists(atPath: item.path, isDirectory: &isDirectory), !isDirectory.boolValue else { continue }
            switch copyFile(from: item, to: destinationFolder) {
            case .imported: report.imported += 1
            case .skipped: report.skipped += 1
            case .failed: report.failed += 1
            }
        }
        return report
    }

    private static func copyFile(from source: URL, to directory: URL) -> CopyOutcome {
        let extensionName = source.pathExtension.lowercased()
        guard AppConstants.SupportedFormats.audioExtensions.contains(extensionName) ||
                AppConstants.SupportedFormats.lyricsExtensions.contains(extensionName) else { return .skipped }
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            let destination = availableFile(for: source, in: directory)
            
            var isMaterialized = false
            do {
                try fm.startDownloadingUbiquitousItem(at: source)
                try fm.copyItem(at: source, to: destination)
                isMaterialized = true
            } catch {
                print("[LocalFileManager] copyItem failed, attempting Data fallback: \(error.localizedDescription)")
            }
            
            if !isMaterialized {
                // Fallback: Read directly to memory and write (handles many security-scoped edge cases)
                let data = try Data(contentsOf: source)
                try data.write(to: destination, options: .atomic)
            }
            return .imported
        } catch {
            print("[LocalFileManager] Could not import \(source.lastPathComponent): \(error.localizedDescription)")
            return .failed
        }
    }

    /// Never overwrite a user's existing music when two imports contain the same name.
    private static func availableFile(for source: URL, in directory: URL) -> URL {
        let fm = FileManager.default
        let base = source.deletingPathExtension().lastPathComponent
        let ext = source.pathExtension
        var candidate = directory.appendingPathComponent(source.lastPathComponent)
        var copyNumber = 2
        while fm.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(base) \(copyNumber).\(ext)")
            copyNumber += 1
        }
        return candidate
    }

    private static func availableDirectory(for name: String, in parent: URL) -> URL {
        let fm = FileManager.default
        var candidate = parent.appendingPathComponent(name, isDirectory: true)
        var copyNumber = 2
        while fm.fileExists(atPath: candidate.path) {
            candidate = parent.appendingPathComponent("\(name) \(copyNumber)", isDirectory: true)
            copyNumber += 1
        }
        return candidate
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
