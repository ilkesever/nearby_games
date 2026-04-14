// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Damas Cercanas';

  @override
  String get homeTagline =>
      'Juega a las damas con alguien cercano\nSin internet necesario';

  @override
  String get homeYourName => 'Tu nombre';

  @override
  String get homeInitializingBluetooth => 'Iniciando Bluetooth…';

  @override
  String get homePlayNearby => 'Jugar cerca';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth no disponible';

  @override
  String get homeLocalPlay => 'Juego local (Pasar y jugar)';

  @override
  String get homeBluetoothInfo => 'Usa Bluetooth • Funciona sin internet';

  @override
  String get localGameTitle => 'Damas — Juego local';

  @override
  String get localGameNewGame => 'Nueva partida';

  @override
  String get localGameWhiteWins => '¡Ganan las blancas!';

  @override
  String get localGameBlackWins => '¡Ganan las negras!';

  @override
  String get localGameWhiteTurn => 'Turno de blancas';

  @override
  String get localGameBlackTurn => 'Turno de negras';

  @override
  String get localGamePlayAgain => 'Jugar de nuevo';

  @override
  String get drawOfferedTitle => 'Tablas ofrecidas';

  @override
  String get drawOfferedContent => 'Tu rival ofrece tablas. ¿Aceptar?';

  @override
  String get drawDecline => 'Rechazar';

  @override
  String get drawAccept => 'Aceptar';

  @override
  String get scoreWhite => 'Blancas';

  @override
  String get scoreBlack => 'Negras';
}
