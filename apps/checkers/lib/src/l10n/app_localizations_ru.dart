// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Шашки рядом';

  @override
  String get homeTagline => 'Играйте в шашки с кем-то рядом\nБез интернета';

  @override
  String get homeYourName => 'Ваше имя';

  @override
  String get homeInitializingBluetooth => 'Инициализация Bluetooth…';

  @override
  String get homePlayNearby => 'Играть рядом';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth недоступен';

  @override
  String get homeLocalPlay => 'Локальная игра (Передавай и играй)';

  @override
  String get homeBluetoothInfo => 'Использует Bluetooth • Работает офлайн';

  @override
  String get localGameTitle => 'Шашки — Локальная игра';

  @override
  String get localGameNewGame => 'Новая игра';

  @override
  String get localGameWhiteWins => 'Белые победили!';

  @override
  String get localGameBlackWins => 'Чёрные победили!';

  @override
  String get localGameWhiteTurn => 'Ход белых';

  @override
  String get localGameBlackTurn => 'Ход чёрных';

  @override
  String get localGamePlayAgain => 'Сыграть ещё';

  @override
  String get drawOfferedTitle => 'Предложена ничья';

  @override
  String get drawOfferedContent => 'Ваш соперник предлагает ничью. Принять?';

  @override
  String get drawDecline => 'Отклонить';

  @override
  String get drawAccept => 'Принять';

  @override
  String get scoreWhite => 'Белые';

  @override
  String get scoreBlack => 'Чёрные';
}
