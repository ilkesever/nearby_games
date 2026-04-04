// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Gamão Próximo';

  @override
  String get homeTagline =>
      'Jogue gamão com alguém por perto\nSem internet necessária';

  @override
  String get homeYourName => 'Seu nome';

  @override
  String get homeInitializingBluetooth => 'Inicializando Bluetooth...';

  @override
  String get homePlayNearby => 'Jogar por perto';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth indisponível';

  @override
  String get homeLocalPlay => 'Jogo local (passar e jogar)';

  @override
  String get homeBluetoothInfo => 'Usa Bluetooth • Funciona offline';

  @override
  String get localGameTitle => 'Gamão — Jogo local';

  @override
  String get localGameNewGame => 'Novo jogo';

  @override
  String get localGameRollDice => 'Lançar dados';

  @override
  String get localGameWhiteWins => 'Brancas vencem!';

  @override
  String get localGameBlackWins => 'Pretas vencem!';

  @override
  String get localGameWhiteTurn => 'Vez das brancas';

  @override
  String get localGameBlackTurn => 'Vez das pretas';

  @override
  String get localGameBar => 'Barra';

  @override
  String get localGameBearOff => 'Tirar peças';

  @override
  String get localGameNoMoves => 'Sem movimentos disponíveis — passando a vez';

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

  @override
  String get undoRequestedTitle => 'Desfazer solicitado';

  @override
  String get undoRequestedContent =>
      'Seu oponente quer desfazer o último movimento. Permitir?';

  @override
  String get undoAllow => 'Permitir';
}
