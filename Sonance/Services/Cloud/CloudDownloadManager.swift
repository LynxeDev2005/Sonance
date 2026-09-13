import Foundation
import Combine

/// Multi-threaded background download manager for remote cloud files
public final class CloudDownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    public static let shared = CloudDownloadManager()
    
    @Published public var activeDownloads: [String: Double] = [:] // File ID -> Progress (0.0 ... 1.0)
    @Published public var downloadQueue: [CloudItem] = []
    @Published public var isDownloading: Bool = false
    
    private var downloadSession: URLSession!
    private var taskToFileMap: [Int: CloudItem] = [:]
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.default
        self.downloadSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }
    
    /// Adds items to the download queue and begins downloading
    public func download(items: [CloudItem]) {
        for item in items where !item.isFolder {
            if !downloadQueue.contains(where: { $0.id == item.id }) {
                downloadQueue.append(item)
            }
        }
        processNextDownload()
    }
    
    private func processNextDownload() {
        guard !downloadQueue.isEmpty else {
            isDownloading = false
            return
        }
        
        isDownloading = true
        let item = downloadQueue.removeFirst()
        
        Task {
            do {
                let token = try await GoogleDriveAuthManager.shared.getValidAccessToken()
                let downloadURLString = "https://www.googleapis.com/drive/v3/files/\(item.id)?alt=media"
                guard let url = URL(string: downloadURLString) else { return }
                
                var request = URLRequest(url: url)
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                let task = downloadSession.downloadTask(with: request)
                taskToFileMap[task.taskIdentifier] = item
                activeDownloads[item.id] = 0.05
                task.resume()
            } catch {
                print("[CloudDownloadManager] Failed to start download for \(item.name): \(error)")
                processNextDownload()
            }
        }
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let item = taskToFileMap[downloadTask.taskIdentifier], totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        activeDownloads[item.id] = progress
    }
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let item = taskToFileMap[downloadTask.taskIdentifier] else { return }
        
        let destination = LocalFileManager.shared.musicDirectory.appendingPathComponent(item.name)
        try? FileManager.default.removeItem(at: destination)
        
        do {
            try FileManager.default.moveItem(at: location, to: destination)
            activeDownloads.removeValue(forKey: item.id)
            taskToFileMap.removeValue(forKey: downloadTask.taskIdentifier)
            
            Task {
                await LocalFileManager.shared.scanMusicDirectory()
            }
        } catch {
            print("[CloudDownloadManager] Failed to save downloaded file \(item.name): \(error)")
        }
        
        processNextDownload()
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("[CloudDownloadManager] Download failed with error: \(error)")
            if let item = taskToFileMap[task.taskIdentifier] {
                activeDownloads.removeValue(forKey: item.id)
                taskToFileMap.removeValue(forKey: task.taskIdentifier)
            }
            processNextDownload()
        }
    }
}
