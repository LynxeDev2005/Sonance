import Foundation
import AVFoundation
import UIKit

/// Manages the system AVAudioSession, handling background audio permissions,
/// audio interruptions (e.g. phone calls), and route changes (e.g. AirPods disconnect)
public final class AudioSessionManager {
    public static let shared = AudioSessionManager()
    
    public var onInterruption: ((AVAudioSession.InterruptionType, AVAudioSession.InterruptionOptions) -> Void)?
    public var onRouteChangedToSpeaker: (() -> Void)? // Auto-pause trigger when headphones disconnected
    
    private init() {
        setupNotifications()
    }
    
    /// Configures and activates the background playback audio session
    public func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, policy: .longFormAudio, options: [])
            try session.setActive(true)
            
            // Required for SwiftUI apps to keep background audio alive!
            DispatchQueue.main.async {
                UIApplication.shared.beginReceivingRemoteControlEvents()
            }
        } catch {
            print("[AudioSessionManager] Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        var options: AVAudioSession.InterruptionOptions = []
        if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
            options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
        }
        
        onInterruption?(type, options)
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Headphones or Bluetooth device was disconnected -> Auto pause
            if let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                let hasHeadphones = previousRoute.outputs.contains { output in
                    output.portType == .headphones ||
                    output.portType == .bluetoothA2DP ||
                    output.portType == .bluetoothHFP ||
                    output.portType == .bluetoothLE
                }
                if hasHeadphones {
                    onRouteChangedToSpeaker?()
                }
            }
        default:
            break
        }
    }
}
