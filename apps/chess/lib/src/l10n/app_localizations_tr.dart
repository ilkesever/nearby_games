// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Yakın Satranç';

  @override
  String get homeTagline =>
      'Yakınızdaki biriyle satranç oynayın\nİnternet gerekmez';

  @override
  String get homeYourName => 'Adınız';

  @override
  String get homeInitializingBluetooth => 'Bluetooth başlatılıyor...';

  @override
  String get homePlayNearby => 'Yakında Oyna';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth kullanılamıyor';

  @override
  String get homeLocalPlay => 'Yerel Oyun (Geçir ve Oyna)';

  @override
  String get homeBluetoothInfo => 'Bluetooth kullanır • Çevrimdışı çalışır';

  @override
  String get localGameTitle => 'Satranç — Yerel Oyun';

  @override
  String get localGameNewGame => 'Yeni Oyun';

  @override
  String get localGameWhiteWins => 'Beyaz kazandı!';

  @override
  String get localGameBlackWins => 'Siyah kazandı!';

  @override
  String get localGameDraw => 'Beraberlik!';

  @override
  String get localGameWhiteTurn => 'Beyazın hamlesi';

  @override
  String get localGameBlackTurn => 'Siyahın hamlesi';

  @override
  String get localGameCheckSuffix => '— ŞAH!';

  @override
  String get localGameTapToStart => 'Oynamaya başlamak için bir taşa dokun';

  @override
  String get localGamePlayAgain => 'Tekrar Oyna';

  @override
  String get drawOfferedTitle => 'Beraberlik Teklifi';

  @override
  String get drawOfferedContent =>
      'Rakibiniz beraberlik teklif ediyor. Kabul et?';

  @override
  String get drawDecline => 'Reddet';

  @override
  String get drawAccept => 'Kabul Et';

  @override
  String get undoRequestedTitle => 'Geri Al İsteği';

  @override
  String get undoRequestedContent =>
      'Rakibiniz son hamlesini geri almak istiyor. İzin ver?';

  @override
  String get undoAllow => 'İzin Ver';
}
