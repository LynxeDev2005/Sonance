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
    @Namespace private var tabSelectionNamespace
    @ObservedObject var playerVM = PlayerViewModel.shared
    @ObservedObject var audioService = AudioPlayerService.shared
    
    public init() {}
    
    public var body: some View {
        ZStack {
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
        }
        // The system reserves this area on every device/orientation, so scrollable
        // content is never hidden below the player or Home indicator.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                // Mini Player (Only visible when track is loaded)
                if audioService.currentSong != nil {
                    MiniPlayerView()
                        .frame(maxWidth: 680)
                }
                
                CrystalPillTabBar(selection: $selectedTab, selectionNamespace: tabSelectionNamespace)
                .padding(.horizontal, 24)
                .padding(.bottom, 6)
                .frame(maxWidth: 680)
            }
            .padding(.top, 8)
        }
        .fullScreenCover(isPresented: $playerVM.showFullPlayer) {
            FullPlayerView()
        }
    }
}

/// A clear glass navigation capsule with one shared indicator that glides between tabs.
private struct CrystalPillTabBar: View {
    @Binding var selection: TabSelection
    var selectionNamespace: Namespace.ID

    var body: some View {
        HStack(spacing: 4) {
            ForEach(TabSelection.allCases, id: \.self) { tab in
                let isSelected = selection == tab
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.76)) {
                        selection = tab
                    }
                } label: {
                    ZStack {
                        if isSelected {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.35, green: 0.82, blue: 1).opacity(0.46),
                                            Color(red: 0.58, green: 0.42, blue: 0.96).opacity(0.34)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.36), lineWidth: 0.8))
                                .matchedGeometryEffect(id: "active-tab", in: selectionNamespace)
                        }

                        VStack(spacing: 3) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 17, weight: isSelected ? .bold : .medium))
                            Text(tab.title)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                .lineLimit(1)
                        }
                        .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.5))
                        .shadow(color: isSelected ? Color.cyan.opacity(0.42) : .clear, radius: 7)
                    }
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(6)
        .crystalGlass(cornerRadius: 30, specularIntensity: 1, elevation: 16)
    }
}
