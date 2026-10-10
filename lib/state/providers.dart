import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/catalog.dart';
import '../data/feeling_catalog.dart';
import '../data/learning_catalog.dart';
import '../data/store.dart';
import '../data/summarization.dart';
import '../engine/cycle_engine.dart';
import '../engine/feeling_selector.dart';
import '../engine/garden_engine.dart';
import '../engine/models.dart';
import '../log.dart';

final storeProvider = Provider((_) => Store());

/// Local calendar date; override in widget tests to avoid midnight-sensitive UI.
final todayProvider = Provider<DateTime>((_) => CycleEngine.dateOnly(DateTime.now()));

/// Whether the last persistence attempt failed, surfaced so the UI can warn and
/// offer a retry. In-memory state stays authoritative regardless.
enum SaveState { ok, failed }

class AppDataNotifier extends StateNotifier<AppData> {
  final Store _store;
  Future<void> _pending = Future<void>.value();
  AppDataNotifier(this._store, super.initial);

  /// Latest save outcome for new persistent interactions. A failed write keeps
  /// the data in memory and flips this to `failed` until a save succeeds.
  final ValueNotifier<SaveState> saveState = ValueNotifier<SaveState>(SaveState.ok);

  /// Wait until queued writes have completed (or failed and been logged).
  Future<void> get persistenceIdle => _pending;

  /// Publish immediately, but commit snapshots in the same order. A failed
  /// write must not poison the queue or let an older save finish after wipe.
  Future<bool> _set(AppData next, {bool wipe = false}) {
    state = next;
    final operation = _pending.then((_) async {
      try {
        if (wipe) {
          await _store.wipe();
        } else {
          await _store.save(next);
        }
        saveState.value = SaveState.ok;
        return true;
      } catch (e, s) {
        logErr('store', e, s); // state stays in memory; report write failure
        saveState.value = SaveState.failed;
        return false;
      }
    });
    _pending = operation.then((_) {});
    return operation;
  }

  /// Re-persist the current in-memory snapshot after a failure. Because the
  /// activity and its garden reward already live in `state`, retrying only
  /// rewrites the same snapshot — it can never duplicate a reward.
  Future<bool> retrySave() => _set(state);

  void updateSettings(Settings s) => _set(state.copyWith(settings: s));

  /// Every period-start write goes through this gate: a start closer than 21
  /// calendar days to any *other* recorded start (earlier or later) is
  /// rejected at the mutation layer, so no logging entry point can bypass the
  /// spacing rule. Marking/unmarking an end keeps the same start and passes.
  bool saveLog(PeriodLog log) {
    if (!CycleEngine.startSpacingOk(state.logs, log.start)) return false;
    final logs = [...state.logs.where((l) => l.start != log.start), log]
      ..sort((a, b) => a.start.compareTo(b.start));
    _set(state.copyWith(logs: logs));
    return true;
  }

  void deleteLog(PeriodLog log) =>
      _set(state.copyWith(logs: state.logs.where((l) => l != log).toList()));

  void feedback(String date, bool thumbsUp) {
    final others = state.feedback.where((f) => f.date != date).toList();
    _set(state.copyWith(feedback: [...others, ForecastFeedback(date, thumbsUp)]));
  }

  // ---------- feeling records (upsert; empty entries deletes) ----------

  /// One dated feeling record per calendar day. Selections are always
  /// user-chosen; intensity is optional and never inferred.
  void saveFeelingLog(String date, List<FeelingEntry> entries) {
    final others = state.feelingLogs.where((f) => f.date != date).toList();
    final validCustoms = state.customFeelings.map((c) => c.concept).toSet();
    final deduped = AppData.dedupeEntries(entries.where((e) =>
        !e.concept.startsWith('custom:') || validCustoms.contains(e.concept)).toList());
    final next = deduped.isEmpty
        ? others
        : [...others, FeelingLog(date, deduped)]
          ..sort((a, b) => a.date.compareTo(b.date));
    _set(state.copyWith(feelingLogs: next));
  }

  /// Custom concept created when no catalog match exists. Returns the stable
  /// `custom:<id>` reference so the caller can immediately select it.
  String addCustomFeeling(String label) {
    final (id, next) = state.allocateId();
    _set(state.copyWith(
      nextId: next,
      customFeelings: [...state.customFeelings, CustomFeeling(id, label.trim())],
    ));
    return 'custom:$id';
  }

  void renameCustomFeeling(int id, String label) => _set(state.copyWith(
      customFeelings: [
        for (final c in state.customFeelings)
          c.id == id ? c.copyWith(label: label.trim()) : c,
      ]));

  /// Merge one custom concept into another (canonical or custom): every dated
  /// reference moves over, same-date duplicates collapse keeping any explicit
  /// intensity, and the merged-away concept disappears.
  void mergeCustomFeeling(int fromId, String intoConcept) {
    final from = 'custom:$fromId';
    if (from == intoConcept) return;
    if (!state.customFeelings.any((c) => c.id == fromId)) return;
    if (intoConcept.startsWith('custom:') &&
        !state.customFeelings.any((c) => c.concept == intoConcept)) {
      return;
    }
    final logs = <FeelingLog>[];
    for (final f in state.feelingLogs) {
      if (!f.entries.any((e) => e.concept == from)) {
        logs.add(f);
        continue;
      }
      final mapped = [
        for (final e in f.entries)
          if (e.concept == from)
            FeelingEntry(intoConcept, intensity: e.intensity)
          else
            e,
      ];
      logs.add(f.copyWith(entries: AppData.dedupeEntries(mapped)));
    }
    _set(state.copyWith(
      feelingLogs: logs..sort((a, b) => a.date.compareTo(b.date)),
      customFeelings: state.customFeelings.where((c) => c.id != fromId).toList(),
    ));
  }

  void deleteCustomFeeling(int id) {
    final from = 'custom:$id';
    final logs = <FeelingLog>[];
    for (final f in state.feelingLogs) {
      if (!f.entries.any((e) => e.concept == from)) {
        logs.add(f);
        continue;
      }
      final kept = f.entries.where((e) => e.concept != from).toList();
      if (kept.isEmpty) continue;
      logs.add(f.copyWith(entries: kept));
    }
    _set(state.copyWith(
      feelingLogs: logs,
      customFeelings: state.customFeelings.where((c) => c.id != id).toList(),
    ));
  }

  /// Persist the manual "Show others" rotation for one date. Historical items
  /// are untouched; only general possibilities move.
  void setFeelingRotation(String date, int cursor) {
    final others = state.feelingRotations.where((r) => r.date != date).toList();
    _set(state.copyWith(
        feelingRotations: [...others, FeelingRotation(date, cursor)]));
  }

  /// v0.3.0 (#18): user-written phase-bound cards.
  void addCustomCard(CustomCard card) =>
      _set(state.copyWith(customCards: [...state.customCards, card]));

  void updateCustomCard(CustomCard old, String text) => _set(state.copyWith(
      customCards: [
        for (final c in state.customCards)
          identical(c, old) ? CustomCard(c.phase, text.trim()) : c,
      ]));

  void deleteCustomCard(CustomCard card) => _set(state.copyWith(
      customCards: state.customCards.where((c) => c != card).toList()));

  // ---------- preferences (allocator-backed, stable across delete/restart) ----------

  void addPreference(String category, String text) {
    final (id, next) = state.allocateId();
    _set(state.copyWith(
      nextId: next,
      preferences: [
        ...state.preferences,
        SupportPreference(id, category, text.trim()),
      ],
    ));
  }

  void updatePreference(SupportPreference preference) => _set(state.copyWith(
      preferences: [
        for (final p in state.preferences) p.id == preference.id ? preference : p
      ]));

  void deletePreference(int id) => _set(state.copyWith(
      preferences: state.preferences.where((p) => p.id != id).toList(),
      actionFeedback:
          state.actionFeedback.where((f) => f.actionId != 'preference:$id').toList()));

  // ---------- action feedback, selection, completion ----------

  /// Usefulness ratings are kept separate from completions. Rating a *completed*
  /// action (positive or negative) can earn the day's `reflect` care moment —
  /// a "useful" tap alone never counts as completing the action.
  void rateAction(String date, String actionId, bool useful) {
    final feedback = [
      ...state.actionFeedback
          .where((f) => f.date != date || f.actionId != actionId),
      ActionFeedback(date, actionId, useful),
    ];
    final completed = state.completions
        .any((c) => c.date == date && c.actionId == actionId);
    final care = completed
        ? _awardCare(
            state.careEvents, CareCategory.reflect, date, actionId, state.nextId)
        : (events: state.careEvents, next: state.nextId);
    _set(state.copyWith(
        actionFeedback: feedback, careEvents: care.events, nextId: care.next));
  }

  /// Persist today's deterministic selection so rebuilds/restarts keep it.
  void setSelection(String date, List<String> order, int cursor, {String scope = ''}) {
    final others = state.selections.where((s) => s.date != date || s.scope != scope).toList();
    _set(state.copyWith(
        selections: [...others, DaySelection(date, order, cursor, scope: scope)]));
  }

  void swapSelection(String date, List<String> order) {
    final current =
        state.selections.where((s) => s.date == date && s.scope.isEmpty).firstOrNull;
    final next = (current?.cursor ?? -1) + 1;
    setSelection(date, order, next);
  }

  /// Mark a practical action done: records the completion and, in the *same*
  /// snapshot, awards the day's `act` care moment (capped at one per category).
  void completeAction(String date, String actionId) {
    if (state.completions
        .any((c) => c.date == date && c.actionId == actionId)) {
      return; // a single action is only credited once regardless of taps
    }
    final compId = state.nextId;
    final care = _awardCare(
        state.careEvents, CareCategory.act, date, actionId, compId + 1);
    _set(state.copyWith(
      nextId: care.next,
      completions: [...state.completions, ActionCompletion(compId, date, actionId)],
      careEvents: care.events,
    ));
  }

  /// Explicitly finished a learning card → the day's `learn` care moment.
  void completeLearning(String cardId, String date) {
    final alreadyLearned = state.learning.any((l) => l.cardId == cardId);
    final learning = alreadyLearned
        ? state.learning
        : [...state.learning, LearningCompletion(cardId, date)];
    final care = _awardCare(
        state.careEvents, CareCategory.learn, date, cardId, state.nextId);
    _set(state.copyWith(
      learning: learning,
      careEvents: care.events,
      nextId: care.next,
    ));
  }

  // ---------- quick entries ----------

  void addEntry(String date, EntryKind kind, String text,
      {int? linkPreferenceId, String? linkActionId}) {
    final (id, next) = state.allocateId();
    _set(state.copyWith(
      nextId: next,
      entries: [
        ...state.entries,
        QuickEntry(
            id: id,
            date: date,
            kind: kind,
            text: text.trim(),
            linkPreferenceId: linkPreferenceId,
            linkActionId: linkActionId),
      ],
    ));
  }

  void updateEntry(QuickEntry entry, String text) => _set(state.copyWith(
      entries: [
        for (final e in state.entries)
          e.id == entry.id ? e.copyWith(text: text.trim()) : e,
      ]));

  void deleteEntry(int id) =>
      _set(state.copyWith(entries: state.entries.where((e) => e.id != id).toList()));

  /// A reflection earns the day's `reflect` moment; a shared-information note is
  /// stored normally and does NOT auto-count as reflection.
  void saveReflection(String date, String text) {
    final id = state.nextId;
    final care = _awardCare(
        state.careEvents, CareCategory.reflect, date, 'entry:$id', id + 1);
    _set(state.copyWith(
      nextId: care.next,
      entries: [
        ...state.entries,
        QuickEntry(id: id, date: date, kind: EntryKind.reflection, text: text.trim()),
      ],
      careEvents: care.events,
    ));
  }

  /// Convert an entry into a saved preference, linking them both ways.
  void entryToPreference(QuickEntry entry) {
    final (pid, next) = state.allocateId();
    _set(state.copyWith(
      nextId: next,
      preferences: [...state.preferences, SupportPreference(pid, 'checkIn', entry.text)],
      entries: [
        for (final e in state.entries)
          e.id == entry.id ? e.copyWith(linkPreferenceId: pid) : e,
      ],
    ));
  }

  /// Convert an entry into a one-off reminder (no reward; creating is not credit).
  void entryToReminder(QuickEntry entry, DateTime when) {
    final (rid, next) = state.allocateId();
    _set(state.copyWith(
      nextId: next,
      reminders: [
        ...state.reminders,
        Reminder(id: rid, title: entry.text, when: when),
      ],
      entries: [
        for (final e in state.entries)
          e.id == entry.id ? e.copyWith(linkActionId: 'reminder:$rid') : e,
      ],
    ));
  }

  // ---------- reminders ----------

  void addReminder(String title, DateTime when,
      {int? linkPreferenceId, String? linkActionId}) {
    final (id, next) = state.allocateId();
    _set(state.copyWith(
      nextId: next,
      reminders: [
        ...state.reminders,
        Reminder(
            id: id,
            title: title.trim(),
            when: when,
            linkPreferenceId: linkPreferenceId,
            linkActionId: linkActionId),
      ],
    ));
  }

  void updateReminder(Reminder reminder) => _set(state.copyWith(
      reminders: [
        for (final r in state.reminders) r.id == reminder.id ? reminder : r
      ]));

  /// Completing a personal reminder is an `act` moment (same cap as actions).
  void completeReminder(int id) {
    final reminder = state.reminders.where((r) => r.id == id).firstOrNull;
    if (reminder == null || reminder.done) return;
    final care = _awardCare(state.careEvents, CareCategory.act,
        _dateKey(reminder.when), 'reminder:$id', state.nextId);
    _set(state.copyWith(
      careEvents: care.events,
      nextId: care.next,
      reminders: [
        for (final r in state.reminders)
          r.id == id ? r.copyWith(done: true) : r
      ],
    ));
  }

  void deleteReminder(int id) => _set(state.copyWith(
      reminders: state.reminders.where((r) => r.id != id).toList()));

  // ---------- garden naming / appearance ----------

  /// Ensure a plant record exists for `index` (creating it via the allocator)
  /// and apply the user's name/pot edit. Growth itself is derived, never stored.
  void namePlant(int index, int variety, String name) =>
      _upsertPlant(index, variety, (p) => p.copyWith(name: name));

  void setPlantStyle(int index, int variety, int potStyle) =>
      _upsertPlant(index, variety, (p) => p.copyWith(potStyle: potStyle));

  void _upsertPlant(int index, int variety, Plant Function(Plant) edit) {
    final existing = state.plants.where((p) => p.index == index).firstOrNull;
    if (existing == null) {
      _set(state.copyWith(
          plants: [...state.plants, edit(Plant(index: index, variety: variety))]));
    } else {
      _set(state.copyWith(
          plants: [
            for (final p in state.plants) p.index == index ? edit(p) : p
          ]));
    }
  }

  void setGardenHidden(bool hidden) =>
      _set(state.copyWith(settings: state.settings.copyWith(gardenHidden: hidden)));

  // ---------- legacy id migration ----------

  /// Rewrite `general:<pt>` feedback keys to stable catalog ids (P3). Idempotent;
  /// already-migrated ids are left untouched.
  void migrateLegacyActionIds(Map<String, String> legacyMap) {
    if (legacyMap.isEmpty) return;
    var changed = false;
    final migrated = <ActionFeedback>[];
    for (final f in state.actionFeedback) {
      final mapped = legacyMap[f.actionId];
      if (mapped != null) {
        changed = true;
        final dupe = migrated.any((e) => e.date == f.date && e.actionId == mapped);
        if (!dupe) migrated.add(ActionFeedback(f.date, mapped, f.useful));
      } else {
        migrated.add(f);
      }
    }
    if (changed) _set(state.copyWith(actionFeedback: migrated));
  }

  // ---------- helpers ----------

  /// One credited moment per category per local calendar day; duplicates and
  /// same-category same-day activity never add extra credit. Draws a fresh id
  /// from `nextId` and returns the advanced counter so the caller commits both
  /// the activity and its reward in a single `_set` snapshot.
  ({List<CareEvent> events, int next}) _awardCare(List<CareEvent> existing,
      CareCategory category, String date, String source, int nextId) {
    if (existing.any((e) => e.category == category && e.date == date)) {
      return (events: existing, next: nextId);
    }
    return (
      events: [...existing, CareEvent(nextId, category, date, source)],
      next: nextId + 1,
    );
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<bool> wipe() async {
    logInfo('store', 'wiping all data');
    final previous = state;
    const empty = AppData();
    if (await _set(empty, wipe: true)) {
      saveState.value = SaveState.ok;
      return true;
    }
    // The disk still holds sensitive data. Restore the visible state rather
    // than falsely claiming the wipe succeeded. Never overwrite a newer edit.
    if (identical(state, empty)) await _set(previous);
    return false;
  }

  @override
  void dispose() {
    saveState.dispose();
    super.dispose();
  }
}

final appDataProvider =
    StateNotifierProvider<AppDataNotifier, AppData>((_) => throw UnimplementedError());

final catalogProvider = FutureProvider<Catalog>((_) async =>
    Catalog.parse(await rootBundle.loadString('assets/catalog.json')));

final feelingCatalogProvider = FutureProvider<FeelingCatalog>((_) async =>
    FeelingCatalog.parse(await rootBundle.loadString('assets/feelings.json')));

final learningProvider = FutureProvider<LearningCatalog>((_) async =>
    LearningCatalog.parse(await rootBundle.loadString('assets/learning.json')));

Map<Phase, Map<OutlookAxis, Traffic>> catalogAxes(Catalog catalog) =>
    {for (final phase in Phase.values) phase: catalog[phase].axes};

/// Effective language code — device language, EN fallback. 'pt' or 'en'.
/// Reads the binding's dispatcher (not `PlatformDispatcher.instance`) so the
/// locale is the same one MaterialApp resolves from, and tests can pin it.
final langCodeProvider = Provider<String>((_) =>
    WidgetsBinding.instance.platformDispatcher.locale.languageCode
            .startsWith('pt')
        ? 'pt'
        : 'en');

/// Engine for a given day; catalog axes are the source of truth once loaded.
final engineProvider = Provider.family<CycleEngine, DateTime>((ref, date) {
  final data = ref.watch(appDataProvider);
  final catalog = ref.watch(catalogProvider).valueOrNull;
  return CycleEngine(
    settings: data.settings,
    logs: data.logs,
    today: date,
    axes: catalog == null ? null : catalogAxes(catalog),
  );
});

/// Derived garden progression for the current local day.
final gardenProvider = Provider<GardenState>((ref) {
  final data = ref.watch(appDataProvider);
  final today = ref.watch(todayProvider);
  return GardenEngine(events: data.careEvents, today: today).state();
});

/// Optional on-device note summaries: isolated behind the platform adapter,
/// never on the load/save/ranking path, and never a cloud fallback.
final summarizationControllerProvider =
    ChangeNotifierProvider.autoDispose<SummarizationController>((ref) {
  final controller = SummarizationController(summarizationPlatformOverrideForTests);
  // Note edits/deletions/wipes orphan any displayed summary.
  ref.listen(appDataProvider, (prev, next) {
    if (prev == null) return;
    final changed = next.entries.length != prev.entries.length ||
        !identical(next.entries, prev.entries) ||
        next.entries.map((e) => '${e.id}:${e.text}').join() !=
            prev.entries.map((e) => '${e.id}:${e.text}').join();
    if (changed) controller.invalidate();
  });
  return controller;
});

/// The "She may notice" briefing for one date: up to two fixed historical
/// picks plus at least one general possibility, all derived from the pure
/// selector — never preselected feelings, never fabricated when the estimate
/// state offers no stage context. Null until the feeling catalog is loaded.
final feelingBriefingProvider =
    Provider.family<FeelingBriefing?, DateTime>((ref, date) {
  final catalog = ref.watch(feelingCatalogProvider).valueOrNull;
  if (catalog == null) return null;
  final data = ref.watch(appDataProvider);
  final eng = ref.watch(engineProvider(date));
  if (!eng.canPredict) return null;
  final stage = historyStageOf(eng.phaseOrNull(date));
  final key = CycleEngine.dayKey(date);
  final logged = {
    for (final e in AppData.feelingLogFor(data.feelingLogs, key)?.entries ??
            const <FeelingEntry>[])
        e.concept,
  };
  final cursor = data.feelingRotations
          .where((r) => r.date == key)
          .firstOrNull
          ?.cursor ??
      0;
  return FeelingSelector.pick(
    logs: data.logs,
    feelings: data.feelingLogs,
    eng: eng,
    date: date,
    generalEligible: stage == HistoryStage.luteal && eng.phaseOrNull(date) != Phase.pms
        ? const [] : catalog.eligibleFor(stage),
    fallbackEligible: catalog.eligibleFor(HistoryStage.unknown),
    exclude: logged,
    cursor: cursor,
  );
});

/// Support priority for the catalog pick on a date: the user's explicit
/// intensive-support setting, recent (≤3 days) moderate/strong logged
/// discomfort, or a pre-period context where the estimate puts the next start
/// within 3 days. All flow through the existing `PhaseCatalog.pick`
/// `supportPriority` contract; nothing bypasses filtering or caps.
final supportPriorityProvider =
    Provider.family<bool, DateTime>((ref, date) {
  final data = ref.watch(appDataProvider);
  final eng = ref.watch(engineProvider(date));
  final catalog = ref.watch(feelingCatalogProvider).valueOrNull;
  return data.settings.intensiveSupport ||
      FeelingSelector.recentDiscomfort(data.feelingLogs, date,
          discomfortConcepts: catalog?.discomfortConcepts ?? const {}) ||
      FeelingSelector.periodNear(eng, date);
});

final supportContextProvider = Provider.family<
    ({Set<ActionCategory> current, Set<ActionCategory> historical}), DateTime>((ref, date) {
  final data = ref.watch(appDataProvider);
  final catalog = ref.watch(feelingCatalogProvider).valueOrNull;
  final eng = ref.watch(engineProvider(date));
  final current = <ActionCategory>{};
  for (final log in data.feelingLogs) {
    final day = DateTime.tryParse(log.date);
    if (day == null) continue;
    final age = CycleEngine.daysBetween(day, date);
    if (age < 0 || age > 3) continue;
    for (final entry in log.entries) {
      current.addAll(catalog?.byId(entry.concept)?.supportCategories ?? const {});
    }
  }
  final historical = <ActionCategory>{};
  if (eng.canPredict) {
    for (final h in FeelingSelector.history(logs: data.logs,
        feelings: data.feelingLogs, eng: eng, date: date)) {
      historical.addAll(catalog?.byId(h.concept)?.supportCategories ?? const {});
    }
  }
  return (current: current, historical: historical);
});
