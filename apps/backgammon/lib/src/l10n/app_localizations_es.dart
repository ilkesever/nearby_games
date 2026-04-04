// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Backgammon Cercano';

  @override
  String get homeTagline =>
      'Juega al backgammon con alguien cercano\nSin internet';

  @override
  String get homeYourName => 'Tu nombre';

  @override
  String get homeInitializingBluetooth => 'Inicializando Bluetooth...';

  @override
  String get homePlayNearby => 'Jugar cerca';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth no disponible';

  @override
  String get homeLocalPlay => 'Juego local (pasar y jugar)';

  @override
  String get homeBluetoothInfo => 'Usa Bluetooth • Funciona sin conexión';

  @override
  String get localGameTitle => 'Backgammon — Juego local';

  @override
  String get localGameNewGame => 'Nuevo juego';

  @override
  String get localGameRollDice => 'Lanzar dados';

  @override
  String get localGameWhiteWins => '¡Blancas ganan!';

  @override
  String get localGameBlackWins => '¡Negras ganan!';

  @override
  String get localGameWhiteTurn => 'Turno de blancas';

  @override
  String get localGameBlackTurn => 'Turno de negras';

  @override
  String get localGameBar => 'Barra';

  @override
  String get localGameBearOff => 'Sacar fichas';

  @override
  String get localGameNoMoves => 'Sin movimientos disponibles — pasa el turno';

  @override
  String get localGamePlayAgain => 'Jugar de nuevo';

  @override
  String get drawOfferedTitle => 'Oferta de tablas';

  @override
  String get drawOfferedContent => 'Tu oponente ofrece tablas. ¿Aceptar?';

  @override
  String get drawDecline => 'Rechazar';

  @override
  String get drawAccept => 'Aceptar';

  @override
  String get undoRequestedTitle => 'Deshacer solicitado';

  @override
  String get undoRequestedContent =>
      'Tu oponente quiere deshacer su último movimiento. ¿Permitir?';

  @override
  String get undoAllow => 'Permitir';
}
