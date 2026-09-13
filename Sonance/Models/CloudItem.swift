import Foundation

/// Represents a remote item from Google Drive or Cloud Provider
public struct CloudItem: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let mimeType: String
    public let size: Int64
    public let isFolder: Bool
    public let parentId: String?
    public var isDownloaded: Bool
    public var downloadProgress: Double // 0.0 to 1.0
    
    public init(
        id: String,
        name: String,
        mimeType: String,
        size: Int64 = 0,
        isFolder: Bool = false,
        parentId: String? = nil,
        isDownloaded: Bool = false,
        downloadProgress: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.mimeType = mimeType
        self.size = size
        self.isFolder = isFolder
        self.parentId = parentId
        self.isDownloaded = isDownloaded
        self.downloadProgress = downloadProgress
    }
    
    public var isAudioFile: Bool {
        if isFolder { return false }
        let ext = (name as NSString).pathExtension.lowercased()
        return AppConstants.SupportedFormats.audioExtensions.contains(ext) || mimeType.starts(with: "audio/")
    }
    
    public var formattedSize: String {
        guard !isFolder else { return "" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
