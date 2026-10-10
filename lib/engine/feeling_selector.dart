import 'cycle_engine.dart';
import 'models.dart';
import 'support_selector.dart';

/// One historical feeling suggestion and its transparent, rule-derived basis.
/// Recurrence is counted across *distinct cycles*; repeated logs inside one
/// cycle never inflate it. Missing logs stay unknown, never "absent".
class HistoricalPick {
  final String concept; // canonical or custom:<id> concept reference
  final int cycles; // distinct cycles that logged it in a similar position
  final DateTime lastLogged; // most recent contributing date
  const HistoricalPick(this.concept, this.cycles, this.lastLogged);
}

/// The three "She may notice" possibilities for one date plus the provenance
/// needed to render them honestly.
class FeelingBriefing {
  final List<HistoricalPick> historical; // fixed; never rotated by "Show others"
  final List<String> general; // date-deterministic, rotates only these
  const FeelingBriefing(this.historical, this.general);

  bool get isEmpty => historical.isEmpty && general.isEmpty;
  List<String> get concepts => [...historical.map((h) => h.concept), ...general];
}

/// Deterministic feeling selection for the Today briefing.
///
/// Pure Dart with an injected date (no clock reads, no Flutter), so the same
/// inputs always produce the same items — they survive reopening and rebuilds.
/// "Show others" advances [cursor] through the ranked general pool only;
/// historical items are fixed for the day.
class FeelingSelector {
  const FeelingSelector._();

  /// One previous cycle may supply a "Previously logged" item; recurrence in
  /// at least two distinct cycles supports the stronger "From history" framing.
  static const int recurrenceCycles = 2;

  /// Similar-position window: a logged date counts for the target date when it
  /// falls at a similar position within its own stage. The window is
  /// ±3 calendar days from the target's offset into its stage, measured
  /// separately per stage group, and never crosses a stage boundary.
  /// (Documented product choice: 7±3 days inside luteal and 5±3 inside
  /// menstrual keep sparse histories useful without pretending precision.)
  static const int positionWindow = 3;

  static List<String> _ranked(List<String> ids, DateTime date) =>
      [...ids]..sort((a, b) =>
          SupportSelector.dayRank(a, date).compareTo(SupportSelector.dayRank(b, date)));

  /// [count] general possibilities for [date].
  /// - [eligible] concepts are already filtered to reviewed stage applicability.
  /// - [exclude] removes concepts already shown or logged for that date.
  /// - [cursor] advances the rotation window; the pick is stable for a given
  ///   date + cursor before and after manual rotation.
  static List<String> general({
    required List<String> eligible,
    required DateTime date,
    Set<String> exclude = const {},
    int cursor = 0,
    int count = 3,
  }) {
    final ranked = _ranked(eligible.where((e) => !exclude.contains(e)).toList(), date);
    if (ranked.isEmpty || count <= 0) return const [];
    final start = cursor % ranked.length;
    final n = count < ranked.length ? count : ranked.length;
    return [for (var i = 0; i < n; i++) ranked[(start + i) % ranked.length]];
  }

  /// Stage-position of [date] within its own cycle, in days from the stage
  /// start, plus which stage. Null when the date has no derivable stage.
  static ({HistoryStage stage, int position})? stagePosition(
      CycleEngine eng, DateTime date) {
    final phase = eng.phaseForRecord(date);
    if (phase == null) return null;
    final stage = historyStageOf(phase);
    final start = stageStart(eng, date, stage);
    if (start == null) return null;
    return (stage: stage, position: CycleEngine.daysBetween(start, date));
  }

  /// First day of the stage [date] falls in, walking its cycle anchors.
  static DateTime? stageStart(CycleEngine eng, DateTime date, HistoryStage stage) {
    for (var back = 0; back <= 40; back++) {
      final probe = CycleEngine.addCalendarDays(date, -back);
      if (historyStageOf(eng.phaseForRecord(probe)) != stage) {
        return CycleEngine.addCalendarDays(probe, 1);
      }
    }
    return null;
  }

  /// Historical recurrence for [date]: counts distinct cycles in which the
  /// concept was logged at a similar position of the same stage group.
  ///
  /// A date is attributed to the cycle whose period start immediately precedes
  /// it, so two logs inside one cycle count once. PMS logs count inside
  /// luteal. Results carry `cycles` and the most recent contributing date so
  /// the UI can explain its own basis.
  static List<HistoricalPick> history({
    required List<PeriodLog> logs,
    required List<FeelingLog> feelings,
    required CycleEngine eng,
    required DateTime date,
    int maxItems = 2,
  }) {
    final position = stagePosition(eng, date);
    if (position == null) return const [];
    final past = logs.where((l) => !l.start.isAfter(CycleEngine.dateOnly(date))).toList();
    if (past.isEmpty) return const [];
    DateTime? cycleStartOf(DateTime d) {
      DateTime? best;
      for (final l in past) {
        if (!l.start.isAfter(d) && (best == null || l.start.isAfter(best))) best = l.start;
      }
      return best;
    }

    int? distinctCycle(DateTime logDate) {
      final s = cycleStartOf(logDate);
      return s == null ? null : past.indexOf(past.firstWhere((l) => l.start == s));
    }

    final byConcept = <String, ({int cycles, Set<int> seen, DateTime last})>{};
    final targetCycle = distinctCycle(CycleEngine.dateOnly(date));
    final stageStartForDate = <String, int?>{};
    for (final f in feelings) {
      final logDate = DateTime.tryParse(f.date);
      if (logDate == null || !logDate.isBefore(CycleEngine.dateOnly(date))) continue;
      final cycle = distinctCycle(logDate);
      if (cycle == null || cycle == targetCycle) continue;
      // similar-position: same stage group, offset within ±positionWindow
      final s = stageStartForDate.putIfAbsent(
          f.date, () => _positionInStage(eng, logDate, position.stage));
      if (s == null || (s - position.position).abs() > positionWindow) continue;
      for (final e in AppData.dedupeEntries(f.entries)) {
        final concept = canonicalFeelingId(e.concept);
        final prev = byConcept[concept];
        if (prev == null) {
          byConcept[concept] = (cycles: 1, seen: {cycle}, last: logDate);
        } else {
          final seen = {...prev.seen};
          final grew = seen.add(cycle);
          byConcept[concept] = (
            cycles: prev.cycles + (grew ? 1 : 0),
            seen: seen,
            last: logDate.isAfter(prev.last) ? logDate : prev.last,
          );
        }
      }
    }
    final picks = [
      for (final e in byConcept.entries)
        HistoricalPick(e.key, e.value.cycles, e.value.last),
    ];
    // Recurrence across distinct cycles first, then recency; ties by concept
    // id so the result is deterministic.
    picks.sort((a, b) {
      final byCycles = b.cycles.compareTo(a.cycles);
      if (byCycles != 0) return byCycles;
      final byRecent = b.lastLogged.compareTo(a.lastLogged);
      return byRecent != 0 ? byRecent : a.concept.compareTo(b.concept);
    });
    return picks.take(maxItems).toList();
  }

  /// Offset of [date] into its current [stage] run, or null when the date's
  /// derived stage differs.
  static int? _positionInStage(CycleEngine eng, DateTime date, HistoryStage stage) {
    if (historyStageOf(eng.phaseForRecord(date)) != stage) return null;
    final start = stageStart(eng, date, stage);
    if (start == null) return null;
    return CycleEngine.daysBetween(start, date);
  }

  /// The full briefing: up to [maxHistorical] fixed historical picks plus at
  /// least one general possibility to fill three slots. Deduplicates canonical
  /// and merged concepts across the two groups. When the stage-specific pool
  /// cannot fill the remaining slots (thin reviewed stage lists), the general
  /// [fallbackEligible] pool fills them — still date-deterministic.
  static FeelingBriefing pick({
    required List<PeriodLog> logs,
    required List<FeelingLog> feelings,
    required CycleEngine eng,
    required DateTime date,
    required List<String> generalEligible,
    List<String> fallbackEligible = const [],
    Set<String> exclude = const {},
    int cursor = 0,
    int total = 3,
    int maxHistorical = 2,
  }) {
    final canonicalExclude = exclude.map(canonicalFeelingId).toSet();
    final hist = history(
      logs: logs,
      feelings: feelings,
      eng: eng,
      date: date,
      maxItems: maxHistorical + canonicalExclude.length,
    ).where((h) => !canonicalExclude.contains(h.concept)).take(maxHistorical).toList();
    var taken = {...hist.map((h) => h.concept), ...canonicalExclude};
    final need = (total - hist.length).clamp(0, total);
    var gen = general(
      eligible: generalEligible,
      date: date,
      exclude: taken,
      cursor: cursor,
      count: need,
    );
    if (gen.length < need && fallbackEligible.isNotEmpty) {
      taken = {...taken, ...gen};
      gen = [
        ...gen,
        ...general(
          eligible: fallbackEligible,
          date: date,
          exclude: taken,
          cursor: cursor,
          count: need - gen.length,
        ),
      ];
    }
    return FeelingBriefing(hist, gen);
  }

  /// Four-stage grouping for the History view. Stage is derived at read time
  /// from the dated record's cycle position (PMS counts inside luteal); when
  /// no stage can be derived the date lands in "unknown" — never dropped and
  /// never invented. Newest records first within each group.
  static Map<HistoryStage, List<FeelingLog>> groupByStage({
    required List<FeelingLog> feelings,
    required CycleEngine eng,
  }) {
    final out = <HistoryStage, List<FeelingLog>>{
      for (final s in HistoryStage.values) s: <FeelingLog>[],
    };
    for (final f in feelings) {
      final day = DateTime.tryParse(f.date);
      out[historyStageOf(day == null ? null : eng.phaseForRecord(day))]!
          .add(f);
    }
    for (final list in out.values) {
      list.sort((a, b) => b.date.compareTo(a.date));
    }
    return out;
  }

  /// Support-relevance signal: discomfort logged with at least moderate
  /// intensity in the three days up to [date]. Used only to raise the existing
  /// `supportPriority` flag through the untouched catalog pick path — it never
  /// adds, removes or rewrites catalog items.
  static bool recentDiscomfort(List<FeelingLog> logs, DateTime date,
      {Set<String> discomfortConcepts = const {}}) {
    final d = CycleEngine.dateOnly(date);
    for (final f in logs) {
      final day = DateTime.tryParse(f.date);
      if (day == null) continue;
      final diff = CycleEngine.daysBetween(day, d);
      if (diff < 0 || diff > 3) continue;
      if (f.entries.any((e) =>
          discomfortConcepts.contains(canonicalFeelingId(e.concept)) &&
          (e.intensity == FeelingIntensity.moderate ||
          e.intensity == FeelingIntensity.strong))) {
        return true;
      }
    }
    return false;
  }

  /// Pre-period context signal: the next expected start is estimated within
  /// [withinDays] days (or overdue to on-time). Also served only through the
  /// existing `supportPriority` pick flag; estimates that don't exist (no
  /// data, hormonal, silence) never trigger it — nothing is fabricated.
  static bool periodNear(CycleEngine eng, DateTime date, {int withinDays = 3}) {
    final next = eng.nextExpectedStart();
    if (next == null) return false;
    final diff = CycleEngine.daysBetween(CycleEngine.dateOnly(date), next);
    return diff >= 0 && diff <= withinDays;
  }
}
