// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLEn extends AppL {
  AppLEn([String locale = 'en']) : super(locale);

  @override
  String get tabHoje => 'Dashboard';

  @override
  String get tabCalendario => 'Calendar';

  @override
  String get tabSugestoes => 'Suggestions';

  @override
  String get tabDefinicoes => 'Settings';

  @override
  String get phaseMenstrual => 'Menstrual';

  @override
  String get phaseFollicular => 'Follicular';

  @override
  String get phaseOvulation => 'Ovulation';

  @override
  String get phaseLuteal => 'Luteal';

  @override
  String get phasePms => 'PMS';

  @override
  String get statusLabel => 'Likely phase';

  @override
  String get confHigh => 'high confidence';

  @override
  String get confMedium => 'medium confidence';

  @override
  String get confLow => 'limited estimate';

  @override
  String get suggestionsTitle => 'For today';

  @override
  String get warningsTitle => 'Better avoid';

  @override
  String get contextTitle => 'For context';

  @override
  String get axisFavor => 'Ask favors';

  @override
  String get axisNews => 'Give bad news';

  @override
  String get axisOut => 'Go out & plan';

  @override
  String get axisEnergy => 'Energy';

  @override
  String get searchTitle => 'Search all suggestions';

  @override
  String get searchHint => 'Type to search';

  @override
  String get searchEmpty => 'Nothing found.';

  @override
  String get searchAllPhases => 'All';

  @override
  String get varianceTitle => 'Cycle variance';

  @override
  String varianceAvg(int n) {
    return 'avg: $n days';
  }

  @override
  String get weekendTimeTitle => 'Different time on weekends';

  @override
  String get weekendBriefingTime => 'Weekend briefing time';

  @override
  String get supportTitle => 'Intensive support';

  @override
  String get supportBody =>
      'Shows luteal support notes first. It\'s your preference, not a diagnosis.';

  @override
  String get obsTitle => 'Log an observation';

  @override
  String get obsBody =>
      'What you noticed today — your notes, not clinical data.';

  @override
  String get obsLegend => 'observation logged';

  @override
  String get patternTitle => 'Pattern in your notes';

  @override
  String get patternCaption =>
      'Spread across phases — your notes, not clinical data.';

  @override
  String get obsCalm => 'Calm';

  @override
  String get obsTired => 'Tired';

  @override
  String get obsSensitive => 'Sensitive';

  @override
  String get obsGoodMood => 'Good mood';

  @override
  String get obsIrritable => 'Irritable';

  @override
  String get obsCramps => 'Cramps';

  @override
  String get obsHeadache => 'Headache';

  @override
  String get obsBloating => 'Bloating';

  @override
  String get obsCravings => 'Cravings';

  @override
  String get obsSleepless => 'Slept badly';

  @override
  String get save => 'Save';

  @override
  String get customTitle => 'Your notes';

  @override
  String get customAdd => 'Add note';

  @override
  String get customText => 'What you want to remember';

  @override
  String get lockTitle => 'App lock';

  @override
  String get lockBody =>
      'Biometrics or PIN to open. The PIN stays only on your phone.';

  @override
  String get lockDisable => 'PIN to disable';

  @override
  String get lockTitleScreen => 'Unlock SideBySide';

  @override
  String get lockPinField => 'PIN';

  @override
  String get lockPinSet => 'Set a PIN (4–6 digits)';

  @override
  String get lockPinConfirm => 'Repeat the PIN';

  @override
  String get lockPinMismatch => 'PINs don\'t match';

  @override
  String get lockPinBad => 'Wrong PIN';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get lockBiometric => 'Use biometrics';

  @override
  String get lockBiometricReason => 'Unlock SideBySide';

  @override
  String get widgetTitle => 'Home screen widget';

  @override
  String get widgetBody =>
      'Shows the probable phase and tomorrow\'s traffic light. Android only.';

  @override
  String get dataTitle => 'Data';

  @override
  String get deviceFail => 'Couldn\'t complete on this device.';

  @override
  String get calTitle => 'Add to calendar';

  @override
  String get calBody =>
      'Writes the next 14 days to your calendar with the neutral title \"SxS\" — nothing revealing. Warning: if your calendar syncs with Google/Apple, these events leave the phone.';

  @override
  String get avgTitle => 'Averages in use';

  @override
  String get avgAuto => 'automatic — median of your logs';

  @override
  String get avgFallback => 'starting average — still few logs';

  @override
  String get avgFromLogs =>
      'The app computes cycle and period length from your logs — you don\'t need to set them.';

  @override
  String get trafficGreen => 'good';

  @override
  String get trafficYellow => 'careful';

  @override
  String get trafficRed => 'avoid';

  @override
  String get tomorrowCard => 'Tomorrow';

  @override
  String get tomorrowPreview => 'See tomorrow ↓';

  @override
  String get feedbackQuestion => 'Did the forecast match?';

  @override
  String get feedbackThanks => 'Thanks — saved.';

  @override
  String get confirmTitle => 'Confirm date';

  @override
  String get confirmBody =>
      'Your period forecast passed without a log. Confirm the real date?';

  @override
  String get confirmAction => 'Log now';

  @override
  String get confirmDismiss => 'Not yet';

  @override
  String get hormonalBanner =>
      'With hormonal contraception, phases may not reflect reality.';

  @override
  String get healthNudge =>
      'Your cycles vary a lot — worth a peek with a professional. Not an alarm or a diagnosis.';

  @override
  String get healthNudgeOk => 'Got it';

  @override
  String get noForecast => 'No forecast — log a period to resume.';

  @override
  String get noDataYet => 'Tap a day in the Calendar to mark the period start.';

  @override
  String calendarBandPeriod(int n) {
    return 'expected period (±$n days)';
  }

  @override
  String calendarBandOvulation(int n) {
    return 'expected fertile window (±$n days)';
  }

  @override
  String get calendarLogged => 'logged';

  @override
  String get calendarFuture => 'planned by you';

  @override
  String get calendarExpectedPeriod => 'expected period';

  @override
  String get calendarExpectedFertile => 'expected fertile window';

  @override
  String get calendarToday => 'Today';

  @override
  String get tipOfDayTitle => 'Tip of the day';

  @override
  String get contraception => 'Contraception';

  @override
  String get contrNone => 'None';

  @override
  String get contrHormonal => 'Hormonal';

  @override
  String get contrUnknown => 'Unknown';

  @override
  String get liveTogether => 'Living together?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get profileTitle => 'Profile';

  @override
  String get settingsBriefing => 'Tomorrow briefing';

  @override
  String get settingsBriefingTime => 'Briefing time';

  @override
  String get settingsHeadsUp => '\"Period expected in ~2 days\" heads-up';

  @override
  String get settingsWipe => 'Delete all data';

  @override
  String get settingsWipeConfirm => 'Deleting erases all data. No recovery.';

  @override
  String todayCycleDay(int day) {
    return 'Day $day of the cycle';
  }

  @override
  String todayNextPeriod(String date) {
    return 'Next period: $date';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get calMarkStart => 'Mark period start';

  @override
  String get calMarkEnd => 'Mark period end';

  @override
  String get calUnmarkStart => 'Unmark period start';

  @override
  String get calUnmarkEnd => 'Unmark period end';

  @override
  String get periodTooShort => 'A period usually lasts at least ~3 days.';

  @override
  String get periodTooSoon =>
      'A period usually doesn\'t start less than ~10 days after the previous one.';

  @override
  String get notifBriefTitle => 'SideBySide';

  @override
  String get notifBriefRed =>
      'Tomorrow\'s forecast: 🔴 delicate day. See the recommendations.';

  @override
  String get notifBriefYellow =>
      'Tomorrow\'s forecast: 🟡 careful day. See the recommendations.';

  @override
  String get notifBriefGreen =>
      'Tomorrow\'s forecast: 🟢 good day. See the recommendations.';

  @override
  String get notifHeadsUpTitle => 'SideBySide';

  @override
  String get notifHeadsUpBody =>
      'Period expected in ~2 days. See the recommendations.';

  @override
  String get ofToday => 'from today';

  @override
  String get onbSetupTitle => 'Get started';

  @override
  String get onbSetupBody =>
      'How are things at home? The app learns your rhythms from your logs.';

  @override
  String get onbAvgCycle => 'Average cycle length';

  @override
  String get onbAvgPeriod => 'Period length';

  @override
  String onbDays(int n) {
    return '$n days';
  }

  @override
  String get onbLogTitle => 'Log the last period';

  @override
  String get onbLogBody =>
      'When did it start? The end is optional — you can skip and log later in the Calendar.';

  @override
  String get onbLogStart => 'Period start';

  @override
  String get onbLogEnd => 'Period end (optional)';

  @override
  String get onbNotSet => 'Tap to choose';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbTimeTitle => 'Briefing time';

  @override
  String get onbTimeBody =>
      'Once a day, at the time you pick, a neutral forecast for tomorrow.';

  @override
  String get onbSampleTitle => 'This is what you\'ll get';

  @override
  String get onbSampleBody =>
      'On the lock screen you only see the traffic light — details stay in the app.';

  @override
  String get onbNotifyTitle => 'Enable notifications';

  @override
  String get onbNotifyBody =>
      'Without permission the briefing can\'t arrive. You can change this later in Settings.';

  @override
  String get onbNotifyAction => 'Enable and see a sample';

  @override
  String get onbBack => 'Back';

  @override
  String get onbNext => 'Continue';

  @override
  String get onbDone => 'Start';
}
