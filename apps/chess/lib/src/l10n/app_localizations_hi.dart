// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'नज़दीकी शतरंज';

  @override
  String get homeTagline =>
      'किसी नज़दीकी के साथ शतरंज खेलें\nइंटरनेट की जरूरत नहीं';

  @override
  String get homeYourName => 'आपका नाम';

  @override
  String get homeInitializingBluetooth => 'ब्लूटूथ शुरू हो रहा है...';

  @override
  String get homePlayNearby => 'नज़दीक खेलें';

  @override
  String get homeBluetoothUnavailable => 'ब्लूटूथ उपलब्ध नहीं';

  @override
  String get homeLocalPlay => 'स्थानीय खेल (पास करके खेलें)';

  @override
  String get homeBluetoothInfo => 'ब्लूटूथ का उपयोग • ऑफलाइन काम करता है';

  @override
  String get localGameTitle => 'शतरंज — स्थानीय खेल';

  @override
  String get localGameNewGame => 'नया गेम';

  @override
  String get localGameWhiteWins => 'सफेद जीता!';

  @override
  String get localGameBlackWins => 'काला जीता!';

  @override
  String get localGameDraw => 'ड्रॉ!';

  @override
  String get localGameWhiteTurn => 'सफेद की बारी';

  @override
  String get localGameBlackTurn => 'काले की बारी';

  @override
  String get localGameCheckSuffix => '— शह!';

  @override
  String get localGameTapToStart =>
      'खेलना शुरू करने के लिए एक मोहरे पर टैप करें';

  @override
  String get localGamePlayAgain => 'फिर से खेलें';

  @override
  String get drawOfferedTitle => 'ड्रॉ ऑफर';

  @override
  String get drawOfferedContent =>
      'आपका प्रतिद्वंद्वी ड्रॉ की पेशकश कर रहा है। स्वीकार करें?';

  @override
  String get drawDecline => 'अस्वीकार करें';

  @override
  String get drawAccept => 'स्वीकार करें';

  @override
  String get undoRequestedTitle => 'अनडू का अनुरोध';

  @override
  String get undoRequestedContent =>
      'प्रतिद्वंद्वी अपनी आखिरी चाल वापस लेना चाहता है। अनुमति दें?';

  @override
  String get undoAllow => 'अनुमति दें';
}
