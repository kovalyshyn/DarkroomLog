# DarkroomLog

An iOS app for analog darkroom photographers. Log printing sessions, catalog film rolls, track chemistry, share your work, and keep notes on every print.

## Features

### Darkroom
- **Session logging** — record enlarger, lens, paper, and developer for each session
- **Print tracking** — log exposure steps, aperture, notes, and attach a photo of each print
- **Print rating** — rate prints with 1–3 stars
- **Duplicate print** — swipe right on any print to duplicate it with all settings
- **Darkroom timer** — red digits on black, screen dims to minimum, shake or knock to restart
- **Progress bar** — fills and resets with each exposure step; shows current step number
- **Wash timer** — background countdown with Time Sensitive notification when done
- **Equipment library** — save your gear once, pick it every time; categories: Enlargers, Cameras, Film Stocks, Lenses, Papers, Developers

### Light Table
- **Film roll catalog** — log every roll: format (135/120), film stock, camera, lens, developer, notes
- **Development steps** — add your development process step by step (developer, stop bath, fixer, wash, etc.)
- **Film development timer** — run your dev steps in sequence with a progress bar and step counter
- **Film roll picker** — link prints to specific rolls from the Light Table
- **Searchable lists** — find sessions and rolls instantly

### Chemistry
- **Chemical batch tracking** — track developer, fixer, bleach, and any other chemistry
- **Usage counter** — log rolls processed per batch with swipe gestures
- **Expiry tracking** — color-coded status (green/orange/red) based on age and usage
- **Renew** — reset a batch to fresh when you mix a new one

### Share
- **Print cards** — generate a dark-themed image card with photo, name, rating, film roll, equipment, and exposure; choose portrait or landscape layout
- **Film roll cards** — share the full development record of any roll as an image card
- Save to Photos or share to any app directly from the preview sheet

### General
- **Backup & Restore** — export all data (sessions, prints, film rolls, equipment, chemistry, photos) as JSON; restore on any device; forward-compatible across versions
- **Dark interface** — force dark mode independently of system appearance
- **Search** — full-text search in both Darkroom and Light Table

## Timers

### Darkroom Timer
Designed for use in complete darkness:
- Large red digits on pure black (OLED-friendly)
- Screen brightness drops to minimum automatically
- Status bar and navigation bar hidden while running
- Tap, knock on the table, or toss the phone to restart from zero
- Bell sound at each exposure step; free-run mode after the last step
- Progress bar fills within each step, resets at step boundary
- Swipe right to exit

### Film Development Timer
For use outside the darkroom (developing tank, chemical mixing):
- Add named steps with custom durations to any film roll
- Progress bar and step counter (e.g. 2 / 4) while running
- White digits, normal screen brightness
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

## About

Independent project by [Vitalii Kovalyshyn](https://filmly.co.ua) — founder of the Ukrainian-language film photography community in the Fediverse.

## License

GNU Affero General Public License v3.0. See [LICENSE](LICENSE) for details.
