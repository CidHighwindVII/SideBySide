import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL
/// returned by `AppL.of(context)`.
///
/// Applications need to include `AppL.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL.localizationsDelegates,
///   supportedLocales: AppL.supportedLocales,
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
/// be consistent with the languages listed in the AppL.supportedLocales
/// property.
abstract class AppL {
  AppL(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL of(BuildContext context) {
    return Localizations.of<AppL>(context, AppL)!;
  }

  static const LocalizationsDelegate<AppL> delegate = _AppLDelegate();

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
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tabCalendar;

  /// No description provided for @tabSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get tabSuggestions;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @phaseMenstrual.
  ///
  /// In en, this message translates to:
  /// **'Menstrual'**
  String get phaseMenstrual;

  /// No description provided for @phaseFollicular.
  ///
  /// In en, this message translates to:
  /// **'Follicular'**
  String get phaseFollicular;

  /// No description provided for @phaseOvulation.
  ///
  /// In en, this message translates to:
  /// **'Ovulation'**
  String get phaseOvulation;

  /// No description provided for @phaseLuteal.
  ///
  /// In en, this message translates to:
  /// **'Luteal'**
  String get phaseLuteal;

  /// No description provided for @phasePms.
  ///
  /// In en, this message translates to:
  /// **'PMS'**
  String get phasePms;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Likely phase'**
  String get statusLabel;

  /// No description provided for @confHigh.
  ///
  /// In en, this message translates to:
  /// **'more consistent logged dates'**
  String get confHigh;

  /// No description provided for @confMedium.
  ///
  /// In en, this message translates to:
  /// **'estimate with some history'**
  String get confMedium;

  /// No description provided for @confLow.
  ///
  /// In en, this message translates to:
  /// **'limited estimate'**
  String get confLow;

  /// No description provided for @suggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'For today'**
  String get suggestionsTitle;

  /// No description provided for @warningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Better avoid'**
  String get warningsTitle;

  /// No description provided for @contextTitle.
  ///
  /// In en, this message translates to:
  /// **'For context'**
  String get contextTitle;

  /// No description provided for @axisFavor.
  ///
  /// In en, this message translates to:
  /// **'Ask favors'**
  String get axisFavor;

  /// No description provided for @axisNews.
  ///
  /// In en, this message translates to:
  /// **'Give bad news'**
  String get axisNews;

  /// No description provided for @axisOut.
  ///
  /// In en, this message translates to:
  /// **'Go out & plan'**
  String get axisOut;

  /// No description provided for @axisEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get axisEnergy;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search support ideas'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Type to search'**
  String get searchHint;

  /// No description provided for @searchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing found.'**
  String get searchEmpty;

  /// No description provided for @catalogUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Suggestions could not be loaded. Restart the app to try again.'**
  String get catalogUnavailable;

  /// No description provided for @searchAllPhases.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchAllPhases;

  /// No description provided for @varianceTitle.
  ///
  /// In en, this message translates to:
  /// **'Cycle variance'**
  String get varianceTitle;

  /// No description provided for @varianceAvg.
  ///
  /// In en, this message translates to:
  /// **'avg: {n} days'**
  String varianceAvg(int n);

  /// No description provided for @weekendTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Different time on weekends'**
  String get weekendTimeTitle;

  /// No description provided for @weekendBriefingTime.
  ///
  /// In en, this message translates to:
  /// **'Weekend briefing time'**
  String get weekendBriefingTime;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Prioritize offers of help'**
  String get supportTitle;

  /// No description provided for @supportBody.
  ///
  /// In en, this message translates to:
  /// **'Shows offers of help first, without inferring her preferences from a cycle.'**
  String get supportBody;

  /// No description provided for @obsTitle.
  ///
  /// In en, this message translates to:
  /// **'Log an observation'**
  String get obsTitle;

  /// No description provided for @obsBody.
  ///
  /// In en, this message translates to:
  /// **'What you noticed today — your notes, not clinical data.'**
  String get obsBody;

  /// No description provided for @obsLegend.
  ///
  /// In en, this message translates to:
  /// **'observation logged'**
  String get obsLegend;

  /// No description provided for @patternTitle.
  ///
  /// In en, this message translates to:
  /// **'Pattern in your notes'**
  String get patternTitle;

  /// No description provided for @patternCaption.
  ///
  /// In en, this message translates to:
  /// **'Spread across phases — your notes, not clinical data.'**
  String get patternCaption;

  /// No description provided for @obsCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get obsCalm;

  /// No description provided for @obsTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get obsTired;

  /// No description provided for @obsSensitive.
  ///
  /// In en, this message translates to:
  /// **'Sensitive'**
  String get obsSensitive;

  /// No description provided for @obsGoodMood.
  ///
  /// In en, this message translates to:
  /// **'Good mood'**
  String get obsGoodMood;

  /// No description provided for @obsIrritable.
  ///
  /// In en, this message translates to:
  /// **'Irritable'**
  String get obsIrritable;

  /// No description provided for @obsCramps.
  ///
  /// In en, this message translates to:
  /// **'Cramps'**
  String get obsCramps;

  /// No description provided for @obsHeadache.
  ///
  /// In en, this message translates to:
  /// **'Headache'**
  String get obsHeadache;

  /// No description provided for @obsBloating.
  ///
  /// In en, this message translates to:
  /// **'Bloating'**
  String get obsBloating;

  /// No description provided for @obsCravings.
  ///
  /// In en, this message translates to:
  /// **'Cravings'**
  String get obsCravings;

  /// No description provided for @obsSleepless.
  ///
  /// In en, this message translates to:
  /// **'Slept badly'**
  String get obsSleepless;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @customTitle.
  ///
  /// In en, this message translates to:
  /// **'Your notes'**
  String get customTitle;

  /// No description provided for @customAdd.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get customAdd;

  /// No description provided for @customText.
  ///
  /// In en, this message translates to:
  /// **'What you want to remember'**
  String get customText;

  /// No description provided for @widgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Home screen widget'**
  String get widgetTitle;

  /// No description provided for @widgetBody.
  ///
  /// In en, this message translates to:
  /// **'Only shows a neutral prompt to open the app. Android only.'**
  String get widgetBody;

  /// No description provided for @widgetPrompt.
  ///
  /// In en, this message translates to:
  /// **'Check the app'**
  String get widgetPrompt;

  /// No description provided for @dataTitle.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataTitle;

  /// No description provided for @deviceFail.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t complete on this device.'**
  String get deviceFail;

  /// No description provided for @calTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get calTitle;

  /// No description provided for @calBody.
  ///
  /// In en, this message translates to:
  /// **'Writes the next 14 days to your calendar with the neutral title \"SxS\" — nothing revealing. Warning: if your calendar syncs with Google/Apple, these events leave the phone.'**
  String get calBody;

  /// No description provided for @avgTitle.
  ///
  /// In en, this message translates to:
  /// **'Averages in use'**
  String get avgTitle;

  /// No description provided for @avgAuto.
  ///
  /// In en, this message translates to:
  /// **'automatic — median of your logs'**
  String get avgAuto;

  /// No description provided for @avgFallback.
  ///
  /// In en, this message translates to:
  /// **'starting average — still few logs'**
  String get avgFallback;

  /// No description provided for @avgFromLogs.
  ///
  /// In en, this message translates to:
  /// **'The app computes cycle and period length from your logs — you don\'t need to set them.'**
  String get avgFromLogs;

  /// No description provided for @trafficGreen.
  ///
  /// In en, this message translates to:
  /// **'good'**
  String get trafficGreen;

  /// No description provided for @trafficYellow.
  ///
  /// In en, this message translates to:
  /// **'careful'**
  String get trafficYellow;

  /// No description provided for @trafficRed.
  ///
  /// In en, this message translates to:
  /// **'avoid'**
  String get trafficRed;

  /// No description provided for @tomorrowCard.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrowCard;

  /// No description provided for @tomorrowPreview.
  ///
  /// In en, this message translates to:
  /// **'See tomorrow ↓'**
  String get tomorrowPreview;

  /// No description provided for @feedbackQuestion.
  ///
  /// In en, this message translates to:
  /// **'Was this suggestion useful?'**
  String get feedbackQuestion;

  /// No description provided for @feedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks — saved.'**
  String get feedbackThanks;

  /// No description provided for @confirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm date'**
  String get confirmTitle;

  /// No description provided for @confirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your period forecast passed without a log. Confirm the real date?'**
  String get confirmBody;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Log now'**
  String get confirmAction;

  /// No description provided for @confirmDismiss.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get confirmDismiss;

  /// No description provided for @healthNudge.
  ///
  /// In en, this message translates to:
  /// **'Your cycles vary a lot — worth a peek with a professional. Not an alarm or a diagnosis.'**
  String get healthNudge;

  /// No description provided for @healthNudgeOk.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get healthNudgeOk;

  /// No description provided for @noForecast.
  ///
  /// In en, this message translates to:
  /// **'No current forecast — log a date to start estimating again.'**
  String get noForecast;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No dates logged yet. You can start with the last period date.'**
  String get noDataYet;

  /// No description provided for @calendarBandPeriod.
  ///
  /// In en, this message translates to:
  /// **'expected period (±{n} days)'**
  String calendarBandPeriod(int n);

  /// No description provided for @calendarBandOvulation.
  ///
  /// In en, this message translates to:
  /// **'expected fertile window (±{n} days)'**
  String calendarBandOvulation(int n);

  /// No description provided for @calendarLogged.
  ///
  /// In en, this message translates to:
  /// **'logged'**
  String get calendarLogged;

  /// No description provided for @calendarFuture.
  ///
  /// In en, this message translates to:
  /// **'planned by you'**
  String get calendarFuture;

  /// No description provided for @calendarExpectedPeriod.
  ///
  /// In en, this message translates to:
  /// **'estimated period; the date may change'**
  String get calendarExpectedPeriod;

  /// No description provided for @calendarExpectedFertile.
  ///
  /// In en, this message translates to:
  /// **'estimated fertile window (6 days)'**
  String get calendarExpectedFertile;

  /// No description provided for @calendarFertileUncertainty.
  ///
  /// In en, this message translates to:
  /// **'fertile-window uncertainty (±{n} days)'**
  String calendarFertileUncertainty(int n);

  /// No description provided for @calendarNoBand.
  ///
  /// In en, this message translates to:
  /// **'No period or fertile-window estimates (hormonal contraception). Logged bleeding stays visible.'**
  String get calendarNoBand;

  /// No description provided for @unknownContrNote.
  ///
  /// In en, this message translates to:
  /// **'Contraception is set to unknown. Estimates assume a natural cycle and may not apply — confirm in Settings.'**
  String get unknownContrNote;

  /// No description provided for @unknownContrAction.
  ///
  /// In en, this message translates to:
  /// **'Set contraception'**
  String get unknownContrAction;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @tipOfDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Tip of the day'**
  String get tipOfDayTitle;

  /// No description provided for @prepTitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare thoughtfully'**
  String get prepTitle;

  /// No description provided for @prepBody.
  ///
  /// In en, this message translates to:
  /// **'The next period may be near. If it works for you both, ask what she needs and prepare the essentials — the estimate can change.'**
  String get prepBody;

  /// No description provided for @contraception.
  ///
  /// In en, this message translates to:
  /// **'Contraception'**
  String get contraception;

  /// No description provided for @contrNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get contrNone;

  /// No description provided for @contrHormonal.
  ///
  /// In en, this message translates to:
  /// **'Hormonal'**
  String get contrHormonal;

  /// No description provided for @contrUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get contrUnknown;

  /// No description provided for @liveTogether.
  ///
  /// In en, this message translates to:
  /// **'Living together?'**
  String get liveTogether;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @settingsBriefing.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow briefing'**
  String get settingsBriefing;

  /// No description provided for @settingsBriefingTime.
  ///
  /// In en, this message translates to:
  /// **'Briefing time'**
  String get settingsBriefingTime;

  /// No description provided for @settingsHeadsUp.
  ///
  /// In en, this message translates to:
  /// **'Preparation reminder (details in the app only)'**
  String get settingsHeadsUp;

  /// No description provided for @settingsWipe.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get settingsWipe;

  /// No description provided for @settingsWipeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deleting erases all data. No recovery.'**
  String get settingsWipeConfirm;

  /// No description provided for @todayCycleDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of the cycle'**
  String todayCycleDay(int day);

  /// No description provided for @todayNextPeriod.
  ///
  /// In en, this message translates to:
  /// **'Estimated next period: {date}'**
  String todayNextPeriod(String date);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @calMarkStart.
  ///
  /// In en, this message translates to:
  /// **'Mark period start'**
  String get calMarkStart;

  /// No description provided for @calMarkEnd.
  ///
  /// In en, this message translates to:
  /// **'Mark period end'**
  String get calMarkEnd;

  /// No description provided for @calUnmarkStart.
  ///
  /// In en, this message translates to:
  /// **'Unmark period start'**
  String get calUnmarkStart;

  /// No description provided for @calUnmarkEnd.
  ///
  /// In en, this message translates to:
  /// **'Unmark period end'**
  String get calUnmarkEnd;

  /// No description provided for @periodTooShort.
  ///
  /// In en, this message translates to:
  /// **'A period usually lasts at least ~3 days.'**
  String get periodTooShort;

  /// No description provided for @periodTooSoon.
  ///
  /// In en, this message translates to:
  /// **'In this app, logged period starts must be at least 21 days apart.'**
  String get periodTooSoon;

  /// No description provided for @notifBriefTitle.
  ///
  /// In en, this message translates to:
  /// **'SideBySide'**
  String get notifBriefTitle;

  /// No description provided for @notifBriefBody.
  ///
  /// In en, this message translates to:
  /// **'There\'s an update to view in the app.'**
  String get notifBriefBody;

  /// No description provided for @notifHeadsUpTitle.
  ///
  /// In en, this message translates to:
  /// **'SideBySide'**
  String get notifHeadsUpTitle;

  /// No description provided for @notifHeadsUpBody.
  ///
  /// In en, this message translates to:
  /// **'There\'s a note to check in the app.'**
  String get notifHeadsUpBody;

  /// No description provided for @notifReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'SideBySide'**
  String get notifReminderTitle;

  /// No description provided for @notifReminderBody.
  ///
  /// In en, this message translates to:
  /// **'There\'s a reminder to view in the app.'**
  String get notifReminderBody;

  /// No description provided for @ofToday.
  ///
  /// In en, this message translates to:
  /// **'from today'**
  String get ofToday;

  /// No description provided for @onbSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onbSetupTitle;

  /// No description provided for @onbSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Only log dates you know. Ask about her needs; don\'t try to predict them.'**
  String get onbSetupBody;

  /// No description provided for @onbAvgCycle.
  ///
  /// In en, this message translates to:
  /// **'Average cycle length'**
  String get onbAvgCycle;

  /// No description provided for @onbAvgPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period length'**
  String get onbAvgPeriod;

  /// No description provided for @onbDays.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String onbDays(int n);

  /// No description provided for @onbLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Log the last period'**
  String get onbLogTitle;

  /// No description provided for @onbLogBody.
  ///
  /// In en, this message translates to:
  /// **'When did it start? The end is optional — you can skip and log later in the Calendar.'**
  String get onbLogBody;

  /// No description provided for @onbLogStart.
  ///
  /// In en, this message translates to:
  /// **'Period start'**
  String get onbLogStart;

  /// No description provided for @onbLogEnd.
  ///
  /// In en, this message translates to:
  /// **'Period end (optional)'**
  String get onbLogEnd;

  /// No description provided for @onbNotSet.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose'**
  String get onbNotSet;

  /// No description provided for @onbSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbSkip;

  /// No description provided for @onbTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Briefing time'**
  String get onbTimeTitle;

  /// No description provided for @onbTimeBody.
  ///
  /// In en, this message translates to:
  /// **'At the time you choose, receive a generic reminder to check the app. You can turn it off later.'**
  String get onbTimeBody;

  /// No description provided for @preferenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Support you agreed on'**
  String get preferenceTitle;

  /// No description provided for @preferenceConsent.
  ///
  /// In en, this message translates to:
  /// **'Only save preferences you have discussed. Edit or delete them any time; the app cannot verify her consent.'**
  String get preferenceConsent;

  /// No description provided for @preferenceAdd.
  ///
  /// In en, this message translates to:
  /// **'Add agreed preference'**
  String get preferenceAdd;

  /// No description provided for @preferenceEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit preference'**
  String get preferenceEdit;

  /// No description provided for @preferenceDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete preference'**
  String get preferenceDelete;

  /// No description provided for @preferenceCategory.
  ///
  /// In en, this message translates to:
  /// **'Kind of support'**
  String get preferenceCategory;

  /// No description provided for @preferenceCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get preferenceCheckIn;

  /// No description provided for @preferenceHelp.
  ///
  /// In en, this message translates to:
  /// **'Practical help'**
  String get preferenceHelp;

  /// No description provided for @preferenceSpace.
  ///
  /// In en, this message translates to:
  /// **'Give space'**
  String get preferenceSpace;

  /// No description provided for @preferenceText.
  ///
  /// In en, this message translates to:
  /// **'What did you agree to remember?'**
  String get preferenceText;

  /// No description provided for @agreedPreference.
  ///
  /// In en, this message translates to:
  /// **'A preference you saved — always check if it still fits.'**
  String get agreedPreference;

  /// No description provided for @actionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Was this action useful to you?'**
  String get actionQuestion;

  /// No description provided for @actionUseful.
  ///
  /// In en, this message translates to:
  /// **'Useful'**
  String get actionUseful;

  /// No description provided for @actionNotUseful.
  ///
  /// In en, this message translates to:
  /// **'Show less of this for 7 days'**
  String get actionNotUseful;

  /// No description provided for @actionThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for the feedback.'**
  String get actionThanks;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionDoneThanks.
  ///
  /// In en, this message translates to:
  /// **'Marked as done.'**
  String get actionDoneThanks;

  /// No description provided for @actionAnother.
  ///
  /// In en, this message translates to:
  /// **'Another suggestion'**
  String get actionAnother;

  /// No description provided for @actionCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get actionCompletedLabel;

  /// No description provided for @allActionsSeen.
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen today\'s available suggestions. Ask directly what would help.'**
  String get allActionsSeen;

  /// No description provided for @legacyNotes.
  ///
  /// In en, this message translates to:
  /// **'Older phase notes (edit or delete)'**
  String get legacyNotes;

  /// No description provided for @logDateAction.
  ///
  /// In en, this message translates to:
  /// **'Log a date'**
  String get logDateAction;

  /// No description provided for @estimateFallback.
  ///
  /// In en, this message translates to:
  /// **'Few logs: initial {n}-day assumption, not personalized.'**
  String estimateFallback(int n);

  /// No description provided for @estimateFromLogs.
  ///
  /// In en, this message translates to:
  /// **'Based on {n} logged intervals; indicative margin of ±{band} days.'**
  String estimateFromLogs(int n, int band);

  /// No description provided for @estimateNotCertain.
  ///
  /// In en, this message translates to:
  /// **'The date may change; it cannot tell you how she feels.'**
  String get estimateNotCertain;

  /// No description provided for @estimateEvidence.
  ///
  /// In en, this message translates to:
  /// **'Dates cannot confirm phases or ovulation (Henry et al., 2024; Johnson et al., 2018).'**
  String get estimateEvidence;

  /// No description provided for @phaseDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'View approximate phase (optional)'**
  String get phaseDetailTitle;

  /// No description provided for @phaseDetailBody.
  ///
  /// In en, this message translates to:
  /// **'This is an approximation from dates, not an indication of mood, energy or availability.'**
  String get phaseDetailBody;

  /// No description provided for @onbSampleTitle.
  ///
  /// In en, this message translates to:
  /// **'This is what you\'ll get'**
  String get onbSampleTitle;

  /// No description provided for @onbSampleBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications only show a neutral message — details stay in the app.'**
  String get onbSampleBody;

  /// No description provided for @onbNotifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get onbNotifyTitle;

  /// No description provided for @onbNotifyBody.
  ///
  /// In en, this message translates to:
  /// **'Optional: use the button to enable generic reminders. You can start without them and change this later in Settings.'**
  String get onbNotifyBody;

  /// No description provided for @onbNotifyAction.
  ///
  /// In en, this message translates to:
  /// **'Enable and see a sample'**
  String get onbNotifyAction;

  /// No description provided for @onbBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onbBack;

  /// No description provided for @onbNext.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onbNext;

  /// No description provided for @onbDone.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onbDone;

  /// No description provided for @learningTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learningTitle;

  /// No description provided for @learningIntro.
  ///
  /// In en, this message translates to:
  /// **'Short cards about cycles, variability and support. Not a diagnosis — open, read, and mark done whenever you like.'**
  String get learningIntro;

  /// No description provided for @learningSource.
  ///
  /// In en, this message translates to:
  /// **'Where it comes from'**
  String get learningSource;

  /// No description provided for @learningQuiz.
  ///
  /// In en, this message translates to:
  /// **'Check your understanding'**
  String get learningQuiz;

  /// No description provided for @learningCheckRight.
  ///
  /// In en, this message translates to:
  /// **'Correct.'**
  String get learningCheckRight;

  /// No description provided for @learningCheckWrong.
  ///
  /// In en, this message translates to:
  /// **'Not quite — see the explanation.'**
  String get learningCheckWrong;

  /// No description provided for @learningDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get learningDone;

  /// No description provided for @learningCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get learningCompleted;

  /// No description provided for @entriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick notes'**
  String get entriesTitle;

  /// No description provided for @entryAdd.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get entryAdd;

  /// No description provided for @entrySharedKind.
  ///
  /// In en, this message translates to:
  /// **'Shared information'**
  String get entrySharedKind;

  /// No description provided for @entryReflectionKind.
  ///
  /// In en, this message translates to:
  /// **'Your reflection'**
  String get entryReflectionKind;

  /// No description provided for @entryPrompt.
  ///
  /// In en, this message translates to:
  /// **'What do you want to note?'**
  String get entryPrompt;

  /// No description provided for @entryKindHint.
  ///
  /// In en, this message translates to:
  /// **'\"Shared information\" is something she told you; \"Your reflection\" is what you think. Only reflections count as a care moment.'**
  String get entryKindHint;

  /// No description provided for @entryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get entryEdit;

  /// No description provided for @entryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get entryDelete;

  /// No description provided for @entryToPreference.
  ///
  /// In en, this message translates to:
  /// **'Make a preference'**
  String get entryToPreference;

  /// No description provided for @entryToReminder.
  ///
  /// In en, this message translates to:
  /// **'Make a reminder'**
  String get entryToReminder;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @reminderAdd.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get reminderAdd;

  /// No description provided for @reminderTitleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reminderTitleField;

  /// No description provided for @reminderWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get reminderWhen;

  /// No description provided for @reminderComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get reminderComplete;

  /// No description provided for @reminderDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete reminder'**
  String get reminderDelete;

  /// No description provided for @reminderEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet.'**
  String get reminderEmpty;

  /// No description provided for @reminderDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get reminderDoneLabel;

  /// No description provided for @todayQuickEntry.
  ///
  /// In en, this message translates to:
  /// **'Quick note'**
  String get todayQuickEntry;

  /// No description provided for @todayReminders.
  ///
  /// In en, this message translates to:
  /// **'Today\'s reminders'**
  String get todayReminders;

  /// No description provided for @todayLearning.
  ///
  /// In en, this message translates to:
  /// **'Learn something'**
  String get todayLearning;

  /// No description provided for @todayOpenLearning.
  ///
  /// In en, this message translates to:
  /// **'See cards'**
  String get todayOpenLearning;

  /// No description provided for @catHelp.
  ///
  /// In en, this message translates to:
  /// **'Practical help'**
  String get catHelp;

  /// No description provided for @catCommunicate.
  ///
  /// In en, this message translates to:
  /// **'Communicate'**
  String get catCommunicate;

  /// No description provided for @catCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get catCompany;

  /// No description provided for @catSpace.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get catSpace;

  /// No description provided for @catPrepare.
  ///
  /// In en, this message translates to:
  /// **'Prepare'**
  String get catPrepare;

  /// No description provided for @saveFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save'**
  String get saveFailedTitle;

  /// No description provided for @saveFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Your data is in this session but hasn\'t reached your phone yet. Try saving again.'**
  String get saveFailedBody;

  /// No description provided for @saveRetry.
  ///
  /// In en, this message translates to:
  /// **'Try to save'**
  String get saveRetry;

  /// No description provided for @calcDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'How we estimate (optional)'**
  String get calcDetailsTitle;

  /// No description provided for @gardenTitle.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get gardenTitle;

  /// No description provided for @gardenIntro.
  ///
  /// In en, this message translates to:
  /// **'Welcome back. Every care moment counts — nothing dies or loses progress when you take a break.'**
  String get gardenIntro;

  /// No description provided for @gardenOpen.
  ///
  /// In en, this message translates to:
  /// **'Open garden'**
  String get gardenOpen;

  /// No description provided for @gardenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plants yet. One care moment starts a seed.'**
  String get gardenEmpty;

  /// No description provided for @gardenActivePlant.
  ///
  /// In en, this message translates to:
  /// **'Growing'**
  String get gardenActivePlant;

  /// No description provided for @gardenCollection.
  ///
  /// In en, this message translates to:
  /// **'Mature plants'**
  String get gardenCollection;

  /// No description provided for @gardenWeeklyGoal.
  ///
  /// In en, this message translates to:
  /// **'This week\'s care: {n}/3'**
  String gardenWeeklyGoal(int n);

  /// No description provided for @gardenMoments.
  ///
  /// In en, this message translates to:
  /// **'{n} of 12 moments'**
  String gardenMoments(int n);

  /// No description provided for @gardenStageSeed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get gardenStageSeed;

  /// No description provided for @gardenStageSprout.
  ///
  /// In en, this message translates to:
  /// **'Sprout'**
  String get gardenStageSprout;

  /// No description provided for @gardenStageLeaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get gardenStageLeaves;

  /// No description provided for @gardenStageBuds.
  ///
  /// In en, this message translates to:
  /// **'Buds'**
  String get gardenStageBuds;

  /// No description provided for @gardenStageFlowering.
  ///
  /// In en, this message translates to:
  /// **'Flowering'**
  String get gardenStageFlowering;

  /// No description provided for @gardenStageMature.
  ///
  /// In en, this message translates to:
  /// **'Mature'**
  String get gardenStageMature;

  /// No description provided for @gardenVariety0.
  ///
  /// In en, this message translates to:
  /// **'Fern'**
  String get gardenVariety0;

  /// No description provided for @gardenVariety1.
  ///
  /// In en, this message translates to:
  /// **'Lavender'**
  String get gardenVariety1;

  /// No description provided for @gardenVariety2.
  ///
  /// In en, this message translates to:
  /// **'Succulent'**
  String get gardenVariety2;

  /// No description provided for @gardenName.
  ///
  /// In en, this message translates to:
  /// **'Name it'**
  String get gardenName;

  /// No description provided for @gardenPotStyle.
  ///
  /// In en, this message translates to:
  /// **'Pot style'**
  String get gardenPotStyle;

  /// No description provided for @gardenDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Plant detail'**
  String get gardenDetailTitle;

  /// No description provided for @gardenGrowthDates.
  ///
  /// In en, this message translates to:
  /// **'Growth dates'**
  String get gardenGrowthDates;

  /// No description provided for @gardenTotals.
  ///
  /// In en, this message translates to:
  /// **'Moments by type'**
  String get gardenTotals;

  /// No description provided for @gardenCatLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get gardenCatLearn;

  /// No description provided for @gardenCatAct.
  ///
  /// In en, this message translates to:
  /// **'Act'**
  String get gardenCatAct;

  /// No description provided for @gardenCatReflect.
  ///
  /// In en, this message translates to:
  /// **'Reflect'**
  String get gardenCatReflect;

  /// No description provided for @gardenNextHint.
  ///
  /// In en, this message translates to:
  /// **'Next care'**
  String get gardenNextHint;

  /// No description provided for @gardenShowTitle.
  ///
  /// In en, this message translates to:
  /// **'Show the garden'**
  String get gardenShowTitle;

  /// No description provided for @gardenShowBody.
  ///
  /// In en, this message translates to:
  /// **'Hides the garden in the app without losing any progress.'**
  String get gardenShowBody;

  /// No description provided for @gardenUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get gardenUnnamed;
}

class _AppLDelegate extends LocalizationsDelegate<AppL> {
  const _AppLDelegate();

  @override
  Future<AppL> load(Locale locale) {
    return SynchronousFuture<AppL>(lookupAppL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLDelegate old) => false;
}

AppL lookupAppL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLEn();
    case 'pt':
      return AppLPt();
  }

  throw FlutterError(
    'AppL.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
