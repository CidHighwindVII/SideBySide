import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidebyside/data/store.dart';
import 'package:sidebyside/engine/garden_engine.dart';
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
  test('old JSON still loads; legacy observations migrate to feeling records', () {
    final old = AppData.fromJson({
      'settings': {'onboarded': true},
      'logs': [PeriodLog(DateTime(2026, 8, 1), null).toJson()],
      'observations': [
        {'date': '2026-08-01', 'tags': ['colicas', 'weird-tag']},
      ],
      'customCards': [const CustomCard(Phase.pms, 'old note').toJson()],
      'feedback': [const ForecastFeedback('2026-08-01', true).toJson()],
    });
    expect(old.preferences, isEmpty);
    expect(old.actionFeedback, isEmpty);
    // known legacy tag → canonical concept; unmapped value preserved as a
    // custom concept, so the record is never dropped.
    final migrated = old.feelingLogs.single;
    expect(migrated.date, '2026-08-01');
    expect(migrated.entries.map((e) => e.concept).toList(),
        containsAll(['cramps', 'custom:1']));
    expect(old.customFeelings.single.label, 'weird-tag');
    // migration is idempotent: re-parsing the new file changes nothing
    final reparsed = AppData.fromJson(old.toJson());
    expect(reparsed.feelingLogs.single.entries.length, 2);
    expect(reparsed.customFeelings.single.label, 'weird-tag');
    expect(reparsed.nextId, old.nextId);
    final updated = old.copyWith(
      preferences: [const SupportPreference(1, 'help', 'Agreed chore')],
      actionFeedback: [const ActionFeedback('2026-08-02', 'preference:1', true)],
    );
    final restored = AppData.fromJson(updated.toJson());
    expect(restored.logs.length, 1);
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

  group('Phase 3 — new models, allocator and atomic rewards', () {
    test('new JSON fields round-trip; absent fields get safe defaults', () {
      final withNew = AppData(
        settings: const Settings(onboarded: true, gardenHidden: true),
        selections: const [DaySelection('2026-10-05', ['a:x', 'a:y'], 1)],
        completions: const [ActionCompletion(1, '2026-10-05', 'a:x')],
        learning: const [LearningCompletion('l:phases', '2026-10-05')],
        entries: const [QuickEntry(id: 2, date: '2026-10-05', kind: EntryKind.reflection, text: 'note')],
        reminders: [Reminder(id: 3, title: 'Pick up', when: DateTime(2026, 10, 6, 9))],
        careEvents: const [CareEvent(4, CareCategory.act, '2026-10-05', 'a:x')],
        plants: const [Plant(index: 0, variety: 1, name: 'Fern', potStyle: 2)],
        nextId: 5,
      );
      final restored = AppData.fromJson(withNew.toJson());
      expect(restored.settings.gardenHidden, isTrue);
      expect(restored.selections.single.cursor, 1);
      expect(restored.completions.single.actionId, 'a:x');
      expect(restored.learning.single.cardId, 'l:phases');
      expect(restored.entries.single.kind, EntryKind.reflection);
      expect(restored.reminders.single.when, DateTime(2026, 10, 6, 9));
      expect(restored.careEvents.single.category, CareCategory.act);
      expect(restored.plants.single.name, 'Fern');
      expect(restored.nextId, 5);

      // an old file with none of the new keys still loads with empty defaults
      final old = AppData.fromJson({'settings': {'onboarded': true}});
      expect(old.selections, isEmpty);
      expect(old.completions, isEmpty);
      expect(old.learning, isEmpty);
      expect(old.entries, isEmpty);
      expect(old.reminders, isEmpty);
      expect(old.careEvents, isEmpty);
      expect(old.plants, isEmpty);
      expect(old.nextId, 1);
      expect(old.settings.gardenHidden, isFalse);
    });

    test('allocator keeps ids unique after deletion and reload', () async {
      final store = _RecordingStore()..releaseFirstWrite.complete();
      final n = AppDataNotifier(store, const AppData());
      n.addPreference('help', 'first'); // id 1
      await n.persistenceIdle;
      n.deletePreference(1);
      n.addPreference('help', 'second'); // must NOT reuse 1
      await n.persistenceIdle;
      expect(n.state.preferences.single.id, 2);
      // reload from disk: nextId advanced past 2, so a new record is 3
      final reloaded = AppData.fromJson(store.onDisk!.toJson());
      final n2 = AppDataNotifier(store, reloaded);
      n2.addPreference('help', 'third');
      await n2.persistenceIdle;
      expect(n2.state.preferences.last.id, 3);
      n.dispose();
      n2.dispose();
    });

    test('completion + reward are one snapshot and cap per category/day', () async {
      final store = _RecordingStore()..releaseFirstWrite.complete();
      final n = AppDataNotifier(store, const AppData());
      n.completeAction('2026-10-05', 'a:x');
      await n.persistenceIdle;
      // a second different action the same day cannot add a second `act` moment
      n.completeAction('2026-10-05', 'a:y');
      await n.persistenceIdle;
      // duplicate tap of the same action adds neither completion nor reward
      n.completeAction('2026-10-05', 'a:x');
      await n.persistenceIdle;
      expect(n.state.completions.length, 2);
      expect(n.state.careEvents.where((c) => c.category == CareCategory.act).length, 1);
      // learning on the same day is a distinct category → its own moment
      n.completeLearning('l:phases', '2026-10-05');
      await n.persistenceIdle;
      expect(n.state.careEvents.where((c) => c.category == CareCategory.learn).length, 1);
      n.dispose();
    });

    test('a failed save is surfaced and a retry cannot duplicate the reward', () async {
      final store = _RecordingStore()..failFirst = true;
      final n = AppDataNotifier(store, const AppData());
      n.completeAction('2026-10-05', 'a:x'); // state updated, save will fail
      await store.firstWrite.future;
      store.releaseFirstWrite.complete();
      await n.persistenceIdle;
      expect(n.saveState.value, SaveState.failed);
      expect(n.state.careEvents.length, 1); // reward already in memory
      final ok = await n.retrySave();
      expect(ok, isTrue);
      expect(n.saveState.value, SaveState.ok);
      expect(store.onDisk!.careEvents.length, 1); // retried the same snapshot
      expect(n.state.careEvents.length, 1);
      n.dispose();
    });

    test('legacy text-based feedback ids migrate to stable catalog ids', () {
      final base = const AppData(actionFeedback: [
        ActionFeedback('2026-10-01', 'general:Pergunta o que seria útil hoje e ouve a resposta', false),
      ]);
      final store = _RecordingStore()..releaseFirstWrite.complete();
      final n = AppDataNotifier(store, base);
      n.migrateLegacyActionIds({'general:Pergunta o que seria útil hoje e ouve a resposta': 'a:ask-what-helps'});
      expect(n.state.actionFeedback.single.actionId, 'a:ask-what-helps');
      n.dispose();
    });

    test('wipe clears all new collections through the ordered path', () async {
      final store = _RecordingStore()..releaseFirstWrite.complete();
      final n = AppDataNotifier(store, const AppData());
      n.completeAction('2026-10-05', 'a:x');
      n.addEntry('2026-10-05', EntryKind.shared, 'note');
      n.addReminder('Pick up', DateTime(2026, 10, 6, 9));
      await n.persistenceIdle;
      expect(await n.wipe(), isTrue);
      expect(n.state.careEvents, isEmpty);
      expect(n.state.entries, isEmpty);
      expect(n.state.reminders, isEmpty);
      expect(n.state.nextId, 1);
      expect(store.onDisk, isNull);
      n.dispose();
    });
  });

  group('Phase 9 — end-to-end regression', () {
    test('saveLog enforces 21-day spacing for every logging entry point',
        () async {
      final store = _RecordingStore()..releaseFirstWrite.complete();
      final n = AppDataNotifier(store, const AppData());
      expect(n.saveLog(PeriodLog(DateTime(2026, 1, 1), null)), isTrue);
      await n.persistenceIdle;
      expect(n.saveLog(PeriodLog(DateTime(2026, 1, 21), null)), isFalse);
      expect(n.saveLog(PeriodLog(DateTime(2025, 12, 20), null)), isFalse); // earlier direction
      expect(n.saveLog(PeriodLog(DateTime(2026, 1, 22), null)), isTrue);
      await n.persistenceIdle;
      expect(n.state.logs.length, 2);
      expect(store.onDisk!.logs.length, 2); // rejected writes never persisted
      // an end edit on the same start still passes
      expect(n.saveLog(PeriodLog(DateTime(2026, 1, 22), DateTime(2026, 1, 26))), isTrue);
      await n.persistenceIdle;
      expect(n.state.logs.last.end, DateTime(2026, 1, 26));
      n.dispose();
    });

    test('existing starts can still have end dates edited in legacy short cycles', () async {
      final store = _RecordingStore()..releaseFirstWrite.complete();
      final n = AppDataNotifier(store, AppData(logs: [
        PeriodLog(DateTime(2026, 1, 1), null),
        PeriodLog(DateTime(2026, 1, 15), null),
      ]));
      expect(n.saveLog(PeriodLog(DateTime(2026, 1, 1), DateTime(2026, 1, 4))), isTrue);
      await n.persistenceIdle;
      expect(n.state.logs.first.end, DateTime(2026, 1, 4));
      expect(n.saveLog(PeriodLog(DateTime(2026, 1, 8), null)), isFalse);
      n.dispose();
    });

    test('feeling edits, custom rename/merge and rotation persist through _set',
        () async {
      final store = _RecordingStore()..releaseFirstWrite.complete();
      final n = AppDataNotifier(store, const AppData());
      expect(n.addCustomFeeling('zumbido'), 'custom:1');
      expect(n.addCustomFeeling('tontura leve'), 'custom:2');
      n.saveFeelingLog('2026-10-10', const [
        FeelingEntry('cramps', intensity: FeelingIntensity.mild),
        FeelingEntry('custom:1'),
        FeelingEntry('custom:1'), // duplicate tap collapses
      ]);
      await n.persistenceIdle;
      expect(n.state.feelingLogs.single.entries.length, 2);
      expect(store.onDisk!.feelingLogs.single.date, '2026-10-10');
      expect(store.onDisk!.customFeelings.length, 2);

      n.renameCustomFeeling(1, 'zumbido nos ouvidos');
      await n.persistenceIdle;
      expect(n.state.customFeelings.first.label, 'zumbido nos ouvidos');

      // merge custom:1 into a canonical concept: dated references move over
      // and same-date duplicates collapse.
      n.saveFeelingLog('2026-10-09', const [FeelingEntry('custom:1')]);
      n.mergeCustomFeeling(1, 'dizzy');
      await n.persistenceIdle;
      expect(n.state.customFeelings.length, 1);
      final merged = n.state.feelingLogs
          .firstWhere((f) => f.date == '2026-10-10')
          .entries
          .map((e) => e.concept)
          .toList();
      expect(merged, containsAll(['cramps', 'dizzy']));
      expect(merged.where((c) => c == 'custom:1'), isEmpty);
      expect(n.state.feelingLogs.any((f) =>
              f.entries.any((e) => e.concept == 'custom:1')),
          isFalse);

      n.setFeelingRotation('2026-10-10', 4);
      await n.persistenceIdle;
      expect(store.onDisk!.feelingRotations.single.cursor, 4);
      final reloaded = AppData.fromJson(store.onDisk!.toJson());
      expect(reloaded.feelingRotations.single.cursor, 4);
      expect(reloaded.customFeelings.length, 1);
      n.dispose();
    });

    test('stale deleted-custom references cannot be reintroduced by a save', () async {
      final store = _RecordingStore()..releaseFirstWrite.complete();
      final n = AppDataNotifier(store, const AppData());
      n.addCustomFeeling('temporary');
      n.saveFeelingLog('2026-10-10', const [FeelingEntry('custom:1')]);
      await n.persistenceIdle;
      n.mergeCustomFeeling(1, 'dizzy');
      await n.persistenceIdle;
      n.saveFeelingLog('2026-10-10', const [
        FeelingEntry('custom:1'), // stale editor draft
        FeelingEntry('cramps'),
      ]);
      await n.persistenceIdle;
      final saved = n.state.feelingLogs.single.entries.map((e) => e.concept);
      expect(saved, contains('cramps'));
      expect(saved, isNot(contains('custom:1')));
      expect(n.state.customFeelings, isEmpty);
      n.dispose();
    });

    test('deleting a custom concept removes only its dated references',
        () async {
      final store = _RecordingStore()..releaseFirstWrite.complete();
      final n = AppDataNotifier(store, const AppData());
      n.addCustomFeeling('extra');
      n.saveFeelingLog('2026-10-10', const [
        FeelingEntry('cramps'),
        FeelingEntry('custom:1'),
      ]);
      n.saveFeelingLog('2026-10-11', const [FeelingEntry('custom:1')]);
      await n.persistenceIdle;
      n.deleteCustomFeeling(1);
      await n.persistenceIdle;
      expect(n.state.feelingLogs.length, 1); // 10-11 had only the custom → removed
      expect(n.state.feelingLogs.single.date, '2026-10-10');
      expect(n.state.feelingLogs.single.entries.single.concept, 'cramps');
      n.dispose();
    });


    test('completion → persistence → garden growth → restart, no duplicates',
        () async {
      final store = _RecordingStore()..releaseFirstWrite.complete();
      final n = AppDataNotifier(store,
          const AppData(settings: Settings(onboarded: true)));
      n.completeAction('2026-10-05', 'a:x');
      n.completeAction('2026-10-05', 'a:x'); // duplicate tap adds nothing
      await n.persistenceIdle;
      final reloaded = AppData.fromJson(store.onDisk!.toJson());
      expect(reloaded.completions.length, 1);
      expect(reloaded.careEvents.length, 1);
      final g = GardenEngine(
          events: reloaded.careEvents, today: DateTime(2026, 10, 5));
      expect(g.momentsOnActive, 1);
      expect(g.stage, PlantStage.sprout);
      // a restarted notifier over the same record cannot re-award the same day
      final n2 = AppDataNotifier(store, reloaded);
      n2.completeAction('2026-10-05', 'a:x');
      await n2.persistenceIdle;
      expect(n2.state.careEvents.length, 1);
      n.dispose();
      n2.dispose();
    });

    test('PT and EN ARBs stay key-identical (l10n invariant)', () {
      final pt = jsonDecode(File('lib/l10n/app_pt.arb').readAsStringSync())
          as Map<String, dynamic>;
      final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
      expect(pt.keys.toSet(), en.keys.toSet());
    });
  });
}
