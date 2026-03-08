import 'dart:async';

import 'package:flutter/widgets.dart';

/// Localized strings for the game_framework package.
///
/// Add the delegate to your [MaterialApp]:
/// ```dart
/// localizationsDelegates: [
///   GameFrameworkLocalizations.delegate,
///   ...GlobalMaterialLocalizations.delegates,
/// ],
/// supportedLocales: GameFrameworkLocalizations.supportedLocales,
/// ```
class GameFrameworkLocalizations {
  final Locale locale;

  GameFrameworkLocalizations(this.locale);

  static GameFrameworkLocalizations of(BuildContext context) {
    return Localizations.of<GameFrameworkLocalizations>(
      context,
      GameFrameworkLocalizations,
    )!;
  }

  static const LocalizationsDelegate<GameFrameworkLocalizations> delegate =
      _Delegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('zh'),
    Locale('hi'),
    Locale('es'),
    Locale('fr'),
    Locale('ar'),
    Locale('bn'),
    Locale('ru'),
    Locale('pt'),
    Locale('id'),
    Locale('tr'),
    Locale('de'),
  ];

  String _t(String key) {
    final lang = _strings[locale.languageCode] ?? _strings['en']!;
    return lang[key] ?? _strings['en']![key] ?? key;
  }

  // ---------------------------------------------------------------------------
  // Lobby strings
  // ---------------------------------------------------------------------------

  String lobbyNearbyGame(String gameName) =>
      _t('lobbyNearbyGame').replaceAll('{gameName}', gameName);
  String get lobbyPlayWithSomeoneNearby => _t('lobbyPlayWithSomeoneNearby');
  String get lobbyCreateGame => _t('lobbyCreateGame');
  String get lobbyCreateGameSubtitle => _t('lobbyCreateGameSubtitle');
  String get lobbyJoinGame => _t('lobbyJoinGame');
  String get lobbyJoinGameSubtitle => _t('lobbyJoinGameSubtitle');
  String get lobbyWaitingForOpponent => _t('lobbyWaitingForOpponent');
  String get lobbyGameVisible => _t('lobbyGameVisible');
  String get lobbyNearbyGames => _t('lobbyNearbyGames');
  String lobbyLookingForGames(String gameName) =>
      _t('lobbyLookingForGames').replaceAll('{gameName}', gameName);
  String get lobbyNoGamesFound => _t('lobbyNoGamesFound');
  String get lobbyMakeSureOtherPlayer => _t('lobbyMakeSureOtherPlayer');
  String get lobbyDistanceImmediate => _t('lobbyDistanceImmediate');
  String get lobbyDistanceNear => _t('lobbyDistanceNear');
  String get lobbyDistanceFar => _t('lobbyDistanceFar');
  String get lobbyDistanceUnknown => _t('lobbyDistanceUnknown');
  String get lobbyJoinButton => _t('lobbyJoinButton');

  // ---------------------------------------------------------------------------
  // Game scaffold strings
  // ---------------------------------------------------------------------------

  String get gameResign => _t('gameResign');
  String get gameOfferDraw => _t('gameOfferDraw');
  String get gameRequestUndo => _t('gameRequestUndo');
  String get gameDrawOfferSent => _t('gameDrawOfferSent');
  String get gameUndoRequestSent => _t('gameUndoRequestSent');
  String get gameResignTitle => _t('gameResignTitle');
  String get gameResignContent => _t('gameResignContent');
  String get gameCancel => _t('gameCancel');
  String get gameLeaveTitle => _t('gameLeaveTitle');
  String get gameLeaveContent => _t('gameLeaveContent');
  String get gameStay => _t('gameStay');
  String get gameLeave => _t('gameLeave');
  String get gameTurn => _t('gameTurn');
  String get gameWaiting => _t('gameWaiting');
  String get gameYourTurn => _t('gameYourTurn');
  String get gameOpponentTurn => _t('gameOpponentTurn');
  String get gameOver => _t('gameOver');
  String get gameConnectionLost => _t('gameConnectionLost');
  String get gameOpponent => _t('gameOpponent');
  String get gameYou => _t('gameYou');
}

// =============================================================================
// Delegate
// =============================================================================

class _Delegate extends LocalizationsDelegate<GameFrameworkLocalizations> {
  const _Delegate();

  static const _supportedLanguages = {
    'en', 'zh', 'hi', 'es', 'fr', 'ar', 'bn', 'ru', 'pt', 'id', 'tr', 'de',
  };

  @override
  bool isSupported(Locale locale) =>
      _supportedLanguages.contains(locale.languageCode);

  @override
  Future<GameFrameworkLocalizations> load(Locale locale) async =>
      GameFrameworkLocalizations(locale);

  @override
  bool shouldReload(_Delegate old) => false;
}

// =============================================================================
// Translations map
// =============================================================================

const Map<String, Map<String, String>> _strings = {
  // -------------------------------------------------------------------------
  'en': {
    'lobbyNearbyGame': 'Nearby {gameName}',
    'lobbyPlayWithSomeoneNearby': 'Play with someone nearby using Bluetooth',
    'lobbyCreateGame': 'Create Game',
    'lobbyCreateGameSubtitle': 'Host a game and wait for a player',
    'lobbyJoinGame': 'Join Game',
    'lobbyJoinGameSubtitle': 'Find a nearby game to join',
    'lobbyWaitingForOpponent': 'Waiting for opponent...',
    'lobbyGameVisible': 'Your game is visible to nearby players',
    'lobbyNearbyGames': 'Nearby Games',
    'lobbyLookingForGames': 'Looking for {gameName} games nearby...',
    'lobbyNoGamesFound': 'No games found yet',
    'lobbyMakeSureOtherPlayer':
        'Make sure the other player has created a game',
    'lobbyDistanceImmediate': 'Very close',
    'lobbyDistanceNear': 'Nearby',
    'lobbyDistanceFar': 'Far away',
    'lobbyDistanceUnknown': 'Distance unknown',
    'lobbyJoinButton': 'Join',
    'gameResign': 'Resign',
    'gameOfferDraw': 'Offer Draw',
    'gameRequestUndo': 'Request Undo',
    'gameDrawOfferSent': 'Draw offer sent',
    'gameUndoRequestSent': 'Undo request sent',
    'gameResignTitle': 'Resign?',
    'gameResignContent': 'Are you sure you want to resign this game?',
    'gameCancel': 'Cancel',
    'gameLeaveTitle': 'Leave Game?',
    'gameLeaveContent':
        'Leaving will end the current game. Are you sure?',
    'gameStay': 'Stay',
    'gameLeave': 'Leave',
    'gameTurn': 'Turn',
    'gameWaiting': 'Waiting for game to start...',
    'gameYourTurn': 'Your turn',
    'gameOpponentTurn': "Opponent's turn",
    'gameOver': 'Game Over',
    'gameConnectionLost': 'Connection lost',
    'gameOpponent': 'Opponent',
    'gameYou': 'You',
  },
  // -------------------------------------------------------------------------
  'zh': {
    'lobbyNearbyGame': '附近的{gameName}',
    'lobbyPlayWithSomeoneNearby': '通过蓝牙与附近的人对弈',
    'lobbyCreateGame': '创建游戏',
    'lobbyCreateGameSubtitle': '创建游戏并等待玩家',
    'lobbyJoinGame': '加入游戏',
    'lobbyJoinGameSubtitle': '寻找附近的游戏加入',
    'lobbyWaitingForOpponent': '等待对手...',
    'lobbyGameVisible': '您的游戏对附近玩家可见',
    'lobbyNearbyGames': '附近游戏',
    'lobbyLookingForGames': '正在寻找附近的{gameName}游戏...',
    'lobbyNoGamesFound': '暂无游戏',
    'lobbyMakeSureOtherPlayer': '请确保对方已创建游戏',
    'lobbyDistanceImmediate': '非常近',
    'lobbyDistanceNear': '附近',
    'lobbyDistanceFar': '较远',
    'lobbyDistanceUnknown': '距离未知',
    'lobbyJoinButton': '加入',
    'gameResign': '认输',
    'gameOfferDraw': '提和',
    'gameRequestUndo': '请求悔棋',
    'gameDrawOfferSent': '已发送提和请求',
    'gameUndoRequestSent': '已发送悔棋请求',
    'gameResignTitle': '认输？',
    'gameResignContent': '确定要认输吗？',
    'gameCancel': '取消',
    'gameLeaveTitle': '离开游戏？',
    'gameLeaveContent': '离开将结束当前游戏。确定吗？',
    'gameStay': '留下',
    'gameLeave': '离开',
    'gameTurn': '回合',
    'gameWaiting': '等待游戏开始...',
    'gameYourTurn': '您的回合',
    'gameOpponentTurn': '对手的回合',
    'gameOver': '游戏结束',
    'gameConnectionLost': '连接断开',
    'gameOpponent': '对手',
    'gameYou': '你',
  },
  // -------------------------------------------------------------------------
  'hi': {
    'lobbyNearbyGame': 'नज़दीक {gameName}',
    'lobbyPlayWithSomeoneNearby': 'ब्लूटूथ के ज़रिए किसी नज़दीकी के साथ खेलें',
    'lobbyCreateGame': 'गेम बनाएं',
    'lobbyCreateGameSubtitle': 'गेम होस्ट करें और खिलाड़ी का इंतजार करें',
    'lobbyJoinGame': 'गेम जॉइन करें',
    'lobbyJoinGameSubtitle': 'नज़दीक का गेम ढूंढें',
    'lobbyWaitingForOpponent': 'प्रतिद्वंद्वी का इंतजार...',
    'lobbyGameVisible': 'आपका गेम नज़दीकी खिलाड़ियों को दिख रहा है',
    'lobbyNearbyGames': 'नज़दीकी गेम',
    'lobbyLookingForGames': 'नज़दीक {gameName} गेम ढूंढा जा रहा है...',
    'lobbyNoGamesFound': 'अभी कोई गेम नहीं मिला',
    'lobbyMakeSureOtherPlayer': 'सुनिश्चित करें कि दूसरे खिलाड़ी ने गेम बनाया हो',
    'lobbyDistanceImmediate': 'बहुत पास',
    'lobbyDistanceNear': 'नज़दीक',
    'lobbyDistanceFar': 'दूर',
    'lobbyDistanceUnknown': 'दूरी अज्ञात',
    'lobbyJoinButton': 'जॉइन करें',
    'gameResign': 'हार मानें',
    'gameOfferDraw': 'ड्रॉ ऑफर करें',
    'gameRequestUndo': 'अनडू का अनुरोध करें',
    'gameDrawOfferSent': 'ड्रॉ ऑफर भेजा गया',
    'gameUndoRequestSent': 'अनडू अनुरोध भेजा गया',
    'gameResignTitle': 'हार मानें?',
    'gameResignContent': 'क्या आप वाकई यह गेम छोड़ना चाहते हैं?',
    'gameCancel': 'रद्द करें',
    'gameLeaveTitle': 'गेम छोड़ें?',
    'gameLeaveContent': 'छोड़ने से यह गेम समाप्त हो जाएगा। क्या आप सुनिश्चित हैं?',
    'gameStay': 'रहें',
    'gameLeave': 'छोड़ें',
    'gameTurn': 'मोड़',
    'gameWaiting': 'गेम शुरू होने का इंतजार...',
    'gameYourTurn': 'आपकी बारी',
    'gameOpponentTurn': 'प्रतिद्वंद्वी की बारी',
    'gameOver': 'गेम खत्म',
    'gameConnectionLost': 'कनेक्शन टूट गया',
    'gameOpponent': 'प्रतिद्वंद्वी',
    'gameYou': 'आप',
  },
  // -------------------------------------------------------------------------
  'es': {
    'lobbyNearbyGame': '{gameName} cercano',
    'lobbyPlayWithSomeoneNearby': 'Juega con alguien cercano usando Bluetooth',
    'lobbyCreateGame': 'Crear partida',
    'lobbyCreateGameSubtitle': 'Hospeda una partida y espera a un jugador',
    'lobbyJoinGame': 'Unirse a partida',
    'lobbyJoinGameSubtitle': 'Encuentra una partida cercana para unirte',
    'lobbyWaitingForOpponent': 'Esperando al oponente...',
    'lobbyGameVisible': 'Tu partida es visible para los jugadores cercanos',
    'lobbyNearbyGames': 'Partidas cercanas',
    'lobbyLookingForGames': 'Buscando partidas de {gameName} cercanas...',
    'lobbyNoGamesFound': 'No se encontraron partidas',
    'lobbyMakeSureOtherPlayer':
        'Asegúrate de que el otro jugador haya creado una partida',
    'lobbyDistanceImmediate': 'Muy cerca',
    'lobbyDistanceNear': 'Cerca',
    'lobbyDistanceFar': 'Lejos',
    'lobbyDistanceUnknown': 'Distancia desconocida',
    'lobbyJoinButton': 'Unirse',
    'gameResign': 'Rendirse',
    'gameOfferDraw': 'Ofrecer tablas',
    'gameRequestUndo': 'Solicitar deshacer',
    'gameDrawOfferSent': 'Oferta de tablas enviada',
    'gameUndoRequestSent': 'Solicitud de deshacer enviada',
    'gameResignTitle': '¿Rendirse?',
    'gameResignContent': '¿Estás seguro de que quieres rendirte?',
    'gameCancel': 'Cancelar',
    'gameLeaveTitle': '¿Salir de la partida?',
    'gameLeaveContent': 'Salir terminará la partida actual. ¿Estás seguro?',
    'gameStay': 'Quedarse',
    'gameLeave': 'Salir',
    'gameTurn': 'Turno',
    'gameWaiting': 'Esperando que empiece la partida...',
    'gameYourTurn': 'Tu turno',
    'gameOpponentTurn': 'Turno del oponente',
    'gameOver': 'Fin de la partida',
    'gameConnectionLost': 'Conexión perdida',
    'gameOpponent': 'Oponente',
    'gameYou': 'Tú',
  },
  // -------------------------------------------------------------------------
  'fr': {
    'lobbyNearbyGame': '{gameName} à proximité',
    'lobbyPlayWithSomeoneNearby':
        'Jouez avec quelqu\'un à proximité via Bluetooth',
    'lobbyCreateGame': 'Créer une partie',
    'lobbyCreateGameSubtitle': 'Héberger une partie et attendre un joueur',
    'lobbyJoinGame': 'Rejoindre une partie',
    'lobbyJoinGameSubtitle': 'Trouver une partie à proximité',
    'lobbyWaitingForOpponent': 'En attente d\'un adversaire...',
    'lobbyGameVisible': 'Votre partie est visible des joueurs à proximité',
    'lobbyNearbyGames': 'Parties à proximité',
    'lobbyLookingForGames':
        'Recherche de parties {gameName} à proximité...',
    'lobbyNoGamesFound': 'Aucune partie trouvée',
    'lobbyMakeSureOtherPlayer':
        'Assurez-vous que l\'autre joueur a créé une partie',
    'lobbyDistanceImmediate': 'Très proche',
    'lobbyDistanceNear': 'À proximité',
    'lobbyDistanceFar': 'Loin',
    'lobbyDistanceUnknown': 'Distance inconnue',
    'lobbyJoinButton': 'Rejoindre',
    'gameResign': 'Abandonner',
    'gameOfferDraw': 'Proposer nulle',
    'gameRequestUndo': 'Demander annulation',
    'gameDrawOfferSent': 'Proposition de nulle envoyée',
    'gameUndoRequestSent': 'Demande d\'annulation envoyée',
    'gameResignTitle': 'Abandonner ?',
    'gameResignContent': 'Êtes-vous sûr de vouloir abandonner ?',
    'gameCancel': 'Annuler',
    'gameLeaveTitle': 'Quitter la partie ?',
    'gameLeaveContent':
        'Quitter mettra fin à la partie en cours. Êtes-vous sûr ?',
    'gameStay': 'Rester',
    'gameLeave': 'Quitter',
    'gameTurn': 'Tour',
    'gameWaiting': 'En attente du début de la partie...',
    'gameYourTurn': 'Votre tour',
    'gameOpponentTurn': 'Tour de l\'adversaire',
    'gameOver': 'Partie terminée',
    'gameConnectionLost': 'Connexion perdue',
    'gameOpponent': 'Adversaire',
    'gameYou': 'Vous',
  },
  // -------------------------------------------------------------------------
  'ar': {
    'lobbyNearbyGame': '{gameName} القريب',
    'lobbyPlayWithSomeoneNearby': 'العب مع شخص قريب عبر البلوتوث',
    'lobbyCreateGame': 'إنشاء لعبة',
    'lobbyCreateGameSubtitle': 'استضف لعبة وانتظر لاعباً',
    'lobbyJoinGame': 'الانضمام إلى لعبة',
    'lobbyJoinGameSubtitle': 'ابحث عن لعبة قريبة للانضمام',
    'lobbyWaitingForOpponent': 'في انتظار المنافس...',
    'lobbyGameVisible': 'لعبتك مرئية للاعبين القريبين',
    'lobbyNearbyGames': 'الألعاب القريبة',
    'lobbyLookingForGames': 'البحث عن ألعاب {gameName} القريبة...',
    'lobbyNoGamesFound': 'لم يتم العثور على ألعاب',
    'lobbyMakeSureOtherPlayer': 'تأكد من أن اللاعب الآخر قد أنشأ لعبة',
    'lobbyDistanceImmediate': 'قريب جداً',
    'lobbyDistanceNear': 'قريب',
    'lobbyDistanceFar': 'بعيد',
    'lobbyDistanceUnknown': 'المسافة غير معروفة',
    'lobbyJoinButton': 'انضمام',
    'gameResign': 'استسلام',
    'gameOfferDraw': 'عرض تعادل',
    'gameRequestUndo': 'طلب تراجع',
    'gameDrawOfferSent': 'تم إرسال عرض التعادل',
    'gameUndoRequestSent': 'تم إرسال طلب التراجع',
    'gameResignTitle': 'استسلام؟',
    'gameResignContent': 'هل أنت متأكد من رغبتك في الاستسلام؟',
    'gameCancel': 'إلغاء',
    'gameLeaveTitle': 'مغادرة اللعبة؟',
    'gameLeaveContent': 'المغادرة ستنهي اللعبة الحالية. هل أنت متأكد؟',
    'gameStay': 'البقاء',
    'gameLeave': 'مغادرة',
    'gameTurn': 'دور',
    'gameWaiting': 'في انتظار بدء اللعبة...',
    'gameYourTurn': 'دورك',
    'gameOpponentTurn': 'دور المنافس',
    'gameOver': 'انتهت اللعبة',
    'gameConnectionLost': 'انقطع الاتصال',
    'gameOpponent': 'المنافس',
    'gameYou': 'أنت',
  },
  // -------------------------------------------------------------------------
  'bn': {
    'lobbyNearbyGame': 'কাছের {gameName}',
    'lobbyPlayWithSomeoneNearby': 'ব্লুটুথের মাধ্যমে কাছের কারো সাথে খেলুন',
    'lobbyCreateGame': 'গেম তৈরি করুন',
    'lobbyCreateGameSubtitle': 'গেম হোস্ট করুন এবং খেলোয়াড়ের জন্য অপেক্ষা করুন',
    'lobbyJoinGame': 'গেমে যোগ দিন',
    'lobbyJoinGameSubtitle': 'কাছের গেম খুঁজুন',
    'lobbyWaitingForOpponent': 'প্রতিপক্ষের জন্য অপেক্ষা করছি...',
    'lobbyGameVisible': 'আপনার গেম কাছের খেলোয়াড়দের কাছে দৃশ্যমান',
    'lobbyNearbyGames': 'কাছের গেম',
    'lobbyLookingForGames': 'কাছের {gameName} গেম খোঁজা হচ্ছে...',
    'lobbyNoGamesFound': 'এখনো কোনো গেম পাওয়া যায়নি',
    'lobbyMakeSureOtherPlayer': 'নিশ্চিত করুন যে অন্য খেলোয়াড় একটি গেম তৈরি করেছেন',
    'lobbyDistanceImmediate': 'খুব কাছে',
    'lobbyDistanceNear': 'কাছে',
    'lobbyDistanceFar': 'দূরে',
    'lobbyDistanceUnknown': 'দূরত্ব অজানা',
    'lobbyJoinButton': 'যোগ দিন',
    'gameResign': 'হার মানুন',
    'gameOfferDraw': 'ড্র অফার করুন',
    'gameRequestUndo': 'আন্ডু অনুরোধ করুন',
    'gameDrawOfferSent': 'ড্র অফার পাঠানো হয়েছে',
    'gameUndoRequestSent': 'আন্ডু অনুরোধ পাঠানো হয়েছে',
    'gameResignTitle': 'হার মানবেন?',
    'gameResignContent': 'আপনি কি সত্যিই এই গেম ছেড়ে দিতে চান?',
    'gameCancel': 'বাতিল',
    'gameLeaveTitle': 'গেম ছাড়বেন?',
    'gameLeaveContent': 'ছেড়ে গেলে বর্তমান গেম শেষ হবে। নিশ্চিত?',
    'gameStay': 'থাকুন',
    'gameLeave': 'ছাড়ুন',
    'gameTurn': 'পালা',
    'gameWaiting': 'গেম শুরুর জন্য অপেক্ষা করছি...',
    'gameYourTurn': 'আপনার পালা',
    'gameOpponentTurn': 'প্রতিপক্ষের পালা',
    'gameOver': 'গেম শেষ',
    'gameConnectionLost': 'সংযোগ বিচ্ছিন্ন',
    'gameOpponent': 'প্রতিপক্ষ',
    'gameYou': 'আপনি',
  },
  // -------------------------------------------------------------------------
  'ru': {
    'lobbyNearbyGame': '{gameName} рядом',
    'lobbyPlayWithSomeoneNearby': 'Играйте с кем-то поблизости через Bluetooth',
    'lobbyCreateGame': 'Создать игру',
    'lobbyCreateGameSubtitle': 'Создайте игру и ждите игрока',
    'lobbyJoinGame': 'Присоединиться к игре',
    'lobbyJoinGameSubtitle': 'Найти игру поблизости',
    'lobbyWaitingForOpponent': 'Ожидание соперника...',
    'lobbyGameVisible': 'Ваша игра видна игрокам поблизости',
    'lobbyNearbyGames': 'Игры поблизости',
    'lobbyLookingForGames': 'Поиск игр {gameName} поблизости...',
    'lobbyNoGamesFound': 'Игры не найдены',
    'lobbyMakeSureOtherPlayer': 'Убедитесь, что другой игрок создал игру',
    'lobbyDistanceImmediate': 'Очень близко',
    'lobbyDistanceNear': 'Рядом',
    'lobbyDistanceFar': 'Далеко',
    'lobbyDistanceUnknown': 'Расстояние неизвестно',
    'lobbyJoinButton': 'Присоединиться',
    'gameResign': 'Сдаться',
    'gameOfferDraw': 'Предложить ничью',
    'gameRequestUndo': 'Запросить отмену',
    'gameDrawOfferSent': 'Предложение ничьей отправлено',
    'gameUndoRequestSent': 'Запрос отмены отправлен',
    'gameResignTitle': 'Сдаться?',
    'gameResignContent': 'Вы уверены, что хотите сдаться?',
    'gameCancel': 'Отмена',
    'gameLeaveTitle': 'Выйти из игры?',
    'gameLeaveContent': 'Выход завершит текущую игру. Вы уверены?',
    'gameStay': 'Остаться',
    'gameLeave': 'Выйти',
    'gameTurn': 'Ход',
    'gameWaiting': 'Ожидание начала игры...',
    'gameYourTurn': 'Ваш ход',
    'gameOpponentTurn': 'Ход соперника',
    'gameOver': 'Игра окончена',
    'gameConnectionLost': 'Соединение потеряно',
    'gameOpponent': 'Соперник',
    'gameYou': 'Вы',
  },
  // -------------------------------------------------------------------------
  'pt': {
    'lobbyNearbyGame': '{gameName} próximo',
    'lobbyPlayWithSomeoneNearby': 'Jogue com alguém próximo via Bluetooth',
    'lobbyCreateGame': 'Criar partida',
    'lobbyCreateGameSubtitle': 'Hospede uma partida e aguarde um jogador',
    'lobbyJoinGame': 'Entrar na partida',
    'lobbyJoinGameSubtitle': 'Encontre uma partida próxima para entrar',
    'lobbyWaitingForOpponent': 'Aguardando oponente...',
    'lobbyGameVisible': 'Sua partida está visível para jogadores próximos',
    'lobbyNearbyGames': 'Partidas próximas',
    'lobbyLookingForGames': 'Procurando partidas de {gameName} próximas...',
    'lobbyNoGamesFound': 'Nenhuma partida encontrada',
    'lobbyMakeSureOtherPlayer':
        'Certifique-se de que o outro jogador criou uma partida',
    'lobbyDistanceImmediate': 'Muito perto',
    'lobbyDistanceNear': 'Próximo',
    'lobbyDistanceFar': 'Longe',
    'lobbyDistanceUnknown': 'Distância desconhecida',
    'lobbyJoinButton': 'Entrar',
    'gameResign': 'Render',
    'gameOfferDraw': 'Oferecer empate',
    'gameRequestUndo': 'Solicitar desfazer',
    'gameDrawOfferSent': 'Oferta de empate enviada',
    'gameUndoRequestSent': 'Solicitação de desfazer enviada',
    'gameResignTitle': 'Render?',
    'gameResignContent': 'Tem certeza que deseja se render?',
    'gameCancel': 'Cancelar',
    'gameLeaveTitle': 'Sair da partida?',
    'gameLeaveContent': 'Sair encerrará a partida atual. Tem certeza?',
    'gameStay': 'Ficar',
    'gameLeave': 'Sair',
    'gameTurn': 'Vez',
    'gameWaiting': 'Aguardando início da partida...',
    'gameYourTurn': 'Sua vez',
    'gameOpponentTurn': 'Vez do oponente',
    'gameOver': 'Fim de jogo',
    'gameConnectionLost': 'Conexão perdida',
    'gameOpponent': 'Oponente',
    'gameYou': 'Você',
  },
  // -------------------------------------------------------------------------
  'id': {
    'lobbyNearbyGame': '{gameName} Terdekat',
    'lobbyPlayWithSomeoneNearby':
        'Bermain dengan seseorang di dekatmu menggunakan Bluetooth',
    'lobbyCreateGame': 'Buat Permainan',
    'lobbyCreateGameSubtitle': 'Jadikan tuan rumah dan tunggu pemain',
    'lobbyJoinGame': 'Bergabung ke Permainan',
    'lobbyJoinGameSubtitle': 'Cari permainan terdekat untuk bergabung',
    'lobbyWaitingForOpponent': 'Menunggu lawan...',
    'lobbyGameVisible': 'Permainanmu terlihat oleh pemain terdekat',
    'lobbyNearbyGames': 'Permainan Terdekat',
    'lobbyLookingForGames': 'Mencari permainan {gameName} terdekat...',
    'lobbyNoGamesFound': 'Belum ada permainan ditemukan',
    'lobbyMakeSureOtherPlayer':
        'Pastikan pemain lain sudah membuat permainan',
    'lobbyDistanceImmediate': 'Sangat dekat',
    'lobbyDistanceNear': 'Di dekat',
    'lobbyDistanceFar': 'Jauh',
    'lobbyDistanceUnknown': 'Jarak tidak diketahui',
    'lobbyJoinButton': 'Bergabung',
    'gameResign': 'Menyerah',
    'gameOfferDraw': 'Tawarkan Remis',
    'gameRequestUndo': 'Minta Batalkan',
    'gameDrawOfferSent': 'Tawaran remis terkirim',
    'gameUndoRequestSent': 'Permintaan batalkan terkirim',
    'gameResignTitle': 'Menyerah?',
    'gameResignContent': 'Yakin ingin menyerah dari permainan ini?',
    'gameCancel': 'Batal',
    'gameLeaveTitle': 'Keluar dari Permainan?',
    'gameLeaveContent': 'Keluar akan mengakhiri permainan saat ini. Yakin?',
    'gameStay': 'Tetap',
    'gameLeave': 'Keluar',
    'gameTurn': 'Giliran',
    'gameWaiting': 'Menunggu permainan dimulai...',
    'gameYourTurn': 'Giliranmu',
    'gameOpponentTurn': 'Giliran lawan',
    'gameOver': 'Permainan Selesai',
    'gameConnectionLost': 'Koneksi terputus',
    'gameOpponent': 'Lawan',
    'gameYou': 'Kamu',
  },
  // -------------------------------------------------------------------------
  'de': {
    'lobbyNearbyGame': '{gameName} in der Nähe',
    'lobbyPlayWithSomeoneNearby': 'Spiele per Bluetooth mit jemandem in der Nähe',
    'lobbyCreateGame': 'Spiel erstellen',
    'lobbyCreateGameSubtitle': 'Spiel hosten und auf einen Spieler warten',
    'lobbyJoinGame': 'Spiel beitreten',
    'lobbyJoinGameSubtitle': 'Ein Spiel in der Nähe finden und beitreten',
    'lobbyWaitingForOpponent': 'Warte auf Gegner...',
    'lobbyGameVisible': 'Dein Spiel ist für Spieler in der Nähe sichtbar',
    'lobbyNearbyGames': 'Spiele in der Nähe',
    'lobbyLookingForGames': 'Suche nach {gameName}-Spielen in der Nähe...',
    'lobbyNoGamesFound': 'Noch keine Spiele gefunden',
    'lobbyMakeSureOtherPlayer': 'Stelle sicher, dass der andere Spieler ein Spiel erstellt hat',
    'lobbyDistanceImmediate': 'Sehr nah',
    'lobbyDistanceNear': 'In der Nähe',
    'lobbyDistanceFar': 'Weit entfernt',
    'lobbyDistanceUnknown': 'Entfernung unbekannt',
    'lobbyJoinButton': 'Beitreten',
    'gameResign': 'Aufgeben',
    'gameOfferDraw': 'Remis anbieten',
    'gameRequestUndo': 'Rückzug anfragen',
    'gameDrawOfferSent': 'Remisangebot gesendet',
    'gameUndoRequestSent': 'Rückzuganfrage gesendet',
    'gameResignTitle': 'Aufgeben?',
    'gameResignContent': 'Möchtest du dieses Spiel wirklich aufgeben?',
    'gameCancel': 'Abbrechen',
    'gameLeaveTitle': 'Spiel verlassen?',
    'gameLeaveContent': 'Das aktuelle Spiel wird beendet. Bist du sicher?',
    'gameStay': 'Bleiben',
    'gameLeave': 'Verlassen',
    'gameTurn': 'Zug',
    'gameWaiting': 'Warte auf Spielstart...',
    'gameYourTurn': 'Du bist dran',
    'gameOpponentTurn': 'Gegner ist dran',
    'gameOver': 'Spiel beendet',
    'gameConnectionLost': 'Verbindung unterbrochen',
    'gameOpponent': 'Gegner',
    'gameYou': 'Du',
  },
  // -------------------------------------------------------------------------
  'tr': {
    'lobbyNearbyGame': 'Yakınımdaki {gameName}',
    'lobbyPlayWithSomeoneNearby': 'Bluetooth ile yakınınızdaki biriyle oynayın',
    'lobbyCreateGame': 'Oyun Oluştur',
    'lobbyCreateGameSubtitle': 'Bir oyun başlatın ve oyuncu bekleyin',
    'lobbyJoinGame': 'Oyuna Katıl',
    'lobbyJoinGameSubtitle': 'Katılmak için yakın bir oyun bul',
    'lobbyWaitingForOpponent': 'Rakip bekleniyor...',
    'lobbyGameVisible': 'Oyununuz yakındaki oyunculara görünüyor',
    'lobbyNearbyGames': 'Yakındaki Oyunlar',
    'lobbyLookingForGames': 'Yakındaki {gameName} oyunları aranıyor...',
    'lobbyNoGamesFound': 'Henüz oyun bulunamadı',
    'lobbyMakeSureOtherPlayer':
        'Diğer oyuncunun bir oyun oluşturduğundan emin olun',
    'lobbyDistanceImmediate': 'Çok yakın',
    'lobbyDistanceNear': 'Yakında',
    'lobbyDistanceFar': 'Uzakta',
    'lobbyDistanceUnknown': 'Mesafe bilinmiyor',
    'lobbyJoinButton': 'Katıl',
    'gameResign': 'Teslim ol',
    'gameOfferDraw': 'Beraberlik Teklif Et',
    'gameRequestUndo': 'Geri Al İsteği',
    'gameDrawOfferSent': 'Beraberlik teklifi gönderildi',
    'gameUndoRequestSent': 'Geri al isteği gönderildi',
    'gameResignTitle': 'Teslim mi olunacak?',
    'gameResignContent': 'Bu oyundan teslim olmak istediğinizden emin misiniz?',
    'gameCancel': 'İptal',
    'gameLeaveTitle': 'Oyundan Çık?',
    'gameLeaveContent': 'Çıkmak mevcut oyunu sonlandıracak. Emin misiniz?',
    'gameStay': 'Kal',
    'gameLeave': 'Çık',
    'gameTurn': 'Hamle',
    'gameWaiting': 'Oyunun başlaması bekleniyor...',
    'gameYourTurn': 'Sıra sende',
    'gameOpponentTurn': 'Rakibin sırası',
    'gameOver': 'Oyun Bitti',
    'gameConnectionLost': 'Bağlantı kesildi',
    'gameOpponent': 'Rakip',
    'gameYou': 'Sen',
  },
};
