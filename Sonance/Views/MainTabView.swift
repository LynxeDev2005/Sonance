import SwiftUI

public enum TabSelection: Int, CaseIterable {
    case library = 0
    case folders = 1
    case cloud = 2
    case settings = 3
    
    public var title: String {
        switch self {
        case .library: return "Library"
        case .folders: return "Folders"
        case .cloud: return "Cloud"
        case .settings: return "Settings"
        }
    }
    
    public var icon: String {
        switch self {
        case .library: return "music.note.list"
        case .folders: return "folder.fill"
        case .cloud: return "cloud.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

/// Root application view hosting navigation tabs, floating crystal MiniPlayer, and full-screen player modal
public struct MainTabView: View {
    @State private var selectedTab: TabSelection = .library
    @ObservedObject var playerVM = PlayerViewModel.shared
    @ObservedObject var audioService = AudioPlayerService.shared
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Views with State Preservation
            ZStack {
                LibraryView()
                    .opacity(selectedTab == .library ? 1 : 0)
                    .allowsHitTesting(selectedTab == .library)
                
                FolderBrowserView()
                    .opacity(selectedTab == .folders ? 1 : 0)
                    .allowsHitTesting(selectedTab == .folders)
                
                CloudHubView()
                    .opacity(selectedTab == .cloud ? 1 : 0)
                    .allowsHitTesting(selectedTab == .cloud)
                
                SettingsView()
                    .opacity(selectedTab == .settings ? 1 : 0)
                    .allowsHitTesting(selectedTab == .settings)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            
            // Floating Overlay: MiniPlayer + Custom Crystal Glass Tab Bar
            VStack(spacing: 8) {
                // Mini Player (Only visible when track is loaded)
                if audioService.currentSong != nil {
                    MiniPlayerView()
                }
                
                // Custom Crystal Bottom Bar
                HStack {
                    ForEach(TabSelection.allCases, id: \.self) { tab in
                        let isSelected = (selectedTab == tab)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                                
                                Text(tab.title)
                                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            }
                            .foregroundStyle(
                                isSelected ?
                                Color(red: 0.4, green: 0.8, blue: 1.0) :
                                Color.white.opacity(0.45)
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .crystalGlass(cornerRadius: 32, specularIntensity: 0.75, elevation: 12)
                .padding(.horizontal, 24)
                .padding(.bottom, 6)
            }
        }
        .fullScreenCover(isPresented: $playerVM.showFullPlayer) {
            FullPlayerView()
        }
    }
}
