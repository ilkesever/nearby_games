// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Backgammon Proche';

  @override
  String get homeTagline =>
      'Jouez au backgammon avec quelqu\'un à proximité\nSans internet';

  @override
  String get homeYourName => 'Votre nom';

  @override
  String get homeInitializingBluetooth => 'Initialisation du Bluetooth...';

  @override
  String get homePlayNearby => 'Jouer à proximité';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth indisponible';

  @override
  String get homeLocalPlay => 'Jeu local (passer et jouer)';

  @override
  String get homeBluetoothInfo =>
      'Utilise le Bluetooth • Fonctionne hors ligne';

  @override
  String get localGameTitle => 'Backgammon — Jeu local';

  @override
  String get localGameNewGame => 'Nouvelle partie';

  @override
  String get localGameRollDice => 'Lancer les dés';

  @override
  String get localGameWhiteWins => 'Les blancs gagnent !';

  @override
  String get localGameBlackWins => 'Les noirs gagnent !';

  @override
  String get localGameWhiteTurn => 'Tour des blancs';

  @override
  String get localGameBlackTurn => 'Tour des noirs';

  @override
  String get localGameBar => 'Barre';

  @override
  String get localGameBearOff => 'Sortie';

  @override
  String get localGameNoMoves => 'Aucun mouvement disponible — passage du tour';

  @override
  String get localGamePlayAgain => 'Rejouer';

  @override
  String get drawOfferedTitle => 'Nulle proposée';

  @override
  String get drawOfferedContent =>
      'Votre adversaire propose la nulle. Accepter ?';

  @override
  String get drawDecline => 'Refuser';

  @override
  String get drawAccept => 'Accepter';

  @override
  String get openingRollTitle => 'Lancer initial';

  @override
  String get openingRollInstruction =>
      'Chaque joueur lance — le plus haut commence';

  @override
  String get openingRollTie => 'Égalité ! Relancez';

  @override
  String openingRollGoesFirst(String color) {
    return '$color commence !';
  }

  @override
  String get scoreWhite => 'Blanc';

  @override
  String get scoreBlack => 'Noir';
}
