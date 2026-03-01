# Nearby Games 🎮

A **modular framework** for building peer-to-peer multiplayer board games that work over **Bluetooth Low Energy (BLE)** — no internet, no WiFi, no server required.

Supports **iOS↔Android cross-platform play**.

## Architecture

```
┌──────────────────────────────────────────┐
│          Game App (Chess, Backgammon)     │
├──────────────────────────────────────────┤
│  Game UI Layer        (Flutter Widgets)  │
├──────────────────────────────────────────┤
│  Game Logic Layer     (Rules, State)     │
├──────────────────────────────────────────┤
│  Game Session Layer   (Turns, Sync)      │  ← game_framework
├──────────────────────────────────────────┤
│  BLE Communication    (Discovery,        │
│                        Connection,       │  ← nearby_ble
│                        Messaging)        │
└──────────────────────────────────────────┘
```

## Project Structure

```
nearby_games/
├── packages/
│   ├── nearby_ble/          # BLE communication plugin (iOS + Android)
│   └── game_framework/      # Shared game session framework + UI
├── apps/
│   └── chess/               # ♟️ Chess app (first game)
├── melos.yaml               # Monorepo management
└── README.md
```

## How It Works

1. **Device A** (Host) starts advertising a game via BLE
2. **Device B** (Joiner) scans for nearby games, discovers Device A
3. Devices connect via BLE GATT (works iOS↔Android)
4. Game moves are sent as small JSON messages over BLE characteristics
5. Both devices validate moves locally — the framework keeps state in sync

## Adding a New Game

To add a new game (e.g., backgammon), you only need to:

1. **Implement `GameEngine<YourState, YourMove>`** — define your rules
2. **Build your board UI widget** — render the game
3. **Wire it up** — the framework handles discovery, connection, turns, and sync

```dart
// 1. Implement the engine
class BackgammonEngine extends GameEngine<BackgammonState, BackgammonMove> {
  @override
  String get gameType => 'backgammon';
  
  @override
  BackgammonState applyMove(BackgammonState state, BackgammonMove move) {
    // Your game logic here
  }
  
  // ... implement the rest
}

// 2. Use the shared lobby and game scaffold
LobbyScreen(
  gameType: 'backgammon',
  gameName: 'Backgammon',
  bleService: bleService,
  onConnected: (connection, isHost) {
    // Navigate to your game screen
  },
);
```

## Getting Started

### Prerequisites
- Flutter 3.41+
- Xcode (for iOS)
- Android Studio (for Android)

### Setup
```bash
# Install melos
dart pub global activate melos

# Bootstrap the monorepo
melos bootstrap

# Run the chess app
cd apps/chess
flutter run
```

### iOS Configuration
Add to `ios/Runner/Info.plist`:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect with nearby players.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to connect with nearby players.</string>
```

### Android Configuration
BLE permissions are automatically included via the `nearby_ble` plugin manifest.

## Tech Stack

- **Flutter** — Cross-platform UI framework
- **Dart** — Application language
- **CoreBluetooth** (iOS) — BLE Central + Peripheral
- **Android BLE API** (Android) — BLE Central + Peripheral
- **Melos** — Monorepo management

## Communication Protocol

Messages are JSON-encoded with a simple envelope:

```json
{
  "v": 1,
  "type": "move",
  "seq": 5,
  "ts": 1735909326000,
  "payload": {
    "from": 52,
    "to": 36
  }
}
```

## License

MIT
