import Foundation

/// Service communicating with Google Drive API v3
public final class GoogleDriveService: ObservableObject {
    public static let shared = GoogleDriveService()
    
    private init() {}
    
    /// Fetches audio files and subfolders within a specific folder (defaults to root)
    public func fetchItems(in folderId: String = "root") async throws -> [CloudItem] {
        let token = try await GoogleDriveAuthManager.shared.getValidAccessToken()
        
        let query = "'\(folderId)' in parents and trashed = false and (mimeType = 'application/vnd.google-apps.folder' or mimeType contains 'audio' or name contains '.mp3' or name contains '.flac' or name contains '.m4a' or name contains '.wav' or name contains '.aac' or name contains '.lrc')"
        
        var components = URLComponents(string: AppConstants.GoogleDrive.driveFilesEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fields", value: "files(id, name, mimeType, size, parents)"),
            URLQueryItem(name: "orderBy", value: "folder,name"),
            URLQueryItem(name: "pageSize", value: "100")
        ]
        
        guard let url = components.url else {
            throw NSError(domain: "GoogleDriveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Failed to fetch Drive items"
            throw NSError(domain: "GoogleDriveService", code: -2, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let filesArray = json["files"] as? [[String: Any]] else {
            return []
        }
        
        return filesArray.compactMap { dict -> CloudItem? in
            guard let id = dict["id"] as? String,
                  let name = dict["name"] as? String,
                  let mimeType = dict["mimeType"] as? String else {
                return nil
            }
            
            let isFolder = mimeType == "application/vnd.google-apps.folder"
            let size = Int64(dict["size"] as? String ?? "0") ?? 0
            let parentId = (dict["parents"] as? [String])?.first
            
            // Check if already downloaded locally
            let localMusicDir = LocalFileManager.shared.musicDirectory
            let localFileURL = localMusicDir.appendingPathComponent(name)
            let isDownloaded = FileManager.default.fileExists(atPath: localFileURL.path)
            
            return CloudItem(
                id: id,
                name: name,
                mimeType: mimeType,
                size: size,
                isFolder: isFolder,
                parentId: parentId,
                isDownloaded: isDownloaded,
                downloadProgress: isDownloaded ? 1.0 : 0.0
            )
        }
    }
}
