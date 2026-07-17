# 🏏 Pitch Point

**Where Every Run Counts!**

Pitch Point is a cross-platform Flutter app for scoring cricket matches live — from the coin toss all the way to the winner's trophy. It tracks ball-by-ball scoring, batting and bowling stats, extras, and full match history, all stored locally on-device with SQLite.

---

## Screenshots

| Home | Team Setup | Coin Toss |
| :---: | :---: | :---: |
| ![Home Screen](assets/screenshots/Home%20Screen.png) | ![Team Setup](assets/screenshots/Team%20Setup.png) | ![Coin Toss](assets/screenshots/Coin%20Toss.png) |

| Toss Result | Live Scoreboard | Match Stats |
| :---: | :---: | :---: |
| ![Toss Result](assets/screenshots/Coin%20Toss1.png) | ![Live Scoreboard](assets/screenshots/Live%20Scoreboard.png) | ![Match Stats](assets/screenshots/Match%20Stats.jpeg) |

| Score History | Match History |
| :---: | :---: |
| ![Score History](assets/screenshots/Score%20History.jpeg) | ![Match History](assets/screenshots/Match%20History.jpeg) |

---

## ✨ Features

- **Team Setup** — Enter custom names for both competing teams before the match begins.
- **Animated Coin Toss** — Call heads or tails with an animated spinning coin, then choose to bat or bowl first.
- **Live Ball-by-Ball Scoreboard**
  - Score runs, boundaries (4s/6s), dot balls, wickets, and retirements with a single tap.
  - Support for extras: no balls, wides, byes, and leg byes.
  - Live-updating overs, run rate, and current batting/bowling figures.
  - Configurable total overs and max wickets per innings.
- **Resume In-Progress Matches** — Matches are saved after every delivery, so an interrupted match can be resumed exactly where it left off.
- **Man of the Match** — Award the standout performer at the end of the game.
- **Winner Celebration Screen** — An animated congratulations screen with match result and final scores once the match concludes.
- **Full Match Scorecard** — Detailed batting and bowling cards for both innings, including runs, balls faced, fours, sixes, and strike rate, plus an over-by-over scoring comparison chart.
- **Match History** — Browse, review, and delete previously played matches, stored locally in a SQLite database.
- **Cross-Platform** — Built with Flutter, runs on Android, iOS, Windows, macOS, Linux, and Web.

---

## 🛠 Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** [Provider](https://pub.dev/packages/provider)
- **Local Storage:** [sqflite](https://pub.dev/packages/sqflite) (mobile) / [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) (desktop)
- **UI:** Material 3, custom theming with the Montserrat font family

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (^3.9.2)
- A connected device, emulator, or desktop/web target

### Run the app

```bash
flutter pub get
flutter run
```

### Build a release

```bash
flutter build apk      # Android
flutter build windows  # Windows
flutter build web       # Web
```

---

## 📂 Project Structure

```
lib/
├── main.dart              # App entry point & theme
├── Providers/              # State management (scoreboard, team names)
├── pages/                   # App screens (main, teams, toss, scoreboard, history, details, congratulations)
├── widgets/                 # Reusable UI components (score buttons, input fields)
├── animations/               # Custom animations (coin toss)
├── models/                   # Data models mirroring the SQLite schema
├── services/                  # Match service (business logic layer)
├── db/                        # SQLite database helper
└── util/                       # Shared utilities (innings, footer, bat/ball logic)
```

---

## 📄 License

All rights reserved. See [LICENSE](LICENSE) for details.
