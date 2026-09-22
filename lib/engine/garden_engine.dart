import 'models.dart';

/// Plant growth stages (implementation.md P6). Five visible stages; the twelfth
/// credited moment matures the plant (it is retained) and the next moment starts
/// a fresh seed — "mature" is a completed plant, not an active-plant stage.
enum PlantStage { seed, sprout, leaves, buds, flowering }

PlantStage stageForActive(int momentsOnActive) {
  if (momentsOnActive <= 0) return PlantStage.seed;
  if (momentsOnActive <= 2) return PlantStage.sprout;
  if (momentsOnActive <= 5) return PlantStage.leaves;
  if (momentsOnActive <= 8) return PlantStage.buds;
  return PlantStage.flowering; // 9..11
}

/// Immutable snapshot of garden progression derived purely from persisted care
/// events. Nothing here mutates state or imports Flutter — the UI reads it.
class GardenState {
  final int totalMoments;
  final int completedPlants; // fully matured plants retained in the garden
  final int activePlantIndex; // the single in-progress plant
  final int momentsOnActive; // 0..11 credited moments on the active plant
  final PlantStage stage;
  final int variety; // 0..2, rotates deterministically by plant index
  final int weeklyMoments; // all moments earned in the current Mon–Sun week
  final int weeklyGoal; // weeklyMoments capped at 3 for the goal indicator
  final int learn;
  final int act;
  final int reflect;

  const GardenState({
    required this.totalMoments,
    required this.completedPlants,
    required this.activePlantIndex,
    required this.momentsOnActive,
    required this.stage,
    required this.variety,
    required this.weeklyMoments,
    required this.weeklyGoal,
    required this.learn,
    required this.act,
    required this.reflect,
  });

  bool get activePlantMatured => momentsOnActive == 0 && totalMoments > 0 && totalMoments % 12 == 0;
}

/// Pure garden progression. Twelve credited moments mature a plant; the twelfth
/// belongs to the finished plant and the thirteenth grows the next seed. Progress
/// never decays and plants never die.
class GardenEngine {
  final List<CareEvent> events; // persisted care events (category + fixed date)
  final DateTime today; // local calendar day injected by the caller

  const GardenEngine({required this.events, required this.today});

  static const int momentsPerPlant = 12;
  static const int weeklyGoalCap = 3;
  static const int varietyCount = 3;

  /// Chronological order (award date, then id) so plant assignment is stable.
  List<CareEvent> get _ordered => [...events]
    ..sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0 ? c : a.id.compareTo(b.id);
    });

  int get totalMoments => events.length;

  int get completedPlants => totalMoments ~/ momentsPerPlant;

  int get momentsOnActive => totalMoments % momentsPerPlant;

  /// The single active plant is the next ordinal after the completed ones.
  int get activePlantIndex => completedPlants;

  PlantStage get stage => stageForActive(momentsOnActive);

  /// Deterministic variety rotation across the three initial varieties.
  int varietyForPlant(int index) => index % varietyCount;
  int get variety => varietyForPlant(activePlantIndex);

  GardenState state() {
    var learn = 0, act = 0, reflect = 0;
    for (final e in events) {
      switch (e.category) {
        case CareCategory.learn:
          learn++;
          break;
        case CareCategory.act:
          act++;
          break;
        case CareCategory.reflect:
          reflect++;
          break;
      }
    }
    final weekly = weeklyMoments();
    return GardenState(
      totalMoments: totalMoments,
      completedPlants: completedPlants,
      activePlantIndex: activePlantIndex,
      momentsOnActive: momentsOnActive,
      stage: stage,
      variety: variety,
      weeklyMoments: weekly,
      weeklyGoal: weekly > weeklyGoalCap ? weeklyGoalCap : weekly,
      learn: learn,
      act: act,
      reflect: reflect,
    );
  }

  /// Monday–Sunday week bounds for [today], using local calendar-day math.
  ({DateTime start, DateTime end}) currentWeek() {
    final start = CycleEngineDay.add(today, -(today.weekday - DateTime.monday));
    return (start: start, end: CycleEngineDay.add(start, 6));
  }

  /// All credited moments earned in the current Mon–Sun week (uncapped). The
  /// weekly *goal* is encouragement only — growth ignores this cap.
  int weeklyMoments() {
    final week = currentWeek();
    final wk0 = week.start;
    final wk6 = week.end;
    var n = 0;
    for (final e in events) {
      final d = DateTime.tryParse(e.date);
      if (d == null) continue;
      if (!d.isBefore(wk0) && !d.isAfter(wk6)) n++;
    }
    return n;
  }

  /// The events that built a given plant (12 per completed plant, remainder for
  /// the active one). Growth dates are fixed at award time.
  List<CareEvent> eventsForPlant(int index) {
    final ordered = _ordered;
    final from = index * momentsPerPlant;
    if (from >= ordered.length) return const [];
    final to = from + momentsPerPlant;
    return ordered.sublist(from, to > ordered.length ? ordered.length : to);
  }
}

/// Tiny local calendar-day helper so the garden engine stays pure Dart without
/// importing the cycle engine (keeps module boundaries clean).
class CycleEngineDay {
  const CycleEngineDay._();
  static DateTime add(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);
}
