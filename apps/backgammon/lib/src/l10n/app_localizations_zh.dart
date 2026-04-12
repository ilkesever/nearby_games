// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '附近双陆棋';

  @override
  String get homeTagline => '与附近的人下双陆棋\n无需网络';

  @override
  String get homeYourName => '您的名字';

  @override
  String get homeInitializingBluetooth => '正在初始化蓝牙...';

  @override
  String get homePlayNearby => '附近对战';

  @override
  String get homeBluetoothUnavailable => '蓝牙不可用';

  @override
  String get homeLocalPlay => '本地对战（传递游玩）';

  @override
  String get homeBluetoothInfo => '使用蓝牙 • 离线可用';

  @override
  String get localGameTitle => '双陆棋 — 本地对战';

  @override
  String get localGameNewGame => '新游戏';

  @override
  String get localGameRollDice => '掷骰子';

  @override
  String get localGameWhiteWins => '白棋获胜！';

  @override
  String get localGameBlackWins => '黑棋获胜！';

  @override
  String get localGameWhiteTurn => '白棋的回合';

  @override
  String get localGameBlackTurn => '黑棋的回合';

  @override
  String get localGameBar => '棋栏';

  @override
  String get localGameBearOff => '退出棋盘';

  @override
  String get localGameNoMoves => '没有合法移动 — 跳过回合';

  @override
  String get localGamePlayAgain => '再玩一局';

  @override
  String get drawOfferedTitle => '提出和棋';

  @override
  String get drawOfferedContent => '对手提出和棋。接受？';

  @override
  String get drawDecline => '拒绝';

  @override
  String get drawAccept => '接受';

  @override
  String get openingRollTitle => '开局掷骰';

  @override
  String get openingRollInstruction => '每位玩家掷骰 — 点数高者先行';

  @override
  String get openingRollTie => '平局！重新掷骰';

  @override
  String openingRollGoesFirst(String color) {
    return '$color先行！';
  }

  @override
  String get scoreWhite => '白棋';

  @override
  String get scoreBlack => '黑棋';

  @override
  String get openingRollYourTurn => '轮到你了 — 点击掷骰';

  @override
  String get openingRollBlackToRoll => '黑棋掷骰中…';

  @override
  String get openingRollWhiteToRoll => '白棋掷骰中…';

  @override
  String get openingRollTapToRoll => '点击你的骰子来掷';

  @override
  String get openingRollWaitingForOpponent => '等待对手…';

  @override
  String boreOffLabel(String color) {
    return '$color已退出: ';
  }

  @override
  String get moveUndo => '撤销';

  @override
  String get moveDone => '确定';

  @override
  String get opponentPlaying => '对手正在操作…';
}
