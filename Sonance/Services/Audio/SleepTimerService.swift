import Foundation
import Combine

/// Service handling the sleep timer with smooth audio fade out
public final class SleepTimerService: ObservableObject {
    public static let shared = SleepTimerService()
    
    @Published public var isActive: Bool = false
    @Published public var remainingSeconds: TimeInterval = 0
    @Published public var stopAfterCurrentTrack: Bool = false
    
    public var onTimerFired: (() -> Void)?
    public var onVolumeFade: ((Float) -> Void)? // Fade multiplier from 1.0 down to 0.0
    
    private var timer: AnyCancellable?
    private let fadeDuration: TimeInterval = 15.0
    
    private init() {}
    
    /// Starts timer with duration in minutes
    public func start(minutes: Int) {
        start(seconds: TimeInterval(minutes * 60))
    }
    
    /// Starts timer with duration in seconds
    public func start(seconds: TimeInterval) {
        cancel()
        remainingSeconds = seconds
        isActive = true
        stopAfterCurrentTrack = false
        
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.remainingSeconds > 1 {
                    self.remainingSeconds -= 1
                    
                    // Smooth volume fade-out during final seconds
                    if self.remainingSeconds <= self.fadeDuration {
                        let volumeMultiplier = Float(self.remainingSeconds / self.fadeDuration)
                        self.onVolumeFade?(volumeMultiplier)
                    }
                } else {
                    self.fire()
                }
            }
    }
    
    /// Configures the timer to stop playback after the current song finishes
    public func enableStopAfterCurrentTrack() {
        cancel()
        stopAfterCurrentTrack = true
        isActive = true
        remainingSeconds = 0
    }
    
    /// Cancels active sleep timer
    public func cancel() {
        timer?.cancel()
        timer = nil
        isActive = false
        remainingSeconds = 0
        stopAfterCurrentTrack = false
        onVolumeFade?(1.0) // Restore full volume
    }
    
    private func fire() {
        cancel()
        onTimerFired?()
    }
    
    /// Formatted remaining time e.g. "24:18"
    public var formattedRemainingTime: String {
        guard isActive else { return "--:--" }
        if stopAfterCurrentTrack { return "End of Track" }
        let mins = Int(remainingSeconds) / 60
        let secs = Int(remainingSeconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
