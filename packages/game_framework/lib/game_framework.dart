/// Shared framework for turn-based multiplayer games over BLE.
///
/// This package provides:
/// - [GameEngine] — Abstract interface for game rules and validation.
/// - [GameState] — Abstract interface for game state.
/// - [GameSession] — Manages game communication over BLE.
/// - [LobbyScreen] — Reusable UI for discovering and connecting to players.
/// - [GameScaffold] — Shared game chrome (status bar, actions, etc.).
export 'src/game_engine.dart';
export 'src/game_state.dart';
export 'src/game_session.dart';
export 'src/game_player.dart';
export 'src/widgets/lobby_screen.dart';
export 'src/widgets/game_scaffold.dart';
