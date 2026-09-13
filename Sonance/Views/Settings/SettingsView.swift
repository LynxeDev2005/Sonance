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
        NavigationStack {
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
                                Button {
                                    settingsVM.clearCache()
                                    showCacheClearedAlert = true
                                } label: {
                                    Text("Clear")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.4))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .crystalGlass(cornerRadius: 10)
                                }
                            }
                        }
                        .padding(20)
                        .crystalGlass(cornerRadius: 22, specularIntensity: 0.6)
                        .padding(.horizontal, 20)
                        
                        // 2. Audio & Playback Features
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Audio Engine & Enhancements")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.5))
                            
                            Button {
                                showEqualizer = true
                            } label: {
                                HStack {
                                    Image(systemName: "slider.vertical.3")
                                        .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                                    Text("10-Band Graphic Equalizer")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.white.opacity(0.3))
                                }
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            Button {
                                showSleepTimer = true
                            } label: {
                                HStack {
                                    Image(systemName: "moon.fill")
                                        .foregroundStyle(Color(red: 0.8, green: 0.6, blue: 1.0))
                                    Text("Sleep Timer")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.white)
                                    Spacer()
                                    Text(settingsVM.sleepTimerStatus)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.white.opacity(0.5))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.white.opacity(0.3))
                                }
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            Toggle(isOn: $settingsVM.isLosslessPreferred) {
                                HStack {
                                    Image(systemName: "waveform")
                                        .foregroundStyle(Color(red: 0.4, green: 0.9, blue: 0.6))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Lossless Engine Processing")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(Color.white)
                                        Text("Direct 32-bit float audio pipeline")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.white.opacity(0.4))
                                    }
                                }
                            }
                            .tint(Color(red: 0.4, green: 0.8, blue: 1.0))
                        }
                        .padding(20)
                        .crystalGlass(cornerRadius: 22, specularIntensity: 0.6)
                        .padding(.horizontal, 20)
                        
                        // 3. Sideloading & Document Permissions
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Sideloading & Permissions")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.5))
                            
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .foregroundStyle(Color.green)
                                Text("Background Audio (AVAudioSession)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.white)
                                Spacer()
                                Text("Active")
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
                        
                        // 4. About Sonance with Logo and App Icon
                        VStack(spacing: 12) {
                            Image("SplashIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 72, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: Color(red: 0.3, green: 0.8, blue: 1.0).opacity(0.35), radius: 16, x: 0, y: 8)
                            
                            Image("SonanceLogoGradient")
                                .resizable()
                                .renderingMode(.original)
                                .scaledToFit()
                                .frame(height: 26)
                            
                            Text("Version \(AppConstants.appVersion) • Crystal Glass Edition")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .crystalGlass(cornerRadius: 24, specularIntensity: 0.5)
                        .padding(.horizontal, 20)
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
