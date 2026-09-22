enum Phase { menstrual, follicular, ovulation, luteal, pms }

enum Confidence { low, medium, high }

enum Contraception { none, hormonal, unknown }

enum Traffic { green, yellow, red }

// energy appended last — existing order is load-bearing (§4.5/#8).
enum OutlookAxis { favor, news, out, energy }

enum ItemTag { sempre, juntos, apartados }

class PeriodLog {
  final DateTime start;
  final DateTime? end;

  const PeriodLog(this.start, this.end);

  bool isFuture(DateTime today) => start.isAfter(today);

  PeriodLog copyWith({DateTime? start, DateTime? end}) =>
      PeriodLog(start ?? this.start, end ?? this.end);

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        if (end == null) 'futureDated': true,
      };

  factory PeriodLog.fromJson(Map<String, dynamic> j) => PeriodLog(
        DateTime.parse(j['start'] as String),
        j['end'] == null ? null : DateTime.parse(j['end'] as String),
      );
}

class Settings {
  final int avgLength; // v0.6.0 (D20): hidden pre-data seed, no UI edits it
  final int periodLength;
  // ponytail: pin flags kept so old JSON still parses; engine ignores them
  // since D20. Drop the fields + toJson/fromJson after one release.
  final bool cyclePinned;
  final bool periodPinned;
  final Contraception contraception;
  final bool liveTogether;
  final int briefingHour;
  final int briefingMinute;
  final bool briefingEnabled;
  final bool headsUpEnabled;
  final bool healthNudgeShown;
  final bool onboarded;
  // v0.2.0 (#9): weekend briefing time
  final bool weekendTimeEnabled;
  final int weekendBriefingHour;
  final int weekendBriefingMinute;
  // v0.3.0 (#15): user-declared "apoio intensivo" re-ranks Luteal content
  final bool intensiveSupport;
  // v0.3.0 (#3): app lock — salted PIN hash lives in the one JSON file
  final bool appLockEnabled;
  final String? pinSalt;
  final String? pinHash;
  // v0.4.0 (#7): gates writing cycle data to the Android widget prefs
  final bool widgetEnabled;

  const Settings({
    this.avgLength = 28,
    this.periodLength = 5,
    this.cyclePinned = false,
    this.periodPinned = false,
    this.contraception = Contraception.unknown,
    this.liveTogether = true,
    this.briefingHour = 21,
    this.briefingMinute = 0,
    this.briefingEnabled = true,
    this.headsUpEnabled = true,
    this.healthNudgeShown = false,
    this.onboarded = false,
    this.weekendTimeEnabled = false,
    this.weekendBriefingHour = 21,
    this.weekendBriefingMinute = 0,
    this.intensiveSupport = false,
    this.appLockEnabled = false,
    this.pinSalt,
    this.pinHash,
    this.widgetEnabled = false,
  });

  Settings copyWith({
    int? avgLength,
    int? periodLength,
    bool? cyclePinned,
    bool? periodPinned,
    Contraception? contraception,
    bool? liveTogether,
    int? briefingHour,
    int? briefingMinute,
    bool? briefingEnabled,
    bool? headsUpEnabled,
    bool? healthNudgeShown,
    bool? onboarded,
    bool? weekendTimeEnabled,
    int? weekendBriefingHour,
    int? weekendBriefingMinute,
    bool? intensiveSupport,
    bool? appLockEnabled,
    String? pinSalt,
    String? pinHash,
    bool clearPin = false,
    bool? widgetEnabled,
  }) =>
      Settings(
        avgLength: avgLength ?? this.avgLength,
        periodLength: periodLength ?? this.periodLength,
        cyclePinned: cyclePinned ?? this.cyclePinned,
        periodPinned: periodPinned ?? this.periodPinned,
        contraception: contraception ?? this.contraception,
        liveTogether: liveTogether ?? this.liveTogether,
        briefingHour: briefingHour ?? this.briefingHour,
        briefingMinute: briefingMinute ?? this.briefingMinute,
        briefingEnabled: briefingEnabled ?? this.briefingEnabled,
        headsUpEnabled: headsUpEnabled ?? this.headsUpEnabled,
        healthNudgeShown: healthNudgeShown ?? this.healthNudgeShown,
        onboarded: onboarded ?? this.onboarded,
        weekendTimeEnabled: weekendTimeEnabled ?? this.weekendTimeEnabled,
        weekendBriefingHour: weekendBriefingHour ?? this.weekendBriefingHour,
        weekendBriefingMinute:
            weekendBriefingMinute ?? this.weekendBriefingMinute,
        intensiveSupport: intensiveSupport ?? this.intensiveSupport,
        appLockEnabled: appLockEnabled ?? this.appLockEnabled,
        pinSalt: clearPin ? null : (pinSalt ?? this.pinSalt),
        pinHash: clearPin ? null : (pinHash ?? this.pinHash),
        widgetEnabled: widgetEnabled ?? this.widgetEnabled,
      );

  Map<String, dynamic> toJson() => {
        'avgLength': avgLength,
        'periodLength': periodLength,
        'pinnedAverages': {'cycle': cyclePinned, 'period': periodPinned},
        'contraception': contraception.name,
        'liveTogether': liveTogether,
        'briefingTime': '$briefingHour:$briefingMinute',
        'briefingEnabled': briefingEnabled,
        'headsUpEnabled': headsUpEnabled,
        'healthNudgeShown': healthNudgeShown,
        'onboarded': onboarded,
        'weekendTimeEnabled': weekendTimeEnabled,
        'weekendTime': '$weekendBriefingHour:$weekendBriefingMinute',
        'intensiveSupport': intensiveSupport,
        'appLockEnabled': appLockEnabled,
        if (pinSalt != null) 'pinSalt': pinSalt,
        if (pinHash != null) 'pinHash': pinHash,
        'widgetEnabled': widgetEnabled,
      };

  factory Settings.fromJson(Map<String, dynamic> j) {
    final pinned = j['pinnedAverages'] as Map<String, dynamic>? ?? {};
    final bt = (j['briefingTime'] as String? ?? '21:0').split(':');
    final wbt = (j['weekendTime'] as String? ?? '21:0').split(':');
    return Settings(
      avgLength: j['avgLength'] as int? ?? 28,
      periodLength: j['periodLength'] as int? ?? 5,
      cyclePinned: pinned['cycle'] as bool? ?? false,
      periodPinned: pinned['period'] as bool? ?? false,
      contraception: Contraception.values.firstWhere(
          (e) => e.name == j['contraception'],
          orElse: () => Contraception.unknown),
      liveTogether: j['liveTogether'] as bool? ?? true,
      briefingHour: int.tryParse(bt[0]) ?? 21,
      briefingMinute: bt.length > 1 ? int.tryParse(bt[1]) ?? 0 : 0,
      briefingEnabled: j['briefingEnabled'] as bool? ?? true,
      headsUpEnabled: j['headsUpEnabled'] as bool? ?? true,
      healthNudgeShown: j['healthNudgeShown'] as bool? ?? false,
      onboarded: j['onboarded'] as bool? ?? false,
      weekendTimeEnabled: j['weekendTimeEnabled'] as bool? ?? false,
      weekendBriefingHour: int.tryParse(wbt[0]) ?? 21,
      weekendBriefingMinute: wbt.length > 1 ? int.tryParse(wbt[1]) ?? 0 : 0,
      intensiveSupport: j['intensiveSupport'] as bool? ?? false,
       appLockEnabled: j['appLockEnabled'] as bool? ?? false,
       pinSalt: j['pinSalt'] as String?,
       pinHash: j['pinHash'] as String?,
       widgetEnabled: j['widgetEnabled'] as bool? ?? false,
     );
  }
}

class ForecastFeedback {
  final String date; // yyyy-MM-dd
  final bool thumbsUp;
  const ForecastFeedback(this.date, this.thumbsUp);

  Map<String, dynamic> toJson() => {'date': date, 'thumbs': thumbsUp};
  factory ForecastFeedback.fromJson(Map<String, dynamic> j) =>
      ForecastFeedback(j['date'] as String, j['thumbs'] as bool);
}

/// v0.3.0 (#4): partner's own dated observations (mood/symptom tags).
/// Never stores a phase — phase is derived at read time (§3 honesty).
class Observation {
  final String date; // yyyy-MM-dd
  final List<String> tags;
  const Observation(this.date, this.tags);

  Map<String, dynamic> toJson() => {'date': date, 'tags': tags};
  factory Observation.fromJson(Map<String, dynamic> j) => Observation(
      j['date'] as String, (j['tags'] as List? ?? []).cast<String>());
}

/// v0.3.0 (#18): user-written, phase-bound note surfaced in Hoje.
class CustomCard {
  final Phase phase;
  final String text;
  const CustomCard(this.phase, this.text);

  Map<String, dynamic> toJson() => {'phase': phase.name, 'text': text};
  factory CustomCard.fromJson(Map<String, dynamic> j) => CustomCard(
      Phase.values.firstWhere((p) => p.name == j['phase'],
          orElse: () => Phase.luteal),
      j['text'] as String);
}

class AppData {
  final Settings settings;
  final List<PeriodLog> logs; // sorted by start
  final List<ForecastFeedback> feedback;
  final List<Observation> observations; // sorted by date
  final List<CustomCard> customCards;

  const AppData(
      {this.settings = const Settings(),
      this.logs = const [],
      this.feedback = const [],
      this.observations = const [],
      this.customCards = const []});

  AppData copyWith(
          {Settings? settings,
          List<PeriodLog>? logs,
          List<ForecastFeedback>? feedback,
          List<Observation>? observations,
          List<CustomCard>? customCards}) =>
      AppData(
          settings: settings ?? this.settings,
          logs: logs ?? this.logs,
          feedback: feedback ?? this.feedback,
          observations: observations ?? this.observations,
          customCards: customCards ?? this.customCards);

  Map<String, dynamic> toJson() => {
        'settings': settings.toJson(),
        'logs': logs.map((l) => l.toJson()).toList(),
        'feedback': feedback.map((f) => f.toJson()).toList(),
        'observations': observations.map((o) => o.toJson()).toList(),
        'customCards': customCards.map((c) => c.toJson()).toList(),
      };

  factory AppData.fromJson(Map<String, dynamic> j) {
    final logs = (j['logs'] as List? ?? [])
        .map((e) => PeriodLog.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return AppData(
      settings:
          Settings.fromJson(j['settings'] as Map<String, dynamic>? ?? {}),
      logs: logs,
      feedback: (j['feedback'] as List? ?? [])
          .map((e) => ForecastFeedback.fromJson(e as Map<String, dynamic>))
          .toList(),
      observations: (j['observations'] as List? ?? [])
          .map((e) => Observation.fromJson(e as Map<String, dynamic>))
          .toList(),
      customCards: (j['customCards'] as List? ?? [])
          .map((e) => CustomCard.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static ForecastFeedback? forecastFeedbackFor(List<ForecastFeedback> all, String date) {
    for (final f in all) {
      if (f.date == date) return f;
    }
    return null;
  }

  static Observation? observationFor(List<Observation> all, String date) {
    for (final o in all) {
      if (o.date == date) return o;
    }
    return null;
  }
}
