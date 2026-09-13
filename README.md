# 🌊 Sonance — Offline iOS Music Player

Sonance is an ultra-modern, offline-first music player built specifically for iOS with **Liquid Crystal Glassmorphism**, background audio playback, folder hierarchy support, Google Drive integration, and Live Activities for Lock Screen and Dynamic Island.

---

## 🌟 Key Features

- **100% Offline Playback**: Zero subscriptions, zero data required once tracks are on your phone.
- **Direct PC & Files App Folder Sync**:
  - `UIFileSharingEnabled` & `LSSupportsOpeningDocumentsInPlace` enabled.
  - Drop MP3, FLAC, M4A, WAV, AAC, and ALAC files directly into the **Sonance** folder via iTunes, Finder, 3uTools, or the iOS **Files** app.
- **Google Drive Integration**:
  - Direct zero-SDK OAuth 2.0 PKCE connection.
  - Browse your cloud folders and batch download songs directly into local storage.
- **Wi-Fi Local Browser Upload**:
  - Built-in embedded web server (`http://[iPhone-IP]:8080`).
  - Open the address on your PC/Mac browser and drag-and-drop songs wirelessly to your iPhone!
- **Dynamic Island & Lock Screen Live Activities (`ActivityKit`)**:
  - Full **Lock Screen Live Activity** with live scrubber and album art for your **iPhone 12 Pro Max**.
  - Dynamic Island compact & expanded layouts on supported devices.
- **Liquid Crystal Glassmorphism UI**:
  - Water-clear translucency, specular light-reflection rim borders, living ambient mesh gradients reacting to album art.
- **Real-Time Synced Karaoke Lyrics (`.lrc`)**:
  - Pairs automatically with same-named `.lrc` files (e.g. `Song.mp3` + `Song.lrc`) or embedded ID3 tags.
- **10-Band Parametric Equalizer**:
  - Presets for Bass Booster, Rock, Electronic, Vocal, Acoustic, Classical, and custom dB sliders.
- **Sleep Timer with Smooth Volume Fade**:
  - Gentle audio fade-out when time is almost up.

---

## 📂 Project Architecture

```
Sonance/
├── SonanceApp.swift                      # App Entrypoint & AudioSession setup
├── Info.plist                            # Background audio, File sharing, Live Activities
├── Configuration/
│   └── AppConstants.swift               # Constants, formats, and API configs
├── Models/
│   ├── Song.swift                        # Core song entity with metadata & relative path
│   ├── Album.swift, Artist.swift, Playlist.swift, AudioFolder.swift
│   ├── PlaybackMode.swift, LyricLine.swift, CloudItem.swift
├── Services/
│   ├── Audio/
│   │   ├── AudioPlayerService.swift      # AVFoundation playback & queue engine
│   │   ├── AudioSessionManager.swift     # Background session, interruptions, route changes
│   │   ├── NowPlayingManager.swift       # MPNowPlayingInfoCenter & MPRemoteCommandCenter
│   │   ├── EqualizerService.swift        # 10-band AVAudioUnitEQ engine & presets
│   │   └── SleepTimerService.swift       # Countdown timer with audio fade
│   ├── Storage/
│   │   ├── LocalFileManager.swift        # Recursive file scanner & in-app file importer
│   │   ├── MetadataExtractor.swift       # Async ID3 tag, duration, and artwork extractor
│   │   ├── LyricsParser.swift            # LRC synced lyrics parser & active line matcher
│   │   └── DatabaseService.swift         # Persistence for playlists, favorites, & history
│   ├── Cloud/
│   │   ├── GoogleDriveAuthManager.swift  # OAuth 2.0 PKCE authentication flow
│   │   ├── GoogleDriveService.swift      # Google Drive v3 REST API file listing
│   │   └── CloudDownloadManager.swift    # Background multi-threaded download manager
│   ├── LiveActivity/
│   │   ├── SonanceActivityAttributes.swift
│   │   └── LiveActivityManager.swift     # ActivityKit start/update/end lifecycle
│   └── NetworkTransfer/
│       └── WiFiTransferServer.swift      # Local HTTP web server for PC-to-phone uploads
├── ViewModels/
│   ├── PlayerViewModel.swift
│   ├── LibraryViewModel.swift
│   ├── FolderBrowserViewModel.swift
│   ├── CloudDriveViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── MainTabView.swift                 # Bottom navigation + floating crystal MiniPlayer
│   ├── Player/
│   │   ├── FullPlayerView.swift          # Expandable full-screen player
│   │   ├── MiniPlayerView.swift          # Floating pill player
│   │   ├── LyricsView.swift              # Real-time synced karaoke lyrics
│   │   └── QueueView.swift               # Drag-and-drop queue manager
│   ├── Library/
│   │   ├── LibraryView.swift             # Segmented library (Songs, Albums, Artists, Playlists)
│   │   ├── SongRowView.swift             # Crystal list row with context menu
│   │   ├── AlbumDetailView.swift
│   │   ├── ArtistDetailView.swift
│   │   └── PlaylistDetailView.swift
│   ├── Folders/
│   │   └── FolderBrowserView.swift       # File system directory explorer
│   ├── Cloud/
│   │   ├── CloudHubView.swift            # Central import center
│   │   ├── GoogleDriveBrowserView.swift  # Google Drive file browser
│   │   └── DownloadQueueSheet.swift      # Active download progress sheet
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── EqualizerView.swift
│   └── Components/
│       ├── CrystalGlassView.swift        # Specular rim modifier & clear glass container
│       ├── FluidMeshBackground.swift     # Organic liquid backdrop
│       ├── CrystalWaveformScrubber.swift # Liquid seek bar with glowing bead
│       ├── ReflectiveControls.swift      # Tactile crystal glass buttons & haptics
│       ├── ArtworkImageView.swift        # High-res art with ambient bloom
│       └── AnimatedVisualizerView.swift  # Dancing frequency spectrum bars
└── SonanceWidgetExtension/
    ├── SonanceWidgetBundle.swift
    ├── LiveActivity/
    │   └── SonanceLiveActivityWidget.swift # Lock Screen Banner & Dynamic Island
    └── HomeWidgets/
        └── NowPlayingWidget.swift          # Interactive Home Screen widgets
```

---

## 📲 How to Sideload to your iPhone 12 Pro Max

Since you are using a sideloading tool (such as **Sideloadly**, **AltStore**, **SideStore**, or **TrollStore**) with a free Apple ID / personal certificate:

### 1. Enable Developer Mode on your iPhone
1. On your iPhone 12 Pro Max, open **Settings** > **Privacy & Security**.
2. Scroll down to **Developer Mode** and toggle it **ON**.
3. Restart your iPhone and confirm **Turn On** when prompted.

### 2. Sideloading via Sideloadly or AltStore
1. Build or export the `Sonance.ipa` from Xcode or package the Xcode project.
2. Open **Sideloadly** or **AltStore** on your PC.
3. Connect your iPhone via USB cable or ensure Wi-Fi sync is enabled.
4. Drag `Sonance.ipa` into Sideloadly, enter your Apple ID credentials, and click **Start**.
5. Once installed, go to **Settings** > **General** > **VPN & Device Management** on your iPhone, tap your developer email, and tap **Trust**.

---

## 🎵 How to Put Songs on Sonance (4 Easy Ways)

1. **Direct Cable / Files App (Fastest)**:
   - Connect iPhone to PC/Mac via cable -> Open iTunes / Finder / 3uTools -> Go to File Sharing -> **Sonance** -> Drop your music folders into `Music`.
   - Or open the iOS **Files** app -> `On My iPhone` -> `Sonance` -> `Music` and copy songs there.
2. **Wi-Fi Computer Upload**:
   - In Sonance, go to the **Cloud** tab -> Enable **Wi-Fi Computer Upload**.
   - On your PC browser, open `http://[iPhone-IP]:8080`.
   - Drag and drop your audio files directly in the browser!
3. **Google Drive Sync**:
   - Go to **Cloud** tab -> Connect **Google Drive** -> Browse and tap download on any songs/folders.
4. **In-App File & Folder Importer**:
   - Go to **Library** or **Cloud** tab -> Tap **Import** -> Select any audio files or folders from iCloud Drive or local storage.
