// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '附近跳棋';

  @override
  String get homeTagline => '与附近的人下跳棋\n无需网络';

  @override
  String get homeYourName => '你的名字';

  @override
  String get homeInitializingBluetooth => '正在初始化蓝牙…';

  @override
  String get homePlayNearby => '附近对战';

  @override
  String get homeBluetoothUnavailable => '蓝牙不可用';

  @override
  String get homeLocalPlay => '本地游戏（传递游玩）';

  @override
  String get homeBluetoothInfo => '使用蓝牙 • 可离线使用';

  @override
  String get localGameTitle => '跳棋 — 本地游戏';

  @override
  String get localGameNewGame => '新游戏';

  @override
  String get localGameWhiteWins => '白方获胜！';

  @override
  String get localGameBlackWins => '黑方获胜！';

  @override
  String get localGameWhiteTurn => '白方回合';

  @override
  String get localGameBlackTurn => '黑方回合';

  @override
  String get localGamePlayAgain => '再玩一局';

  @override
  String get drawOfferedTitle => '提和';

  @override
  String get drawOfferedContent => '对手提议和棋，是否接受？';

  @override
  String get drawDecline => '拒绝';

  @override
  String get drawAccept => '接受';

  @override
  String get scoreWhite => '白';

  @override
  String get scoreBlack => '黑';
}
