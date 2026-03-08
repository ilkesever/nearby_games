// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Шахматы рядом';

  @override
  String get homeTagline =>
      'Играйте в шахматы с кем-то поблизости\nИнтернет не нужен';

  @override
  String get homeYourName => 'Ваше имя';

  @override
  String get homeInitializingBluetooth => 'Инициализация Bluetooth...';

  @override
  String get homePlayNearby => 'Играть рядом';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth недоступен';

  @override
  String get homeLocalPlay => 'Местная игра (передай и играй)';

  @override
  String get homeBluetoothInfo => 'Использует Bluetooth • Работает офлайн';

  @override
  String get localGameTitle => 'Шахматы — Местная игра';

  @override
  String get localGameNewGame => 'Новая игра';

  @override
  String get localGameWhiteWins => 'Белые выиграли!';

  @override
  String get localGameBlackWins => 'Чёрные выиграли!';

  @override
  String get localGameDraw => 'Ничья!';

  @override
  String get localGameWhiteTurn => 'Ход белых';

  @override
  String get localGameBlackTurn => 'Ход чёрных';

  @override
  String get localGameCheckSuffix => '— ШАХ!';

  @override
  String get localGameTapToStart => 'Нажмите на фигуру, чтобы начать';

  @override
  String get localGamePlayAgain => 'Играть снова';

  @override
  String get drawOfferedTitle => 'Предложена ничья';

  @override
  String get drawOfferedContent => 'Соперник предлагает ничью. Принять?';

  @override
  String get drawDecline => 'Отклонить';

  @override
  String get drawAccept => 'Принять';

  @override
  String get undoRequestedTitle => 'Запрос отмены';

  @override
  String get undoRequestedContent =>
      'Соперник хочет отменить последний ход. Разрешить?';

  @override
  String get undoAllow => 'Разрешить';
}
