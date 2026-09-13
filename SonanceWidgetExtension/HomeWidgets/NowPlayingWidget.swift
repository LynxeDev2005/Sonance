import WidgetKit
import SwiftUI

/// Timeline provider for Sonance Home Screen Widget
public struct SonanceWidgetTimelineProvider: TimelineProvider {
    public struct Entry: TimelineEntry {
        public let date: Date
        public let songTitle: String
        public let artistName: String
        public let albumName: String
        public let isPlaying: Bool
    }
    
    public func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), songTitle: "Crystal Waves", artistName: "Sonance", albumName: "Offline Master", isPlaying: true)
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let entry = Entry(date: Date(), songTitle: "Crystal Waves", artistName: "Sonance", albumName: "Offline Master", isPlaying: true)
        completion(entry)
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entry = Entry(date: Date(), songTitle: "Offline Track", artistName: "Sonance Player", albumName: "Local Library", isPlaying: false)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

/// Interactive Home Screen Widget for Sonance
public struct NowPlayingWidget: Widget {
    let kind: String = "SonanceNowPlayingWidget"
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SonanceWidgetTimelineProvider()) { entry in
            ZStack {
                Color(red: 0.06, green: 0.08, blue: 0.14)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "waveform.circle.fill")
                            .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                        Text("Sonance")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.7))
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Text(entry.songTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                    
                    Text(entry.artistName)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .lineLimit(1)
                }
                .padding()
            }
        }
        .configurationDisplayName("Now Playing")
        .description("Quick access to current playing track in Sonance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
