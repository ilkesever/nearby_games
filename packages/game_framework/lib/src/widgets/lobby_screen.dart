import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nearby_ble/nearby_ble.dart';

import '../l10n/game_framework_localizations.dart';

/// Reusable lobby screen for discovering and connecting to nearby players.
class LobbyScreen extends StatefulWidget {
  final String gameType;
  final String gameName;
  final BleService bleService;
  final void Function(BleConnection connection, bool isHost) onConnected;
  final String playerName;
  final Color? accentColor;

  const LobbyScreen({
    super.key,
    required this.gameType,
    required this.gameName,
    required this.bleService,
    required this.onConnected,
    this.playerName = 'Player',
    this.accentColor,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  _LobbyMode _mode = _LobbyMode.choosing;
  final List<BleDevice> _discoveredDevices = [];
  bool _isConnecting = false;
  String? _errorMessage;

  StreamSubscription? _deviceFoundSub;
  StreamSubscription? _deviceLostSub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _errorSub;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _setupListeners();
  }

  void _setupListeners() {
    _deviceFoundSub = widget.bleService.onDeviceFound.listen((device) {
      setState(() {
        _discoveredDevices.removeWhere((d) => d.id == device.id);
        _discoveredDevices.add(device);
      });
    });

    _deviceLostSub = widget.bleService.onDeviceLost.listen((device) {
      setState(() {
        _discoveredDevices.removeWhere((d) => d.id == device.id);
      });
    });

    _connectionSub = widget.bleService.onConnection.listen((connection) {
      if (_mode == _LobbyMode.hosting) {
        widget.onConnected(connection, true);
      }
    });

    _errorSub = widget.bleService.onError.listen((error) {
      setState(() {
        _errorMessage = error.message;
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _deviceFoundSub?.cancel();
    _deviceLostSub?.cancel();
    _connectionSub?.cancel();
    _errorSub?.cancel();
    if (!widget.bleService.isConnected) {
      widget.bleService.stopScanning().catchError((_) {});
      widget.bleService.stopHosting().catchError((_) {});
    }
    super.dispose();
  }

  Color get _accent => widget.accentColor ?? Theme.of(context).primaryColor;

  Future<void> _startHosting() async {
    setState(() {
      _mode = _LobbyMode.hosting;
      _errorMessage = null;
    });
    try {
      await widget.bleService.stopScanning().catchError((_) {});
      await widget.bleService.startHosting(
        gameType: widget.gameType,
        playerName: widget.playerName,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _mode = _LobbyMode.choosing;
      });
    }
  }

  Future<void> _startScanning() async {
    setState(() {
      _mode = _LobbyMode.scanning;
      _discoveredDevices.clear();
      _errorMessage = null;
    });
    try {
      await widget.bleService.stopHosting().catchError((_) {});
      await widget.bleService.startScanning(gameType: widget.gameType);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _mode = _LobbyMode.choosing;
      });
    }
  }

  Future<void> _connectToDevice(BleDevice device) async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });
    try {
      final connection = await widget.bleService.connect(
        device,
        playerName: widget.playerName,
      );
      widget.onConnected(connection, false);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isConnecting = false;
      });
    }
  }

  void _goBack() {
    widget.bleService.stopScanning().catchError((_) {});
    widget.bleService.stopHosting().catchError((_) {});
    setState(() {
      _mode = _LobbyMode.choosing;
      _discoveredDevices.clear();
      _isConnecting = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gameName),
        leading: _mode != _LobbyMode.choosing
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              )
            : null,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_mode) {
      case _LobbyMode.choosing:
        return _buildChoiceScreen();
      case _LobbyMode.hosting:
        return _buildHostingScreen();
      case _LobbyMode.scanning:
        return _buildScanningScreen();
    }
  }

  Widget _buildChoiceScreen() {
    final l10n = GameFrameworkLocalizations.of(context);
    return Center(
      key: const ValueKey('choice'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth, size: 64, color: _accent),
            const SizedBox(height: 24),
            Text(
              l10n.lobbyNearbyGame(widget.gameName),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.lobbyPlayWithSomeoneNearby,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            _LobbyButton(
              icon: Icons.add_circle_outline,
              label: l10n.lobbyCreateGame,
              subtitle: l10n.lobbyCreateGameSubtitle,
              color: _accent,
              onTap: _startHosting,
            ),
            const SizedBox(height: 16),
            _LobbyButton(
              icon: Icons.search,
              label: l10n.lobbyJoinGame,
              subtitle: l10n.lobbyJoinGameSubtitle,
              color: _accent,
              onTap: _startScanning,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              _ErrorBanner(message: _errorMessage!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHostingScreen() {
    final l10n = GameFrameworkLocalizations.of(context);
    return Center(
      key: const ValueKey('hosting'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.1),
                  child: Icon(
                    Icons.bluetooth_searching,
                    size: 80,
                    color: _accent.withValues(
                      alpha: 0.5 + (_pulseController.value * 0.5),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              l10n.lobbyWaitingForOpponent,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.lobbyGameVisible,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.playerName} • ${widget.gameName}',
                style:
                    TextStyle(color: _accent, fontWeight: FontWeight.w600),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              _ErrorBanner(message: _errorMessage!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScanningScreen() {
    final l10n = GameFrameworkLocalizations.of(context);
    return Padding(
      key: const ValueKey('scanning'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bluetooth_searching, color: _accent),
              const SizedBox(width: 12),
              Text(
                l10n.lobbyNearbyGames,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.lobbyLookingForGames(widget.gameName),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          if (_discoveredDevices.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.radar, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      l10n.lobbyNoGamesFound,
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.lobbyMakeSureOtherPlayer,
                      style:
                          TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _discoveredDevices.length,
                itemBuilder: (context, index) {
                  final device = _discoveredDevices[index];
                  return _DeviceCard(
                    device: device,
                    accentColor: _accent,
                    isConnecting: _isConnecting,
                    onTap: () => _connectToDevice(device),
                  );
                },
              ),
            ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: _errorMessage!),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _LobbyButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _LobbyButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final BleDevice device;
  final Color accentColor;
  final bool isConnecting;
  final VoidCallback onTap;

  const _DeviceCard({
    required this.device,
    required this.accentColor,
    required this.isConnecting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = GameFrameworkLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accentColor.withValues(alpha: 0.1),
          child: Icon(Icons.person, color: accentColor),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(_distanceLabel(l10n)),
        trailing: isConnecting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.lobbyJoinButton),
              ),
        onTap: isConnecting ? null : onTap,
      ),
    );
  }

  String _distanceLabel(GameFrameworkLocalizations l10n) {
    switch (device.estimatedDistance) {
      case BleDeviceDistance.immediate:
        return l10n.lobbyDistanceImmediate;
      case BleDeviceDistance.near:
        return l10n.lobbyDistanceNear;
      case BleDeviceDistance.far:
        return l10n.lobbyDistanceFar;
      case BleDeviceDistance.unknown:
        return l10n.lobbyDistanceUnknown;
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LobbyMode {
  choosing,
  hosting,
  scanning,
}
