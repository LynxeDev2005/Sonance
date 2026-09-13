import SwiftUI

/// Active background download monitor sheet
public struct DownloadQueueSheet: View {
    @ObservedObject var downloadManager = CloudDownloadManager.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Active Downloads")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.white)
                        
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
                    .padding(.top, 20)
                    
                    if downloadManager.activeDownloads.isEmpty && downloadManager.downloadQueue.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 48, weight: .light))
                                .foregroundStyle(Color.white.opacity(0.3))
                                .padding(.top, 60)
                            Text("No Active Downloads")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(Array(downloadManager.activeDownloads.keys), id: \.self) { fileId in
                                    let progress = downloadManager.activeDownloads[fileId] ?? 0
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Image(systemName: "arrow.down.circle.fill")
                                                .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                                            Text("Downloading...")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(Color.white)
                                            Spacer()
                                            Text(String(format: "%.0f%%", progress * 100))
                                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                                        }
                                        
                                        ProgressView(value: progress)
                                            .tint(Color(red: 0.4, green: 0.8, blue: 1.0))
                                    }
                                    .padding()
                                    .crystalGlass(cornerRadius: 14)
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}
