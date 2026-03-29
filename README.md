# DarkroomLog

An iOS app for analog darkroom photographers. Log your printing sessions, track exposure times, and keep notes on every print.

## Features

- **Session logging** — record enlarger, lens, paper, and developer for each session
- **Equipment library** — save your gear once, select it every time
- **Print tracking** — log exposure time, notes, and attach a photo of each print
- **Darkroom timer** — black screen with red digits, tick sound every second, shake or knock to restart, screen dims automatically while running
- **iCloud Backup** — data is included in iOS iCloud Backup

## Timer

The timer is designed to be used in complete darkness:
- Large red digits on pure black (OLED-friendly)
- Status bar and navigation bar hidden while running
- Screen brightness drops to minimum automatically
- Tap screen, knock on the table, or toss the phone to restart from zero
- Swipe right to exit

## Screenshots

_Coming soon_

## Requirements

- iOS 26.0+
- Xcode 26+

## Installation

Clone the repository and open `DarkroomLog.xcodeproj` in Xcode.

```bash
git clone https://github.com/kovalyshyn/DarkroomLog
cd DarkroomLog
open DarkroomLog.xcodeproj
```

## Architecture

- **SwiftUI** — declarative UI
- **SwiftData** — local persistence
- **AVFoundation** — tick audio
- **CoreMotion** — shake and toss detection
- **PhotosUI** — print photo attachment

## About

Independent project by [Vitalii Kovalyshyn](https://filmly.co.ua) — founder of the Ukrainian-language film photography community in the Fediverse.

## License

This project is licensed under the GNU Affero General Public License v3.0.
See [LICENSE](LICENSE) for details.
