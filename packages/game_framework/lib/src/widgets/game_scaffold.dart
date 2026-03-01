import 'package:flutter/material.dart';

import '../game_session.dart';
import '../game_state.dart';

/// Shared scaffold for all games.
///
/// Provides consistent game chrome including:
/// - Player names and turn indicator
/// - Game status bar (whose turn, game over, etc.)
/// - Action buttons (resign, draw, undo)
/// - Connection status indicator
///
/// Games plug their own board widget into [gameBoard].
///
/// Usage:
/// ```dart
/// GameScaffold(
///   session: gameSession,
///   gameName: 'Chess',
///   gameBoard: ChessBoardWidget(state: gameSession.state),
///   accentColor: Colors.brown,
/// )
/// ```
class GameScaffold<TState extends GameState, TMove> extends StatelessWidget {
  /// The game session.
  final GameSession<TState, TMove> session;

  /// The game name (shown in app bar).
  final String gameName;

  /// The main game board widget.
  final Widget gameBoard;

  /// Optional accent color.
  final Color? accentColor;

  /// Called when the user wants to go back.
  final VoidCallback? onExit;

  const GameScaffold({
    super.key,
    required this.session,
    required this.gameName,
    required this.gameBoard,
    this.accentColor,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(gameName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
        actions: [
          if (session.isPlaying)
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, value),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'resign', child: Text('Resign')),
                const PopupMenuItem(
                    value: 'draw', child: Text('Offer Draw')),
                const PopupMenuItem(value: 'undo', child: Text('Request Undo')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: session,
          builder: (context, _) {
            return Column(
              children: [
                // Remote player info
                _PlayerBar(
                  name: session.remotePlayer?.name ?? 'Opponent',
                  isActive: !session.isMyTurn && session.isPlaying,
                  accentColor: accent,
                  isLocal: false,
                ),

                // Status bar
                _StatusBar(session: session, accentColor: accent),

                // Game board (the main content)
                Expanded(child: gameBoard),

                // Local player info
                _PlayerBar(
                  name: session.localPlayer?.name ?? 'You',
                  isActive: session.isMyTurn && session.isPlaying,
                  accentColor: accent,
                  isLocal: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'resign':
        _showResignDialog(context);
      case 'draw':
        session.offerDraw();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draw offer sent')),
        );
      case 'undo':
        session.requestUndo();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Undo request sent')),
        );
    }
  }

  void _showResignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resign?'),
        content: const Text('Are you sure you want to resign this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              session.resign();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    if (!session.isPlaying) {
      onExit?.call();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Game?'),
        content: const Text(
            'Leaving will end the current game. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              session.resign();
              onExit?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// HELPER WIDGETS
// ==========================================================================

class _PlayerBar extends StatelessWidget {
  final String name;
  final bool isActive;
  final Color accentColor;
  final bool isLocal;

  const _PlayerBar({
    required this.name,
    required this.isActive,
    required this.accentColor,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? accentColor.withValues(alpha: 0.1) : null,
        border: Border(
          left: BorderSide(
            color: isActive ? accentColor : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                isActive ? accentColor : Colors.grey[300],
            child: Icon(
              isLocal ? Icons.person : Icons.person_outline,
              size: 18,
              color: isActive ? Colors.white : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
                color: isActive ? accentColor : null,
              ),
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Turn',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBar<TState extends GameState, TMove> extends StatelessWidget {
  final GameSession<TState, TMove> session;
  final Color accentColor;

  const _StatusBar({required this.session, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (session.status) {
      case GameSessionStatus.waiting:
        statusText = 'Waiting for game to start...';
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
      case GameSessionStatus.playing:
        statusText = session.isMyTurn ? 'Your turn' : "Opponent's turn";
        statusColor = session.isMyTurn ? accentColor : Colors.grey;
        statusIcon = session.isMyTurn ? Icons.touch_app : Icons.hourglass_top;
      case GameSessionStatus.gameOver:
        statusText = 'Game Over';
        statusColor = Colors.deepPurple;
        statusIcon = Icons.flag;
      case GameSessionStatus.disconnected:
        statusText = 'Connection lost';
        statusColor = Colors.red;
        statusIcon = Icons.bluetooth_disabled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: statusColor.withValues(alpha: 0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
