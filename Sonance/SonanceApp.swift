import SwiftUI
import AVFoundation

@main
struct SonanceApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Bootstrap Background Audio Session
        AudioSessionManager.shared.configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .task {
                    // Initial scan of local Music folder
                    await LocalFileManager.shared.scanMusicDirectory()
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                Task {
                    await LocalFileManager.shared.scanMusicDirectory()
                }
            case .background:
                // App entered background; audio playback continues smoothly
                break
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        if url.isFileURL {
            // Audio file or folder opened from Files / AirDrop / Sideloading
            Task {
                _ = await LocalFileManager.shared.importFiles(from: [url])
            }
        }
    }
}
