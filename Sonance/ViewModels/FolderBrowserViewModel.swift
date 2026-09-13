import Foundation
import SwiftUI

/// ViewModel for exploring and playing songs organized in physical file folders
public final class FolderBrowserViewModel: ObservableObject {
    public static let shared = FolderBrowserViewModel()
    
    @ObservedObject public var fileManager = LocalFileManager.shared
    @Published public var currentFolder: AudioFolder?
    @Published public var folderPathStack: [AudioFolder] = []
    
    private init() {
        self.currentFolder = fileManager.rootFolder
    }
    
    public func navigateTo(folder: AudioFolder) {
        if let current = currentFolder {
            folderPathStack.append(current)
        }
        currentFolder = folder
    }
    
    public func navigateBack() {
        guard !folderPathStack.isEmpty else { return }
        currentFolder = folderPathStack.removeLast()
    }
    
    public func playAll(in folder: AudioFolder, shuffle: Bool = false) {
        var allSongs: [Song] = []
        func collectSongs(from f: AudioFolder) {
            allSongs.append(contentsOf: f.songs)
            for sub in f.subfolders {
                collectSongs(from: sub)
            }
        }
        collectSongs(from: folder)
        
        guard !allSongs.isEmpty else { return }
        if shuffle {
            AudioPlayerService.shared.isShuffleEnabled = true
            allSongs.shuffle()
        }
        AudioPlayerService.shared.play(songs: allSongs, startingAt: 0)
    }
}
