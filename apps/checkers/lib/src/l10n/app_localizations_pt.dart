// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Damas por Perto';

  @override
  String get homeTagline =>
      'Jogue damas com alguém próximo\nSem internet necessária';

  @override
  String get homeYourName => 'Seu nome';

  @override
  String get homeInitializingBluetooth => 'Iniciando Bluetooth…';

  @override
  String get homePlayNearby => 'Jogar por perto';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth indisponível';

  @override
  String get homeLocalPlay => 'Jogo local (Passar e jogar)';

  @override
  String get homeBluetoothInfo => 'Usa Bluetooth • Funciona offline';

  @override
  String get localGameTitle => 'Damas — Jogo local';

  @override
  String get localGameNewGame => 'Nova partida';

  @override
  String get localGameWhiteWins => 'Brancas venceram!';

  @override
  String get localGameBlackWins => 'Negras venceram!';

  @override
  String get localGameWhiteTurn => 'Vez das brancas';

  @override
  String get localGameBlackTurn => 'Vez das negras';

  @override
  String get localGamePlayAgain => 'Jogar novamente';

  @override
  String get drawOfferedTitle => 'Empate oferecido';

  @override
  String get drawOfferedContent =>
      'Seu adversário está oferecendo empate. Aceitar?';

  @override
  String get drawDecline => 'Recusar';

  @override
  String get drawAccept => 'Aceitar';

  @override
  String get scoreWhite => 'Brancas';

  @override
  String get scoreBlack => 'Negras';
}
