import 'dart:convert';
import 'dart:io';

import 'package:sidebyside/data/feeling_catalog.dart';
import 'package:sidebyside/data/catalog.dart';
import 'package:sidebyside/engine/cycle_engine.dart';
import 'package:sidebyside/engine/feeling_selector.dart';
import 'package:sidebyside/engine/models.dart';
import 'package:test/test.dart';

void main() {
  final catalog = FeelingCatalog.parse(
      File('assets/feelings.json').readAsStringSync());
  final supportCatalog = Catalog.parse(File('assets/catalog.json').readAsStringSync());

  group('support action identity contracts', () {
    test('every packaged actionable has a globally unique stable ID', () {
      final ids = [
        ...supportCatalog.general.actionable.map((i) => i.id),
        for (final phase in supportCatalog.phases.values)
          ...phase.actionable.map((i) => i.id),
      ];
      expect(ids.every((id) => id.isNotEmpty), isTrue);
      expect(ids.toSet().length, ids.length);
    });
  });

  group('feeling catalog content contracts', () {
    test('meets the >=1,000 searchable-entry target', () {
      // Report counts separately: entries include every EN/PT label and alias.
      expect(catalog.searchableEntryCount, greaterThanOrEqualTo(1000),
          reason: 'canonical concepts: ${catalog.conceptCount}');
    });
    test('every concept carries a unique stable id and EN/PT labels', () {
      final ids = catalog.concepts.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final c in catalog.concepts) {
        expect(c.id.trim(), isNotEmpty);
        expect(c.en.trim(), isNotEmpty, reason: c.id);
        expect(c.pt.trim(), isNotEmpty, reason: c.id);
      }
    });
    test('aliases are non-empty and distinct from their own labels', () {
      for (final c in catalog.concepts) {
        for (final a in [...c.aliasesEn, ...c.aliasesPt]) {
          expect(a.trim(), isNotEmpty, reason: c.id);
          expect(a.toLowerCase(), isNot(c.en.toLowerCase()), reason: c.id);
          expect(a.toLowerCase(), isNot(c.pt.toLowerCase()), reason: c.id);
        }
      }
    });
    test('no duplicate searchable terms map ambiguously across ids', () {
      // Equivalent legacy IDs canonicalize to one result; otherwise an exact
      // EN/PT term must never offer two independently selectable concepts.
      final en = <String, String>{};
      final pt = <String, String>{};
      for (final c in catalog.concepts) {
        for (final term in c.terms(false)) {
          final e = FeelingCatalog.searchFold(term.toLowerCase());
          expect(en.putIfAbsent(e, () => c.id), c.id,
              reason: 'ambiguous EN term $e');
        }
        for (final term in c.terms(true)) {
          final p = FeelingCatalog.searchFold(term.toLowerCase());
          expect(pt.putIfAbsent(p, () => c.id), c.id,
              reason: 'ambiguous PT term $p');
        }
      }
    });
    test('stage associations are only the reviewed set — never invented', () {
      // Associations here are a small, deliberate subset of the library;
      // everything else stays searchable without any stage claim.
      final staged = catalog.concepts.where((c) => c.stages.isNotEmpty).toList();
      expect(staged.length, lessThan(catalog.conceptCount ~/ 4));
      for (final c in staged) {
        expect(c.stages.every((s) => s != HistoryStage.unknown), isTrue,
            reason: c.id);
      }
      expect(staged.map((c) => c.id).toSet(), containsAll([
        'cramps', 'backache', 'pelvic-pain', 'leg-ache',
        'tender-breasts', 'bloating', 'acne', 'appetite-up', 'cravings',
        'irritable', 'mood-swings', 'anxious', 'sad', 'emotional',
        'low-energy', 'slept-badly',
      ]));
      expect(catalog.byId('good-mood')!.stages, isEmpty);
    });
    test('unassociated library entries are not general briefing suggestions', () {
      expect(catalog.eligibleFor(HistoryStage.unknown),
          unorderedEquals(['calm', 'content', 'neutral', 'private', 'sociable']));
      expect(catalog.eligibleFor(HistoryStage.unknown), isNot(contains('chest-tight')));
      expect(catalog.byId('chest-tight'), isNotNull); // still searchable/loggable
    });
    test('all categories from the agreed scope are covered', () {
      final cats = catalog.concepts.map((c) => c.category).toSet();
      for (final cat in FeelingCategory.values) {
        expect(cats, contains(cat), reason: cat.name);
      }
    });
    test('legacy observation tags map to real catalog concepts', () {
      for (final entry in legacyFeelingTags.entries) {
        expect(catalog.byId(entry.value), isNotNull, reason: entry.key);
      }
    });
    test('equivalent old identifiers resolve and deduplicate as canonical concepts', () {
      expect(catalog.byId('sweet-tooth')!.id, 'cravings');
      expect(catalog.byId('breath-shallow')!.id, 'shallow-breath');
      final merged = AppData.dedupeEntries(const [
        FeelingEntry('sweet-tooth'),
        FeelingEntry('cravings', intensity: FeelingIntensity.strong),
        FeelingEntry('breath-shallow'),
        FeelingEntry('shallow-breath'),
      ]);
      expect(merged, hasLength(2));
      expect(merged.firstWhere((e) => e.concept == 'cravings').intensity,
          FeelingIntensity.strong);
    });
    test('every stage group has response cues in EN and PT', () {
      for (final stage in HistoryStage.values) {
        final cues = catalog.cuesFor(stage);
        expect(cues, isNotEmpty, reason: stage.name);
        for (final c in cues) {
          expect(c.en.trim(), isNotEmpty);
          expect(c.pt.trim(), isNotEmpty);
        }
      }
    });
    test('search is accent-insensitive EN/PT and alias-backed', () {
      expect(catalog.search('inchaço').map((c) => c.id), contains('bloating'));
      expect(catalog.search('inchaco').map((c) => c.id), contains('bloating'));
      expect(catalog.search('chocolate').map((c) => c.id),
          contains('cravings'));
      expect(catalog.search('cabeça nublada').map((c) => c.id),
          contains('focus-off'));
    });
  });

  group('period-start spacing enforcement (pure)', () {
    test('20 days from any start is rejected, 21 days is allowed', () {
      final logs = [PeriodLog(DateTime(2026, 1, 1), null)];
      expect(
          CycleEngine.startSpacingOk(logs, DateTime(2026, 1, 21)), isFalse);
      expect(
          CycleEngine.startSpacingOk(logs, DateTime(2026, 1, 22)), isTrue);
    });
    test('retroactive entries cannot bypass the rule', () {
      final logs = [
        PeriodLog(DateTime(2026, 1, 1), null),
        PeriodLog(DateTime(2026, 2, 1), null),
      ];
      // Mid-January is <21 days from BOTH neighbours.
      expect(
          CycleEngine.startSpacingOk(logs, DateTime(2026, 1, 15)), isFalse);
    });
    test('re-saving the same start (end edit) never trips the rule', () {
      final logs = [PeriodLog(DateTime(2026, 1, 1), null)];
      expect(CycleEngine.startSpacingOk(logs, DateTime(2026, 1, 1)), isTrue);
    });
  });

  group('feeling record models', () {
    test('dedupe keeps the entry with an explicit intensity', () {
      final deduped = AppData.dedupeEntries(const [
        FeelingEntry('cramps'),
        FeelingEntry('cramps', intensity: FeelingIntensity.strong),
        FeelingEntry('bloating'),
      ]);
      expect(deduped.length, 2);
      expect(deduped.firstWhere((e) => e.concept == 'cramps').intensity,
          FeelingIntensity.strong);
    });
    test('dated selections round-trip through JSON with intensity', () {
      const log = FeelingLog('2026-10-10', [
        FeelingEntry('cramps', intensity: FeelingIntensity.mild),
        FeelingEntry('custom:3'),
      ]);
      final back = FeelingLog.fromJson(
          jsonDecode(jsonEncode(log.toJson())) as Map<String, dynamic>);
      expect(back.entries.first.intensity, FeelingIntensity.mild);
      expect(back.entries.last.concept, 'custom:3');
      expect(back.entries.last.intensity, isNull);
    });
  });

  group('deterministic general selection', () {
    test('same date + cursor always yields the same items', () {
      final eligible = catalog.concepts.map((c) => c.id).toList();
      final a = FeelingSelector.general(
          eligible: eligible, date: DateTime(2026, 10, 10), count: 3);
      final b = FeelingSelector.general(
          eligible: eligible, date: DateTime(2026, 10, 10), count: 3);
      expect(a, b);
    });
    test('rotation cursor moves the window without duplicates', () {
      final eligible = catalog.concepts.map((c) => c.id).toList();
      final base = FeelingSelector.general(
          eligible: eligible, date: DateTime(2026, 10, 10), count: 3);
      final next = FeelingSelector.general(
          eligible: eligible, date: DateTime(2026, 10, 10), cursor: 1, count: 3);
      expect(next, isNot(equals(base)));
      // the window shifts by exactly one ranked slot
      final ranked = FeelingSelector.general(
          eligible: eligible, date: DateTime(2026, 10, 10), count: 4);
      expect(next.first, ranked[1]);
    });
    test('exclusions remove concepts from general picks', () {
      final eligible = catalog.concepts.map((c) => c.id).toList();
      final picked = FeelingSelector.general(
          eligible: eligible,
          date: DateTime(2026, 10, 10),
          exclude: {eligible.first},
          count: 50);
      expect(picked, isNot(contains(eligible.first)));
    });
    test('general items change across days (daily rotation)', () {
      final eligible = catalog.concepts.map((c) => c.id).toList();
      final d1 = FeelingSelector.general(
          eligible: eligible, date: DateTime(2026, 10, 10), count: 3);
      final d2 = FeelingSelector.general(
          eligible: eligible, date: DateTime(2026, 10, 11), count: 3);
      expect(d1, isNot(equals(d2)));
    });
  });
}
