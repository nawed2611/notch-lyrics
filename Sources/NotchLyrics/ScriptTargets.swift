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

/// Remembers which apps are allowed, so the poll asks TCC only about apps it
/// hasn't seen allowed yet. Never asks the user, and never blocks the caller.
///
/// `AEDeterminePermissionToAutomateTarget` can block indefinitely. Run inline,
/// one stuck call would freeze polling for good, so the check runs on
/// its own thread and callers read the last answer. An app counts as not
/// allowed until a check has said otherwise.
enum AutomationGate {
    private struct State {
        var allowed: Set<String> = []
        /// Apps whose last finished check said they aren't allowed.
        var denied: Set<String> = []
        var inFlight: [String: Int] = [:]
        var lastStarted: [String: Date] = [:]
        var lastFinished: [String: Date] = [:]
    }

    private static let state = OSAllocatedUnfairLock(initialState: State())
    /// How soon an app that wasn't allowed is checked again.
    private static let recheckAfter: TimeInterval = 3
    /// A check still running after this long is treated as stuck, and another
    /// one is started alongside it.
    private static let stuckAfter: TimeInterval = 10
    /// Stuck checks per app, at most, so hung threads can't pile up.
    private static let maxInFlight = 3

    static func isAllowed(_ target: ScriptTarget) -> Bool {
        let id = target.bundleID
        let now = Date()
        let (allowed, startCheck) = state.withLock { s -> (Bool, Bool) in
            if s.allowed.contains(id) { return (true, false) }
            let inFlight = s.inFlight[id, default: 0]
            if inFlight > 0 {
                let started = s.lastStarted[id] ?? now
                guard now.timeIntervalSince(started) >= stuckAfter, inFlight < maxInFlight else {
                    return (false, false)
                }
                playbackLogger.log("🔐 permission check for \(id, privacy: .public) stuck, retrying")
            } else if let finished = s.lastFinished[id], now.timeIntervalSince(finished) < recheckAfter {
                return (false, false)
            }
            s.inFlight[id] = inFlight + 1
            s.lastStarted[id] = now
            return (false, true)
        }
        if startCheck {
            Thread {
                let ok = OnboardingChecks.automationStatus(for: id) == .satisfied
                state.withLock { s in
                    s.inFlight[id, default: 1] -= 1
                    s.lastFinished[id] = Date()
                    if ok {
                        s.allowed.insert(id)
                        s.denied.remove(id)
                    } else if !s.allowed.contains(id) {
                        s.denied.insert(id)
                    }
                }
            }.start()
        }
        return allowed
    }

    /// Running players the user hasn't allowed yet, for the pill's idle hint.
    /// Only apps a finished check turned down, so the hint doesn't flash
    /// while the first check is still running.
    static func playersWaitingForAccess() -> [ScriptTarget] {
        ScriptTarget.players.filter { target in
            guard target.isRunning, !isAllowed(target) else { return false }
            return state.withLock { $0.denied.contains(target.bundleID) }
        }
    }
}
