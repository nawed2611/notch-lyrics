import AppKit
import os

/// Every app Notch Lyrics talks to over Apple Events.
///
/// Scripts address apps by bundle id and only ever run against an app that is
/// already running and already allowed. Both rules exist so that the
/// background poll never puts anything on screen:
///
/// - Compiling `tell application "Brave Browser"` loads Brave's scripting
///   dictionary, so on a Mac without Brave macOS asks "Where is Brave
///   Browser?". An `is running` check inside the script doesn't help, because
///   the whole script is compiled before any of it runs.
/// - Sending the first Apple Event to an app shows the Automation prompt. That
///   prompt belongs to Setup, where the user asked for it.
enum ScriptTarget: String, CaseIterable, Sendable {
    case spotify   = "com.spotify.client"
    case music     = "com.apple.Music"
    case quickTime = "com.apple.QuickTimePlayerX"
    case safari    = "com.apple.Safari"
    case chrome    = "com.google.Chrome"
    case arc       = "company.thebrowser.Browser"
    case brave     = "com.brave.Browser"
    case edge      = "com.microsoft.edgemac"

    var bundleID: String { rawValue }

    var name: String {
        switch self {
        case .spotify:   "Spotify"
        case .music:     "Apple Music"
        case .quickTime: "QuickTime Player"
        case .safari:    "Safari"
        case .chrome:    "Google Chrome"
        case .arc:       "Arc"
        case .brave:     "Brave"
        case .edge:      "Microsoft Edge"
        }
    }

    /// Music players, as opposed to browsers and QuickTime.
    static let players: [ScriptTarget] = [.spotify, .music]
    /// Read through `BrowserMediaSource`, in the order tabs are searched.
    static let browsers: [ScriptTarget] = [.safari, .chrome, .arc, .brave, .edge]

    var isBrowser: Bool { Self.browsers.contains(self) }
    var isSafari: Bool { self == .safari }

    /// The `tell` target for scripts. By id, so a renamed or localised app
    /// still resolves.
    var scriptReference: String { "application id \"\(bundleID)\"" }

    var isInstalled: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil
    }

    var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }

    /// Running and already allowed, so a script can run without any dialog.
    var isReadable: Bool {
        isRunning && AutomationGate.isAllowed(self)
    }

    /// Runs `source` only if this app is readable. Nil otherwise.
    func run(_ source: String) -> String? {
        guard isReadable else { return nil }
        return AppleScriptRunner.run(source)
    }
}

/// Remembers which apps are already allowed, so the poll asks TCC only about
/// apps it hasn't seen allowed yet. Never asks the user.
enum AutomationGate {
    private static let allowed = OSAllocatedUnfairLock(initialState: Set<String>())

    static func isAllowed(_ target: ScriptTarget) -> Bool {
        if allowed.withLock({ $0.contains(target.bundleID) }) { return true }
        guard OnboardingChecks.automationStatus(for: target.bundleID) == .satisfied else { return false }
        allowed.withLock { _ = $0.insert(target.bundleID) }
        return true
    }

    /// Running players the user hasn't allowed yet, for the pill's idle hint.
    static func playersWaitingForAccess() -> [ScriptTarget] {
        ScriptTarget.players.filter { $0.isRunning && !isAllowed($0) }
    }
}
