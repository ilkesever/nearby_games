// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Yakın Tavla';

  @override
  String get homeTagline => 'Yakınındaki biriyle tavla oyna\nİnternet gerekmez';

  @override
  String get homeYourName => 'Adınız';

  @override
  String get homeInitializingBluetooth => 'Bluetooth başlatılıyor...';

  @override
  String get homePlayNearby => 'Yakında Oyna';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth kullanılamıyor';

  @override
  String get homeLocalPlay => 'Yerel Oyun (Sırayla Oyna)';

  @override
  String get homeBluetoothInfo => 'Bluetooth kullanır • Çevrimdışı çalışır';

  @override
  String get localGameTitle => 'Tavla — Yerel Oyun';

  @override
  String get localGameNewGame => 'Yeni Oyun';

  @override
  String get localGameRollDice => 'Zar At';

  @override
  String get localGameWhiteWins => 'Beyaz kazandı!';

  @override
  String get localGameBlackWins => 'Siyah kazandı!';

  @override
  String get localGameWhiteTurn => 'Beyazın sırası';

  @override
  String get localGameBlackTurn => 'Siyahın sırası';

  @override
  String get localGameBar => 'Bar';

  @override
  String get localGameBearOff => 'Taşları Çıkar';

  @override
  String get localGameNoMoves => 'Geçerli hamle yok — sıra geçiliyor';

  @override
  String get localGamePlayAgain => 'Tekrar Oyna';

  @override
  String get drawOfferedTitle => 'Beraberlik Teklifi';

  @override
  String get drawOfferedContent =>
      'Rakibiniz beraberlik teklif ediyor. Kabul edilsin mi?';

  @override
  String get drawDecline => 'Reddet';

  @override
  String get drawAccept => 'Kabul Et';

  @override
  String get openingRollTitle => 'Açılış Zarı';

  @override
  String get openingRollInstruction =>
      'Her oyuncu zar atar — en yüksek ilk başlar';

  @override
  String get openingRollTie => 'Beraberlik! Tekrar at';

  @override
  String openingRollGoesFirst(String color) {
    return '$color önce başlar!';
  }

  @override
  String get scoreWhite => 'Beyaz';

  @override
  String get scoreBlack => 'Siyah';
}
