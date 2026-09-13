import Foundation
import SwiftUI
import Combine

/// ViewModel managing Google Drive file browsing, navigation stack, and download selection
public final class CloudDriveViewModel: ObservableObject {
    public static let shared = CloudDriveViewModel()
    
    @ObservedObject public var authManager = GoogleDriveAuthManager.shared
    @ObservedObject public var downloadManager = CloudDownloadManager.shared
    
    @Published public var items: [CloudItem] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var selectedItemIds: Set<String> = []
    @Published public var isSelectionMode: Bool = false
    
    @Published public var currentFolderId: String = "root"
    @Published public var folderStack: [(id: String, name: String)] = [("root", "Google Drive")]
    
    private init() {}
    
    public func loadCurrentFolder() async {
        guard authManager.isAuthenticated else { return }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let fetched = try await GoogleDriveService.shared.fetchItems(in: currentFolderId)
            await MainActor.run {
                self.items = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    public func navigateInto(folder: CloudItem) {
        guard folder.isFolder else { return }
        folderStack.append((id: folder.id, name: folder.name))
        currentFolderId = folder.id
        Task {
            await loadCurrentFolder()
        }
    }
    
    public func navigateBack() {
        guard folderStack.count > 1 else { return }
        folderStack.removeLast()
        currentFolderId = folderStack.last?.id ?? "root"
        Task {
            await loadCurrentFolder()
        }
    }
    
    public func toggleSelection(for item: CloudItem) {
        if selectedItemIds.contains(item.id) {
            selectedItemIds.remove(item.id)
        } else {
            selectedItemIds.insert(item.id)
        }
    }
    
    public func downloadSelected() {
        let itemsToDownload = items.filter { selectedItemIds.contains($0.id) }
        downloadManager.download(items: itemsToDownload)
        selectedItemIds.removeAll()
        isSelectionMode = false
    }
    
    public func downloadSingle(item: CloudItem) {
        downloadManager.download(items: [item])
    }
}
