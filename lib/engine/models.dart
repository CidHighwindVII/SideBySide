enum Phase { menstrual, follicular, ovulation, luteal, pms }

enum Confidence { low, medium, high }

enum Contraception { none, hormonal, unknown }

enum Traffic { green, yellow, red }

// energy appended last — existing order is load-bearing (§4.5/#8).
enum OutlookAxis { favor, news, out, energy }

enum ItemTag { sempre, juntos, apartados }

/// Action categories (implementation.md P1/P4). Drives Suggestions grouping and
/// selector variety; never changes the cohabitation tag filter or pick cap.
enum ActionCategory { help, communicate, company, space, prepare }

ActionCategory categoryFromName(String? name) => ActionCategory.values
    .firstWhere((c) => c.name == name, orElse: () => ActionCategory.help);

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
  // v0.4.0 (#7): gates writing cycle data to the Android widget prefs
  final bool widgetEnabled;
  // v0.13 (implementation.md P7): hide the garden UI without losing progress
  final bool gardenHidden;

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
    this.widgetEnabled = false,
    this.gardenHidden = false,
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
    bool? widgetEnabled,
    bool? gardenHidden,
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
        widgetEnabled: widgetEnabled ?? this.widgetEnabled,
        gardenHidden: gardenHidden ?? this.gardenHidden,
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
        'widgetEnabled': widgetEnabled,
        'gardenHidden': gardenHidden,
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
       widgetEnabled: j['widgetEnabled'] as bool? ?? false,
       gardenHidden: j['gardenHidden'] as bool? ?? false,
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

/// v0.3.0 (#18): user-written, phase-bound note surfaced in Today.
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

/// User-owned, phase-independent preference discussed with the partner.
class SupportPreference {
  final int id;
  final String category;
  final String text;
  const SupportPreference(this.id, this.category, this.text);

  Map<String, dynamic> toJson() => {'id': id, 'category': category, 'text': text};
  factory SupportPreference.fromJson(Map<String, dynamic> j) =>
      SupportPreference(j['id'] as int, j['category'] as String, j['text'] as String);
}

class ActionFeedback {
  final String date;
  final String actionId;
  final bool useful;
  const ActionFeedback(this.date, this.actionId, this.useful);

  Map<String, dynamic> toJson() =>
      {'date': date, 'actionId': actionId, 'useful': useful};
  factory ActionFeedback.fromJson(Map<String, dynamic> j) => ActionFeedback(
      j['date'] as String, j['actionId'] as String, j['useful'] as bool);
}

/// v0.13 (implementation.md P3): today's deterministic action selection, stored
/// per local calendar day so rebuilds/restarts keep the same pick and the
/// "Another suggestion" cursor survives. `order` holds stable ids.
class DaySelection {
  final String date; // yyyy-MM-dd
  final List<String> order;
  final int cursor; // index into `order` currently leading
  const DaySelection(this.date, this.order, this.cursor);

  DaySelection copyWith({List<String>? order, int? cursor}) =>
      DaySelection(date, order ?? this.order, cursor ?? this.cursor);

  Map<String, dynamic> toJson() =>
      {'date': date, 'order': order, 'cursor': cursor};
  factory DaySelection.fromJson(Map<String, dynamic> j) => DaySelection(
      j['date'] as String,
      (j['order'] as List? ?? const []).cast<String>(),
      j['cursor'] as int? ?? 0);
}

/// A practical action the user actually did — the `act` reward source. Kept
/// separate from usefulness ratings: a "useful" rating is NOT a completion.
class ActionCompletion {
  final int id;
  final String date; // yyyy-MM-dd local
  final String actionId; // stable catalog id or preference:<id>
  const ActionCompletion(this.id, this.date, this.actionId);

  Map<String, dynamic> toJson() =>
      {'id': id, 'date': date, 'actionId': actionId};
  factory ActionCompletion.fromJson(Map<String, dynamic> j) =>
      ActionCompletion(j['id'] as int, j['date'] as String,
          j['actionId'] as String);
}

/// Explicitly finished a learning card — the `learn` reward source.
class LearningCompletion {
  final String cardId;
  final String date; // yyyy-MM-dd local
  const LearningCompletion(this.cardId, this.date);

  Map<String, dynamic> toJson() => {'cardId': cardId, 'date': date};
  factory LearningCompletion.fromJson(Map<String, dynamic> j) =>
      LearningCompletion(j['cardId'] as String, j['date'] as String);
}

/// A quick note: `shared` = information from the partner, `reflection` = the
/// user's own reflection (the `reflect` reward source for reflections).
enum EntryKind { shared, reflection }

class QuickEntry {
  final int id;
  final String date; // yyyy-MM-dd local
  final EntryKind kind;
  final String text;
  final int? linkPreferenceId; // set when converted to a preference
  final String? linkActionId; // set when converted to/from a catalog action
  const QuickEntry(
      {required this.id,
      required this.date,
      required this.kind,
      required this.text,
      this.linkPreferenceId,
      this.linkActionId});

  QuickEntry copyWith(
          {String? text,
          EntryKind? kind,
          int? linkPreferenceId,
          String? linkActionId}) =>
      QuickEntry(
          id: id,
          date: date,
          kind: kind ?? this.kind,
          text: text ?? this.text,
          linkPreferenceId: linkPreferenceId ?? this.linkPreferenceId,
          linkActionId: linkActionId ?? this.linkActionId);

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'kind': kind.name,
        'text': text,
        if (linkPreferenceId != null) 'linkPreferenceId': linkPreferenceId,
        if (linkActionId != null) 'linkActionId': linkActionId,
      };
  factory QuickEntry.fromJson(Map<String, dynamic> j) => QuickEntry(
      id: j['id'] as int,
      date: j['date'] as String,
      kind: EntryKind.values.firstWhere((k) => k.name == j['kind'],
          orElse: () => EntryKind.shared),
      text: j['text'] as String,
      linkPreferenceId: j['linkPreferenceId'] as int?,
      linkActionId: j['linkActionId'] as String?);
}

/// A one-off local reminder, independent of cycle history.
class Reminder {
  final int id;
  final String title;
  final DateTime when; // local wall-clock
  final bool done;
  final int? linkPreferenceId;
  final String? linkActionId;
  const Reminder(
      {required this.id,
      required this.title,
      required this.when,
      this.done = false,
      this.linkPreferenceId,
      this.linkActionId});

  Reminder copyWith({String? title, DateTime? when, bool? done}) => Reminder(
      id: id,
      title: title ?? this.title,
      when: when ?? this.when,
      done: done ?? this.done,
      linkPreferenceId: linkPreferenceId,
      linkActionId: linkActionId);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'when': when.toIso8601String(),
        'done': done,
        if (linkPreferenceId != null) 'linkPreferenceId': linkPreferenceId,
        if (linkActionId != null) 'linkActionId': linkActionId,
      };
  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
      id: j['id'] as int,
      title: j['title'] as String,
      when: DateTime.parse(j['when'] as String),
      done: j['done'] as bool? ?? false,
      linkPreferenceId: j['linkPreferenceId'] as int?,
      linkActionId: j['linkActionId'] as String?);
}

/// Garden reward categories (implementation.md P6). Metadata carries no note
/// text or cycle detail — only what kind of activity earned the moment.
enum CareCategory { learn, act, reflect }

class CareEvent {
  final int id;
  final CareCategory category;
  final String date; // fixed local yyyy-MM-dd at award time
  final String source; // stable id of the activity, e.g. action/l/reminder id
  const CareEvent(this.id, this.category, this.date, this.source);

  Map<String, dynamic> toJson() =>
      {'id': id, 'category': category.name, 'date': date, 'source': source};
  factory CareEvent.fromJson(Map<String, dynamic> j) => CareEvent(
      j['id'] as int,
      CareCategory.values.firstWhere((c) => c.name == j['category'],
          orElse: () => CareCategory.act),
      j['date'] as String,
      j['source'] as String? ?? '');
}

/// A garden plant record. Growth is derived from `CareEvent`s; only the user's
/// naming/appearance edits are stored here, keyed by plant `index`.
class Plant {
  final int index; // ordinal in the garden (0 = first)
  final int variety; // 0..2 rotating variety
  final String? name;
  final int potStyle; // 0..2
  const Plant(
      {required this.index,
      required this.variety,
      this.name,
      this.potStyle = 0});

  Plant copyWith({String? name, int? potStyle}) =>
      Plant(index: index, variety: variety, name: name ?? this.name,
          potStyle: potStyle ?? this.potStyle);

  Map<String, dynamic> toJson() =>
      {'index': index, 'variety': variety, if (name != null) 'name': name,
        'potStyle': potStyle};
  factory Plant.fromJson(Map<String, dynamic> j) => Plant(
      index: j['index'] as int,
      variety: j['variety'] as int? ?? 0,
      name: j['name'] as String?,
      potStyle: j['potStyle'] as int? ?? 0);
}

class AppData {
  final Settings settings;
  final List<PeriodLog> logs; // sorted by start
  final List<ForecastFeedback> feedback;
  final List<Observation> observations; // sorted by date
  final List<CustomCard> customCards;
  final List<SupportPreference> preferences;
  final List<ActionFeedback> actionFeedback;
  // v0.13 (implementation.md P3) — new, all with safe empty defaults.
  final List<DaySelection> selections;
  final List<ActionCompletion> completions;
  final List<LearningCompletion> learning;
  final List<QuickEntry> entries;
  final List<Reminder> reminders;
  final List<CareEvent> careEvents;
  final List<Plant> plants;
  final int nextId; // persisted monotonic allocator for user records

  const AppData(
      {this.settings = const Settings(),
      this.logs = const [],
      this.feedback = const [],
      this.observations = const [],
      this.customCards = const [],
      this.preferences = const [],
      this.actionFeedback = const [],
      this.selections = const [],
      this.completions = const [],
      this.learning = const [],
      this.entries = const [],
      this.reminders = const [],
      this.careEvents = const [],
      this.plants = const [],
      this.nextId = 1});

  AppData copyWith(
          {Settings? settings,
          List<PeriodLog>? logs,
          List<ForecastFeedback>? feedback,
          List<Observation>? observations,
          List<CustomCard>? customCards,
          List<SupportPreference>? preferences,
          List<ActionFeedback>? actionFeedback,
          List<DaySelection>? selections,
          List<ActionCompletion>? completions,
          List<LearningCompletion>? learning,
          List<QuickEntry>? entries,
          List<Reminder>? reminders,
          List<CareEvent>? careEvents,
          List<Plant>? plants,
          int? nextId}) =>
      AppData(
          settings: settings ?? this.settings,
          logs: logs ?? this.logs,
          feedback: feedback ?? this.feedback,
          observations: observations ?? this.observations,
          customCards: customCards ?? this.customCards,
          preferences: preferences ?? this.preferences,
          actionFeedback: actionFeedback ?? this.actionFeedback,
          selections: selections ?? this.selections,
          completions: completions ?? this.completions,
          learning: learning ?? this.learning,
          entries: entries ?? this.entries,
          reminders: reminders ?? this.reminders,
          careEvents: careEvents ?? this.careEvents,
          plants: plants ?? this.plants,
          nextId: nextId ?? this.nextId);

  /// Allocate the next id for a persisted user record. Callers use the returned
  /// value and pass the incremented `nextId` into the same `_set` snapshot so
  /// ids stay unique across deletion and restart.
  (int id, int next) allocateId() => (nextId, nextId + 1);

  Map<String, dynamic> toJson() => {
        'settings': settings.toJson(),
        'logs': logs.map((l) => l.toJson()).toList(),
        'feedback': feedback.map((f) => f.toJson()).toList(),
        'observations': observations.map((o) => o.toJson()).toList(),
        'customCards': customCards.map((c) => c.toJson()).toList(),
        'preferences': preferences.map((p) => p.toJson()).toList(),
        'actionFeedback': actionFeedback.map((f) => f.toJson()).toList(),
        'selections': selections.map((s) => s.toJson()).toList(),
        'completions': completions.map((c) => c.toJson()).toList(),
        'learning': learning.map((l) => l.toJson()).toList(),
        'entries': entries.map((e) => e.toJson()).toList(),
        'reminders': reminders.map((r) => r.toJson()).toList(),
        'careEvents': careEvents.map((c) => c.toJson()).toList(),
        'plants': plants.map((p) => p.toJson()).toList(),
        'nextId': nextId,
      };

  factory AppData.fromJson(Map<String, dynamic> j) {
    final logs = (j['logs'] as List? ?? [])
        .map((e) => PeriodLog.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final preferences = (j['preferences'] as List? ?? [])
        .map((e) => SupportPreference.fromJson(e as Map<String, dynamic>))
        .toList();
    final entries = (j['entries'] as List? ?? [])
        .map((e) => QuickEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final reminders = (j['reminders'] as List? ?? [])
        .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
        .toList();
    final completions = (j['completions'] as List? ?? [])
        .map((e) => ActionCompletion.fromJson(e as Map<String, dynamic>))
        .toList();
    final careEvents = (j['careEvents'] as List? ?? [])
        .map((e) => CareEvent.fromJson(e as Map<String, dynamic>))
        .toList();
    final plants = (j['plants'] as List? ?? [])
        .map((e) => Plant.fromJson(e as Map<String, dynamic>))
        .toList();
    // Rebuild the allocator above every id already in use so a fresh record
    // can never collide with a preserved one (old JSON has no nextId).
    var highMark = (j['nextId'] as int? ?? 1) - 1;
    void bump(int? id) {
      if (id != null && id > highMark) highMark = id;
    }
    for (final p in preferences) {
      bump(p.id);
    }
    for (final e in entries) {
      bump(e.id);
    }
    for (final r in reminders) {
      bump(r.id);
    }
    for (final c in completions) {
      bump(c.id);
    }
    for (final c in careEvents) {
      bump(c.id);
    }
    for (final p in plants) {
      bump(p.index);
    }
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
      preferences: preferences,
      actionFeedback: (j['actionFeedback'] as List? ?? [])
          .map((e) => ActionFeedback.fromJson(e as Map<String, dynamic>))
          .toList(),
      selections: (j['selections'] as List? ?? [])
          .map((e) => DaySelection.fromJson(e as Map<String, dynamic>))
          .toList(),
      completions: completions,
      learning: (j['learning'] as List? ?? [])
          .map((e) => LearningCompletion.fromJson(e as Map<String, dynamic>))
          .toList(),
      entries: entries,
      reminders: reminders,
      careEvents: careEvents,
      plants: plants,
      nextId: highMark + 1,
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
