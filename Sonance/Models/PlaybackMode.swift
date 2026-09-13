import Foundation

/// Playback repeat modes
public enum RepeatMode: String, Codable, CaseIterable, Identifiable {
    case off
    case all
    case one
    
    public var id: String { rawValue }
    
    public var systemImage: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }
}

/// Playback speed options
public enum PlaybackSpeed: Double, Codable, CaseIterable, Identifiable {
    case half = 0.5
    case threeQuarters = 0.75
    case normal = 1.0
    case oneAndQuarter = 1.25
    case oneAndHalf = 1.5
    case double = 2.0
    
    public var id: Double { rawValue }
    
    public var label: String {
        switch self {
        case .normal: return "1.0x"
        default: return String(format: "%.2fx", rawValue)
        }
    }
}
