import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/catalog.dart';
import '../data/store.dart';
import '../engine/cycle_engine.dart';
import '../engine/models.dart';
import '../log.dart';

final storeProvider = Provider((_) => Store());

/// Local calendar date; override in widget tests to avoid midnight-sensitive UI.
final todayProvider = Provider<DateTime>((_) => CycleEngine.dateOnly(DateTime.now()));

class AppDataNotifier extends StateNotifier<AppData> {
  final Store _store;
  Future<void> _pending = Future<void>.value();
  AppDataNotifier(this._store, super.initial);

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
        return true;
      } catch (e, s) {
        logErr('store', e, s); // state stays in memory; report write failure
        return false;
      }
    });
    _pending = operation.then((_) {});
    return operation;
  }

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

  void deleteCustomCard(CustomCard card) => _set(state.copyWith(
      customCards: state.customCards.where((c) => c != card).toList()));

  Future<bool> wipe() async {
    logInfo('store', 'wiping all data');
    final previous = state;
    const empty = AppData();
    if (await _set(empty, wipe: true)) return true;
    // The disk still holds sensitive data. Restore the visible state rather
    // than falsely claiming the wipe succeeded. Never overwrite a newer edit.
    if (identical(state, empty)) await _set(previous);
    return false;
  }
}

final appDataProvider =
    StateNotifierProvider<AppDataNotifier, AppData>((_) => throw UnimplementedError());

final catalogProvider = FutureProvider<Catalog>((_) async =>
    Catalog.parse(await rootBundle.loadString('assets/catalog.json')));

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
