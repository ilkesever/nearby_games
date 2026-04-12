// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'नजदीकी बैकगैमन';

  @override
  String get homeTagline =>
      'पास के किसी व्यक्ति के साथ बैकगैमन खेलें\nइंटरनेट की जरूरत नहीं';

  @override
  String get homeYourName => 'आपका नाम';

  @override
  String get homeInitializingBluetooth => 'ब्लूटूथ शुरू हो रहा है...';

  @override
  String get homePlayNearby => 'पास में खेलें';

  @override
  String get homeBluetoothUnavailable => 'ब्लूटूथ उपलब्ध नहीं';

  @override
  String get homeLocalPlay => 'स्थानीय खेल (पास और खेलें)';

  @override
  String get homeBluetoothInfo => 'ब्लूटूथ उपयोग करता है • ऑफलाइन काम करता है';

  @override
  String get localGameTitle => 'बैकगैमन — स्थानीय खेल';

  @override
  String get localGameNewGame => 'नया खेल';

  @override
  String get localGameRollDice => 'पासे फेंकें';

  @override
  String get localGameWhiteWins => 'सफेद जीत गया!';

  @override
  String get localGameBlackWins => 'काला जीत गया!';

  @override
  String get localGameWhiteTurn => 'सफेद की बारी';

  @override
  String get localGameBlackTurn => 'काले की बारी';

  @override
  String get localGameBar => 'बार';

  @override
  String get localGameBearOff => 'बाहर निकालें';

  @override
  String get localGameNoMoves => 'कोई चाल उपलब्ध नहीं — बारी छोड़ें';

  @override
  String get localGamePlayAgain => 'फिर खेलें';

  @override
  String get drawOfferedTitle => 'ड्रॉ का प्रस्ताव';

  @override
  String get drawOfferedContent =>
      'आपके प्रतिद्वंद्वी ने ड्रॉ का प्रस्ताव दिया। स्वीकार करें?';

  @override
  String get drawDecline => 'अस्वीकार करें';

  @override
  String get drawAccept => 'स्वीकार करें';

  @override
  String get openingRollTitle => 'शुरुआती रोल';

  @override
  String get openingRollInstruction =>
      'हर खिलाड़ी रोल करने के लिए टैप करे — सबसे ऊँचा पहले चलेगा';

  @override
  String get openingRollTie => 'बराबरी! फिर से रोल करें';

  @override
  String openingRollGoesFirst(String color) {
    return '$color पहले चलेगा!';
  }

  @override
  String get scoreWhite => 'सफेद';

  @override
  String get scoreBlack => 'काला';

  @override
  String get openingRollYourTurn => 'आपकी बारी — रोल करने के लिए टैप करें';

  @override
  String get openingRollBlackToRoll => 'काले का रोल…';

  @override
  String get openingRollWhiteToRoll => 'सफेद का रोल…';

  @override
  String get openingRollTapToRoll => 'रोल करने के लिए अपना पासा टैप करें';

  @override
  String get openingRollWaitingForOpponent => 'प्रतिद्वंद्वी की प्रतीक्षा…';

  @override
  String boreOffLabel(String color) {
    return '$color बाहर: ';
  }

  @override
  String get moveUndo => 'वापस';

  @override
  String get moveDone => 'पूर्ण';

  @override
  String get opponentPlaying => 'प्रतिद्वंद्वी खेल रहा है…';
}
