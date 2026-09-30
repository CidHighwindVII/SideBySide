import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidebyside/data/store.dart';
import 'package:sidebyside/engine/models.dart';
import 'package:sidebyside/state/providers.dart';

class _RecordingStore extends Store {
  final writes = <AppData>[];
  final operations = <String>[];
  final firstWrite = Completer<void>();
  final releaseFirstWrite = Completer<void>();
  final wipeStarted = Completer<void>();
  Completer<void>? releaseWipe;
  bool failFirst = false;
  bool failWipe = false;
  AppData? onDisk;

  @override
  Future<void> save(AppData data) async {
    final first = operations.isEmpty;
    operations.add('save');
    if (first) {
      firstWrite.complete();
      await releaseFirstWrite.future;
      if (failFirst) throw const FileSystemException('test failure');
    }
    onDisk = data;
    writes.add(data);
  }

  @override
  Future<void> wipe() async {
    operations.add('wipe');
    if (!wipeStarted.isCompleted) wipeStarted.complete();
    if (releaseWipe != null) await releaseWipe!.future;
    if (failWipe) throw const FileSystemException('test wipe failure');
    onDisk = null;
  }
}

void main() {
  test('old JSON still loads; preferences and action ratings round-trip', () {
    final old = AppData.fromJson({
      'settings': {'onboarded': true},
      'logs': [PeriodLog(DateTime(2026, 8, 1), null).toJson()],
      'observations': [const Observation('2026-08-01', ['colicas']).toJson()],
      'customCards': [const CustomCard(Phase.pms, 'old note').toJson()],
      'feedback': [const ForecastFeedback('2026-08-01', true).toJson()],
    });
    expect(old.preferences, isEmpty);
    expect(old.actionFeedback, isEmpty);
    final updated = old.copyWith(
      preferences: [const SupportPreference(1, 'help', 'Agreed chore')],
      actionFeedback: [const ActionFeedback('2026-08-02', 'preference:1', true)],
    );
    final restored = AppData.fromJson(updated.toJson());
    expect(restored.logs.length, 1);
    expect(restored.observations.single.tags, ['colicas']);
    expect(restored.customCards.single.text, 'old note');
    expect(restored.feedback.single.thumbsUp, isTrue);
    expect(restored.preferences.single.text, 'Agreed chore');
    expect(restored.actionFeedback.single.useful, isTrue);
  });

  test('preference and action changes persist through the ordered _set queue', () async {
    final store = _RecordingStore();
    final notifier = AppDataNotifier(store, const AppData());
    notifier.addPreference('help', 'Do the dishes');
    await store.firstWrite.future;
    notifier.rateAction('2026-09-30', 'preference:1', false);
    notifier.deletePreference(1);
    store.releaseFirstWrite.complete();
    await notifier.persistenceIdle;
    expect(store.onDisk!.preferences, isEmpty);
    expect(store.onDisk!.actionFeedback, isEmpty);
    expect(store.operations, ['save', 'save', 'save']);
    notifier.dispose();
  });
  test('rapid mutations persist in order; wipe is last and publishes empty data',
      () async {
    final store = _RecordingStore();
    final notifier = AppDataNotifier(store, const AppData());
    notifier.updateSettings(const Settings(briefingHour: 20));
    await store.firstWrite.future;
    notifier.saveLog(PeriodLog(DateTime(2026, 9, 1), null));
    final wiped = notifier.wipe();
    expect(notifier.state.logs, isEmpty);
    expect(store.operations, ['save']);
    store.releaseFirstWrite.complete();
    expect(await wiped, isTrue);
    expect(store.operations, ['save', 'save', 'wipe']);
    expect(store.onDisk, isNull);
    notifier.dispose();
  });

  test('a failed write cannot block subsequent persistence', () async {
    final store = _RecordingStore()..failFirst = true;
    final notifier = AppDataNotifier(store, const AppData());
    notifier.updateSettings(const Settings(briefingHour: 20));
    await store.firstWrite.future;
    notifier.updateSettings(const Settings(briefingHour: 19));
    store.releaseFirstWrite.complete();
    await notifier.persistenceIdle;
    expect(store.onDisk?.settings.briefingHour, 19);
    notifier.dispose();
  });

  test('failed wipe restores the visible state and reports failure', () async {
    final store = _RecordingStore()..failWipe = true;
    final notifier = AppDataNotifier(store,
        const AppData(settings: Settings(onboarded: true)));
    notifier.updateSettings(const Settings(onboarded: true, briefingHour: 20));
    await store.firstWrite.future;
    store.releaseFirstWrite.complete();
    await notifier.persistenceIdle;
    expect(await notifier.wipe(), isFalse);
    expect(notifier.state.settings.onboarded, isTrue);
    expect(store.onDisk?.settings.briefingHour, 20);
    notifier.dispose();
  });

  test('failed wipe never restores an older snapshot over a later change',
      () async {
    final store = _RecordingStore()
      ..failWipe = true
      ..releaseWipe = Completer<void>();
    final notifier = AppDataNotifier(store,
        const AppData(settings: Settings(onboarded: true)));
    notifier.updateSettings(const Settings(onboarded: true, briefingHour: 20));
    await store.firstWrite.future;
    store.releaseFirstWrite.complete();
    await notifier.persistenceIdle;
    final wipe = notifier.wipe();
    await store.wipeStarted.future;
    notifier.updateSettings(const Settings(onboarded: true, briefingHour: 18));
    store.releaseWipe!.complete();
    expect(await wipe, isFalse);
    await notifier.persistenceIdle;
    expect(notifier.state.settings.briefingHour, 18);
    expect(store.onDisk?.settings.briefingHour, 18);
    notifier.dispose();
  });

  test('both scheduled notification bodies are generic in both locales', () {
    for (final lang in ['pt', 'en']) {
      final arb = jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
          as Map<String, dynamic>;
      for (final key in ['notifHeadsUpBody', 'notifBriefBody']) {
        final body = (arb[key] as String).toLowerCase();
        expect(body, isNot(contains('period')));
        expect(body, isNot(contains('período')));
        expect(body, isNot(contains('menstrua')));
        expect(body, isNot(contains('tomorrow')));
        expect(body, isNot(contains('amanhã')));
      }
    }
  });
}
