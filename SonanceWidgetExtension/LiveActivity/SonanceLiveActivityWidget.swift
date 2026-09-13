import ActivityKit
import WidgetKit
import SwiftUI

/// Dynamic Island and Lock Screen Live Activity Widget for Sonance
public struct SonanceLiveActivityWidget: Widget {
    public init() {}
    
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: SonanceActivityAttributes.self) { context in
            // MARK: - Lock Screen Banner (For iPhone 12 Pro Max & All iOS Lock Screens)
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            // MARK: - Dynamic Island (For Dynamic Island equipped devices)
            DynamicIsland {
                // Expanded Leading
                DynamicIslandExpandedRegion(.leading) {
                    if let data = context.state.artworkData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                
                // Expanded Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.isPlaying ? "PLAYING" : "PAUSED")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(context.state.isPlaying ? Color(red: 0.4, green: 0.8, blue: 1.0) : Color.white.opacity(0.4))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.white.opacity(0.1)))
                    }
                }
                
                // Expanded Center
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.songTitle)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                        Text(context.state.artistName)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                
                // Expanded Bottom: Scrubber & Controls
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Progress Line
                        let progress = context.state.duration > 0 ? min(context.state.currentTime / context.state.duration, 1.0) : 0.0
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 4)
                                Capsule()
                                    .fill(Color(red: 0.4, green: 0.8, blue: 1.0))
                                    .frame(width: geo.size.width * CGFloat(progress), height: 4)
                            }
                        }
                        .frame(height: 4)
                        
                        HStack {
                            Text(formatTime(context.state.currentTime))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.5))
                            Spacer()
                            Text(formatTime(context.state.duration))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // Compact Leading: Mini Artwork
                if let data = context.state.artworkData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                }
            } compactTrailing: {
                // Compact Trailing: Playback glyph
                Image(systemName: context.state.isPlaying ? "waveform" : "pause.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
            } minimal: {
                // Minimal: Glowing Note
                Image(systemName: "music.note")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
            }
        }
    }
}

/// Lock Screen Banner View (Presented on iPhone 12 Pro Max notch screen)
private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<SonanceActivityAttributes>
    
    var body: some View {
        HStack(spacing: 14) {
            // Artwork
            if let data = context.state.artworkData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 52, height: 52)
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                }
            }
            
            // Info & Scrubber
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.songTitle)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                
                Text(context.state.artistName)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .lineLimit(1)
                
                // Progress
                let progress = context.state.duration > 0 ? min(context.state.currentTime / context.state.duration, 1.0) : 0.0
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 3)
                        Capsule()
                            .fill(Color(red: 0.4, green: 0.8, blue: 1.0))
                            .frame(width: geo.size.width * CGFloat(progress), height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.top, 2)
            }
            
            Spacer()
            
            // Status Icon
            Image(systemName: context.state.isPlaying ? "waveform" : "pause.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
        }
        .padding(16)
        .background(Color(red: 0.08, green: 0.10, blue: 0.16).opacity(0.95))
    }
}

private func formatTime(_ time: TimeInterval) -> String {
    guard !time.isNaN && !time.isInfinite && time >= 0 else { return "00:00" }
    let total = Int(time.rounded())
    let mins = total / 60
    let secs = total % 60
    return String(format: "%02d:%02d", mins, secs)
}
