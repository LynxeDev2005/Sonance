import Foundation
import AVFoundation

/// Equalizer Preset Model
public struct EqualizerPreset: Identifiable, Hashable, Codable {
    public var id: String { name }
    public let name: String
    public let gains: [Float] // 10 bands from 32Hz to 16kHz in dB (-12 to +12)
    
    public static let standardFrequencies: [Float] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    
    public static let flat = EqualizerPreset(name: "Flat", gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    public static let bassBooster = EqualizerPreset(name: "Bass Booster", gains: [6.0, 5.0, 4.0, 2.5, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    public static let bassReducer = EqualizerPreset(name: "Bass Reducer", gains: [-6.0, -5.0, -4.0, -2.5, -1.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    public static let trebleBooster = EqualizerPreset(name: "Treble Booster", gains: [0, 0, 0, 0, 0, 1.0, 2.5, 4.5, 6.0, 7.0])
    public static let vocalBooster = EqualizerPreset(name: "Vocal Booster", gains: [-2.0, -1.0, 0.0, 2.0, 4.0, 4.5, 3.5, 2.0, 0.5, -1.0])
    public static let rock = EqualizerPreset(name: "Rock", gains: [5.0, 3.5, 2.0, 0.0, -1.0, 0.0, 2.0, 3.5, 4.5, 5.0])
    public static let electronic = EqualizerPreset(name: "Electronic", gains: [4.5, 4.0, 2.0, 0.0, -1.5, 1.5, 0.5, 2.0, 4.0, 4.5])
    public static let acoustic = EqualizerPreset(name: "Acoustic", gains: [3.5, 3.0, 2.0, 1.0, 1.5, 2.0, 3.0, 3.5, 3.0, 2.0])
    public static let hipHop = EqualizerPreset(name: "Hip-Hop", gains: [6.0, 5.0, 3.0, 1.0, -1.0, 0.0, 1.0, 2.0, 3.5, 4.0])
    public static let jazz = EqualizerPreset(name: "Jazz", gains: [3.0, 2.0, 1.0, 1.5, -1.5, -1.5, 0.0, 1.5, 2.5, 3.5])
    public static let classical = EqualizerPreset(name: "Classical", gains: [4.0, 3.5, 2.5, 1.0, -1.0, -1.0, 0.0, 2.0, 3.5, 4.0])
    
    public static let allPresets: [EqualizerPreset] = [
        .flat, .bassBooster, .bassReducer, .trebleBooster, .vocalBooster,
        .rock, .electronic, .acoustic, .hipHop, .jazz, .classical
    ]
}

/// Service managing parametric 10-band audio equalization
public final class EqualizerService: ObservableObject {
    public static let shared = EqualizerService()
    
    @Published public var isEnabled: Bool = false
    @Published public var selectedPreset: EqualizerPreset = .flat
    @Published public var customGains: [Float] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    
    public let eqUnit: AVAudioUnitEQ
    
    private init() {
        self.eqUnit = AVAudioUnitEQ(numberOfBands: EqualizerPreset.standardFrequencies.count)
        setupBands()
    }
    
    private func setupBands() {
        for (index, freq) in EqualizerPreset.standardFrequencies.enumerated() {
            let band = eqUnit.bands[index]
            band.frequency = freq
            band.bandwidth = 1.0
            band.bypass = false
            band.filterType = (index == 0) ? .lowShelf : (index == EqualizerPreset.standardFrequencies.count - 1 ? .highShelf : .parametric)
            band.gain = 0.0
        }
    }
    
    public func applyPreset(_ preset: EqualizerPreset) {
        selectedPreset = preset
        customGains = preset.gains
        applyGains(preset.gains)
    }
    
    public func setGain(for bandIndex: Int, gain: Float) {
        guard bandIndex >= 0 && bandIndex < customGains.count else { return }
        customGains[bandIndex] = min(max(gain, -12.0), 12.0)
        if isEnabled {
            eqUnit.bands[bandIndex].gain = customGains[bandIndex]
        }
    }
    
    public func toggleEnabled(_ enabled: Bool) {
        isEnabled = enabled
        eqUnit.bypass = !enabled
        if enabled {
            applyGains(customGains)
        }
    }
    
    private func applyGains(_ gains: [Float]) {
        guard isEnabled else { return }
        for (index, gain) in gains.enumerated() {
            if index < eqUnit.bands.count {
                eqUnit.bands[index].gain = gain
            }
        }
    }
}
