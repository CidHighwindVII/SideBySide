import 'package:sidebyside/engine/cycle_engine.dart';
import 'package:sidebyside/engine/feeling_selector.dart';
import 'package:sidebyside/engine/models.dart';
import 'package:test/test.dart';

DateTime d(int m, int day) => DateTime(2026, m, day);

String key(DateTime day) => CycleEngine.dayKey(day);

// Four 21-day cycles: Aug 20, Sep 10, Oct 1, Oct 22 (+ Oct 25-29 continues
// an open cycle at avg 21 once ≥3 gaps exist). Period ends 4 days later.
final starts = [d(8, 20), d(9, 10), d(10, 1), d(10, 22)];
final cycleLogs = [
  for (final s in starts) PeriodLog(s, CycleEngine.addCalendarDays(s, 4)),
];

CycleEngine engAt(DateTime today) => CycleEngine(
      settings: const Settings(contraception: Contraception.none),
      logs: cycleLogs,
      today: today,
    );

/// Day 8 of a 21-day cycle = ovulation stage, position 3 from its start.
final target = d(10, 29); // day 8 after the Oct 22 start

FeelingLog log(DateTime day, List<String> concepts,
        {FeelingIntensity? intensity}) =>
    FeelingLog(key(day), [
      for (final c in concepts) FeelingEntry(c, intensity: intensity),
    ]);

void main() {
  group('stage-position matching', () {
    test('recurrence across two distinct cycles earns From-history ranking',
        () {
      final picks = FeelingSelector.history(
        logs: cycleLogs,
        feelings: [log(d(8, 27), ['good-mood']), log(d(9, 17), ['good-mood'])],
        eng: engAt(target),
        date: target,
      );
      expect(picks, hasLength(1));
      expect(picks.single.concept, 'good-mood');
      expect(picks.single.cycles, 2);
      expect(picks.single.cycles,
          greaterThanOrEqualTo(FeelingSelector.recurrenceCycles));
    });
    test('repeated logs inside ONE cycle count once', () {
      final picks = FeelingSelector.history(
        logs: cycleLogs,
        feelings: [
          log(d(9, 17), ['good-mood']),
          log(d(9, 18), ['good-mood']), // day 9, still ovulation, same cycle
        ],
        eng: engAt(target),
        date: target,
      );
      expect(picks.single.cycles, 1); // "Previously logged" threshold
    });
    test('same-cycle recent feelings are not previous-cycle evidence', () {
      final picks = FeelingSelector.history(
        logs: cycleLogs,
        feelings: [log(d(10, 28), ['good-mood'])],
        eng: engAt(target),
        date: target,
      );
      expect(picks, isEmpty);
    });
    test('similar-position window excludes the same day-number in another stage',
        () {
      // Aug 25 (day 6 of its cycle but here day 6 is menstrual-end+1...
      // Aug 24 sits inside the menstrual run (ends Aug 24): different stage.
      final picks = FeelingSelector.history(
        logs: cycleLogs,
        feelings: [log(d(8, 23), ['good-mood'])], // day 4 → menstrual stage
        eng: engAt(target),
        date: target,
      );
      expect(picks, isEmpty);
    });
    test('position beyond the window does not match', () {
      // Oct 26 → ovulation day 5 → position 1 vs target position 3 → within 3;
      // Oct 22 start+0 in an ovulation stage is impossible, so use menstrual
      // positions instead: day 0 matches day 0 across cycles, day 4 does not.
      final m = engAt(d(10, 22));
      final picks = FeelingSelector.history(
        logs: cycleLogs,
        feelings: [log(d(8, 24), ['cramps'])], // position 4 in menstrual
        eng: m,
        date: d(10, 22), // position 0 in menstrual
      );
      expect(picks, isEmpty);
      final inWindow = FeelingSelector.history(
        logs: cycleLogs,
        feelings: [log(d(8, 20), ['cramps'])], // position 0
        eng: m,
        date: d(10, 22),
      );
      expect(inWindow.single.cycles, 1);
    });
    test('missing logs stay unknown — no invented absence', () {
      final picks = FeelingSelector.history(
        logs: cycleLogs,
        feelings: const [],
        eng: engAt(target),
        date: target,
      );
      expect(picks, isEmpty);
    });
    test('no cycle logs → no history at all', () {
      final e = CycleEngine(
          settings: const Settings(), logs: const [], today: target);
      final picks = FeelingSelector.history(
        logs: const [],
        feelings: [log(d(9, 17), ['good-mood'])],
        eng: e,
        date: target,
      );
      expect(picks, isEmpty);
    });
    test('dates before the first ever start or after corrections regroup',
        () {
      final feelings = [
        log(d(8, 27), ['good-mood']),
        log(d(9, 17), ['good-mood']),
      ];
      final base = FeelingSelector.history(
          logs: cycleLogs, feelings: feelings, eng: engAt(target), date: target);
      expect(base.single.cycles, 2);
      // Correct away a period start: the merged cycle now counts once.
      final corrected = [cycleLogs[0], cycleLogs[2], cycleLogs[3]];
      final e2 = CycleEngine(
          settings: const Settings(contraception: Contraception.none),
          logs: corrected,
          today: target);
      final after = FeelingSelector.history(
          logs: corrected, feelings: feelings, eng: e2, date: target);
      expect(after.isEmpty || after.single.cycles < 2, isTrue);
    });
  });

  group('briefing composition', () {
    final eligible = ['good-mood', 'energized', 'confident', 'calm'];
    test('three items: two historical + at least one general', () {
      final b = FeelingSelector.pick(
        logs: cycleLogs,
        feelings: [
          log(d(8, 27), ['good-mood']),
          log(d(9, 17), ['good-mood']),
          log(d(8, 25), ['calm']),
          log(d(9, 15), ['calm']),
        ],
        eng: engAt(target),
        date: target,
        generalEligible: eligible,
        fallbackEligible: eligible,
      );
      expect(b.historical.length, 2);
      expect(b.general.length, 1);
      expect(b.concepts.toSet().length, 3); // no duplicate concepts
    });
    test('Show others moves only the general slot, historical stays fixed',
        () {
      final feelings = [
        log(d(8, 27), ['good-mood']),
        log(d(9, 17), ['good-mood']),
      ];
      final a = FeelingSelector.pick(
        logs: cycleLogs,
        feelings: feelings,
        eng: engAt(target),
        date: target,
        generalEligible: const ['calm', 'confident', 'energized', 'private'],
        cursor: 0,
      );
      final b = FeelingSelector.pick(
        logs: cycleLogs,
        feelings: feelings,
        eng: engAt(target),
        date: target,
        generalEligible: const ['calm', 'confident', 'energized', 'private'],
        cursor: 1,
      );
      expect(a.historical.map((h) => h.concept),
          equals(b.historical.map((h) => h.concept)));
      expect(a.general, isNot(equals(b.general)));
    });
    test('merged/custom concepts deduplicate against general picks', () {
      final b = FeelingSelector.pick(
        logs: cycleLogs,
        feelings: [log(d(8, 27), ['custom:9']), log(d(9, 17), ['custom:9'])],
        eng: engAt(target),
        date: target,
        generalEligible: const ['custom:9', 'calm', 'confident'],
      );
      expect(b.historical.single.concept, 'custom:9');
      expect(b.general, isNot(contains('custom:9')));
    });
    test('thin stage pool falls back to the general pool', () {
      final b = FeelingSelector.pick(
        logs: cycleLogs,
        feelings: [log(d(8, 27), ['good-mood']), log(d(9, 17), ['good-mood'])],
        eng: engAt(target),
        date: target,
        generalEligible: const ['good-mood'], // only historical concept
        fallbackEligible: const ['calm', 'private', 'neutral'],
      );
      expect(b.general, isNotEmpty);
      expect(b.general, isNot(contains('good-mood')));
    });
  });

  group('four-stage grouping (read time)', () {
    test('PMS dates land inside luteal; no-data dates land in unknown', () {
      final eng = engAt(d(10, 29));
      final groups = FeelingSelector.groupByStage(
        feelings: [
          log(d(10, 22), ['cramps']), // menstrual
          log(d(10, 29), ['good-mood']), // ovulation stage
          log(d(2, 3), ['calm']), // no cycle → unknown
        ],
        eng: eng,
      );
      expect(groups[HistoryStage.menstrual]!.single.date, '2026-10-22');
      expect(groups[HistoryStage.ovulatory]!.single.date, '2026-10-29');
      expect(groups[HistoryStage.unknown]!.single.date, '2026-02-03');
      // Luteal day 14 of the Oct 22 cycle (21-day → pms day 15..21): PMS
      // sits inside luteal grouping.
      final withPms = FeelingSelector.groupByStage(
        feelings: [log(d(11, 4), ['sensitive'])], // day 14 after Oct 22
        eng: eng,
      );
      expect(withPms[HistoryStage.luteal]!, hasLength(1));
    });
    test('corrected period dates re-group on the next read', () {
      final before = FeelingSelector.groupByStage(
          feelings: [log(d(10, 26), ['cramps'])], eng: engAt(target));
      // With the logged cycle, Oct 26 is follicular (period ended Oct 26?
      // end = Oct 26 → day 5 = menstrual; day 5 ≤ periodLength 5 → menstrual).
      expect(
          before[HistoryStage.menstrual]!.any((f) => f.date == '2026-10-26') ||
              before[HistoryStage.follicular]!
                  .any((f) => f.date == '2026-10-26'),
          isTrue);
      // Remove the Oct 22 start → that date's stage is derived from the
      // previous cycle/average instead — grouping changes but nothing drops.
      final fewer = [cycleLogs[0], cycleLogs[1], cycleLogs[2]];
      final e2 = CycleEngine(
          settings: const Settings(contraception: Contraception.none),
          logs: fewer,
          today: target);
      final after =
          FeelingSelector.groupByStage(feelings: [log(d(10, 26), ['cramps'])], eng: e2);
      expect(after.values.expand((l) => l).length, 1);
    });
    test('known historical records remain grouped during current silence', () {
      final oldLogs = [
        PeriodLog(d(1, 1), d(1, 5)),
        PeriodLog(d(1, 29), d(2, 2)),
      ];
      final silent = CycleEngine(
        settings: const Settings(contraception: Contraception.none),
        logs: oldLogs,
        today: d(3, 10),
      );
      expect(silent.inSilenceMode, isTrue);
      final groups = FeelingSelector.groupByStage(
        feelings: [log(d(1, 3), ['cramps'])],
        eng: silent,
      );
      expect(groups[HistoryStage.menstrual]!.single.date, key(d(1, 3)));
      expect(groups[HistoryStage.unknown], isEmpty);
    });
  });

  group('recentDiscomfort support signal', () {
    test('moderate/strong within three days raises it', () {
      expect(
          FeelingSelector.recentDiscomfort(
              [log(d(10, 27), ['cramps'], intensity: FeelingIntensity.strong)],
              target,
              discomfortConcepts: {'cramps'},
              ),
          isTrue);
      expect(
          FeelingSelector.recentDiscomfort(
              [log(d(10, 29), ['headache'],
                   intensity: FeelingIntensity.moderate)],
              target,
              discomfortConcepts: {'headache'}),
          isTrue);
    });
    test('mild, older, or future entries do not', () {
      expect(
          FeelingSelector.recentDiscomfort(
              [log(d(10, 29), ['headache'], intensity: FeelingIntensity.mild)],
              target,
              discomfortConcepts: {'headache'}),
          isFalse);
      expect(
          FeelingSelector.recentDiscomfort(
              [log(d(10, 25), ['headache'],
                   intensity: FeelingIntensity.strong)], // 4 days back
              target,
              discomfortConcepts: {'headache'}),
          isFalse);
      expect(
          FeelingSelector.recentDiscomfort(
              [log(d(10, 31), ['headache'],
                   intensity: FeelingIntensity.strong)],
              target,
              discomfortConcepts: {'headache'}),
          isFalse);
    });
    test('intensity alone does not classify a positive feeling as discomfort', () {
      expect(
          FeelingSelector.recentDiscomfort(
              [log(d(10, 29), ['good-mood'], intensity: FeelingIntensity.strong)],
              target,
              discomfortConcepts: {'cramps', 'headache'}),
          isFalse);
    });
    test('periodNear: ≤3 days from a valid estimate only', () {
      // 21-day cycles: start 10-22 → expected next 11-12; 11-10 is 2 days out
      expect(FeelingSelector.periodNear(engAt(d(11, 10)), d(11, 10)), isTrue);
      expect(FeelingSelector.periodNear(engAt(d(11, 8)), d(11, 8)), isFalse); // 4 days
      // No estimate offered at all (no logs) → never triggers.
      final empty =
          CycleEngine(settings: const Settings(), logs: const [], today: target);
      expect(FeelingSelector.periodNear(empty, target), isFalse);
      // Hormonal mode → no extrapolated next start → never triggers.
      final hormonal = CycleEngine(
          settings: const Settings(contraception: Contraception.hormonal),
          logs: cycleLogs,
          today: d(11, 10));
      expect(FeelingSelector.periodNear(hormonal, d(11, 10)), isFalse);
    });
  });
}
