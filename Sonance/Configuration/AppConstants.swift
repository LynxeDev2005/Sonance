import Foundation

/// Core application constants and default configurations for Sonance
public enum AppConstants {
    public static let appName = "Sonance"
    public static let appVersion = "1.0.0"
    public static let appBundleId = "com.sonance.player"
    public static let appGroupIdentifier = "group.com.sonance.player"
    
    public enum Directories {
        public static let musicFolder = "Music"
        public static let cacheFolder = "Cache"
        public static let artworkFolder = "Artwork"
        public static let lyricsFolder = "Lyrics"
        public static let databaseFile = "sonance_db.json"
    }
    
    public enum SupportedFormats {
        public static let audioExtensions: Set<String> = [
            "mp3", "m4a", "flac", "wav", "aac", "alac", "aiff", "caf", "ogg", "opus"
        ]
        public static let lyricsExtensions: Set<String> = ["lrc", "txt"]
    }
    
    public enum GoogleDrive {
        // Standard OAuth2 configuration for iOS Desktop/Mobile Client
        // Replace with your Google Cloud Console Client ID & Redirect URI
        public static let clientId = "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
        public static let redirectUri = "com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID:/oauth2redirect"
        public static let authEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
        public static let tokenEndpoint = "https://oauth2.googleapis.com/token"
        public static let driveFilesEndpoint = "https://www.googleapis.com/drive/v3/files"
        public static let scopes = [
            "https://www.googleapis.com/auth/drive.readonly",
            "https://www.googleapis.com/auth/drive.file"
        ]
    }
    
    public enum NetworkServer {
        public static let defaultPort: UInt16 = 8080
    }
}
