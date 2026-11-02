# Security policy

## Supported versions

Only the latest release gets security fixes.

## Reporting a vulnerability

Please don't open a public issue. Report it privately through GitHub instead:
go to the repo's **Security** tab and click **Report a vulnerability**.

Include what you found, how to reproduce it and what an attacker could do with
it. You should get a reply within a week.

## What the app touches

So you know where to look:

- **Network:** lyrics lookups to `lrclib.net` (title, artist, album and
  duration), and cover art over https from the player or the page that is
  playing. With Spotify lyrics turned on, it also reads the web player from
  `open.spotify.com` and `open.spotifycdn.com`, signs in at
  `open.spotify.com/api/token` with your `sp_dc` cookie, and asks
  `spclient.wg.spotify.com` for lyrics by track id. The cookie is sent nowhere
  else. There is no analytics.
- **Spotify cookie:** stored in
  `~/Library/Application Support/Notch Lyrics/spotify-sp_dc`, readable only by
  your account (file `0600`, folder `0700`). Never logged.
- **Automation:** it uses Apple Events to read and control Spotify, Apple
  Music, QuickTime and supported browsers. It only sends them to apps that are
  already running and that you allowed in Setup. In browsers it runs a fixed,
  read-only script, plus play/pause/seek/skip, and only in tabs whose hostname
  is one of the supported music and video sites.
- **Helper:** if `media-control` is installed (Homebrew), it runs it to read
  macOS's Now Playing information.
- **Audio:** the optional effects capture audio from a loopback input device
  (BlackHole) and play it back processed. Audio is never recorded or stored.
