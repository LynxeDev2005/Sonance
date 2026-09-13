import SwiftUI

/// Application settings, diagnostics, storage management, and sideloading details
public struct SettingsView: View {
    @ObservedObject var settingsVM = SettingsViewModel.shared
    @ObservedObject var playerVM = PlayerViewModel.shared
    
    @State private var showEqualizer = false
    @State private var showSleepTimer = false
    @State private var showCacheClearedAlert = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title
                        HStack {
                            Text("Settings")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color.white)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // 1. Storage & Offline Music Diagnostics
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Storage & Library")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.5))
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Music Storage")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.white)
                                    Text("\(settingsVM.totalTrackCount) offline tracks")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.white.opacity(0.5))
                                }
                                Spacer()
                                Text(settingsVM.totalMusicSize)
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Artwork & Temp Cache")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.white)
                                    Text(settingsVM.cacheSize)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.white.opacity(0.5))
                                }
                                Spacer()
                                Button("Clear Cache") {
                                    settingsVM.clearArtworkCache()
                                    showCacheClearedAlert = true
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(red: 1.0, green: 0.35, blue: 0.45))
                            }
                        }
                        .padding(20)
                        .crystalGlass(cornerRadius: 22, specularIntensity: 0.6)
                        .padding(.horizontal, 20)
                        
                        // 2. Audio Engine Features
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Audio Processing")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.5))
                            
                            Button {
                                showEqualizer = true
                            } label: {
                                HStack {
                                    Image(systemName: "slider.vertical.3")
                                        .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                                    Text("Parametric Equalizer")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.white)
                                    Spacer()
                                    Text(settingsVM.equalizer.isEnabled ? settingsVM.equalizer.selectedPreset.name : "Off")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.white.opacity(0.5))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.white.opacity(0.3))
                                }
                                .padding(.vertical, 4)
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            Button {
                                showSleepTimer = true
                            } label: {
                                HStack {
                                    Image(systemName: "moon.stars")
                                        .foregroundStyle(Color(red: 0.7, green: 0.4, blue: 0.95))
                                    Text("Sleep Timer")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.white)
                                    Spacer()
                                    Text(settingsVM.sleepTimer.isActive ? settingsVM.sleepTimer.formattedRemainingTime : "Off")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.white.opacity(0.5))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.white.opacity(0.3))
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(20)
                        .crystalGlass(cornerRadius: 22, specularIntensity: 0.6)
                        .padding(.horizontal, 20)
                        
                        // 3. Sideloading & Device Info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sideloading & System Status")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.5))
                            
                            HStack {
                                Image(systemName: "iphone")
                                    .foregroundStyle(Color.green)
                                Text("Target Device")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.white)
                                Spacer()
                                Text("iPhone 12 Pro Max")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.white.opacity(0.6))
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundStyle(Color.green)
                                Text("Developer Sideload Mode")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.white)
                                Spacer()
                                Text("Active")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.green)
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundStyle(Color.green)
                                Text("Background Audio Engine")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.white)
                                Spacer()
                                Text("Enabled")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.green)
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Image(systemName: "folder.fill.badge.person.crop")
                                    .foregroundStyle(Color.green)
                                Text("Files App Document Sharing")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.white)
                                Spacer()
                                Text("Enabled")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.green)
                            }
                        }
                        .padding(20)
                        .crystalGlass(cornerRadius: 22, specularIntensity: 0.6)
                        .padding(.horizontal, 20)
                        
                        // 4. About Sonance
                        VStack(spacing: 6) {
                            Text("Sonance Player")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.white)
                            Text("Version \(AppConstants.appVersion) • Crystal Glass Edition")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.white.opacity(0.4))
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 120)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showEqualizer) {
            EqualizerView()
        }
        .sheet(isPresented: $showSleepTimer) {
            SleepTimerSheet()
        }
        .alert("Cache Cleared", isPresented: $showCacheClearedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Artwork and temporary cache have been successfully cleared.")
        }
    }
}
