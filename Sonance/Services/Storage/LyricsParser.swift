import Foundation

/// Synchronized LRC lyrics parser and active line locator
public final class LyricsParser {
    public static let shared = LyricsParser()
    
    private init() {}
    
    /// Parses LRC formatted text into structured, sorted LyricLine objects
    public func parse(lrcContent: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        let rawLines = lrcContent.components(separatedBy: .newlines)
        
        // Regex matches [mm:ss.xx] or [mm:ss:xx] or [mm:ss]
        let pattern = "\\[(\\d{2}):(\\d{2})(?:[.:](\\d{2,3}))?\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        for rawLine in rawLines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            let nsString = trimmed as NSString
            let matches = regex.matches(in: trimmed, options: [], range: NSRange(location: 0, length: nsString.length))
            
            guard !matches.isEmpty else { continue }
            
            // Extract the lyric text occurring after all timestamp tags
            let lastMatch = matches.last!
            let lyricTextRange = NSRange(location: lastMatch.range.location + lastMatch.range.length, length: nsString.length - (lastMatch.range.location + lastMatch.range.length))
            let text = nsString.substring(with: lyricTextRange).trimmingCharacters(in: .whitespaces)
            
            for match in matches {
                let minRange = match.range(at: 1)
                let secRange = match.range(at: 2)
                let msRange = match.range(at: 3)
                
                let minutes = Double(nsString.substring(with: minRange)) ?? 0
                let seconds = Double(nsString.substring(with: secRange)) ?? 0
                var fraction: Double = 0
                
                if msRange.location != NSNotFound {
                    let msStr = nsString.substring(with: msRange)
                    if msStr.count == 2 {
                        fraction = (Double(msStr) ?? 0) / 100.0
                    } else if msStr.count == 3 {
                        fraction = (Double(msStr) ?? 0) / 1000.0
                    }
                }
                
                let totalSeconds = (minutes * 60.0) + seconds + fraction
                lines.append(LyricLine(timestamp: totalSeconds, text: text))
            }
        }
        
        return lines.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Loads and parses an .lrc file at the given file URL
    public func parse(fileURL: URL) -> [LyricLine]? {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return nil
        }
        return parse(lrcContent: content)
    }
    
    /// Returns the index of the currently active lyric line for a given playback time
    public func findActiveLineIndex(at currentTime: TimeInterval, in lines: [LyricLine]) -> Int? {
        guard !lines.isEmpty else { return nil }
        
        var low = 0
        var high = lines.count - 1
        var candidate: Int? = nil
        
        while low <= high {
            let mid = (low + high) / 2
            if lines[mid].timestamp <= currentTime {
                candidate = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        
        return candidate
    }
}
