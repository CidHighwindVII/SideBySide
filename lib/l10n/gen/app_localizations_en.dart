// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLEn extends AppL {
  AppLEn([String locale = 'en']) : super(locale);

  @override
  String get tabHoje => 'Today';

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
  String get confHigh => 'more consistent logged dates';

  @override
  String get confMedium => 'estimate with some history';

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
  String get searchTitle => 'Search support ideas';

  @override
  String get searchHint => 'Type to search';

  @override
  String get searchEmpty => 'Nothing found.';

  @override
  String get catalogUnavailable =>
      'Suggestions could not be loaded. Restart the app to try again.';

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
  String get supportTitle => 'Prioritize offers of help';

  @override
  String get supportBody =>
      'Shows offers of help first, without inferring her preferences from a cycle.';

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
  String get widgetTitle => 'Home screen widget';

  @override
  String get widgetBody =>
      'Only shows a neutral prompt to open the app. Android only.';

  @override
  String get widgetPrompt => 'Check the app';

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
  String get feedbackQuestion => 'Was this suggestion useful?';

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
  String get healthNudge =>
      'Your cycles vary a lot — worth a peek with a professional. Not an alarm or a diagnosis.';

  @override
  String get healthNudgeOk => 'Got it';

  @override
  String get noForecast =>
      'No current forecast — log a date to start estimating again.';

  @override
  String get noDataYet =>
      'No dates logged yet. You can start with the last period date.';

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
  String get calendarExpectedPeriod => 'estimated period; the date may change';

  @override
  String get calendarExpectedFertile => 'estimated fertile window (6 days)';

  @override
  String calendarFertileUncertainty(int n) {
    return 'fertile-window uncertainty (±$n days)';
  }

  @override
  String get calendarNoBand =>
      'No period or fertile-window estimates (hormonal contraception). Logged bleeding stays visible.';

  @override
  String get unknownContrNote =>
      'Contraception is set to unknown. Estimates assume a natural cycle and may not apply — confirm in Settings.';

  @override
  String get unknownContrAction => 'Set contraception';

  @override
  String get calendarToday => 'Today';

  @override
  String get tipOfDayTitle => 'Tip of the day';

  @override
  String get prepTitle => 'Prepare thoughtfully';

  @override
  String get prepBody =>
      'The next period may be near. If it works for you both, ask what she needs and prepare the essentials — the estimate can change.';

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
  String get settingsHeadsUp =>
      'Preparation reminder (details in the app only)';

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
    return 'Estimated next period: $date';
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
      'In this app, logged period starts must be at least 21 days apart.';

  @override
  String get notifBriefTitle => 'SideBySide';

  @override
  String get notifBriefBody => 'There\'s an update to view in the app.';

  @override
  String get notifHeadsUpTitle => 'SideBySide';

  @override
  String get notifHeadsUpBody => 'There\'s a note to check in the app.';

  @override
  String get notifReminderTitle => 'SideBySide';

  @override
  String get notifReminderBody => 'There\'s a reminder to view in the app.';

  @override
  String get ofToday => 'from today';

  @override
  String get onbSetupTitle => 'Get started';

  @override
  String get onbSetupBody =>
      'Only log dates you know. Ask about her needs; don\'t try to predict them.';

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
      'At the time you choose, receive a generic reminder to check the app. You can turn it off later.';

  @override
  String get preferenceTitle => 'Support you agreed on';

  @override
  String get preferenceConsent =>
      'Only save preferences you have discussed. Edit or delete them any time; the app cannot verify her consent.';

  @override
  String get preferenceAdd => 'Add agreed preference';

  @override
  String get preferenceEdit => 'Edit preference';

  @override
  String get preferenceDelete => 'Delete preference';

  @override
  String get preferenceCategory => 'Kind of support';

  @override
  String get preferenceCheckIn => 'Check in';

  @override
  String get preferenceHelp => 'Practical help';

  @override
  String get preferenceSpace => 'Give space';

  @override
  String get preferenceText => 'What did you agree to remember?';

  @override
  String get agreedPreference =>
      'A preference you saved — always check if it still fits.';

  @override
  String get actionQuestion => 'Was this action useful to you?';

  @override
  String get actionUseful => 'Useful';

  @override
  String get actionNotUseful => 'Show less of this for 7 days';

  @override
  String get actionThanks => 'Thanks for the feedback.';

  @override
  String get actionDone => 'Done';

  @override
  String get actionDoneThanks => 'Marked as done.';

  @override
  String get actionAnother => 'Another suggestion';

  @override
  String get actionCompletedLabel => 'Done today';

  @override
  String get allActionsSeen =>
      'You\'ve seen today\'s available suggestions. Ask directly what would help.';

  @override
  String get legacyNotes => 'Older phase notes (edit or delete)';

  @override
  String get logDateAction => 'Log a date';

  @override
  String estimateFallback(int n) {
    return 'Few logs: initial $n-day assumption, not personalized.';
  }

  @override
  String estimateFromLogs(int n, int band) {
    return 'Based on $n logged intervals; indicative margin of ±$band days.';
  }

  @override
  String get estimateNotCertain =>
      'The date may change; it cannot tell you how she feels.';

  @override
  String get estimateEvidence =>
      'Dates cannot confirm phases or ovulation (Henry et al., 2024; Johnson et al., 2018).';

  @override
  String get phaseDetailTitle => 'View approximate phase (optional)';

  @override
  String get phaseDetailBody =>
      'This is an approximation from dates, not an indication of mood, energy or availability.';

  @override
  String get onbSampleTitle => 'This is what you\'ll get';

  @override
  String get onbSampleBody =>
      'Notifications only show a neutral message — details stay in the app.';

  @override
  String get onbNotifyTitle => 'Enable notifications';

  @override
  String get onbNotifyBody =>
      'Optional: use the button to enable generic reminders. You can start without them and change this later in Settings.';

  @override
  String get onbNotifyAction => 'Enable and see a sample';

  @override
  String get onbBack => 'Back';

  @override
  String get onbNext => 'Continue';

  @override
  String get onbDone => 'Start';

  @override
  String get learningTitle => 'Learn';

  @override
  String get learningIntro =>
      'Short cards about cycles, variability and support. Not a diagnosis — open, read, and mark done whenever you like.';

  @override
  String get learningSource => 'Where it comes from';

  @override
  String get learningQuiz => 'Check your understanding';

  @override
  String get learningCheckRight => 'Correct.';

  @override
  String get learningCheckWrong => 'Not quite — see the explanation.';

  @override
  String get learningDone => 'Mark as done';

  @override
  String get learningCompleted => 'Completed';

  @override
  String get entriesTitle => 'Quick notes';

  @override
  String get entryAdd => 'Add note';

  @override
  String get entrySharedKind => 'Shared information';

  @override
  String get entryReflectionKind => 'Your reflection';

  @override
  String get entryPrompt => 'What do you want to note?';

  @override
  String get entryKindHint =>
      '\"Shared information\" is something she told you; \"Your reflection\" is what you think. Only reflections count as a care moment.';

  @override
  String get entryEdit => 'Edit note';

  @override
  String get entryDelete => 'Delete note';

  @override
  String get entryToPreference => 'Make a preference';

  @override
  String get entryToReminder => 'Make a reminder';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get reminderAdd => 'New reminder';

  @override
  String get reminderTitleField => 'Title';

  @override
  String get reminderWhen => 'When';

  @override
  String get reminderComplete => 'Complete';

  @override
  String get reminderDelete => 'Delete reminder';

  @override
  String get reminderEmpty => 'No reminders yet.';

  @override
  String get reminderDoneLabel => 'Completed';

  @override
  String get todayQuickEntry => 'Quick note';

  @override
  String get todayReminders => 'Today\'s reminders';

  @override
  String get todayLearning => 'Learn something';

  @override
  String get todayOpenLearning => 'See cards';

  @override
  String get catHelp => 'Practical help';

  @override
  String get catCommunicate => 'Communicate';

  @override
  String get catCompany => 'Company';

  @override
  String get catSpace => 'Space';

  @override
  String get catPrepare => 'Prepare';

  @override
  String get saveFailedTitle => 'Couldn\'t save';

  @override
  String get saveFailedBody =>
      'Your data is in this session but hasn\'t reached your phone yet. Try saving again.';

  @override
  String get saveRetry => 'Try to save';

  @override
  String get calcDetailsTitle => 'How we estimate (optional)';

  @override
  String get gardenTitle => 'Garden';

  @override
  String get gardenIntro =>
      'Welcome back. Every care moment counts — nothing dies or loses progress when you take a break.';

  @override
  String get gardenOpen => 'Open garden';

  @override
  String get gardenEmpty => 'No plants yet. One care moment starts a seed.';

  @override
  String get gardenActivePlant => 'Growing';

  @override
  String get gardenCollection => 'Mature plants';

  @override
  String gardenWeeklyGoal(int n) {
    return 'This week\'s care: $n/3';
  }

  @override
  String gardenMoments(int n) {
    return '$n of 12 moments';
  }

  @override
  String get gardenStageSeed => 'Seed';

  @override
  String get gardenStageSprout => 'Sprout';

  @override
  String get gardenStageLeaves => 'Leaves';

  @override
  String get gardenStageBuds => 'Buds';

  @override
  String get gardenStageFlowering => 'Flowering';

  @override
  String get gardenStageMature => 'Mature';

  @override
  String get gardenVariety0 => 'Fern';

  @override
  String get gardenVariety1 => 'Lavender';

  @override
  String get gardenVariety2 => 'Succulent';

  @override
  String get gardenName => 'Name it';

  @override
  String get gardenPotStyle => 'Pot style';

  @override
  String get gardenDetailTitle => 'Plant detail';

  @override
  String get gardenGrowthDates => 'Growth dates';

  @override
  String get gardenTotals => 'Moments by type';

  @override
  String get gardenCatLearn => 'Learn';

  @override
  String get gardenCatAct => 'Act';

  @override
  String get gardenCatReflect => 'Reflect';

  @override
  String get gardenNextHint => 'Next care';

  @override
  String get gardenShowTitle => 'Show the garden';

  @override
  String get gardenShowBody =>
      'Hides the garden in the app without losing any progress.';

  @override
  String get gardenUnnamed => 'Unnamed';
}
