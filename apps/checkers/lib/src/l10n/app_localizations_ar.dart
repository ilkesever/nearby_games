// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'داما قريبة';

  @override
  String get homeTagline => 'العب الداما مع شخص قريب منك\nلا يلزم إنترنت';

  @override
  String get homeYourName => 'اسمك';

  @override
  String get homeInitializingBluetooth => 'جارٍ تهيئة البلوتوث…';

  @override
  String get homePlayNearby => 'العب مع القريبين';

  @override
  String get homeBluetoothUnavailable => 'البلوتوث غير متاح';

  @override
  String get homeLocalPlay => 'لعب محلي (تمرير وعب)';

  @override
  String get homeBluetoothInfo => 'يستخدم البلوتوث • يعمل بدون إنترنت';

  @override
  String get localGameTitle => 'داما — لعب محلي';

  @override
  String get localGameNewGame => 'لعبة جديدة';

  @override
  String get localGameWhiteWins => 'الأبيض يفوز!';

  @override
  String get localGameBlackWins => 'الأسود يفوز!';

  @override
  String get localGameWhiteTurn => 'دور الأبيض';

  @override
  String get localGameBlackTurn => 'دور الأسود';

  @override
  String get localGamePlayAgain => 'العب مجدداً';

  @override
  String get drawOfferedTitle => 'عرض تعادل';

  @override
  String get drawOfferedContent => 'خصمك يعرض التعادل. هل تقبل؟';

  @override
  String get drawDecline => 'رفض';

  @override
  String get drawAccept => 'قبول';

  @override
  String get scoreWhite => 'أبيض';

  @override
  String get scoreBlack => 'أسود';
}
