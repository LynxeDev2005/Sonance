import SwiftUI
import UniformTypeIdentifiers

/// Central Cloud and Music Import Hub featuring Google Drive, iCloud Files, and Wi-Fi Transfer
public struct CloudHubView: View {
    @ObservedObject var authManager = GoogleDriveAuthManager.shared
    @ObservedObject var wifiServer = WiFiTransferServer.shared
    @ObservedObject var fileManager = LocalFileManager.shared
    @ObservedObject var downloadManager = CloudDownloadManager.shared
    
    @State private var showFileImporter = false
    @State private var showGoogleDriveBrowser = false
    @State private var showDownloadQueue = false
    @State private var authError: String?
    @State private var isSigningIn = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Import & Cloud")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(Color.white)
                                Text("Add music to your offline library")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.white.opacity(0.5))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // 1. Google Drive Card
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 12) {
                                Image(systemName: "externaldrive.fill.badge.icloud")
                                    .font(.system(size: 28))
                                    .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Google Drive")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Color.white)
                                    Text(authManager.isAuthenticated ? "Connected" : "Download tracks directly from Drive")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.white.opacity(0.5))
                                }
                                
                                Spacer()
                            }
                            
                            if authManager.isAuthenticated {
                                HStack(spacing: 12) {
                                    Button {
                                        showGoogleDriveBrowser = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "folder")
                                            Text("Browse Files")
                                        }
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(red: 0.25, green: 0.55, blue: 0.95))
                                        .cornerRadius(12)
                                    }
                                    
                                    Button {
                                        authManager.signOut()
                                    } label: {
                                        Text("Disconnect")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(Color.white.opacity(0.6))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(Color.white.opacity(0.06))
                                            .cornerRadius(12)
                                    }
                                }
                            } else {
                                Button {
                                    signInToGoogle()
                                } label: {
                                    HStack {
                                        if isSigningIn {
                                            ProgressView().tint(.white).padding(.trailing, 4)
                                        }
                                        Image(systemName: "person.crop.circle.badge.plus")
                                        Text("Connect Google Drive")
                                    }
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.25, green: 0.55, blue: 0.95),
                                                Color(red: 0.15, green: 0.40, blue: 0.85)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(14)
                                }
                                .disabled(isSigningIn)
                            }
                        }
                        .padding(20)
                        .crystalGlass(cornerRadius: 22, specularIntensity: 0.7)
                        .padding(.horizontal, 20)
                        
                        // 2. iOS Files App & iCloud Picker Card
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 12) {
                                Image(systemName: "folder.badge.gearshape")
                                    .font(.system(size: 28))
                                    .foregroundStyle(Color(red: 0.7, green: 0.4, blue: 0.95))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("iOS Files & Folders")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Color.white)
                                    Text("Import from iPhone storage, iCloud, or USB")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.white.opacity(0.5))
                                }
                                
                                Spacer()
                            }
                            
                            Button {
                                showFileImporter = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Select Audio Files or Folders")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .crystalGlass(cornerRadius: 12, specularIntensity: 0.6)
                            }
                        }
                        .padding(20)
                        .crystalGlass(cornerRadius: 22, specularIntensity: 0.6)
                        .padding(.horizontal, 20)
                        
                        // 3. Wi-Fi Local Browser Transfer Card
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 12) {
                                Image(systemName: "wifi.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(Color(red: 0.3, green: 0.85, blue: 0.6))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Wi-Fi Computer Upload")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Color.white)
                                    Text("Upload songs wirelessly from any PC or Mac")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.white.opacity(0.5))
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { wifiServer.isRunning },
                                    set: { if $0 { wifiServer.start() } else { wifiServer.stop() } }
                                ))
                                .labelsHidden()
                                .tint(Color(red: 0.3, green: 0.85, blue: 0.6))
                            }
                            
                            if wifiServer.isRunning {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Open this address in your PC/Mac web browser:")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.white.opacity(0.7))
                                    
                                    HStack {
                                        Text(wifiServer.serverAddress)
                                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                                            .foregroundStyle(Color(red: 0.3, green: 0.85, blue: 0.6))
                                        Spacer()
                                        Button {
                                            UIPasteboard.general.string = wifiServer.serverAddress
                                        } label: {
                                            Image(systemName: "doc.on.doc")
                                                .foregroundStyle(Color.white.opacity(0.6))
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(10)
                                    
                                    if wifiServer.uploadedFileCount > 0 {
                                        Text("✅ \(wifiServer.uploadedFileCount) files received this session")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(Color(red: 0.3, green: 0.85, blue: 0.6))
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(20)
                        .crystalGlass(cornerRadius: 22, specularIntensity: 0.6)
                        .padding(.horizontal, 20)
                        
                        // 4. iTunes & Sideloading Tip Banner
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "cable.connector")
                                    .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                                Text("Direct Cable & Sideloading Drop")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color.white)
                            }
                            Text("You can also plug your iPhone 12 Pro Max into your computer (iTunes/Finder/3uTools) or open the iOS Files app -> On My iPhone -> Sonance -> Music, and drop folders of songs directly!")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.white.opacity(0.6))
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 120)
                }
            }
            .navigationBarHidden(true)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.audio, .folder],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task {
                    _ = await fileManager.importFiles(from: urls)
                }
            case .failure(let error):
                print("[CloudHubView] Import failed: \(error)")
            }
        }
        .sheet(isPresented: $showGoogleDriveBrowser) {
            NavigationStack {
                GoogleDriveBrowserView()
            }
        }
    }
    
    private func signInToGoogle() {
        isSigningIn = true
        authError = nil
        Task {
            do {
                try await authManager.signIn()
                await MainActor.run {
                    self.isSigningIn = false
                    self.showGoogleDriveBrowser = true
                }
            } catch {
                await MainActor.run {
                    self.isSigningIn = false
                    self.authError = error.localizedDescription
                }
            }
        }
    }
}
