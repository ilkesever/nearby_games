// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nearby Backgammon';

  @override
  String get homeTagline =>
      'Play backgammon with someone nearby\nNo internet required';

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
  String get localGameTitle => 'Backgammon — Local Play';

  @override
  String get localGameNewGame => 'New Game';

  @override
  String get localGameRollDice => 'Roll Dice';

  @override
  String get localGameWhiteWins => 'White wins!';

  @override
  String get localGameBlackWins => 'Black wins!';

  @override
  String get localGameWhiteTurn => 'White\'s turn';

  @override
  String get localGameBlackTurn => 'Black\'s turn';

  @override
  String get localGameBar => 'Bar';

  @override
  String get localGameBearOff => 'Bear Off';

  @override
  String get localGameNoMoves => 'No moves available — passing turn';

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
  String get openingRollTitle => 'Opening Roll';

  @override
  String get openingRollInstruction =>
      'Each player taps to roll — highest goes first';

  @override
  String get openingRollTie => 'Tie! Roll again';

  @override
  String openingRollGoesFirst(String color) {
    return '$color goes first!';
  }

  @override
  String get scoreWhite => 'White';

  @override
  String get scoreBlack => 'Black';

  @override
  String get openingRollYourTurn => 'Your turn — tap to roll';

  @override
  String get openingRollBlackToRoll => 'Black to roll…';

  @override
  String get openingRollWhiteToRoll => 'White to roll…';

  @override
  String get openingRollTapToRoll => 'Tap your die to roll';

  @override
  String get openingRollWaitingForOpponent => 'Waiting for opponent…';

  @override
  String boreOffLabel(String color) {
    return '$color bore off: ';
  }

  @override
  String get moveUndo => 'Undo';

  @override
  String get moveDone => 'Done';

  @override
  String get opponentPlaying => 'Opponent is playing…';
}
