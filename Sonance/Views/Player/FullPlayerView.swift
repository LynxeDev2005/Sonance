import SwiftUI
import AVKit

/// Full-screen Liquid Crystal Player with dynamic backdrop, synced lyrics, and tactile controls
public struct FullPlayerView: View {
    @ObservedObject var playerVM = PlayerViewModel.shared
    @ObservedObject var audioService = AudioPlayerService.shared
    @ObservedObject var sleepTimer = SleepTimerService.shared
    
    @State private var showLyricsMode = false
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        ZStack {
            if let song = audioService.currentSong {
                // 1. Dynamic Fluid Ambient Backdrop
                FluidMeshBackground(song: song)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 2. Top Header Bar
                    HStack {
                        Button {
                            playerVM.showFullPlayer = false
                        } label: {
                            Image(systemName: "chevron.compact.down")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.8))
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text("PLAYING FROM")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.4))
                                .tracking(1.5)
                            Text(song.album)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Menu {
                            Button {
                                playerVM.showEqualizerSheet = true
                            } label: {
                                Label("Equalizer", systemImage: "slider.vertical.3")
                            }
                            
                            Button {
                                playerVM.showSleepTimerSheet = true
                            } label: {
                                Label("Sleep Timer", systemImage: "moon.stars")
                            }
                            
                            ShareLink(item: song.fileURL) {
                                Label("Share Audio File", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.white.opacity(0.8))
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    Spacer(minLength: 16)
                    
                    // 3. Middle Area: Large Artwork or Synced Lyrics
                    if showLyricsMode {
                        LyricsView(
                            song: song,
                            currentTime: audioService.currentTime,
                            activeIndex: playerVM.activeLyricIndex,
                            onSeekToLine: { time in
                                playerVM.seek(to: time)
                            }
                        )
                        .frame(maxHeight: 380)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        ArtworkImageView(artworkURL: song.artworkURL, cornerRadius: 28, showBloom: true)
                            .padding(.horizontal, 36)
                            .frame(maxWidth: 340, maxHeight: 340)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    Spacer(minLength: 24)
                    
                    // 4. Track Info & Favorite Heart
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(song.title)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color.white)
                                .lineLimit(1)
                            
                            Text(song.artist)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.65))
                                .lineLimit(1)
                            
                            // Audio Quality Badge
                            Text(song.audioQualityBadge)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.12)))
                                .padding(.top, 4)
                        }
                        
                        Spacer()
                        
                        Button {
                            playerVM.toggleFavorite(for: song)
                        } label: {
                            Image(systemName: song.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(song.isFavorite ? Color(red: 1.0, green: 0.25, blue: 0.45) : Color.white.opacity(0.45))
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 28)
                    
                    // 5. Liquid Waveform Progress Scrubber
                    CrystalWaveformScrubber(
                        currentTime: audioService.currentTime,
                        duration: audioService.duration,
                        onSeek: { targetTime in
                            playerVM.seek(to: targetTime)
                        }
                    )
                    .padding(.horizontal, 28)
                    .padding(.top, 18)
                    
                    // 6. Reflective Tactile Playback Controls
                    ReflectiveControls(
                        isPlaying: audioService.isPlaying,
                        isShuffleEnabled: audioService.isShuffleEnabled,
                        repeatMode: audioService.repeatMode,
                        onPlayPause: { playerVM.togglePlayPause() },
                        onNext: { playerVM.next() },
                        onPrevious: { playerVM.previous() },
                        onToggleShuffle: { playerVM.toggleShuffle() },
                        onCycleRepeat: { playerVM.cycleRepeatMode() }
                    )
                    .padding(.top, 12)
                    
                    Spacer(minLength: 16)
                    
                    // 7. Bottom Crystal Utility Bar
                    HStack(spacing: 32) {
                        // Lyrics Toggle
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                showLyricsMode.toggle()
                            }
                        } label: {
                            Image(systemName: "quote.bubble")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(showLyricsMode ? Color(red: 0.4, green: 0.8, blue: 1.0) : Color.white.opacity(0.5))
                                .frame(width: 44, height: 44)
                        }
                        
                        // Equalizer
                        Button {
                            playerVM.showEqualizerSheet = true
                        } label: {
                            Image(systemName: "slider.vertical.3")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.5))
                                .frame(width: 44, height: 44)
                        }
                        
                        // Sleep Timer Indicator
                        if sleepTimer.isActive {
                            Button {
                                playerVM.showSleepTimerSheet = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "moon.fill")
                                        .font(.system(size: 12))
                                    Text(sleepTimer.formattedRemainingTime)
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                }
                                .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.15)))
                            }
                        }
                        
                        // Up Next Queue
                        Button {
                            playerVM.showQueueSheet = true
                        } label: {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.5))
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.bottom, 24)
                }
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .sheet(isPresented: $playerVM.showQueueSheet) {
            QueueView()
        }
        .sheet(isPresented: $playerVM.showEqualizerSheet) {
            EqualizerView()
        }
        .sheet(isPresented: $playerVM.showSleepTimerSheet) {
            SleepTimerSheet()
        }
    }
}

/// Sheet for selecting sleep timer intervals
public struct SleepTimerSheet: View {
    @ObservedObject var sleepTimer = SleepTimerService.shared
    @Environment(\.dismiss) private var dismiss
    
    let intervals = [5, 10, 15, 30, 45, 60]
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Sleep Timer")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.top, 24)
                    
                    if sleepTimer.isActive {
                        VStack(spacing: 8) {
                            Text("Timer Active")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                            Text(sleepTimer.formattedRemainingTime)
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.white)
                            
                            Button("Turn Off Timer") {
                                sleepTimer.cancel()
                            }
                            .foregroundStyle(Color(red: 1.0, green: 0.35, blue: 0.45))
                            .padding(.top, 4)
                        }
                        .padding()
                        .crystalGlass(cornerRadius: 16)
                        .padding(.horizontal, 24)
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(intervals, id: \.self) { mins in
                            Button {
                                sleepTimer.start(minutes: mins)
                                dismiss()
                            } label: {
                                HStack {
                                    Text("\(mins) Minutes")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Color.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.white.opacity(0.3))
                                }
                                .padding()
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        Button {
                            sleepTimer.enableStopAfterCurrentTrack()
                            dismiss()
                        } label: {
                            HStack {
                                Text("End of Current Track")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Color.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.white.opacity(0.3))
                            }
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}
