// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'طاولة قريبة';

  @override
  String get homeTagline => 'العب الطاولة مع شخص قريب منك\nلا يتطلب إنترنت';

  @override
  String get homeYourName => 'اسمك';

  @override
  String get homeInitializingBluetooth => 'جارٍ تهيئة البلوتوث...';

  @override
  String get homePlayNearby => 'العب قريباً';

  @override
  String get homeBluetoothUnavailable => 'البلوتوث غير متاح';

  @override
  String get homeLocalPlay => 'لعب محلي (تمرير واللعب)';

  @override
  String get homeBluetoothInfo => 'يستخدم البلوتوث • يعمل دون اتصال';

  @override
  String get localGameTitle => 'الطاولة — لعب محلي';

  @override
  String get localGameNewGame => 'لعبة جديدة';

  @override
  String get localGameRollDice => 'رمي النرد';

  @override
  String get localGameWhiteWins => 'الأبيض يفوز!';

  @override
  String get localGameBlackWins => 'الأسود يفوز!';

  @override
  String get localGameWhiteTurn => 'دور الأبيض';

  @override
  String get localGameBlackTurn => 'دور الأسود';

  @override
  String get localGameBar => 'الشريط';

  @override
  String get localGameBearOff => 'إخراج القطع';

  @override
  String get localGameNoMoves => 'لا توجد حركات متاحة — تخطي الدور';

  @override
  String get localGamePlayAgain => 'العب مجدداً';

  @override
  String get drawOfferedTitle => 'عرض التعادل';

  @override
  String get drawOfferedContent => 'خصمك يعرض التعادل. قبول؟';

  @override
  String get drawDecline => 'رفض';

  @override
  String get drawAccept => 'قبول';

  @override
  String get openingRollTitle => 'رمي البداية';

  @override
  String get openingRollInstruction => 'يرمي كل لاعب — الأعلى يبدأ أولاً';

  @override
  String get openingRollTie => 'تعادل! ارمِ مجدداً';

  @override
  String openingRollGoesFirst(String color) {
    return '$color يبدأ أولاً!';
  }

  @override
  String get scoreWhite => 'الأبيض';

  @override
  String get scoreBlack => 'الأسود';

  @override
  String get openingRollYourTurn => 'دورك — اضغط لرمي النرد';

  @override
  String get openingRollBlackToRoll => 'دور الأسود للرمي…';

  @override
  String get openingRollWhiteToRoll => 'دور الأبيض للرمي…';

  @override
  String get openingRollTapToRoll => 'اضغط على نردك لرمي';

  @override
  String get openingRollWaitingForOpponent => 'بانتظار الخصم…';

  @override
  String boreOffLabel(String color) {
    return '$color أخرج: ';
  }

  @override
  String get moveUndo => 'تراجع';

  @override
  String get moveDone => 'تم';

  @override
  String get opponentPlaying => 'الخصم يلعب…';
}
