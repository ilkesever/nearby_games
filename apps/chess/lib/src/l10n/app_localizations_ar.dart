// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'شطرنج قريب';

  @override
  String get homeTagline => 'العب الشطرنج مع شخص قريب\nلا يلزم إنترنت';

  @override
  String get homeYourName => 'اسمك';

  @override
  String get homeInitializingBluetooth => 'جارٍ تهيئة البلوتوث...';

  @override
  String get homePlayNearby => 'العب قريباً';

  @override
  String get homeBluetoothUnavailable => 'البلوتوث غير متاح';

  @override
  String get homeLocalPlay => 'لعب محلي (مرر والعب)';

  @override
  String get homeBluetoothInfo => 'يستخدم البلوتوث • يعمل بلا إنترنت';

  @override
  String get localGameTitle => 'شطرنج — لعب محلي';

  @override
  String get localGameNewGame => 'لعبة جديدة';

  @override
  String get localGameWhiteWins => 'فاز الأبيض!';

  @override
  String get localGameBlackWins => 'فاز الأسود!';

  @override
  String get localGameDraw => 'تعادل!';

  @override
  String get localGameWhiteTurn => 'دور الأبيض';

  @override
  String get localGameBlackTurn => 'دور الأسود';

  @override
  String get localGameCheckSuffix => '— كش!';

  @override
  String get localGameTapToStart => 'اضغط على قطعة للبدء';

  @override
  String get localGamePlayAgain => 'العب مجدداً';

  @override
  String get drawOfferedTitle => 'عرض تعادل';

  @override
  String get drawOfferedContent => 'منافسك يعرض التعادل. قبول؟';

  @override
  String get drawDecline => 'رفض';

  @override
  String get drawAccept => 'قبول';
}
