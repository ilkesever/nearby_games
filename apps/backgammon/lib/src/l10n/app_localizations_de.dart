// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Backgammon in der Nähe';

  @override
  String get homeTagline =>
      'Spiele Backgammon mit jemandem in der Nähe\nKein Internet erforderlich';

  @override
  String get homeYourName => 'Dein Name';

  @override
  String get homeInitializingBluetooth => 'Bluetooth wird initialisiert...';

  @override
  String get homePlayNearby => 'In der Nähe spielen';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth nicht verfügbar';

  @override
  String get homeLocalPlay => 'Lokales Spiel (Weitergeben und Spielen)';

  @override
  String get homeBluetoothInfo => 'Verwendet Bluetooth • Funktioniert offline';

  @override
  String get localGameTitle => 'Backgammon — Lokales Spiel';

  @override
  String get localGameNewGame => 'Neues Spiel';

  @override
  String get localGameRollDice => 'Würfeln';

  @override
  String get localGameWhiteWins => 'Weiß gewinnt!';

  @override
  String get localGameBlackWins => 'Schwarz gewinnt!';

  @override
  String get localGameWhiteTurn => 'Weiß ist dran';

  @override
  String get localGameBlackTurn => 'Schwarz ist dran';

  @override
  String get localGameBar => 'Bar';

  @override
  String get localGameBearOff => 'Steine auswürfeln';

  @override
  String get localGameNoMoves => 'Keine Züge möglich — Zug wird übersprungen';

  @override
  String get localGamePlayAgain => 'Nochmal spielen';

  @override
  String get drawOfferedTitle => 'Remis angeboten';

  @override
  String get drawOfferedContent => 'Dein Gegner bietet Remis an. Annehmen?';

  @override
  String get drawDecline => 'Ablehnen';

  @override
  String get drawAccept => 'Annehmen';

  @override
  String get openingRollTitle => 'Anfangswurf';

  @override
  String get openingRollInstruction =>
      'Jeder Spieler würfelt — der Höchste beginnt';

  @override
  String get openingRollTie => 'Unentschieden! Nochmal würfeln';

  @override
  String openingRollGoesFirst(String color) {
    return '$color beginnt!';
  }

  @override
  String get scoreWhite => 'Weiß';

  @override
  String get scoreBlack => 'Schwarz';
}
