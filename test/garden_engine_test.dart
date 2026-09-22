import 'package:sidebyside/engine/garden_engine.dart';
import 'package:sidebyside/engine/models.dart';
import 'package:test/test.dart';

DateTime d(int m, int day) => DateTime(2026, m, day);
String k(DateTime x) =>
    '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';

/// n care events spread over distinct days so the weekly cap never interferes
/// with stage/rollover checks.
List<CareEvent> events(int n, {CareCategory cat = CareCategory.act, DateTime? from}) {
  final start = from ?? d(1, 1);
  return List.generate(n, (i) {
    final day = DateTime(start.year, start.month, start.day + i * 2);
    return CareEvent(i + 1, cat, k(day), 'src:$i');
  });
}

void main() {
  group('GardenEngine — stage boundaries', () {
    test('0 → seed, 1-2 sprout, 3-5 leaves, 6-8 buds, 9-11 flowering', () {
      expect(stageForActive(0), PlantStage.seed);
      expect(stageForActive(1), PlantStage.sprout);
      expect(stageForActive(2), PlantStage.sprout);
      expect(stageForActive(3), PlantStage.leaves);
      expect(stageForActive(5), PlantStage.leaves);
      expect(stageForActive(6), PlantStage.buds);
      expect(stageForActive(8), PlantStage.buds);
      expect(stageForActive(9), PlantStage.flowering);
      expect(stageForActive(11), PlantStage.flowering);
    });
    test('active plant stage tracks moments on the active plant', () {
      final g = GardenEngine(events: events(5), today: d(6, 1));
      expect(g.momentsOnActive, 5);
      expect(g.stage, PlantStage.leaves);
      expect(g.completedPlants, 0);
    });
  });

  group('GardenEngine — rollover', () {
    test('the 12th moment belongs to the completed plant; 13th grows a new seed',
        () {
      final g12 = GardenEngine(events: events(12), today: d(7, 1));
      expect(g12.completedPlants, 1);
      expect(g12.momentsOnActive, 0);
      expect(g12.stage, PlantStage.seed);
      expect(g12.activePlantIndex, 1);

      final g13 = GardenEngine(events: events(13), today: d(7, 1));
      expect(g13.completedPlants, 1);
      expect(g13.momentsOnActive, 1);
      expect(g13.stage, PlantStage.sprout);
    });
    test('plant 0 holds events 1..12, plant 1 holds 13..', () {
      final g = GardenEngine(events: events(14), today: d(8, 1));
      expect(g.eventsForPlant(0).length, 12);
      expect(g.eventsForPlant(1).length, 2);
    });
  });

  group('GardenEngine — variety rotation', () {
    test('three varieties cycle deterministically by plant index', () {
      final g = GardenEngine(events: const [], today: d(1, 1));
      expect([for (var i = 0; i < 6; i++) g.varietyForPlant(i)],
          [0, 1, 2, 0, 1, 2]);
    });
    test('active variety follows the active plant index', () {
      final g = GardenEngine(events: events(13), today: d(7, 1));
      expect(g.activePlantIndex, 1);
      expect(g.variety, 1);
    });
  });

  group('GardenEngine — weekly goal (Mon–Sun), capped but never limiting growth',
      () {
    // 2026-10-05 is a Monday.
    test('counts only the current week and caps the goal at three', () {
      final week = [
        for (var day = 0; day < 5; day++)
          CareEvent(day + 1, CareCategory.act, k(d(10, 5 + day)), 'w$day'),
      ];
      final g = GardenEngine(events: week, today: d(10, 7)); // Wed of same week
      expect(g.weeklyMoments(), 5);
      final s = g.state();
      expect(s.weeklyGoal, 3); // indicator capped at three
      expect(s.totalMoments, 5); // growth retains all five
    });
    test('a previous week does not count toward this week', () {
      final g = GardenEngine(
          events: [
            CareEvent(1, CareCategory.act, k(d(9, 28)), 'prev'), // prior week
            CareEvent(2, CareCategory.act, k(d(10, 5)), 'this'), // this Monday
          ],
          today: d(10, 7));
      expect(g.weeklyMoments(), 1);
    });
    test('week spans Monday to Sunday', () {
      final g = GardenEngine(events: const [], today: d(10, 5)); // Monday
      final w = g.currentWeek();
      expect(w.start, d(10, 5));
      expect(w.end, d(10, 11)); // following Sunday
    });
  });

  group('GardenEngine — category totals and no decay', () {
    test('totals split by category', () {
      final mixed = [
        CareEvent(1, CareCategory.learn, k(d(1, 2)), 'l'),
        CareEvent(2, CareCategory.act, k(d(1, 4)), 'a'),
        CareEvent(3, CareCategory.reflect, k(d(1, 6)), 'r'),
        CareEvent(4, CareCategory.learn, k(d(1, 8)), 'l2'),
      ];
      final s = GardenEngine(events: mixed, today: d(6, 1)).state();
      expect(s.learn, 2);
      expect(s.act, 1);
      expect(s.reflect, 1);
      expect(s.totalMoments, 4);
    });
    test('long inactivity never removes progress', () {
      final old = [CareEvent(1, CareCategory.act, k(d(1, 2)), 'a')];
      final s = GardenEngine(events: old, today: d(12, 31)).state();
      expect(s.totalMoments, 1);
      expect(s.momentsOnActive, 1);
      expect(s.stage, PlantStage.sprout);
    });
  });
}
