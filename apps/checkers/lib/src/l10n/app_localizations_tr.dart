// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Yakın Dama';

  @override
  String get homeTagline => 'Yakınındaki biriyle dama oyna\nİnternet gerekmez';

  @override
  String get homeYourName => 'Adınız';

  @override
  String get homeInitializingBluetooth => 'Bluetooth başlatılıyor…';

  @override
  String get homePlayNearby => 'Yakında oyna';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth kullanılamıyor';

  @override
  String get homeLocalPlay => 'Yerel oyun (Geçir ve oyna)';

  @override
  String get homeBluetoothInfo => 'Bluetooth kullanır • Çevrimdışı çalışır';

  @override
  String get localGameTitle => 'Dama — Yerel Oyun';

  @override
  String get localGameNewGame => 'Yeni oyun';

  @override
  String get localGameWhiteWins => 'Beyaz kazandı!';

  @override
  String get localGameBlackWins => 'Siyah kazandı!';

  @override
  String get localGameWhiteTurn => 'Beyazın sırası';

  @override
  String get localGameBlackTurn => 'Siyahın sırası';

  @override
  String get localGamePlayAgain => 'Tekrar oyna';

  @override
  String get drawOfferedTitle => 'Beraberlik teklifi';

  @override
  String get drawOfferedContent =>
      'Rakibiniz beraberlik teklif etti. Kabul et?';

  @override
  String get drawDecline => 'Reddet';

  @override
  String get drawAccept => 'Kabul et';

  @override
  String get scoreWhite => 'Beyaz';

  @override
  String get scoreBlack => 'Siyah';
}
