import Foundation
import ActivityKit
import UIKit

/// Manages starting, updating, and ending Live Activities on Lock Screen and Dynamic Island
public final class LiveActivityManager {
    public static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<SonanceActivityAttributes>?
    
    private init() {}
    
    /// Starts or updates the Live Activity for the given song
    public func startOrUpdateLiveActivity(
        song: Song,
        currentTime: TimeInterval,
        isPlaying: Bool
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }
        
        // Load artwork thumbnail data if available
        var artworkData: Data? = nil
        if let artworkURL = song.artworkURL,
           let image = UIImage(contentsOfFile: artworkURL.path) {
            // Compress thumbnail for ActivityKit payload size budget (<4KB)
            artworkData = image.jpegData(compressionQuality: 0.4)
        }
        
        let state = SonanceActivityAttributes.ContentState(
            songTitle: song.title,
            artistName: song.artist,
            albumName: song.album,
            duration: song.duration,
            currentTime: currentTime,
            isPlaying: isPlaying,
            artworkData: artworkData
        )
        
        if let activity = currentActivity {
            Task {
                await activity.update(using: state)
            }
        } else {
            let attributes = SonanceActivityAttributes(trackId: song.id.uuidString)
            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    contentState: state,
                    pushType: nil
                )
                self.currentActivity = activity
            } catch {
                print("[LiveActivityManager] Failed to request Live Activity: \(error)")
            }
        }
    }
    
    /// Ends the current Live Activity when playback stops
    public func endLiveActivity() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(dismissalPolicy: .immediate)
            self.currentActivity = nil
        }
    }
}
