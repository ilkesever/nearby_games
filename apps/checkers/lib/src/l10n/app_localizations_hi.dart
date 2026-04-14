// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'नजदीकी चेकर्स';

  @override
  String get homeTagline =>
      'पास के किसी व्यक्ति के साथ चेकर्स खेलें\nइंटरनेट की जरूरत नहीं';

  @override
  String get homeYourName => 'आपका नाम';

  @override
  String get homeInitializingBluetooth => 'ब्लूटूथ प्रारंभ हो रहा है…';

  @override
  String get homePlayNearby => 'पास में खेलें';

  @override
  String get homeBluetoothUnavailable => 'ब्लूटूथ अनुपलब्ध';

  @override
  String get homeLocalPlay => 'स्थानीय खेल (पास और खेलें)';

  @override
  String get homeBluetoothInfo => 'ब्लूटूथ उपयोग करता है • ऑफलाइन काम करता है';

  @override
  String get localGameTitle => 'चेकर्स — स्थानीय खेल';

  @override
  String get localGameNewGame => 'नया खेल';

  @override
  String get localGameWhiteWins => 'सफेद जीता!';

  @override
  String get localGameBlackWins => 'काला जीता!';

  @override
  String get localGameWhiteTurn => 'सफेद की बारी';

  @override
  String get localGameBlackTurn => 'काले की बारी';

  @override
  String get localGamePlayAgain => 'फिर खेलें';

  @override
  String get drawOfferedTitle => 'ड्रॉ प्रस्ताव';

  @override
  String get drawOfferedContent =>
      'आपके प्रतिद्वंद्वी ने ड्रॉ का प्रस्ताव दिया है। स्वीकार करें?';

  @override
  String get drawDecline => 'अस्वीकार';

  @override
  String get drawAccept => 'स्वीकार';

  @override
  String get scoreWhite => 'सफेद';

  @override
  String get scoreBlack => 'काला';
}
