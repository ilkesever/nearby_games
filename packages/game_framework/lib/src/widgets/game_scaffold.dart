import 'package:flutter/material.dart';

import '../game_session.dart';
import '../game_state.dart';
import '../l10n/game_framework_localizations.dart';

/// Shared scaffold for all games.
class GameScaffold<TState extends GameState, TMove> extends StatelessWidget {
  final GameSession<TState, TMove> session;
  final String gameName;
  final Widget gameBoard;
  final Color? accentColor;
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
    final l10n = GameFrameworkLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        title: Text(gameName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context, l10n),
        ),
        actions: [
          if (session.isPlaying)
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, value, l10n),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'resign', child: Text(l10n.gameResign)),
                PopupMenuItem(
                    value: 'draw', child: Text(l10n.gameOfferDraw)),
                PopupMenuItem(
                    value: 'undo', child: Text(l10n.gameRequestUndo)),
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
                _PlayerBar(
                  name: session.remotePlayer?.name ??
                      l10n.gameOpponent,
                  isActive: !session.isMyTurn && session.isPlaying,
                  accentColor: accent,
                  isLocal: false,
                  turnLabel: l10n.gameTurn,
                ),
                _StatusBar(
                    session: session,
                    accentColor: accent),
                Expanded(child: Center(child: gameBoard)),
                _PlayerBar(
                  name: session.localPlayer?.name ?? l10n.gameYou,
                  isActive: session.isMyTurn && session.isPlaying,
                  accentColor: accent,
                  isLocal: true,
                  turnLabel: l10n.gameTurn,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleAction(
      BuildContext context, String action, GameFrameworkLocalizations l10n) {
    switch (action) {
      case 'resign':
        _showResignDialog(context, l10n);
      case 'draw':
        session.offerDraw();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.gameDrawOfferSent)),
        );
      case 'undo':
        session.requestUndo();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.gameUndoRequestSent)),
        );
    }
  }

  void _showResignDialog(
      BuildContext context, GameFrameworkLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.gameResignTitle),
        content: Text(l10n.gameResignContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.gameCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              session.resign();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.gameResign),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(
      BuildContext context, GameFrameworkLocalizations l10n) {
    if (!session.isPlaying) {
      onExit?.call();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.gameLeaveTitle),
        content: Text(l10n.gameLeaveContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.gameStay),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              session.resign();
              onExit?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.gameLeave),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _PlayerBar extends StatelessWidget {
  final String name;
  final bool isActive;
  final Color accentColor;
  final bool isLocal;
  final String turnLabel;

  const _PlayerBar({
    required this.name,
    required this.isActive,
    required this.accentColor,
    required this.isLocal,
    required this.turnLabel,
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
            backgroundColor: isActive ? accentColor : Colors.grey[300],
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                turnLabel,
                style: const TextStyle(
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
    final l10n = GameFrameworkLocalizations.of(context);
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (session.status) {
      case GameSessionStatus.waiting:
        statusText = l10n.gameWaiting;
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
      case GameSessionStatus.playing:
        statusText =
            session.isMyTurn ? l10n.gameYourTurn : l10n.gameOpponentTurn;
        statusColor = session.isMyTurn ? accentColor : Colors.grey;
        statusIcon =
            session.isMyTurn ? Icons.touch_app : Icons.hourglass_top;
      case GameSessionStatus.gameOver:
        statusText = l10n.gameOver;
        statusColor = Colors.deepPurple;
        statusIcon = Icons.flag;
      case GameSessionStatus.disconnected:
        statusText = l10n.gameConnectionLost;
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
