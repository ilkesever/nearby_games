// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'নিকটবর্তী ব্যাকগ্যামন';

  @override
  String get homeTagline =>
      'কাছের কারো সাথে ব্যাকগ্যামন খেলুন\nইন্টারনেট ছাড়াই';

  @override
  String get homeYourName => 'আপনার নাম';

  @override
  String get homeInitializingBluetooth => 'ব্লুটুথ শুরু হচ্ছে...';

  @override
  String get homePlayNearby => 'কাছে খেলুন';

  @override
  String get homeBluetoothUnavailable => 'ব্লুটুথ পাওয়া যাচ্ছে না';

  @override
  String get homeLocalPlay => 'স্থানীয় খেলা (পাস অ্যান্ড প্লে)';

  @override
  String get homeBluetoothInfo => 'ব্লুটুথ ব্যবহার করে • অফলাইনে কাজ করে';

  @override
  String get localGameTitle => 'ব্যাকগ্যামন — স্থানীয় খেলা';

  @override
  String get localGameNewGame => 'নতুন খেলা';

  @override
  String get localGameRollDice => 'ছক্কা ফেলুন';

  @override
  String get localGameWhiteWins => 'সাদা জিতেছে!';

  @override
  String get localGameBlackWins => 'কালো জিতেছে!';

  @override
  String get localGameWhiteTurn => 'সাদার পালা';

  @override
  String get localGameBlackTurn => 'কালোর পালা';

  @override
  String get localGameBar => 'বার';

  @override
  String get localGameBearOff => 'বেয়ার অফ';

  @override
  String get localGameNoMoves => 'কোনো চাল নেই — পালা বাদ দেওয়া হচ্ছে';

  @override
  String get localGamePlayAgain => 'আবার খেলুন';

  @override
  String get drawOfferedTitle => 'ড্র প্রস্তাব';

  @override
  String get drawOfferedContent => 'প্রতিপক্ষ ড্র প্রস্তাব করছে। গ্রহণ করবেন?';

  @override
  String get drawDecline => 'প্রত্যাখ্যান';

  @override
  String get drawAccept => 'গ্রহণ';

  @override
  String get openingRollTitle => 'শুরুর রোল';

  @override
  String get openingRollInstruction =>
      'প্রতিটি খেলোয়াড় রোল করতে ট্যাপ করুন — সর্বোচ্চ প্রথমে শুরু করবে';

  @override
  String get openingRollTie => 'টাই! আবার রোল করুন';

  @override
  String openingRollGoesFirst(String color) {
    return '$color প্রথমে শুরু করবে!';
  }

  @override
  String get scoreWhite => 'সাদা';

  @override
  String get scoreBlack => 'কালো';

  @override
  String get openingRollYourTurn => 'আপনার পালা — রোল করতে ট্যাপ করুন';

  @override
  String get openingRollBlackToRoll => 'কালোর রোল…';

  @override
  String get openingRollWhiteToRoll => 'সাদার রোল…';

  @override
  String get openingRollTapToRoll => 'রোল করতে আপনার ছক্কা ট্যাপ করুন';

  @override
  String get openingRollWaitingForOpponent => 'প্রতিপক্ষের অপেক্ষায়…';

  @override
  String boreOffLabel(String color) {
    return '$color বাইরে: ';
  }

  @override
  String get moveUndo => 'পূর্বাবস্থা';

  @override
  String get moveDone => 'সম্পন্ন';

  @override
  String get opponentPlaying => 'প্রতিপক্ষ খেলছে…';
}
