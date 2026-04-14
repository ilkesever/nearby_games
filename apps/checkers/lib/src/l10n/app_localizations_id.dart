// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Catur Dam Terdekat';

  @override
  String get homeTagline =>
      'Bermain catur dam dengan seseorang di dekat Anda\nTanpa internet';

  @override
  String get homeYourName => 'Nama Anda';

  @override
  String get homeInitializingBluetooth => 'Menginisialisasi Bluetooth…';

  @override
  String get homePlayNearby => 'Bermain di dekat sini';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth tidak tersedia';

  @override
  String get homeLocalPlay => 'Permainan lokal (Serahkan & mainkan)';

  @override
  String get homeBluetoothInfo => 'Menggunakan Bluetooth • Bekerja offline';

  @override
  String get localGameTitle => 'Catur Dam — Permainan Lokal';

  @override
  String get localGameNewGame => 'Permainan baru';

  @override
  String get localGameWhiteWins => 'Putih menang!';

  @override
  String get localGameBlackWins => 'Hitam menang!';

  @override
  String get localGameWhiteTurn => 'Giliran putih';

  @override
  String get localGameBlackTurn => 'Giliran hitam';

  @override
  String get localGamePlayAgain => 'Main lagi';

  @override
  String get drawOfferedTitle => 'Tawaran seri';

  @override
  String get drawOfferedContent => 'Lawan Anda menawarkan seri. Terima?';

  @override
  String get drawDecline => 'Tolak';

  @override
  String get drawAccept => 'Terima';

  @override
  String get scoreWhite => 'Putih';

  @override
  String get scoreBlack => 'Hitam';
}
