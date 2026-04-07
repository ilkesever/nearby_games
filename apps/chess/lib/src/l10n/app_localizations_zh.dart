// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '附近象棋';

  @override
  String get homeTagline => '与附近的人下棋\n无需网络';

  @override
  String get homeYourName => '您的姓名';

  @override
  String get homeInitializingBluetooth => '正在初始化蓝牙...';

  @override
  String get homePlayNearby => '附近游戏';

  @override
  String get homeBluetoothUnavailable => '蓝牙不可用';

  @override
  String get homeLocalPlay => '本地对弈（传递手机）';

  @override
  String get homeBluetoothInfo => '使用蓝牙 • 离线可玩';

  @override
  String get localGameTitle => '象棋 — 本地对弈';

  @override
  String get localGameNewGame => '新游戏';

  @override
  String get localGameWhiteWins => '白方获胜！';

  @override
  String get localGameBlackWins => '黑方获胜！';

  @override
  String get localGameDraw => '平局！';

  @override
  String get localGameWhiteTurn => '白方的回合';

  @override
  String get localGameBlackTurn => '黑方的回合';

  @override
  String get localGameCheckSuffix => '— 将军！';

  @override
  String get localGameTapToStart => '点击棋子开始游戏';

  @override
  String get localGamePlayAgain => '再来一局';

  @override
  String get drawOfferedTitle => '提和';

  @override
  String get drawOfferedContent => '对手提出平局。接受？';

  @override
  String get drawDecline => '拒绝';

  @override
  String get drawAccept => '接受';
}
