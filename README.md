# DarkroomLog

An iOS app for analog darkroom photographers. Log printing sessions, catalog film rolls, share your work, and keep notes on every print.

## Features

### Darkroom
- **Session logging** — record enlarger, lens, paper, and developer for each session
- **Print tracking** — log exposure steps, aperture, notes, and attach a photo of each print
- **Print rating** — rate prints with 1–3 stars
- **Duplicate print** — swipe right on any print to duplicate it with all settings
- **Darkroom timer** — red digits on black, screen dims to minimum, shake or knock to restart
- **Wash timer** — background countdown with Time Sensitive notification when done
- **Equipment library** — save your gear once, pick it every time; categories: Enlargers, Cameras, Film Stocks, Lenses, Papers, Developers

### Light Table
- **Film roll catalog** — log every roll: format (135/120), film stock, camera, lens, developer, notes
- **Film roll picker** — link prints to specific rolls from the Light Table
- **Searchable lists** — find sessions and rolls instantly

### Share
- **Print cards** — generate a dark-themed image card with photo, name, rating, film roll, equipment, and exposure; choose portrait or landscape layout
- **Film roll cards** — share the full development record of any roll as an image card
- Save to Photos or share to any app directly from the preview sheet

### General
- **Backup & Restore** — export all data (sessions, prints, film rolls, equipment, photos) as JSON; restore on any device
- **Dark interface** — force dark mode independently of system appearance
- **Two timers** — darkroom timer (red, screen dimmed) and film development timer (white, normal brightness)
- **Search** — full-text search in both Darkroom and Light Table

## Darkroom Timer

Designed for use in complete darkness:
- Large red digits on pure black (OLED-friendly)
- Screen brightness drops to minimum automatically
- Status bar and navigation bar hidden while running
- Tap, knock on the table, or toss the phone to restart from zero
- Bell sound at each exposure step; free-run mode after the last step
- Swipe right to exit

## Film Development Timer

A standard timer for use outside the darkroom (developing tank, chemical mixing):
- White digits on black
- Normal screen brightness
- Bell every minute as a reminder
- Same shake/knock/toss to restart

## Requirements

- iOS 18.6+
- Xcode 16+

## Installation

```bash
git clone https://github.com/kovalyshyn/DarkroomLog
cd DarkroomLog
open DarkroomLog.xcodeproj
```

## Architecture

- **SwiftUI** — declarative UI
- **SwiftData** — local persistence (automatic lightweight migration)
- **UserNotifications** — Time Sensitive wash timer notifications
- **AVFoundation** — tick and bell audio
- **CoreMotion** — shake and toss detection
- **PhotosUI** — print photo attachment
- **WidgetKit** — planned for v1.6

## About

Independent project by [Vitalii Kovalyshyn](https://filmly.co.ua) — founder of the Ukrainian-language film photography community in the Fediverse.

## License

GNU Affero General Public License v3.0. See [LICENSE](LICENSE) for details.
