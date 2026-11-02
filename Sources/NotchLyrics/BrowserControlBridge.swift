import Foundation

/// Sites the browser source reads and controls.
enum MediaHosts {
    static let all = [
        "music.youtube.com", "youtube.com", "soundcloud.com",
        "music.apple.com", "open.spotify.com", "bandcamp.com",
        "vimeo.com", "twitch.tv", "music.amazon.com", "tidal.com",
        "deezer.com", "audiomack.com"
    ]

    /// AppleScript list literal, for a cheap first pass on tab URLs.
    static var appleScriptList: String {
        all.map { "\"\($0)\"" }.joined(separator: ", ")
    }

    /// A JS expression that is true only when the page's own hostname is one of
    /// these sites or a subdomain of one. The AppleScript pass only checks that
    /// the URL contains a host somewhere, which `evil.example/?youtube.com`
    /// would pass.
    static var jsGuard: String {
        let list = all.map { "'\($0)'" }.joined(separator: ",")
        return "[\(list)].some(function(d){var h=location.hostname;return h===d||h.endsWith('.'+d);})"
    }
}

/// Sends a JS payload to the first media tab in a running, allowed browser.
/// Used for play/pause/seek/next/previous.
enum BrowserControlBridge {
    @discardableResult
    static func run(js: String) -> String? {
        // Only reports "ok" from a page that passes the host check, so a
        // look-alike URL is skipped and the search carries on.
        let guarded = "(function(){if(!(\(MediaHosts.jsGuard)))return '';\(js);return 'ok';})()"
        let escapedJS = guarded
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        for browser in ScriptTarget.browsers where browser.isReadable {
            let runJS = browser.isSafari ? "do JavaScript js in t" : "execute t javascript js"
            let script = """
            set js to "\(escapedJS)"
            set hosts to {\(MediaHosts.appleScriptList)}
            try
                with timeout of 3 seconds
                    tell \(browser.scriptReference)
                        repeat with w in windows
                            repeat with t in tabs of w
                                try
                                    set u to URL of t as string
                                    repeat with h in hosts
                                        if u contains h then
                                            set r to (\(runJS))
                                            if r is "ok" then return "ok"
                                            exit repeat
                                        end if
                                    end repeat
                                end try
                            end repeat
                        end repeat
                    end tell
                end timeout
            end try
            return ""
            """
            if browser.run(script) == "ok" {
                return "ok"
            }
        }
        return nil
    }
}
