# Changelog

All notable changes to this project are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.1.3] - 2026-11-02

### Fixed

- No more "Where is Brave Browser?" (or Edge, or Spotify) windows. The app
  asked about every supported app on every check, including ones that aren't
  installed.
- The open lyrics card no longer has a pale box around its sides and below
  it on light wallpapers. The card looks the same otherwise.
- macOS permission prompts no longer appear on their own. The app only reads
  apps you've allowed, and Setup asks for each one when you click Allow.

### Changed

- Setup lists your installed browsers and QuickTime, each with its own Allow
  button. Allowing an app that isn't open opens it in the background first.
- When nothing is playing because a music app hasn't been allowed yet, the
  notch says so and links to Setup. After updating, macOS treats the app as
  new, so click Allow in Setup once for each music app you use.

### Security

- Browser scripts only run in tabs whose hostname is a supported site. Before,
  a URL that merely contained one (`example.com/?youtube.com`) also matched.
- Cover art is only downloaded over https.

## [1.1.2] - 2026-10-29

### Changed

- The closed bar rolls to each new line: the old one lifts up and fades out
  while the next rises in and brightens.
- The open card is darker, so busy windows behind it don't compete with the
  lyrics.
- The Spotify cookie is stored in a file only your account can read instead
  of the Keychain. The Keychain asked for your login password every time the
  app was updated. If you saved a cookie in 1.1.0 or 1.1.1, paste it again in
  View › Lyrics.
- Lyrics copy in the app no longer names the lyrics service.

## [1.1.1] - 2026-10-28

### Fixed

- The app crashed on launch on every Mac except the one that built it: it
  looked for its fonts and visualizer outside the app. It now loads them from
  the app's Resources folder, and the release script refuses to package a
  build that would look elsewhere.

## [1.1.0] - 2026-10-28

### Added

- Optional Spotify lyrics: for songs playing in Spotify (app or
  open.spotify.com), use Spotify's own lyrics, timed to the exact recording.
  Set it up in the new Lyrics pane (View › Lyrics, ⌘3) with your `sp_dc`
  cookie, which is kept in the Keychain. Falls back to LRCLIB.
- Displays without a notch show the line whole and centred, with the artwork
  and meter either side.

### Changed

- The notch is set in Geist: a semibold current line, and the same family as
  the timestamps.
- The current line shows solid instead of filling in. Lyrics are only timed
  per line, so the fill was a guess at where the words were.
- Lyrics run half a second ahead, so each line is up just before it's sung.

### Fixed

- Opening and closing the card no longer leaves faded copies of old lyrics
  behind it.

## [1.0.0] - 2026-10-22

First release.

- Synced lyrics in the notch for Spotify, Apple Music, QuickTime and browser
  playback, with lyrics from LRCLIB.
- Lyrics card on hover with a scrubber, playback controls and line-by-line
  scrolling.
- Optional audio effects through a loopback device: presets, a 10-band EQ and
  reverb.
- Same bar centred in the menu bar on displays without a notch.

[Unreleased]: https://github.com/nawed2611/notch-lyrics/compare/v1.1.3...HEAD
[1.1.3]: https://github.com/nawed2611/notch-lyrics/compare/v1.1.2...v1.1.3
[1.1.2]: https://github.com/nawed2611/notch-lyrics/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/nawed2611/notch-lyrics/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/nawed2611/notch-lyrics/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/nawed2611/notch-lyrics/releases/tag/v1.0.0
