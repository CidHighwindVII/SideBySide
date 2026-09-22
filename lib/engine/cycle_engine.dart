import 'dart:math' as math;

import 'models.dart';

/// Why a cycle-based estimate is or is not offered. `available` is a natural,
/// logged, non-silent cycle; `hormonal` deliberately produces no ovulation or
/// fertile-window prediction; `unknown` still estimates but the UI must state
/// the limitation and offer the setting; `noData`/`silence` halt predictions.
enum EstimateState { available, noData, silence, hormonal, unknown }

/// Pure date math for the cycle model. No Flutter imports — testable with `dart test`.
class CycleEngine {
  final Settings settings;
  final List<PeriodLog> logs; // sorted by start
  final DateTime today;
  final Map<Phase, Map<OutlookAxis, Traffic>> axes;

  CycleEngine({
    required this.settings,
    required this.logs,
    required this.today,
    Map<Phase, Map<OutlookAxis, Traffic>>? axes,
  }) : axes = axes ?? _axisMap;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Construct a local calendar date, not an elapsed 24-hour interval (DST).
  static DateTime addCalendarDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  /// UTC-based so a DST clock shift (23/25h days) can never truncate a
  /// calendar-day difference to one day short.
  static int daysBetween(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  List<PeriodLog> get _pastLogs =>
      logs.where((l) => !l.start.isAfter(dateOnly(today))).toList();

  // ---------- averages (D16) ----------

  List<int> get cycleGaps {
    final starts = _pastLogs;
    return [
      for (var i = 1; i < starts.length; i++)
        daysBetween(starts[i - 1].start, starts[i].start),
    ];
  }

  List<int> get periodLengths => _pastLogs
      .where((l) => l.end != null)
      .map((l) => daysBetween(l.start, l.end!) + 1)
      .toList();

  // v0.6.0 (D20): history-only — no manual/pin override. settings.avgLength/
  // periodLength are the hidden pre-data seed (28/5), never user-editable UI.
  int get avgCycle => cycleGaps.length < 3
      ? settings.avgLength
      : _median(cycleGaps.reversed.take(6).toList());

  int get avgPeriod => periodLengths.length < 3
      ? settings.periodLength
      : _median(periodLengths.reversed.take(6).toList());

  /// v0.6.0 (D21): a logged period spans at least 3 calendar days
  /// (start + 2). Used to reject an end date the user picks too early.
  static bool periodTooShort(DateTime start, DateTime end) =>
      daysBetween(start, end) < 2;

  /// Product rule: period starts must be at least 21 calendar days apart.
  static bool cycleTooShort(DateTime a, DateTime b) =>
      daysBetween(a, b).abs() < 21;

  /// v0.2.0 (#1): median resists single-cycle outliers (a 42-day gap in a
  /// 28-day pattern must not drag the average to 31).
  static int _median(List<int> xs) {
    final s = [...xs]..sort();
    final m = s.length ~/ 2;
    return s.length.isOdd ? s[m] : ((s[m - 1] + s[m]) / 2).round();
  }

  // ---------- phases (4.2) ----------

  ({DateTime start, int cycleLength, int periodLength})? _cycleAt(
    DateTime date,
  ) {
    if (logs.isEmpty) return null;
    final d = dateOnly(date);
    final idx = logs.lastIndexWhere((l) => !l.start.isAfter(d));
    if (idx < 0) return null;
    final log = logs[idx];
    final next = idx + 1 < logs.length ? logs[idx + 1] : null;
    // D12: trust the log — a known next start defines this cycle's length
    final cycleLength = next != null
        ? daysBetween(log.start, next.start)
        : avgCycle;
    if (cycleLength <= 0) return null;
    final periodLength = log.end != null
        ? daysBetween(log.start, log.end!) + 1
        : avgPeriod;
    return (
      start: log.start,
      cycleLength: cycleLength,
      periodLength: periodLength.clamp(1, cycleLength - 1),
    );
  }

  int dayOfCycle(DateTime date) {
    final c = _cycleAt(date);
    if (c == null) return 0;
    final day = daysBetween(c.start, date) + 1;
    if (day <= 0) return 0;
    return ((day - 1) % c.cycleLength) + 1; // wraps into predicted cycles
  }

  /// D28: first PMS day (1-based) — last ~7 days of the cycle, clamped so PMS
  /// never begins on/before the ovulation window ends (ovuDay + 2).
  /// ponytail: clamp is a no-op for cycleLength ≥ 14 (cycleLength-6 always
  /// beats ovuDay+3); kept as the spec's short-cycle guard.
  static int _pmsFirstDay(int cycleLength) {
    final ovuDay = cycleLength - 14;
    return math.max(cycleLength - 6, ovuDay > 0 ? ovuDay + 3 : 0);
  }

  Phase? phaseAt(DateTime date) {
    final c = _cycleAt(date);
    if (c == null) return null;
    final day = dayOfCycle(date);
    if (day == 0) return null;
    final ovuDay = c.cycleLength - 14;
    if (day <= c.periodLength) return Phase.menstrual;
    if (day >= _pmsFirstDay(c.cycleLength)) {
      return Phase.pms; // D28: last ~7 days
    }
    if (ovuDay > 0 && (day - ovuDay).abs() <= 2) return Phase.ovulation;
    if (ovuDay > 0 && day < ovuDay - 2) return Phase.follicular;
    return Phase.luteal;
  }

  DateTime? pmsStart(DateTime date) {
    final c = _cycleAt(date);
    if (c == null) return null;
    var start = addCalendarDays(c.start, _pmsFirstDay(c.cycleLength) - 1);
    while (start.isBefore(dateOnly(date))) {
      start = addCalendarDays(start, c.cycleLength);
    }
    return start;
  }

  DateTime? nextExpectedStart() {
    final d = dateOnly(today);
    for (final l in logs) {
      if (l.start.isAfter(d)) return l.start; // trust the (future) log
    }
    // Extrapolating a next start from history is a cycle prediction. Hormonal
    // bleeding is pack-driven, so no extrapolated forecast is offered; silence
    // must still resolve a date here so `missedDays` can count up (checking
    // `canPredict` would recurse through `inSilenceMode` → `missedDays`).
    if (settings.contraception == Contraception.hormonal) return null;
    final past = _pastLogs;
    if (past.isEmpty) return null;
    return addCalendarDays(past.last.start, avgCycle);
  }

  // ---------- silence mode (4.8) ----------

  /// Days since the predicted period start passed with no log. 0 = on track.
  int get missedDays {
    final next = nextExpectedStart();
    if (next == null || !next.isBefore(dateOnly(today))) return 0;
    return daysBetween(next, dateOnly(today));
  }

  bool get inSilenceMode => missedDays >= 10;

  bool get missedPeriodCard => missedDays > 0 && !inSilenceMode;

  /// The single source of truth for whether/how a cycle estimate may be shown.
  /// Hormonal contraception never yields a natural-cycle phase, period band or
  /// fertile window; unknown still estimates but is flagged for a UI caveat.
  EstimateState get estimateState {
    if (settings.contraception == Contraception.hormonal) {
      return EstimateState.hormonal;
    }
    if (logs.isEmpty) return EstimateState.noData;
    if (inSilenceMode) return EstimateState.silence;
    if (settings.contraception == Contraception.unknown) {
      return EstimateState.unknown;
    }
    return EstimateState.available;
  }

  /// Cycle-based estimates (phase, period band, fertile window) are offered for
  /// a natural logged cycle and, with a stated limitation, for unknown
  /// contraception — never for hormonal, no-data or silence.
  bool get canPredict =>
      estimateState == EstimateState.available ||
      estimateState == EstimateState.unknown;

  Phase? phaseOrNull(DateTime date) => canPredict ? phaseAt(date) : null;

  // ---------- confidence (4.3 / 4.7) ----------

  Confidence get confidence {
    if (settings.contraception == Contraception.hormonal) {
      return Confidence.low; // capped (4.7)
    }
    final gaps = cycleGaps;
    if (gaps.length < 3) {
      return Confidence.low; // a single date cannot justify medium confidence
    }
    final mean = gaps.reduce((a, b) => a + b) / gaps.length;
    final variance =
        gaps.map((g) => (g - mean) * (g - mean)).reduce((a, b) => a + b) /
        gaps.length;
    return math.sqrt(variance) <= 3 ? Confidence.high : Confidence.medium;
  }

  /// D27: confidence-scaled band width — low confidence = wider band (§3).
  /// The single source of truth for the uncertainty applied to an estimate's
  /// dates; views read this, never re-derive. It is the *uncertainty in the
  /// dates*, distinct from the fixed 6-day fertile interval (see ovulation).
  /// Hormonal contraception paints no band at all (`canPredict` is false), so
  /// the old hormonal ±1-day assumption is gone.
  int get bandDays => switch (confidence) {
    Confidence.high => 2,
    Confidence.medium => 3,
    Confidence.low => 4,
  };

  // ---------- week outlook (4.5) ----------

  static const Map<Phase, Map<OutlookAxis, Traffic>> _axisMap = {
    Phase.menstrual: {
      OutlookAxis.favor: Traffic.yellow,
      OutlookAxis.news: Traffic.yellow,
      OutlookAxis.out: Traffic.yellow,
      OutlookAxis.energy: Traffic.yellow,
    },
    Phase.follicular: {
      OutlookAxis.favor: Traffic.yellow,
      OutlookAxis.news: Traffic.yellow,
      OutlookAxis.out: Traffic.yellow,
      OutlookAxis.energy: Traffic.yellow,
    },
    Phase.ovulation: {
      OutlookAxis.favor: Traffic.yellow,
      OutlookAxis.news: Traffic.yellow,
      OutlookAxis.out: Traffic.yellow,
      OutlookAxis.energy: Traffic.yellow,
    },
    Phase.luteal: {
      OutlookAxis.favor: Traffic.yellow,
      OutlookAxis.news: Traffic.yellow,
      OutlookAxis.out: Traffic.yellow,
      OutlookAxis.energy: Traffic.yellow,
    },
    Phase.pms: {
      OutlookAxis.favor: Traffic.yellow,
      OutlookAxis.news: Traffic.yellow,
      OutlookAxis.out: Traffic.yellow,
      OutlookAxis.energy: Traffic.yellow,
    },
  };

  Traffic axisRating(Phase? phase, OutlookAxis axis) =>
      phase == null ? Traffic.yellow : axes[phase]![axis]!;

  bool isRedDay(DateTime date) => [
    OutlookAxis.favor,
    OutlookAxis.news,
    OutlookAxis.out,
  ].any((a) => axisRating(phaseOrNull(date), a) == Traffic.red);

  // ---------- briefing suppression (4.6) ----------

  /// Should tonight's briefing (about tomorrow) fire?
  bool shouldBriefTonight() {
    if (!settings.briefingEnabled || logs.isEmpty || inSilenceMode) {
      return false;
    }
    final tomorrow = addCalendarDays(today, 1);
    final pToday = phaseOrNull(today);
    final pTomorrow = phaseOrNull(tomorrow);
    if (pToday == null || pTomorrow == null) return false;

    // day before expected period start
    final next = nextExpectedStart();
    if (next != null && daysBetween(tomorrow, next) == 1) return true;
    return false;
  }

  /// Tomorrow's teaser traffic light: worst of the three social axes —
  /// `energy` (v0.3.0 #8) is in-app only, never on the lock screen (§4.6/D7).
  Traffic tomorrowTeaser() {
    final p = phaseOrNull(addCalendarDays(today, 1));
    return [OutlookAxis.favor, OutlookAxis.news, OutlookAxis.out]
        .map((a) => axisRating(p, a))
        .fold(
          Traffic.green,
          (x, y) => x.index > y.index ? x : y,
        ); // green<yellow<red by enum order
  }

  // ---------- calendar bands (4.8 / D19) ----------

  List<DateTime> get _predictedStarts {
    final out = <DateTime>[];
    for (final l in logs) {
      if (l.start.isAfter(dateOnly(today))) out.add(l.start);
    }
    final past = _pastLogs;
    if (past.isNotEmpty) {
      var s = addCalendarDays(past.last.start, avgCycle);
      for (var k = 0; k < 8; k++) {
        out.add(s);
        s = addCalendarDays(s, avgCycle);
      }
    }
    return out;
  }

  bool _inLoggedPeriod(DateTime date) {
    final d = dateOnly(date);
    return logs.any(
      (l) =>
          !l.start.isAfter(d) &&
          (l.end != null
              ? !dateOnly(l.end!).isBefore(d)
              : daysBetween(l.start, d) < avgPeriod),
    );
  }

  /// Historic regularity flag; even regular histories need an uncertainty band.
  bool get isRegular => confidence == Confidence.high;

  bool periodBandAt(DateTime date) {
    if (!canPredict || _inLoggedPeriod(date)) return false;
    final d = dateOnly(date);
    final band = bandDays;
    return _predictedStarts.any((p) {
      // A logged end resolves the period-length uncertainty: the band stops at
      // the end instead of painting "possibly still in period" past it. The
      // pre-start buffer stays (the period can still start early).
      var upper = avgPeriod + band; // exclusive offset bound from p
      for (final l in logs) {
        if (l.end != null &&
            !l.start.isAfter(addCalendarDays(p, band)) &&
            !dateOnly(l.end!).isBefore(addCalendarDays(p, -band))) {
          upper = math.min(upper, daysBetween(p, l.end!) + 1);
        }
      }
      final offset = daysBetween(p, d);
      return offset >= -band && offset < upper;
    });
  }

  /// Estimated ovulation day for a cycle anchored at `anchor` — the day 14
  /// before the next expected start. Null when the cycle is too short to place
  /// it, or when no cycle-based estimate is offered (hormonal/silence/no-data).
  DateTime? ovulationDayFor(DateTime anchor) {
    if (!canPredict) return null;
    final c = _cycleAt(anchor);
    if (c == null) return null;
    final ovuDay = c.cycleLength - 14;
    if (ovuDay <= 0) return null;
    return addCalendarDays(anchor, ovuDay - 1);
  }

  Iterable<DateTime> get _fertileAnchors =>
      [for (final l in logs) l.start, ..._predictedStarts];

  /// The fixed six-day estimated fertile interval — the days sperm survival plus
  /// ovulation can span — ending on the estimated ovulation day. This is the
  /// interval *duration*, deliberately separate from the confidence-scaled
  /// uncertainty in *when* it falls (`ovulationBandAt`).
  bool fertileIntervalAt(DateTime date) {
    if (!canPredict) return false;
    final d = dateOnly(date);
    for (final a in _fertileAnchors) {
      final ovu = ovulationDayFor(a);
      if (ovu == null) continue;
      final diff = daysBetween(ovu, d);
      if (diff <= 0 && diff >= -5) return true; // 6-day window ending at ovu
    }
    return false;
  }

  /// The six-day fertile interval widened by the ±bandDays uncertainty in its
  /// placement — the honest outer bound shown on the calendar. `fertileIntervalAt`
  /// is the solid core; the extra `bandDays` on each side is date uncertainty.
  bool ovulationBandAt(DateTime date) {
    if (!canPredict) return false;
    final d = dateOnly(date);
    final band = bandDays;
    for (final a in _fertileAnchors) {
      final ovu = ovulationDayFor(a);
      if (ovu == null) continue;
      final diff = daysBetween(ovu, d);
      if (diff <= band && diff >= -(5 + band)) return true;
    }
    return false;
  }

  // ---------- health nudge (4.8 + D29) ----------

  bool get healthNudgeEligible {
    if (settings.healthNudgeShown) return false;
    final gaps = cycleGaps;
    if (gaps.where((g) => g < 21 || g > 35).length >= 2) return true;
    // D29 (F3): in-range-but-wild variability (e.g. 22,31,22,31) is the marker
    return gaps.length >= 3 &&
        gaps.reduce(math.max) - gaps.reduce(math.min) >= 9;
  }
}
