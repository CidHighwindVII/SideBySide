import 'dart:io';

import 'package:sidebyside/data/catalog.dart';
import 'package:sidebyside/engine/cycle_engine.dart';
import 'package:sidebyside/engine/models.dart';
import 'package:test/test.dart';

DateTime d(int m, int day) => DateTime(2026, m, day);

CycleEngine engine({
  List<PeriodLog> logs = const [],
  Settings settings = const Settings(avgLength: 28, periodLength: 5),
  required DateTime today,
}) => CycleEngine(
  settings: settings,
  logs: [...logs]..sort((a, b) => a.start.compareTo(b.start)),
  today: today,
);

final oneLog = [PeriodLog(d(1, 1), d(1, 5))];

void main() {
  group('§4.2 phase windows (28/5 cycle)', () {
    final e = engine(logs: oneLog, today: d(3, 1));
    test('menstrual = day 1..5', () {
      expect(e.phaseAt(d(1, 1)), Phase.menstrual);
      expect(e.phaseAt(d(1, 5)), Phase.menstrual);
    });
    test('follicular = after period → ovulation-2', () {
      expect(e.phaseAt(d(1, 6)), Phase.follicular);
      expect(e.phaseAt(d(1, 11)), Phase.follicular);
    });
    test('ovulation = cycle-14 ±2', () {
      expect(e.phaseAt(d(1, 12)), Phase.ovulation);
      expect(e.phaseAt(d(1, 14)), Phase.ovulation);
      expect(e.phaseAt(d(1, 16)), Phase.ovulation);
    });
    test('luteal = after ovulation → 7 days before next period', () {
      expect(e.phaseAt(d(1, 17)), Phase.luteal);
      expect(e.phaseAt(d(1, 21)), Phase.luteal);
    });
    test('D28: PMS = last 7 days', () {
      expect(
        e.phaseAt(d(1, 22)),
        Phase.pms,
      ); // was luteal under the 5-day window
      expect(e.phaseAt(d(1, 24)), Phase.pms);
      expect(e.phaseAt(d(1, 28)), Phase.pms);
    });
    test('D28: pmsStart fires 2 days earlier', () {
      expect(engine(logs: oneLog, today: d(1, 8)).pmsStart(d(1, 8)), d(1, 22));
    });
    test('D28: 21-day cycle — PMS never overlaps the ovulation window', () {
      final e = engine(
        logs: [PeriodLog(d(1, 1), d(1, 5)), PeriodLog(d(1, 22), d(1, 26))],
        today: d(2, 1),
      );
      // ovuDay = 7 → ovulation window days 5..9; PMS starts day max(21-6, 10) = 15
      expect(e.phaseAt(d(1, 9)), Phase.ovulation);
      for (var day = 1; day <= 21; day++) {
        if (e.phaseAt(d(1, day)) == Phase.pms) {
          expect(day, greaterThan(9), reason: 'PMS day $day');
        }
      }
      expect(e.phaseAt(d(1, 15)), Phase.pms);
    });
    test('predicted next cycle wraps day 29 → menstrual', () {
      expect(e.phaseAt(d(1, 29)), Phase.menstrual);
      expect(e.nextExpectedStart(), d(1, 29));
    });
    test('D12: future-dated log defines the cycle (32-day gap)', () {
      final e2 = engine(
        logs: [oneLog.first, PeriodLog(d(2, 2), null)],
        today: d(3, 1),
      );
      // day 24 of a 32-day cycle is luteal, not PMS (as it would be at 28)
      expect(e2.phaseAt(d(1, 24)), Phase.luteal);
      expect(e2.phaseAt(d(1, 28)), Phase.pms); // day 28 >= 32-6 (D28)
      expect(e2.phaseAt(d(2, 2)), Phase.menstrual); // logged start wins
    });
  });

  group('D16 averages + #1 median', () {
    final starts = [d(1, 1), d(1, 29), d(2, 26), d(3, 26)]; // gaps 28,28,28
    final logs = [
      for (final s in starts) PeriodLog(s, s.add(const Duration(days: 4))),
    ];
    test('auto-recomputes from ≥3 gaps', () {
      expect(engine(logs: logs, today: d(4, 1)).avgCycle, 28);
    });
    test('#1: single outlier does not drag the average (median, not mean)', () {
      final with5 = [...logs, PeriodLog(d(4, 29), d(5, 3))]; // gaps 28,28,28,33
      // mean would be 29.25→29; median stays 28 — the outlier is absorbed.
      expect(engine(logs: with5, today: d(5, 1)).avgCycle, 28);
    });
    test('#1: majority shift moves the median', () {
      final shifted = [
        PeriodLog(d(1, 1), d(1, 5)),
        PeriodLog(d(1, 29), d(2, 2)), // 28
        PeriodLog(d(3, 4), d(3, 8)), // 34
        PeriodLog(d(4, 7), d(4, 11)), // 34
      ];
      expect(engine(logs: shifted, today: d(5, 1)).avgCycle, 34);
    });
    test('#1: 42-day outlier in a 28-day pattern → still 28', () {
      final wild = [
        PeriodLog(d(1, 1), d(1, 5)),
        PeriodLog(d(1, 29), d(2, 2)), // 28
        PeriodLog(d(2, 26), d(3, 2)), // 28
        PeriodLog(d(4, 9), d(4, 13)), // 42
      ];
      // gaps 28,28,42 → median 28 (mean would be 33)
      expect(engine(logs: wild, today: d(5, 10)).avgCycle, 28);
    });
    test('period length auto from last logs', () {
      final e = engine(logs: logs, today: d(4, 1));
      expect(e.avgPeriod, 5);
    });
    test('#1: period median absorbs one long bleed', () {
      final logs = [
        PeriodLog(d(1, 1), d(1, 5)), // 5
        PeriodLog(d(1, 29), d(2, 2)), // 5
        PeriodLog(d(2, 26), d(3, 2)), // 5
        PeriodLog(d(3, 26), d(4, 16)), // 22 (outlier)
      ];
      expect(engine(logs: logs, today: d(5, 1)).avgPeriod, 5);
    });
  });

  group('v0.6.0 D20/D21 — history-only averages + min period length', () {
    test(
      'avgCycle ignores the (now dead) pin flag — median of history wins',
      () {
        final withGaps = [
          PeriodLog(d(1, 1), d(1, 5)),
          PeriodLog(d(1, 29), d(2, 2)), // 28
          PeriodLog(d(3, 4), d(3, 8)), // 34
          PeriodLog(d(4, 7), d(4, 11)), // 34
        ];
        final e = engine(
          logs: withGaps,
          settings: const Settings(avgLength: 28, cyclePinned: true),
          today: d(5, 1),
        );
        expect(e.avgCycle, 34);
      },
    );
    test('periodTooShort: a period must span at least 3 calendar days', () {
      expect(CycleEngine.periodTooShort(d(1, 1), d(1, 1)), isTrue); // same day
      expect(CycleEngine.periodTooShort(d(1, 1), d(1, 2)), isTrue); // 2 days
      expect(
        CycleEngine.periodTooShort(d(1, 1), d(1, 3)),
        isFalse,
      ); // 3 days ok
      expect(CycleEngine.periodTooShort(d(1, 1), d(1, 5)), isFalse);
    });
    test('cycleTooShort: logged starts require at least 21 days', () {
      expect(CycleEngine.cycleTooShort(d(1, 1), d(1, 10)), isTrue); // 9 days
      expect(CycleEngine.cycleTooShort(d(1, 10), d(1, 1)), isTrue); // symmetric
      expect(CycleEngine.cycleTooShort(d(1, 1), d(1, 21)), isTrue); // 20 days
      expect(CycleEngine.cycleTooShort(d(1, 1), d(1, 22)), isFalse); // 21 ok
      expect(CycleEngine.cycleTooShort(d(1, 1), d(2, 1)), isFalse);
    });
    test('calendar-day addition crosses months and leap days without elapsed hours', () {
      expect(CycleEngine.addCalendarDays(DateTime(2024, 2, 28), 1),
          DateTime(2024, 2, 29));
      expect(CycleEngine.addCalendarDays(DateTime(2024, 2, 28), 2),
          DateTime(2024, 3, 1));
      expect(CycleEngine.addCalendarDays(DateTime(2026, 3, 1), -1),
          DateTime(2026, 2, 28));
    });
  });

  group('§4.3 confidence', () {
    test('only setup → low', () {
      expect(engine(logs: [], today: d(1, 1)).confidence, Confidence.low);
    });
    test('one logged start → low', () {
      expect(
        engine(logs: oneLog, today: d(3, 1)).confidence,
        Confidence.low,
      );
    });
    test('≥3 gaps, low variance → high', () {
      final logs = [
        PeriodLog(d(1, 1), d(1, 5)),
        PeriodLog(d(1, 29), d(2, 2)),
        PeriodLog(d(2, 26), d(3, 2)),
        PeriodLog(d(3, 26), d(3, 30)),
      ];
      expect(engine(logs: logs, today: d(4, 1)).confidence, Confidence.high);
    });
    test('≥3 gaps, high variance → medium', () {
      final logs = [
        PeriodLog(d(1, 1), d(1, 5)),
        PeriodLog(d(1, 25), d(1, 29)), // 24
        PeriodLog(d(2, 26), d(3, 1)), // 32
        PeriodLog(d(3, 22), d(3, 26)), // 24
      ];
      expect(engine(logs: logs, today: d(4, 1)).confidence, Confidence.medium);
    });
    test('§4.7 hormonal caps at low', () {
      final logs = [
        PeriodLog(d(1, 1), d(1, 5)),
        PeriodLog(d(1, 29), d(2, 2)),
        PeriodLog(d(2, 26), d(3, 2)),
        PeriodLog(d(3, 26), d(3, 30)),
      ];
      final e = engine(
        logs: logs,
        settings: const Settings(contraception: Contraception.hormonal),
        today: d(4, 1),
      );
      expect(e.confidence, Confidence.low);
    });
  });

  group('§4.6 briefing suppression', () {
    test('quiet follicular stretch → no ping', () {
      for (final day in [6, 7, 8, 9, 10]) {
        expect(
          engine(logs: oneLog, today: d(1, day)).shouldBriefTonight(),
          isFalse,
          reason: 'day $day',
        );
      }
    });
    test('day before expected period start → notify', () {
      expect(
        engine(logs: oneLog, today: d(1, 27)).shouldBriefTonight(),
        isTrue,
      );
    });
    test('first day of PMS window does not trigger a reminder', () {
      // pmsStart moved Jan 24 → Jan 22, so tonight's brief is Jan 21
      expect(
        engine(logs: oneLog, today: d(1, 21)).shouldBriefTonight(),
          isFalse,
      );
    });
    test('phase change alone does not notify', () {
      // follicular (day 11) → ovulation (day 12)
      expect(
        engine(logs: oneLog, today: d(1, 11)).shouldBriefTonight(),
          isFalse,
      );
    });
    test('former red day does not notify', () {
      // day 24 (PMS, red axes) → day 25
      expect(
        engine(logs: oneLog, today: d(1, 24)).shouldBriefTonight(),
          isFalse,
      );
    });
    test('former red bad-news day does not notify', () {
      // menstrual day 3 (news=red) → day 4
      expect(engine(logs: oneLog, today: d(1, 3)).shouldBriefTonight(), isFalse);
    });
    test('briefing toggle off → never', () {
      expect(
        engine(
          logs: oneLog,
          settings: const Settings(briefingEnabled: false),
          today: d(1, 27),
        ).shouldBriefTonight(),
        isFalse,
      );
    });
  });

  group('§4.8 silence mode', () {
    test('missed start → confirmation card, predictions continue', () {
      final e = engine(logs: oneLog, today: d(2, 2)); // expected Jan 29
      expect(e.missedDays, 4);
      expect(e.missedPeriodCard, isTrue);
      expect(e.inSilenceMode, isFalse);
      expect(e.phaseAt(d(2, 2)), isNotNull);
    });
    test('10+ days without log → all predictions halt', () {
      final e = engine(logs: oneLog, today: d(2, 10));
      expect(e.inSilenceMode, isTrue);
      expect(e.phaseOrNull(d(2, 10)), isNull);
      expect(e.shouldBriefTonight(), isFalse);
      expect(e.periodBandAt(d(2, 15)), isFalse);
    });
    test('future-dated log counts as logged → no miss', () {
      final e = engine(
        logs: [oneLog.first, PeriodLog(d(1, 30), d(2, 3))],
        today: d(2, 10),
      );
      expect(e.missedDays, 0);
      expect(e.inSilenceMode, isFalse);
    });
  });

  group('§4.8 bands (D19 + D27)', () {
    final e = engine(logs: oneLog, today: d(1, 8)); // low → ±4
    test('expected period is a ±bandDays band', () {
      expect(e.bandDays, 4);
      expect(e.periodBandAt(d(1, 27)), isTrue);
      expect(e.periodBandAt(d(1, 29)), isTrue);
      expect(e.periodBandAt(d(1, 31)), isTrue);
      expect(e.periodBandAt(d(1, 20)), isFalse);
    });
    test('ovulation window is a ±bandDays band', () {
      expect(e.ovulationBandAt(d(1, 12)), isTrue);
      expect(e.ovulationBandAt(d(1, 16)), isTrue);
      expect(e.ovulationBandAt(d(1, 8)), isFalse);
    });
    test('D27: bandDays = 2/3/4 by confidence', () {
      final regular = [
        PeriodLog(d(1, 1), d(1, 5)),
        PeriodLog(d(1, 29), d(2, 2)),
        PeriodLog(d(2, 26), d(3, 2)),
        PeriodLog(d(3, 26), d(3, 30)),
      ]; // gaps 28,28,28 → high
      expect(engine(logs: regular, today: d(4, 1)).bandDays, 2);
      expect(engine(logs: oneLog, today: d(3, 1)).bandDays, 4); // sparse
      expect(engine(logs: [], today: d(3, 1)).bandDays, 4); // low
    });
    test('regular history still shows a start and end uncertainty band', () {
      final e = engine(
        logs: [
          PeriodLog(d(1, 1), d(1, 5)),
          PeriodLog(d(1, 29), d(2, 2)),
          PeriodLog(d(2, 26), d(3, 2)),
          PeriodLog(d(3, 26), d(3, 30)),
        ],
        today: d(4, 1),
      ); // gaps 28,28,28 → high → isRegular
      expect(e.isRegular, isTrue);
      // estimated Apr 23–27 with ±2 calendar-day margin
      expect(e.periodBandAt(d(4, 20)), isFalse);
      expect(e.periodBandAt(d(4, 22)), isTrue);
      expect(e.periodBandAt(d(4, 23)), isTrue);
      expect(e.periodBandAt(d(4, 27)), isTrue);
      expect(e.periodBandAt(d(4, 29)), isTrue);
      expect(e.periodBandAt(d(4, 30)), isFalse);
    });
    test('v0.10: regular → fixed 6-day fertile window ending at ovulation',
        () {
      final e = engine(
        logs: [
          PeriodLog(d(1, 1), d(1, 5)),
          PeriodLog(d(1, 29), d(2, 2)),
          PeriodLog(d(2, 26), d(3, 2)),
          PeriodLog(d(3, 26), d(3, 30)),
        ],
        today: d(4, 1),
      );
      // Jan cycle: ovu day = Jan 14 → window Jan 9–14, no ± buffer
      expect(e.ovulationBandAt(d(1, 8)), isFalse);
      expect(e.ovulationBandAt(d(1, 9)), isTrue);
      expect(e.ovulationBandAt(d(1, 14)), isTrue);
      expect(e.ovulationBandAt(d(1, 15)), isFalse);
    });
    test('D27: low-confidence band reaches ±4, false at ±5', () {
      final e = engine(
        logs: oneLog,
        settings: const Settings(contraception: Contraception.hormonal),
        today: d(1, 8),
      ); // hormonal caps confidence at low
      expect(e.bandDays, 4);
      expect(e.periodBandAt(d(1, 25)), isTrue); // Jan 29 − 4
      expect(e.periodBandAt(d(2, 2)), isTrue); // Jan 29 + 4
      expect(e.periodBandAt(d(1, 24)), isFalse); // ±5
      expect(e.periodBandAt(d(2, 7)), isFalse);
    });
  });

  group('§4.8 health nudge', () {
    test('wildly irregular gaps → eligible', () {
      final logs = [
        PeriodLog(d(1, 1), d(1, 5)),
        PeriodLog(d(1, 20), d(1, 24)), // 19
        PeriodLog(d(3, 5), d(3, 9)), // 44
        PeriodLog(d(4, 2), d(4, 6)), // 28
      ];
      expect(engine(logs: logs, today: d(5, 1)).healthNudgeEligible, isTrue);
    });
    test('regular gaps → not eligible', () {
      final logs = [
        PeriodLog(d(1, 1), d(1, 5)),
        PeriodLog(d(1, 29), d(2, 2)),
        PeriodLog(d(2, 26), d(3, 2)),
        PeriodLog(d(3, 26), d(3, 30)),
      ];
      expect(engine(logs: logs, today: d(5, 1)).healthNudgeEligible, isFalse);
    });
    test('shown once', () {
      final logs = [
        PeriodLog(d(1, 1), d(1, 5)),
        PeriodLog(d(1, 20), d(1, 24)),
        PeriodLog(d(3, 5), d(3, 9)),
      ];
      expect(
        engine(
          logs: logs,
          settings: const Settings(healthNudgeShown: true),
          today: d(5, 1),
        ).healthNudgeEligible,
        isFalse,
      );
    });
    test('D29: in-range-but-wild gaps [22,31,22,31] → eligible', () {
      final logs = [
        PeriodLog(d(1, 1), d(1, 5)),
        PeriodLog(d(1, 23), d(1, 27)), // 22
        PeriodLog(d(2, 23), d(2, 27)), // 31
        PeriodLog(d(3, 17), d(3, 21)), // 22
        PeriodLog(d(4, 17), d(4, 21)), // 31
      ];
      expect(engine(logs: logs, today: d(5, 1)).healthNudgeEligible, isTrue);
    });
    test('D29: stable in-range gaps [27,28,27,28] → not eligible', () {
      final logs = [
        PeriodLog(d(1, 1), d(1, 5)),
        PeriodLog(d(1, 28), d(2, 1)), // 27
        PeriodLog(d(2, 25), d(2, 29)), // 28
        PeriodLog(d(3, 24), d(3, 28)), // 27
        PeriodLog(d(4, 21), d(4, 25)), // 28
      ];
      expect(engine(logs: logs, today: d(5, 1)).healthNudgeEligible, isFalse);
    });
  });

  group('D17 catalog tags', () {
    test('juntos never appears when apartados', () {
      const items = [
        CatalogItem('a', 'a', ItemTag.sempre),
        CatalogItem('b', 'b', ItemTag.juntos),
        CatalogItem('c', 'c', ItemTag.apartados),
      ];
      expect(PhaseCatalog.pick(items, false, 10).map((i) => i.tag).toList(), [
        ItemTag.sempre,
        ItemTag.apartados,
      ]);
      expect(PhaseCatalog.pick(items, true, 10).map((i) => i.tag).toList(), [
        ItemTag.sempre,
        ItemTag.juntos,
      ]);
    });
  });

  group('v0.3.0 #15 support re-rank', () {
    const items = [
      CatalogItem('plain', 'plain', ItemTag.sempre),
      CatalogItem('boosted', 'boosted', ItemTag.sempre, support: true),
    ];
    test('supportPriority puts apoio items first', () {
      final picked = PhaseCatalog.pick(items, true, 2, supportPriority: true);
      expect(picked.first.pt, 'boosted');
    });
    test('without the flag, original order is kept', () {
      expect(PhaseCatalog.pick(items, true, 2).first.pt, 'plain');
    });
  });

  group('support-first catalog', () {
    test('shipped catalog has neutral, filtered advice and legacy axes', () {
      final catalog = Catalog.parse(
        File('assets/catalog.json').readAsStringSync(),
      );
      for (final p in Phase.values) {
        expect(catalog[p].axes[OutlookAxis.energy], isNotNull, reason: p.name);
        expect(catalog[p].actionable, isNotEmpty, reason: p.name);
        final fallback = engine(logs: [], today: d(1, 1));
        for (final axis in OutlookAxis.values) {
          expect(fallback.axisRating(p, axis), catalog[p].axes[axis],
              reason: '${p.name}/${axis.name}');
        }
      }
      expect(PhaseCatalog.pick(catalog.general.actionable, false, 3).length, 3);
      expect(PhaseCatalog.pick(catalog.general.actionable, false, 3)
          .any((i) => i.tag == ItemTag.juntos), isFalse);
      expect(PhaseCatalog.pick(catalog.general.actionable, true, 3,
          supportPriority: true).first.support, isTrue);
    });
  });
}
