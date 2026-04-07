// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Ajedrez cercano';

  @override
  String get homeTagline =>
      'Juega al ajedrez con alguien cercano\nSin internet';

  @override
  String get homeYourName => 'Tu nombre';

  @override
  String get homeInitializingBluetooth => 'Iniciando Bluetooth...';

  @override
  String get homePlayNearby => 'Jugar cerca';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth no disponible';

  @override
  String get homeLocalPlay => 'Juego local (pasar y jugar)';

  @override
  String get homeBluetoothInfo => 'Usa Bluetooth • Funciona sin conexión';

  @override
  String get localGameTitle => 'Ajedrez — Juego local';

  @override
  String get localGameNewGame => 'Nueva partida';

  @override
  String get localGameWhiteWins => '¡Ganan las blancas!';

  @override
  String get localGameBlackWins => '¡Ganan las negras!';

  @override
  String get localGameDraw => '¡Tablas!';

  @override
  String get localGameWhiteTurn => 'Turno de las blancas';

  @override
  String get localGameBlackTurn => 'Turno de las negras';

  @override
  String get localGameCheckSuffix => '— ¡JAQUE!';

  @override
  String get localGameTapToStart => 'Toca una pieza para empezar';

  @override
  String get localGamePlayAgain => 'Jugar de nuevo';

  @override
  String get drawOfferedTitle => 'Tablas ofrecidas';

  @override
  String get drawOfferedContent => 'Tu oponente ofrece tablas. ¿Aceptar?';

  @override
  String get drawDecline => 'Rechazar';

  @override
  String get drawAccept => 'Aceptar';
}
