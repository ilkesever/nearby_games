// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Nearby Schach';

  @override
  String get homeTagline =>
      'Schach mit jemandem in der Nähe spielen\nKein Internet erforderlich';

  @override
  String get homeYourName => 'Dein Name';

  @override
  String get homeInitializingBluetooth => 'Bluetooth wird initialisiert...';

  @override
  String get homePlayNearby => 'In der Nähe spielen';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth nicht verfügbar';

  @override
  String get homeLocalPlay => 'Lokales Spiel (Pass & Play)';

  @override
  String get homeBluetoothInfo => 'Verwendet Bluetooth • Funktioniert offline';

  @override
  String get localGameTitle => 'Schach — Lokales Spiel';

  @override
  String get localGameNewGame => 'Neues Spiel';

  @override
  String get localGameWhiteWins => 'Weiß gewinnt!';

  @override
  String get localGameBlackWins => 'Schwarz gewinnt!';

  @override
  String get localGameDraw => 'Unentschieden!';

  @override
  String get localGameWhiteTurn => 'Weiß ist dran';

  @override
  String get localGameBlackTurn => 'Schwarz ist dran';

  @override
  String get localGameCheckSuffix => '— SCHACH!';

  @override
  String get localGameTapToStart => 'Tippe auf eine Figur, um zu spielen';

  @override
  String get localGamePlayAgain => 'Nochmal spielen';

  @override
  String get drawOfferedTitle => 'Remis angeboten';

  @override
  String get drawOfferedContent => 'Dein Gegner bietet ein Remis an. Annehmen?';

  @override
  String get drawDecline => 'Ablehnen';

  @override
  String get drawAccept => 'Annehmen';
}
