// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Backgammon Terdekat';

  @override
  String get homeTagline =>
      'Mainkan backgammon dengan seseorang di dekatmu\nTanpa internet';

  @override
  String get homeYourName => 'Nama Anda';

  @override
  String get homeInitializingBluetooth => 'Menginisialisasi Bluetooth...';

  @override
  String get homePlayNearby => 'Bermain Terdekat';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth tidak tersedia';

  @override
  String get homeLocalPlay => 'Permainan Lokal (Bergantian)';

  @override
  String get homeBluetoothInfo => 'Menggunakan Bluetooth • Bekerja offline';

  @override
  String get localGameTitle => 'Backgammon — Permainan Lokal';

  @override
  String get localGameNewGame => 'Permainan Baru';

  @override
  String get localGameRollDice => 'Lempar Dadu';

  @override
  String get localGameWhiteWins => 'Putih menang!';

  @override
  String get localGameBlackWins => 'Hitam menang!';

  @override
  String get localGameWhiteTurn => 'Giliran putih';

  @override
  String get localGameBlackTurn => 'Giliran hitam';

  @override
  String get localGameBar => 'Bar';

  @override
  String get localGameBearOff => 'Keluarkan Pion';

  @override
  String get localGameNoMoves => 'Tidak ada gerakan tersedia — lewati giliran';

  @override
  String get localGamePlayAgain => 'Main Lagi';

  @override
  String get drawOfferedTitle => 'Penawaran Seri';

  @override
  String get drawOfferedContent => 'Lawan Anda menawarkan seri. Terima?';

  @override
  String get drawDecline => 'Tolak';

  @override
  String get drawAccept => 'Terima';

  @override
  String get openingRollTitle => 'Lemparan Awal';

  @override
  String get openingRollInstruction =>
      'Setiap pemain melempar — angka tertinggi mulai duluan';

  @override
  String get openingRollTie => 'Seri! Lempar lagi';

  @override
  String openingRollGoesFirst(String color) {
    return '$color mulai duluan!';
  }

  @override
  String get scoreWhite => 'Putih';

  @override
  String get scoreBlack => 'Hitam';
}
