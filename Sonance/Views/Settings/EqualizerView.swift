import SwiftUI

/// Interactive 10-band equalizer view with preset selection and dB sliders
public struct EqualizerView: View {
    @ObservedObject var equalizer = EqualizerService.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Equalizer")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color.white)
                            Text("10-Band Parametric Audio Shaper")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { equalizer.isEnabled },
                            set: { equalizer.toggleEnabled($0) }
                        ))
                        .labelsHidden()
                        .tint(Color(red: 0.4, green: 0.8, blue: 1.0))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Presets Carousel
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(EqualizerPreset.allPresets) { preset in
                                let isSelected = (equalizer.selectedPreset.name == preset.name)
                                Button {
                                    equalizer.applyPreset(preset)
                                } label: {
                                    Text(preset.name)
                                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                        .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.6))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? Color(red: 0.25, green: 0.55, blue: 0.95) : Color.white.opacity(0.06))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 10 Sliders Grid
                    HStack(spacing: 10) {
                        ForEach(0..<EqualizerPreset.standardFrequencies.count, id: \.self) { index in
                            let freq = EqualizerPreset.standardFrequencies[index]
                            let gain = equalizer.customGains[index]
                            
                            VStack(spacing: 8) {
                                Text(String(format: "%+.0f", gain))
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(gain != 0 ? Color(red: 0.4, green: 0.8, blue: 1.0) : Color.white.opacity(0.4))
                                
                                // Vertical Slider
                                GeometryReader { geo in
                                    ZStack(alignment: .bottom) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 6)
                                        
                                        // Center zero indicator
                                        Rectangle()
                                            .fill(Color.white.opacity(0.3))
                                            .frame(width: 14, height: 1)
                                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                                        
                                        // Thumb
                                        let normalizedGain = CGFloat((gain + 12.0) / 24.0) // 0 to 1
                                        let thumbY = geo.size.height * (1.0 - normalizedGain)
                                        
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 16, height: 16)
                                            .shadow(color: Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.6), radius: 4)
                                            .position(x: geo.size.width / 2, y: thumbY)
                                    }
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { val in
                                                let percent = 1.0 - (val.location.y / geo.size.height)
                                                let clamped = max(0, min(percent, 1.0))
                                                let calculatedGain = Float(clamped * 24.0 - 12.0)
                                                equalizer.setGain(for: index, gain: calculatedGain)
                                            }
                                    )
                                }
                                .frame(height: 180)
                                
                                Text(formatFrequency(freq))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .crystalGlass(cornerRadius: 20)
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func formatFrequency(_ freq: Float) -> String {
        if freq >= 1000 {
            return String(format: "%.0fk", freq / 1000)
        } else {
            return String(format: "%.0f", freq)
        }
    }
}
