import 'package:flutter/material.dart';
import 'package:game_framework/game_framework.dart';
import 'package:nearby_ble/nearby_ble.dart';

import 'ui/chess_game_screen.dart';
import 'ui/local_game_screen.dart';

void main() {
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nearby Chess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.brown,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.brown[800],
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/// Home screen — choose local play or BLE multiplayer.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();
  bool _bleAvailable = false;
  bool _bleChecked = false;
  bool _bleInitializing = false;
  String _playerName = 'Player';

  @override
  void initState() {
    super.initState();
    // BLE is initialized lazily — only when user taps "Play Nearby"
    // This avoids blocking the UI thread with CoreBluetooth manager
    // creation on app startup.
  }

  /// Initialize BLE lazily. Called when user wants to use BLE features.
  Future<bool> _ensureBleReady() async {
    if (_bleChecked) return _bleAvailable;
    if (_bleInitializing) return false;
    setState(() => _bleInitializing = true);
    try {
      await _bleService.initialize();
      // Give CoreBluetooth a moment to settle its state after init
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final available = await _bleService.isAvailable();
      if (available) {
        final granted = await _bleService.requestPermissions();
        if (mounted) {
          setState(() {
            _bleAvailable = granted;
            _bleChecked = true;
          });
        }
        return granted;
      } else {
        if (mounted) {
          setState(() {
            _bleAvailable = false;
            _bleChecked = true;
          });
        }
        return false;
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _bleAvailable = false;
          _bleChecked = true;
        });
      }
      return false;
    } finally {
      if (mounted) setState(() => _bleInitializing = false);
    }
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }

  void _navigateToLocalGame() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocalGameScreen()),
    );
  }

  void _navigateToLobby() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LobbyScreen(
          gameType: 'chess',
          gameName: 'Chess',
          bleService: _bleService,
          playerName: _playerName,
          accentColor: Colors.brown[700],
          onConnected: (connection, isHost) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ChessGameScreen(
                  bleService: _bleService,
                  connection: connection,
                  isHost: isHost,
                  playerName: _playerName,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Chess icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.brown[50],
                  shape: BoxShape.circle,
                ),
                child: const Text('♚', style: TextStyle(fontSize: 64)),
              ),
              const SizedBox(height: 32),
              Text(
                'Nearby Chess',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Play chess with someone nearby\nNo internet required',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 48),

              // Player name input
              TextField(
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  _playerName = value.isEmpty ? 'Player' : value;
                },
              ),
              const SizedBox(height: 24),

              // Play Nearby (BLE) button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _bleInitializing
                      ? null
                      : (_bleChecked && !_bleAvailable)
                          ? null
                          : () async {
                              if (_bleAvailable) {
                                _navigateToLobby();
                              } else {
                                // Lazy-init BLE on first tap
                                final ready = await _ensureBleReady();
                                if (ready && mounted) {
                                  _navigateToLobby();
                                }
                              }
                            },
                  icon: _bleInitializing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bluetooth, size: 24),
                  label: Text(
                    _bleInitializing
                        ? 'Initializing Bluetooth...'
                        : (_bleChecked
                            ? (_bleAvailable
                                ? 'Play Nearby'
                                : 'Bluetooth unavailable')
                            : 'Play Nearby'),
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[700],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Local Play button — always available
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _navigateToLocalGame,
                  icon: Icon(Icons.people, size: 24, color: Colors.brown[700]),
                  label: Text(
                    'Local Play (Pass & Play)',
                    style: TextStyle(fontSize: 18, color: Colors.brown[700]),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.brown[300]!, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bluetooth, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    'Uses Bluetooth • Works offline',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
