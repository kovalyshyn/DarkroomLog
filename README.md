# DarkroomLog

An iOS app for analog darkroom photographers. Log printing sessions, catalog film rolls, and keep notes on every print.

## Features

### Darkroom
- **Session logging** — record enlarger, lens, paper, and developer for each session
- **Print tracking** — log exposure steps, notes, and attach a photo of each print
- **Darkroom timer** — red digits on black, screen dims to minimum, shake or knock to restart
- **Wash timer** — background countdown with Time Sensitive notification when done; multiple timers at once
- **Equipment library** — save your gear once, pick it every time; categories: Enlargers, Cameras, Film Stocks, Lenses, Papers, Developers

### Light Table
- **Film roll catalog** — log every roll: format (135/120), film stock, camera, lens, developer, notes
- **Film roll picker** — link prints to specific rolls from the Light Table
- **Searchable lists** — find sessions and rolls instantly

### General
- **Two timers** — darkroom timer (red, screen dimmed) and film development timer (white, normal brightness)
- **Settings** — toggle metronome tick sound
- **Search** — full-text search in both Darkroom and Light Table

## Darkroom Timer

Designed for use in complete darkness:
- Large red digits on pure black (OLED-friendly)
- Screen brightness drops to minimum automatically
- Status bar and navigation bar hidden while running
- Tap, knock on the table, or toss the phone to restart from zero
- Bell sound at each exposure step
- Swipe right to exit

## Film Development Timer

A standard timer for use outside the darkroom (developing tank, chemical mixing):
- White digits on black
- Normal screen brightness
- Same shake/knock/toss to restart

## Requirements

- iOS 18.6+
- Xcode 26+

## Installation

```bash
git clone https://github.com/kovalyshyn/DarkroomLog
cd DarkroomLog
open DarkroomLog.xcodeproj
```

## Architecture

- **SwiftUI** — declarative UI
- **SwiftData** — local persistence
- **UserNotifications** — Time Sensitive wash timer notifications
- **AVFoundation** — tick and bell audio
- **CoreMotion** — shake and toss detection
- **PhotosUI** — print photo attachment

## About

Independent project by [Vitalii Kovalyshyn](https://filmly.co.ua) — founder of the Ukrainian-language film photography community in the Fediverse.

## License

GNU Affero General Public License v3.0. See [LICENSE](LICENSE) for details.
