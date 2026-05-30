import AppKit

// MARK: - About / version

// Uses the native standard About panel, which automatically shows the app
// icon (from NextMeeting.icns), name, and version (from Info.plist keys
// CFBundleShortVersionString / CFBundleVersion). We add a short credits line.
enum About {
    static func show() {
        let credits = NSAttributedString(
            string: "A compact menu bar countdown to your next meeting.\n100% local & private.",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor,
                .paragraphStyle: {
                    let p = NSMutableParagraphStyle()
                    p.alignment = .center
                    return p
                }()
            ]
        )

        // Bring the menu-bar-only app forward so the panel isn't hidden.
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    }
}
