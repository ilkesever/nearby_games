// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Dames à proximité';

  @override
  String get homeTagline =>
      'Jouez aux dames avec quelqu\'un à proximité\nSans internet';

  @override
  String get homeYourName => 'Votre nom';

  @override
  String get homeInitializingBluetooth => 'Initialisation du Bluetooth…';

  @override
  String get homePlayNearby => 'Jouer à proximité';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth indisponible';

  @override
  String get homeLocalPlay => 'Jeu local (Passer & jouer)';

  @override
  String get homeBluetoothInfo =>
      'Utilise le Bluetooth • Fonctionne hors ligne';

  @override
  String get localGameTitle => 'Dames — Jeu local';

  @override
  String get localGameNewGame => 'Nouvelle partie';

  @override
  String get localGameWhiteWins => 'Les blancs gagnent !';

  @override
  String get localGameBlackWins => 'Les noirs gagnent !';

  @override
  String get localGameWhiteTurn => 'Tour des blancs';

  @override
  String get localGameBlackTurn => 'Tour des noirs';

  @override
  String get localGamePlayAgain => 'Rejouer';

  @override
  String get drawOfferedTitle => 'Nulle proposée';

  @override
  String get drawOfferedContent =>
      'Votre adversaire propose une nulle. Accepter ?';

  @override
  String get drawDecline => 'Refuser';

  @override
  String get drawAccept => 'Accepter';

  @override
  String get scoreWhite => 'Blancs';

  @override
  String get scoreBlack => 'Noirs';
}
