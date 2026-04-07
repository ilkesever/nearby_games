// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Catur Terdekat';

  @override
  String get homeTagline =>
      'Bermain catur dengan seseorang di dekatmu\nTanpa internet';

  @override
  String get homeYourName => 'Namamu';

  @override
  String get homeInitializingBluetooth => 'Menginisialisasi Bluetooth...';

  @override
  String get homePlayNearby => 'Main Terdekat';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth tidak tersedia';

  @override
  String get homeLocalPlay => 'Main Lokal (Giliran Bergantian)';

  @override
  String get homeBluetoothInfo => 'Menggunakan Bluetooth • Bekerja offline';

  @override
  String get localGameTitle => 'Catur — Main Lokal';

  @override
  String get localGameNewGame => 'Permainan Baru';

  @override
  String get localGameWhiteWins => 'Putih menang!';

  @override
  String get localGameBlackWins => 'Hitam menang!';

  @override
  String get localGameDraw => 'Remis!';

  @override
  String get localGameWhiteTurn => 'Giliran Putih';

  @override
  String get localGameBlackTurn => 'Giliran Hitam';

  @override
  String get localGameCheckSuffix => '— SKAK!';

  @override
  String get localGameTapToStart => 'Ketuk sebuah bidak untuk mulai bermain';

  @override
  String get localGamePlayAgain => 'Main Lagi';

  @override
  String get drawOfferedTitle => 'Remis Ditawarkan';

  @override
  String get drawOfferedContent => 'Lawan menawarkan remis. Terima?';

  @override
  String get drawDecline => 'Tolak';

  @override
  String get drawAccept => 'Terima';
}
