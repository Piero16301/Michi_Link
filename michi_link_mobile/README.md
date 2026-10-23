# Michi Link Mobile

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Analysis](https://img.shields.io/badge/Style-Very%20Good%20Analysis-blueviolet.svg)](https://pub.dev/packages/very_good_analysis)

A Flutter mobile application designed for locating, tracking, and monitoring pets (specifically cats) using long-range **LoRa** radiofrequency technology and **GPS** positioning. It provides real-time cartographic tracking, virtual geofencing perimeters, advanced radio link telemetry (RSSI, SNR, packet loss), battery status monitoring, instant security alerts, and historical route playback.

---

## 🚀 Quick Start

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version `>= 3.47.0`)
- [Dart SDK](https://dart.dev/get-dart) (version `>= 3.12.0 < 4.0.0`)
- Android Studio / Xcode configured with simulators, emulators, or physical test devices.
- Valid API keys configured for **Google Maps** (Android and iOS) and a configured **Firebase** project.

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Piero16301/Michi_Link.git
   cd Michi_Link/michi_link_mobile
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate localization files (if needed after checkout):**
   ```bash
   flutter gen-l10n
   ```

4. **Configure environment & credentials:**
   - **Android**: Ensure `android/app/google-services.json` is present and Google Maps API key is configured in `android/app/src/main/AndroidManifest.xml`.
   - **iOS**: Ensure `ios/Runner/GoogleService-Info.plist` is present and Google Maps API key is configured in `ios/Runner/AppDelegate.swift`.
   - The app supports `Environment.mock` (simulated telemetry and collars without live cloud dependencies) and `Environment.prod` (live Cloud Firestore streams). Configurable in `lib/main.dart`.

5. **Run the application:**
   ```bash
   flutter run
   ```

---

## 🛠️ Common Commands

| Command | Description |
|---------|-------------|
| `flutter pub get` | Downloads and installs project dependencies. |
| `flutter run` | Starts the app on the connected device or simulator. |
| `flutter run -d chrome` | Runs the app on Google Chrome (web dev mode). |
| `flutter test` | Executes the unit and widget test suite. |
| `flutter test --coverage` | Runs tests and generates an LCOV coverage report in `coverage/lcov.info`. |
| `flutter analyze` | Runs static code analysis using `very_good_analysis` and `bloc_lint`. |
| `dart fix --apply` | Automatically applies recommended linter fixes across Dart files. |
| `flutter gen-l10n` | Regenerates strongly-typed localization files from `.arb` templates. |
| `dart run flutter_launcher_icons` | Generates adaptive app launcher icons for Android and iOS. |
| `flutter build apk --release` | Generates the production APK binary for Android. |
| `flutter build appbundle --release` | Generates the Android App Bundle (AAB) for Google Play. |
| `flutter build ipa --release` | Generates the iOS distribution archive (App Store / TestFlight). |

---

## 🧭 Key Features

- **🛰️ Real-Time GPS Tracking & LoRa Telemetry**: Continuous rendering of the pet's coordinates, distance to the home base station (`distanceHomeM`), radio signal strength (`rssi`), signal-to-noise ratio (`snr`), and packet loss rate.
- **🛡️ Virtual Geofencing**: Configurable safe movement radius (`maxDistanceM`). Immediate visual and event notifications when the pet breaches or re-enters the safe perimeter.
- **🔋 Battery & Hardware Sensors**: Real-time display of battery percentage, voltage (`batteryV`), GPS lock status (`gpsFix`), and active satellite count (`sats`).
- **🗺️ Interactive Map Experience**: Smooth Google Maps integration featuring custom cat breed avatars as map markers, light and dark map styling, and quick-centering controls.
- **📜 Route History & Breadcrumbs**: Query past positions filtered by date and time, visualizing the travel trail with map polylines.
- **🔔 Notifications & Alert Center**: Categorized by severity (`CRITICAL`, `WARNING`, `INFO`) for geofence breaches, low battery levels, or radio signal dropouts.
- **🐈 Multi-Collar Management & Cat Breeds**: Support for multiple collars with custom pet names and vector SVG avatars for 10 distinct cat breeds.
- **🎨 Expressive Design System**: Built with **Material 3 Expressive** (`expressive_kit`), featuring dynamic seed color palette generation, font selection, and smooth light/dark mode transitions.
- **🌐 Internationalization (i18n / l10n)**: Full Spanish and English support with dynamic runtime language switching.

---

## 🏗️ Architecture & Project Structure

The project follows a **Feature-First** layered architecture emphasizing strict separation of concerns and unidirectional data flow:

```
lib/
├── app/                  # Application core
│   ├── cubit/            # Global app state (theme, language, seed color)
│   ├── global/           # App constants, routes (GoRouter), dependencies (GetIt), enums, styles
│   ├── models/           # Domain data models (CollarModel, AlertRecord, etc.)
│   ├── repositories/     # Data interfaces & implementations (Firestore, Hive, Mocks)
│   ├── services/         # Telemetry services (Crashlytics, Performance, Analytics, Storage)
│   └── view/             # App entry views (AppPage, AppView)
├── collars/              # Collar pairing and configuration management feature
├── history/              # Route history and telemetry breadcrumbs feature
├── home/                 # Main dashboard (map view, telemetry panel, geofence setup)
├── l10n/                 # Localization templates (.arb) and generated classes
├── notifications/        # Alerts and notification history feature
├── settings/             # User settings and UI customization feature
├── bootstrap.dart        # BLoC observer initialization and global crash boundary setup
├── firebase_options.dart # Auto-generated Firebase platform configuration
└── main.dart             # Application main entry point
```

### Architecture Decision Records (ADRs)

Key architectural decisions, trade-offs, and technical rationales are recorded under [`docs/decisions/`](docs/decisions/):

- [**ADR-001: Feature-First Architecture with BLoC/Cubit and GetIt Service Locator**](docs/decisions/ADR-001-architecture-and-state-management.md) — Explains the architectural pattern, unidirectional data flow, and dependency injection via `GetIt` / `ServiceFactory`.
- [**ADR-002: Hybrid Data Strategy: Cloud Firestore and Local Storage with Hive**](docs/decisions/ADR-002-data-storage-strategy.md) — Details the separation between reactive real-time Firestore streams and fast offline local persistence via Hive.
- [**ADR-003: Google Maps Integration, LoRa Telemetry, and Geofencing**](docs/decisions/ADR-003-lora-telemetry-and-mapping.md) — Justifies the use of `google_maps_flutter`, dynamic marker canvas generation, and radio link monitoring metrics.
- [**ADR-004: Expressive Design System and Flutter l10n Internationalization**](docs/decisions/ADR-004-design-system-and-internationalization.md) — Documents the adoption of Material 3 Expressive tokens and typed ARB localization.

---

## 🧪 Testing & Code Quality

The project maintains high code quality standards and testing coverage:

1. **Static Analysis**:
   Enforces rules from [`very_good_analysis`](https://pub.dev/packages/very_good_analysis) and [`bloc_lint`](https://pub.dev/packages/bloc_lint).
   ```bash
   flutter analyze
   ```

2. **Unit & Widget Testing**:
   Built with `mocktail` and `bloc_test`.
   ```bash
   flutter test
   ```

3. **Code Coverage**:
   Generate an LCOV coverage report:
   ```bash
   flutter test --coverage
   genhtml coverage/lcov.info -o coverage/html
   open coverage/html/index.html
   ```

---

## 🤝 Contributing & Workflow

1. Create a descriptive feature branch (`feature/feature-name` or `fix/fix-description`).
2. Adhere to code conventions and ensure `flutter analyze` runs without errors or warnings.
3. Write unit and widget tests for new logic in `test/`.
4. If introducing a major architectural or technical decision, document it with an ADR in `docs/decisions/`.
5. Submit a Pull Request detailing the changes and acceptance criteria.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
