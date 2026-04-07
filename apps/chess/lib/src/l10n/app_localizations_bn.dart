// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'কাছের দাবা';

  @override
  String get homeTagline => 'কাছের কারো সাথে দাবা খেলুন\nইন্টারনেট ছাড়াই';

  @override
  String get homeYourName => 'আপনার নাম';

  @override
  String get homeInitializingBluetooth => 'ব্লুটুথ চালু হচ্ছে...';

  @override
  String get homePlayNearby => 'কাছে খেলুন';

  @override
  String get homeBluetoothUnavailable => 'ব্লুটুথ অনুপলব্ধ';

  @override
  String get homeLocalPlay => 'স্থানীয় খেলা (পাস করে খেলুন)';

  @override
  String get homeBluetoothInfo => 'ব্লুটুথ ব্যবহার করে • অফলাইনে কাজ করে';

  @override
  String get localGameTitle => 'দাবা — স্থানীয় খেলা';

  @override
  String get localGameNewGame => 'নতুন গেম';

  @override
  String get localGameWhiteWins => 'সাদা জিতেছে!';

  @override
  String get localGameBlackWins => 'কালো জিতেছে!';

  @override
  String get localGameDraw => 'ড্র!';

  @override
  String get localGameWhiteTurn => 'সাদার পালা';

  @override
  String get localGameBlackTurn => 'কালোর পালা';

  @override
  String get localGameCheckSuffix => '— কিস্তি!';

  @override
  String get localGameTapToStart => 'খেলা শুরু করতে একটি ঘুঁটি ছুঁয়ে দিন';

  @override
  String get localGamePlayAgain => 'আবার খেলুন';

  @override
  String get drawOfferedTitle => 'ড্র অফার';

  @override
  String get drawOfferedContent =>
      'আপনার প্রতিপক্ষ ড্র প্রস্তাব করছে। গ্রহণ করবেন?';

  @override
  String get drawDecline => 'প্রত্যাখ্যান করুন';

  @override
  String get drawAccept => 'গ্রহণ করুন';
}
