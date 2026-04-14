// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nearby Checkers';

  @override
  String get homeTagline =>
      'Play checkers with someone nearby\nNo internet required';

  @override
  String get homeYourName => 'Your Name';

  @override
  String get homeInitializingBluetooth => 'Initializing Bluetooth...';

  @override
  String get homePlayNearby => 'Play Nearby';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth unavailable';

  @override
  String get homeLocalPlay => 'Local Play (Pass & Play)';

  @override
  String get homeBluetoothInfo => 'Uses Bluetooth • Works offline';

  @override
  String get localGameTitle => 'Checkers — Local Play';

  @override
  String get localGameNewGame => 'New Game';

  @override
  String get localGameWhiteWins => 'White wins!';

  @override
  String get localGameBlackWins => 'Black wins!';

  @override
  String get localGameWhiteTurn => 'White\'s turn';

  @override
  String get localGameBlackTurn => 'Black\'s turn';

  @override
  String get localGamePlayAgain => 'Play Again';

  @override
  String get drawOfferedTitle => 'Draw Offered';

  @override
  String get drawOfferedContent => 'Your opponent is offering a draw. Accept?';

  @override
  String get drawDecline => 'Decline';

  @override
  String get drawAccept => 'Accept';

  @override
  String get scoreWhite => 'White';

  @override
  String get scoreBlack => 'Black';
}
