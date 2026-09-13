import SwiftUI
import AVFoundation

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        AudioSessionManager.shared.configureAudioSession()
        return true
    }
}

@main
struct SonanceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
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
