// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Xadrez próximo';

  @override
  String get homeTagline => 'Jogue xadrez com alguém próximo\nSem internet';

  @override
  String get homeYourName => 'Seu nome';

  @override
  String get homeInitializingBluetooth => 'Inicializando Bluetooth...';

  @override
  String get homePlayNearby => 'Jogar próximo';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth indisponível';

  @override
  String get homeLocalPlay => 'Jogo local (passar e jogar)';

  @override
  String get homeBluetoothInfo => 'Usa Bluetooth • Funciona offline';

  @override
  String get localGameTitle => 'Xadrez — Jogo local';

  @override
  String get localGameNewGame => 'Nova partida';

  @override
  String get localGameWhiteWins => 'Brancas vencem!';

  @override
  String get localGameBlackWins => 'Pretas vencem!';

  @override
  String get localGameDraw => 'Empate!';

  @override
  String get localGameWhiteTurn => 'Vez das brancas';

  @override
  String get localGameBlackTurn => 'Vez das pretas';

  @override
  String get localGameCheckSuffix => '— XEQUE!';

  @override
  String get localGameTapToStart => 'Toque em uma peça para começar';

  @override
  String get localGamePlayAgain => 'Jogar novamente';

  @override
  String get drawOfferedTitle => 'Empate oferecido';

  @override
  String get drawOfferedContent =>
      'Seu oponente está oferecendo empate. Aceitar?';

  @override
  String get drawDecline => 'Recusar';

  @override
  String get drawAccept => 'Aceitar';
}
