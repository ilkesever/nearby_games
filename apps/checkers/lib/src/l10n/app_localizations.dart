import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh'),
  ];

  /// The app title
  ///
  /// In en, this message translates to:
  /// **'Nearby Checkers'**
  String get appTitle;

  /// Home screen tagline
  ///
  /// In en, this message translates to:
  /// **'Play checkers with someone nearby\nNo internet required'**
  String get homeTagline;

  /// Label for the player name text field
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get homeYourName;

  /// BLE initializing label
  ///
  /// In en, this message translates to:
  /// **'Initializing Bluetooth...'**
  String get homeInitializingBluetooth;

  /// Button to play nearby via BLE
  ///
  /// In en, this message translates to:
  /// **'Play Nearby'**
  String get homePlayNearby;

  /// BLE not available label
  ///
  /// In en, this message translates to:
  /// **'Bluetooth unavailable'**
  String get homeBluetoothUnavailable;

  /// Button for local pass-and-play
  ///
  /// In en, this message translates to:
  /// **'Local Play (Pass & Play)'**
  String get homeLocalPlay;

  /// Info label at bottom of home screen
  ///
  /// In en, this message translates to:
  /// **'Uses Bluetooth • Works offline'**
  String get homeBluetoothInfo;

  /// App bar title for local game screen
  ///
  /// In en, this message translates to:
  /// **'Checkers — Local Play'**
  String get localGameTitle;

  /// Button to start a new game
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get localGameNewGame;

  /// Status when white wins
  ///
  /// In en, this message translates to:
  /// **'White wins!'**
  String get localGameWhiteWins;

  /// Status when black wins
  ///
  /// In en, this message translates to:
  /// **'Black wins!'**
  String get localGameBlackWins;

  /// Status when it is white's turn
  ///
  /// In en, this message translates to:
  /// **'White\'s turn'**
  String get localGameWhiteTurn;

  /// Status when it is black's turn
  ///
  /// In en, this message translates to:
  /// **'Black\'s turn'**
  String get localGameBlackTurn;

  /// Button to play again after game over
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get localGamePlayAgain;

  /// Title of draw offer dialog
  ///
  /// In en, this message translates to:
  /// **'Draw Offered'**
  String get drawOfferedTitle;

  /// Body of draw offer dialog
  ///
  /// In en, this message translates to:
  /// **'Your opponent is offering a draw. Accept?'**
  String get drawOfferedContent;

  /// Button to decline a draw
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get drawDecline;

  /// Button to accept a draw
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get drawAccept;

  /// Label for white player score
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get scoreWhite;

  /// Label for black player score
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get scoreBlack;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'id',
    'pt',
    'ru',
    'tr',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
