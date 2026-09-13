import SwiftUI

/// Queue management sheet allowing reordering and removing upcoming tracks
public struct QueueView: View {
    @ObservedObject var audioService = AudioPlayerService.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    // Header Status
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Playing Next")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color.white)
                            Text("\(audioService.queue.count) tracks in queue")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Interactive Reorderable List
                    List {
                        ForEach(Array(audioService.queue.enumerated()), id: \.element.id) { index, song in
                            let isCurrent = (index == audioService.currentIndex)
                            
                            HStack(spacing: 12) {
                                if isCurrent {
                                    AnimatedVisualizerView(isPlaying: audioService.isPlaying, barCount: 3)
                                        .frame(width: 20)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                        .foregroundStyle(Color.white.opacity(0.4))
                                        .frame(width: 20)
                                }
                                
                                ArtworkImageView(artworkURL: song.artworkURL, cornerRadius: 8, showBloom: false)
                                    .frame(width: 42, height: 42)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(song.title)
                                        .font(.system(size: 15, weight: isCurrent ? .bold : .medium))
                                        .foregroundStyle(isCurrent ? Color(red: 0.4, green: 0.8, blue: 1.0) : Color.white)
                                        .lineLimit(1)
                                    
                                    Text(song.artist)
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundStyle(Color.white.opacity(0.5))
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Text(song.formattedDuration)
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.4))
                            }
                            .listRowBackground(
                                isCurrent ? Color.white.opacity(0.08) : Color.clear
                            )
                            .listRowSeparatorTint(Color.white.opacity(0.08))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                audioService.play(songs: audioService.queue, startingAt: index)
                            }
                        }
                        .onMove { source, destination in
                            audioService.moveQueueItem(fromOffsets: source, toOffset: destination)
                        }
                        .onDelete { indexSet in
                            for idx in indexSet {
                                audioService.removeQueueItem(at: idx)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationBarHidden(true)
        }
    }
}
