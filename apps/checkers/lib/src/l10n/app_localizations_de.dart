// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Dame in der Nähe';

  @override
  String get homeTagline =>
      'Spiele Dame mit jemandem in der Nähe\nKein Internet erforderlich';

  @override
  String get homeYourName => 'Dein Name';

  @override
  String get homeInitializingBluetooth => 'Bluetooth wird initialisiert…';

  @override
  String get homePlayNearby => 'In der Nähe spielen';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth nicht verfügbar';

  @override
  String get homeLocalPlay => 'Lokales Spiel (Weitergeben & spielen)';

  @override
  String get homeBluetoothInfo => 'Nutzt Bluetooth • Funktioniert offline';

  @override
  String get localGameTitle => 'Dame — Lokales Spiel';

  @override
  String get localGameNewGame => 'Neues Spiel';

  @override
  String get localGameWhiteWins => 'Weiß gewinnt!';

  @override
  String get localGameBlackWins => 'Schwarz gewinnt!';

  @override
  String get localGameWhiteTurn => 'Weiß ist dran';

  @override
  String get localGameBlackTurn => 'Schwarz ist dran';

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
  String get scoreWhite => 'Weiß';

  @override
  String get scoreBlack => 'Schwarz';
}
