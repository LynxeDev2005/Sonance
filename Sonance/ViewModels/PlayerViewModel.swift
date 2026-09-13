import Foundation
import SwiftUI
import Combine

/// Main ViewModel binding UI player views with AudioPlayerService, LiveActivity, and Database
public final class PlayerViewModel: ObservableObject {
    public static let shared = PlayerViewModel()
    
    @ObservedObject public var audioService = AudioPlayerService.shared
    @ObservedObject public var databaseService = DatabaseService.shared
    @ObservedObject public var sleepTimer = SleepTimerService.shared
    
    @Published public var showFullPlayer: Bool = false
    @Published public var showLyricsSheet: Bool = false
    @Published public var showQueueSheet: Bool = false
    @Published public var showEqualizerSheet: Bool = false
    @Published public var showSleepTimerSheet: Bool = false
    
    @Published public var activeLyricIndex: Int?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Sync active lyric line when playback time changes
        audioService.$currentTime
            .combineLatest(audioService.$currentSong)
            .sink { [weak self] currentTime, song in
                guard let self = self, let lyrics = song?.lyrics else {
                    self?.activeLyricIndex = nil
                    return
                }
                self.activeLyricIndex = LyricsParser.shared.findActiveLineIndex(at: currentTime, in: lyrics)
            }
            .store(in: &cancellables)
        
        // Update Live Activity on playback state changes
        audioService.$currentSong
            .combineLatest(audioService.$isPlaying)
            .sink { [weak self] song, isPlaying in
                guard let self = self else { return }
                if let song = song {
                    LiveActivityManager.shared.startOrUpdateLiveActivity(
                        song: song,
                        currentTime: self.audioService.currentTime,
                        isPlaying: isPlaying
                    )
                    self.databaseService.recordPlay(for: song)
                } else {
                    LiveActivityManager.shared.endLiveActivity()
                }
            }
            .store(in: &cancellables)
    }
    
    public func togglePlayPause() {
        audioService.togglePlayPause()
    }
    
    public func next() {
        audioService.next()
    }
    
    public func previous() {
        audioService.previous()
    }
    
    public func seek(to time: TimeInterval) {
        audioService.seek(to: time)
    }
    
    public func toggleShuffle() {
        audioService.toggleShuffle()
    }
    
    public func cycleRepeatMode() {
        audioService.cycleRepeatMode()
    }
    
    public func toggleFavorite(for song: Song) {
        databaseService.toggleFavorite(for: song)
        if audioService.currentSong?.id == song.id {
            audioService.currentSong?.isFavorite.toggle()
        }
    }
    
    public func play(song: Song) {
        audioService.play(song: song)
    }
    
    public func play(songs: [Song], startingAt index: Int = 0) {
        audioService.play(songs: songs, startingAt: index)
    }
}
