import Foundation
import AVFoundation
import MediaPlayer
import Combine

/// Main playback engine powering Sonance offline audio playback
public final class AudioPlayerService: ObservableObject {
    public static let shared = AudioPlayerService()
    
    // Published State for SwiftUI Bindings
    @Published public var currentSong: Song?
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: TimeInterval = 0
    @Published public var duration: TimeInterval = 0
    @Published public var repeatMode: RepeatMode = .off
    @Published public var isShuffleEnabled: Bool = false
    @Published public var playbackSpeed: PlaybackSpeed = .normal
    @Published public var queue: [Song] = []
    @Published public var originalQueue: [Song] = []
    @Published public var currentIndex: Int = 0
    @Published public var volume: Float = 1.0
    
    // Low-level AVFoundation Player
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var cancellables = Set<AnyCancellable>()
    private var isSeeking: Bool = false
    
    private init() {
        setupAudioSession()
        setupNowPlayingCallbacks()
        setupSleepTimerCallbacks()
    }
    
    deinit {
        removeTimeObserver()
    }
    
    // MARK: - Queue Management & Playback Controls
    
    /// Loads a list of songs into the queue and starts playing at the specified index
    public func play(songs: [Song], startingAt index: Int = 0) {
        guard !songs.isEmpty, index >= 0 && index < songs.count else { return }
        
        self.originalQueue = songs
        if isShuffleEnabled {
            var shuffled = songs
            let selectedSong = shuffled.remove(at: index)
            shuffled.shuffle()
            shuffled.insert(selectedSong, at: 0)
            self.queue = shuffled
            self.currentIndex = 0
        } else {
            self.queue = songs
            self.currentIndex = index
        }
        
        loadAndPlay(song: queue[currentIndex])
    }
    
    /// Plays a single song immediately
    public func play(song: Song) {
        if let existingIndex = queue.firstIndex(where: { $0.id == song.id }) {
            currentIndex = existingIndex
            loadAndPlay(song: song)
        } else {
            play(songs: [song], startingAt: 0)
        }
    }
    
    /// Adds a song to play right after the current song
    public func playNext(song: Song) {
        guard !queue.isEmpty else {
            play(song: song)
            return
        }
        let insertIndex = min(currentIndex + 1, queue.count)
        queue.insert(song, at: insertIndex)
        originalQueue.append(song)
    }
    
    /// Appends a song to the end of the current queue
    public func appendToQueue(song: Song) {
        guard !queue.isEmpty else {
            play(song: song)
            return
        }
        queue.append(song)
        originalQueue.append(song)
    }
    
    /// Appends multiple songs to the queue
    public func appendToQueue(songs: [Song]) {
        guard !queue.isEmpty else {
            play(songs: songs, startingAt: 0)
            return
        }
        queue.append(contentsOf: songs)
        originalQueue.append(contentsOf: songs)
    }
    
    /// Toggles play / pause state
    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }
    
    /// Resumes audio playback
    public func resume() {
        guard let player = player else {
            if let song = currentSong {
                loadAndPlay(song: song)
            } else if !queue.isEmpty {
                loadAndPlay(song: queue[currentIndex])
            }
            return
        }
        AudioSessionManager.shared.configureAudioSession()
        player.play()
        player.rate = Float(playbackSpeed.rawValue)
        isPlaying = true
        updateNowPlayingInfo()
    }
    
    /// Pauses audio playback
    public func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }
    
    /// Skips to the next track in the queue
    public func next() {
        guard !queue.isEmpty else { return }
        
        if repeatMode == .one {
            seek(to: 0)
            resume()
            return
        }
        
        let nextIndex = currentIndex + 1
        if nextIndex < queue.count {
            currentIndex = nextIndex
            loadAndPlay(song: queue[currentIndex])
        } else if repeatMode == .all {
            currentIndex = 0
            loadAndPlay(song: queue[currentIndex])
        } else {
            // Reached end of queue without repeat all
            pause()
            seek(to: 0)
        }
    }
    
    /// Goes to the previous track (or restarts current track if elapsed > 3s)
    public func previous() {
        guard !queue.isEmpty else { return }
        
        if currentTime > 3.0 {
            seek(to: 0)
            return
        }
        
        let prevIndex = currentIndex - 1
        if prevIndex >= 0 {
            currentIndex = prevIndex
            loadAndPlay(song: queue[currentIndex])
        } else if repeatMode == .all {
            currentIndex = queue.count - 1
            loadAndPlay(song: queue[currentIndex])
        } else {
            seek(to: 0)
        }
    }
    
    /// Seeks to a specific timestamp in seconds
    public func seek(to time: TimeInterval) {
        let clampedTime = max(0, min(time, duration))
        currentTime = clampedTime
        let targetTime = CMTime(seconds: clampedTime, preferredTimescale: 1000)
        player?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self = self else { return }
            self.updateNowPlayingInfo()
        }
    }
    
    /// Toggles shuffle mode
    public func toggleShuffle() {
        isShuffleEnabled.toggle()
        guard let current = currentSong else { return }
        
        if isShuffleEnabled {
            var shuffled = originalQueue
            shuffled.removeAll(where: { $0.id == current.id })
            shuffled.shuffle()
            shuffled.insert(current, at: 0)
            self.queue = shuffled
            self.currentIndex = 0
        } else {
            self.queue = originalQueue
            self.currentIndex = originalQueue.firstIndex(where: { $0.id == current.id }) ?? 0
        }
    }
    
    /// Cycles through repeat modes: off -> all -> one -> off
    public func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }
    
    /// Sets playback rate speed
    public func setSpeed(_ speed: PlaybackSpeed) {
        playbackSpeed = speed
        if isPlaying {
            player?.rate = Float(speed.rawValue)
        }
    }
    
    /// Reorders the upcoming queue
    public func moveQueueItem(fromOffsets source: IndexSet, toOffset destination: Int) {
        queue.move(fromOffsets: source, toOffset: destination)
        if let current = currentSong {
            currentIndex = queue.firstIndex(where: { $0.id == current.id }) ?? 0
        }
    }
    
    /// Removes a track from the queue
    public func removeQueueItem(at index: Int) {
        guard index >= 0 && index < queue.count else { return }
        let removedSong = queue.remove(at: index)
        originalQueue.removeAll(where: { $0.id == removedSong.id })
        
        if index == currentIndex {
            if currentIndex < queue.count {
                loadAndPlay(song: queue[currentIndex])
            } else if !queue.isEmpty {
                currentIndex = 0
                loadAndPlay(song: queue[currentIndex])
            } else {
                currentSong = nil
                player?.pause()
                player = nil
            }
        } else if index < currentIndex {
            currentIndex -= 1
        }
    }
    
    // MARK: - Internal Player Mechanics
    
    private func loadAndPlay(song: Song) {
        AudioSessionManager.shared.configureAudioSession()
        removeTimeObserver()
        
        let fileURL = song.fileURL
        let playerItem = AVPlayerItem(url: fileURL)
        
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        
        currentSong = song
        currentTime = 0
        duration = song.duration > 0 ? song.duration : 0
        
        // Observe item completion
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        setupTimeObserver()
        player?.play()
        player?.rate = Float(playbackSpeed.rawValue)
        isPlaying = true
        
        updateNowPlayingInfo()
    }
    
    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let seconds = CMTimeGetSeconds(time)
            if !seconds.isNaN && !seconds.isInfinite {
                self.currentTime = seconds
            }
            
            // Check dynamic duration if unknown
            if let currentItem = self.player?.currentItem {
                let dur = CMTimeGetSeconds(currentItem.duration)
                if !dur.isNaN && !dur.isInfinite && dur > 0 {
                    self.duration = dur
                }
            }
        }
    }
    
    private func removeTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
    @objc private func playerItemDidFinishPlaying() {
        if SleepTimerService.shared.stopAfterCurrentTrack {
            SleepTimerService.shared.cancel()
            pause()
            return
        }
        next()
    }
    
    private func updateNowPlayingInfo() {
        NowPlayingManager.shared.updateNowPlaying(
            song: currentSong,
            currentTime: currentTime,
            duration: duration,
            isPlaying: isPlaying
        )
    }
    
    // MARK: - Setup External Integrations
    
    private func setupAudioSession() {
        let sessionMgr = AudioSessionManager.shared
        sessionMgr.onInterruption = { [weak self] type, options in
            guard let self = self else { return }
            switch type {
            case .began:
                self.pause()
            case .ended:
                if options.contains(.shouldResume) {
                    self.resume()
                }
            @unknown default:
                break
            }
        }
        
        sessionMgr.onRouteChangedToSpeaker = { [weak self] in
            self?.pause()
        }
    }
    
    private func setupNowPlayingCallbacks() {
        let nowPlaying = NowPlayingManager.shared
        nowPlaying.onPlay = { [weak self] in self?.resume() }
        nowPlaying.onPause = { [weak self] in self?.pause() }
        nowPlaying.onTogglePlayPause = { [weak self] in self?.togglePlayPause() }
        nowPlaying.onNextTrack = { [weak self] in self?.next() }
        nowPlaying.onPreviousTrack = { [weak self] in self?.previous() }
        nowPlaying.onSeekTo = { [weak self] position in self?.seek(to: position) }
        nowPlaying.onSkipForward = { [weak self] interval in
            guard let self = self else { return }
            self.seek(to: self.currentTime + interval)
        }
        nowPlaying.onSkipBackward = { [weak self] interval in
            guard let self = self else { return }
            self.seek(to: self.currentTime - interval)
        }
    }
    
    private func setupSleepTimerCallbacks() {
        let sleepTimer = SleepTimerService.shared
        sleepTimer.onTimerFired = { [weak self] in
            self?.pause()
        }
        sleepTimer.onVolumeFade = { [weak self] multiplier in
            self?.player?.volume = multiplier
        }
    }
}
