import 'package:flutter/material.dart';
import 'package:game_framework/game_framework.dart';
import 'package:nearby_ble/nearby_ble.dart';

import 'ui/chess_game_screen.dart';

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

/// Home screen — initializes BLE and navigates to the lobby.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();
  bool _isInitializing = true;
  String? _error;
  String _playerName = 'Player';

  @override
  void initState() {
    super.initState();
    _initBle();
  }

  Future<void> _initBle() async {
    try {
      await _bleService.initialize();
      final available = await _bleService.isAvailable();
      if (!available) {
        setState(() {
          _error = 'Bluetooth is not available or is turned off';
          _isInitializing = false;
        });
        return;
      }
      final granted = await _bleService.requestPermissions();
      if (!granted) {
        setState(() {
          _error = 'Bluetooth permissions are required to play';
          _isInitializing = false;
        });
        return;
      }
      setState(() => _isInitializing = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
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
            // Navigate to the game screen
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
        child: _isInitializing
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing Bluetooth...'),
                  ],
                ),
              )
            : _error != null
                ? _buildErrorScreen()
                : _buildHomeScreen(),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bluetooth_disabled, size: 64, color: Colors.red[300]),
            const SizedBox(height: 24),
            Text(
              'Bluetooth Required',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isInitializing = true;
                  _error = null;
                });
                _initBle();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Padding(
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
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

          // Play button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _navigateToLobby,
              icon: const Icon(Icons.play_arrow, size: 28),
              label: const Text('Play', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[700],
                foregroundColor: Colors.white,
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
    );
  }
}
