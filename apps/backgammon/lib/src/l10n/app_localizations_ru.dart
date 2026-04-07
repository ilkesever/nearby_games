// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Нарды Рядом';

  @override
  String get homeTagline =>
      'Играйте в нарды с кем-то поблизости\nБез интернета';

  @override
  String get homeYourName => 'Ваше имя';

  @override
  String get homeInitializingBluetooth => 'Инициализация Bluetooth...';

  @override
  String get homePlayNearby => 'Играть рядом';

  @override
  String get homeBluetoothUnavailable => 'Bluetooth недоступен';

  @override
  String get homeLocalPlay => 'Местная игра (передача хода)';

  @override
  String get homeBluetoothInfo => 'Использует Bluetooth • Работает офлайн';

  @override
  String get localGameTitle => 'Нарды — Местная игра';

  @override
  String get localGameNewGame => 'Новая игра';

  @override
  String get localGameRollDice => 'Бросить кубики';

  @override
  String get localGameWhiteWins => 'Белые выиграли!';

  @override
  String get localGameBlackWins => 'Чёрные выиграли!';

  @override
  String get localGameWhiteTurn => 'Ход белых';

  @override
  String get localGameBlackTurn => 'Ход чёрных';

  @override
  String get localGameBar => 'Бар';

  @override
  String get localGameBearOff => 'Выбросить шашки';

  @override
  String get localGameNoMoves => 'Нет доступных ходов — пропуск хода';

  @override
  String get localGamePlayAgain => 'Играть снова';

  @override
  String get drawOfferedTitle => 'Предложение ничьей';

  @override
  String get drawOfferedContent => 'Противник предлагает ничью. Принять?';

  @override
  String get drawDecline => 'Отклонить';

  @override
  String get drawAccept => 'Принять';

  @override
  String get openingRollTitle => 'Начальный бросок';

  @override
  String get openingRollInstruction =>
      'Каждый игрок бросает — у кого больше, тот ходит первым';

  @override
  String get openingRollTie => 'Ничья! Бросайте снова';

  @override
  String openingRollGoesFirst(String color) {
    return '$color ходит первым!';
  }

  @override
  String get scoreWhite => 'Белые';

  @override
  String get scoreBlack => 'Чёрные';
}
