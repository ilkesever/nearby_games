import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:game_framework/game_framework.dart';
import 'package:nearby_ble/nearby_ble.dart';

import 'src/l10n/app_localizations.dart';
import 'ui/backgammon_game_screen.dart';
import 'ui/local_game_screen.dart';

void main() {
  runApp(const BackgammonApp());
}

class BackgammonApp extends StatelessWidget {
  const BackgammonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.brown,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.brown[800],
          foregroundColor: Colors.white,
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GameFrameworkLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
        Locale('hi'),
        Locale('es'),
        Locale('fr'),
        Locale('ar'),
        Locale('bn'),
        Locale('ru'),
        Locale('pt'),
        Locale('id'),
        Locale('tr'),
        Locale('de'),
      ],
      home: const HomeScreen(),
    );
  }
}

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

  StreamSubscription<bool>? _bleAvailabilitySub;

  Future<bool> _ensureBleReady() async {
    if (_bleChecked) return _bleAvailable;
    if (_bleInitializing) return false;
    setState(() => _bleInitializing = true);

    try {
      final completer = Completer<bool>();
      _bleAvailabilitySub =
          _bleService.onBleAvailabilityChanged.listen((available) {
        if (!completer.isCompleted) completer.complete(available);
        if (mounted) setState(() => _bleAvailable = available);
      });

      await _bleService.initialize();

      final available = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => _bleService.isAvailable(),
      );

      if (mounted) {
        setState(() {
          _bleAvailable = available;
          _bleChecked = true;
        });
      }
      return available;
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
    _bleAvailabilitySub?.cancel();
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
    final l10n = AppLocalizations.of(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LobbyScreen(
          gameType: 'backgammon',
          gameName: l10n.appTitle,
          bleService: _bleService,
          playerName: _playerName,
          accentColor: Colors.brown[700],
          onConnected: (connection, isHost) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BackgammonGameScreen(
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.brown[50],
                  shape: BoxShape.circle,
                ),
                child: const Text('🎲', style: TextStyle(fontSize: 64)),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.homeTagline,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 48),

              TextField(
                decoration: InputDecoration(
                  labelText: l10n.homeYourName,
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
                        ? l10n.homeInitializingBluetooth
                        : (_bleChecked
                            ? (_bleAvailable
                                ? l10n.homePlayNearby
                                : l10n.homeBluetoothUnavailable)
                            : l10n.homePlayNearby),
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

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _navigateToLocalGame,
                  icon: Icon(Icons.people, size: 24, color: Colors.brown[700]),
                  label: Text(
                    l10n.homeLocalPlay,
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

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bluetooth, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    l10n.homeBluetoothInfo,
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