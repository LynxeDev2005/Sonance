import SwiftUI

/// Google Drive cloud explorer with folder navigation, audio file filtering, and batch downloading
public struct GoogleDriveBrowserView: View {
    @ObservedObject var cloudVM = CloudDriveViewModel.shared
    @ObservedObject var downloadManager = CloudDownloadManager.shared
    
    @State private var showDownloadQueue = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Breadcrumb Header
                HStack(spacing: 12) {
                    if cloudVM.folderStack.count > 1 {
                        Button {
                            cloudVM.navigateBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                        }
                    }
                    
                    Text(cloudVM.folderStack.last?.name ?? "Google Drive")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Download Queue Badge
                    if !downloadManager.activeDownloads.isEmpty {
                        Button {
                            showDownloadQueue = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("\(downloadManager.activeDownloads.count)")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .crystalGlass(cornerRadius: 12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Content List
                if cloudVM.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(Color(red: 0.4, green: 0.8, blue: 1.0))
                    Text("Fetching cloud files...")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .padding(.top, 8)
                    Spacer()
                } else if let error = cloudVM.errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.orange)
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button("Retry") {
                            Task { await cloudVM.loadCurrentFolder() }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .crystalGlass(cornerRadius: 12)
                    }
                    Spacer()
                } else if cloudVM.items.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.badge.questionmark")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(Color.white.opacity(0.3))
                        Text("No Audio Files Found")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.white)
                        Text("Upload MP3, FLAC, M4A, or WAV files to this Google Drive folder.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(cloudVM.items) { item in
                                if item.isFolder {
                                    // Folder Row
                                    Button {
                                        cloudVM.navigateInto(folder: item)
                                    } label: {
                                        HStack(spacing: 14) {
                                            Image(systemName: "folder.fill")
                                                .font(.system(size: 24))
                                                .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                                            
                                            Text(item.name)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(Color.white)
                                                .lineLimit(1)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 13))
                                                .foregroundStyle(Color.white.opacity(0.3))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color.white.opacity(0.04))
                                        .cornerRadius(14)
                                    }
                                } else {
                                    // Audio File Row
                                    HStack(spacing: 14) {
                                        Image(systemName: "music.note")
                                            .font(.system(size: 20))
                                            .foregroundStyle(Color(red: 0.7, green: 0.4, blue: 0.95))
                                            .frame(width: 32)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundStyle(Color.white)
                                                .lineLimit(1)
                                            
                                            Text(item.formattedSize)
                                                .font(.system(size: 12))
                                                .foregroundStyle(Color.white.opacity(0.5))
                                        }
                                        
                                        Spacer()
                                        
                                        if item.isDownloaded {
                                            HStack(spacing: 4) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(Color.green)
                                                Text("Downloaded")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundStyle(Color.green)
                                            }
                                        } else if let progress = downloadManager.activeDownloads[item.id] {
                                            ProgressView(value: progress)
                                                .frame(width: 40)
                                                .tint(Color(red: 0.4, green: 0.8, blue: 1.0))
                                        } else {
                                            Button {
                                                cloudVM.downloadSingle(item: item)
                                            } label: {
                                                Image(systemName: "arrow.down.circle.fill")
                                                    .font(.system(size: 22))
                                                    .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(14)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 120)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if cloudVM.items.isEmpty {
                await cloudVM.loadCurrentFolder()
            }
        }
        .sheet(isPresented: $showDownloadQueue) {
            DownloadQueueSheet()
        }
    }
}
