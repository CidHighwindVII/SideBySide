import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/catalog.dart';
import '../data/learning_catalog.dart';
import '../data/store.dart';
import '../engine/cycle_engine.dart';
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

  void saveLog(PeriodLog log) {
    final logs = [...state.logs.where((l) => l.start != log.start), log]
      ..sort((a, b) => a.start.compareTo(b.start));
    _set(state.copyWith(logs: logs));
  }

  void deleteLog(PeriodLog log) =>
      _set(state.copyWith(logs: state.logs.where((l) => l != log).toList()));

  void feedback(String date, bool thumbsUp) {
    final others = state.feedback.where((f) => f.date != date).toList();
    _set(state.copyWith(feedback: [...others, ForecastFeedback(date, thumbsUp)]));
  }

  /// v0.3.0 (#4): one observation per date — upsert; empty tags deletes.
  void saveObservation(String date, List<String> tags) {
    final others = state.observations.where((o) => o.date != date).toList();
    final next = tags.isEmpty
        ? others
        : [...others, Observation(date, tags)]
          ..sort((a, b) => a.date.compareTo(b.date));
    _set(state.copyWith(observations: next));
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
  void setSelection(String date, List<String> order, int cursor) {
    final others = state.selections.where((s) => s.date != date).toList();
    _set(state.copyWith(
        selections: [...others, DaySelection(date, order, cursor)]));
  }

  void swapSelection(String date, List<String> order) {
    final current =
        state.selections.where((s) => s.date == date).firstOrNull;
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
