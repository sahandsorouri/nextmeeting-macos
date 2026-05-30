import Foundation

// MARK: - Meeting link detection
// Scans event fields (title, location, notes, url) for a known meeting provider.
// Pure string parsing — no network.

struct DetectedLink: Equatable {
    let provider: String
    let url: URL
}

enum LinkDetector {
    private struct Pattern { let provider: String; let regex: NSRegularExpression }

    // Order = priority when several links are present.
    private static let patterns: [Pattern] = {
        let defs: [(String, String)] = [
            ("Zoom",            #"https?://[A-Za-z0-9.-]*zoom\.us/[^\s<>"')]+"#),
            ("Google Meet",     #"https?://meet\.google\.com/[^\s<>"')]+"#),
            ("Microsoft Teams", #"https?://teams\.(microsoft|live)\.com/[^\s<>"')]+"#),
            ("Webex",           #"https?://[A-Za-z0-9.-]*webex\.com/[^\s<>"')]+"#),
            ("Whereby",         #"https?://[A-Za-z0-9.-]*whereby\.com/[^\s<>"')]+"#),
            ("Around",          #"https?://(meet\.)?around\.co/[^\s<>"')]+"#),
            ("Discord",         #"https?://(discord\.gg|discord\.com)/[^\s<>"')]+"#),
            ("Slack",           #"https?://[A-Za-z0-9.-]*slack\.com/[^\s<>"')]*huddle[^\s<>"')]*"#),
            ("Jitsi",           #"https?://[A-Za-z0-9.-]*jit\.si/[^\s<>"')]+"#),
        ]
        return defs.compactMap { name, pat in
            (try? NSRegularExpression(pattern: pat, options: [.caseInsensitive]))
                .map { Pattern(provider: name, regex: $0) }
        }
    }()

    /// Returns the first matching provider link across the given fields.
    static func detect(in fields: [String?]) -> DetectedLink? {
        let text = fields.compactMap { $0 }.joined(separator: "\n")
        guard !text.isEmpty else { return nil }
        let range = NSRange(text.startIndex..., in: text)

        for p in patterns {
            guard let m = p.regex.firstMatch(in: text, options: [], range: range),
                  let r = Range(m.range, in: text) else { continue }
            let raw = String(text[r]).trimmingCharacters(in: CharacterSet(charactersIn: ".,;)"))
            if let url = URL(string: raw) {
                return DetectedLink(provider: p.provider, url: url)
            }
        }
        return nil
    }
}
