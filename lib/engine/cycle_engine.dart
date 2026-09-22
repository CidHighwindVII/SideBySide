import 'dart:math' as math;

import 'models.dart';

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

  Phase? phaseOrNull(DateTime date) => inSilenceMode ? null : phaseAt(date);

  // ---------- confidence (4.3 / 4.7) ----------

  Confidence get confidence {
    if (settings.contraception == Contraception.hormonal) {
      return Confidence.low; // capped (4.7)
    }
    final gaps = cycleGaps;
    if (gaps.length < 3) {
      return logs.isEmpty ? Confidence.low : Confidence.medium;
    }
    final mean = gaps.reduce((a, b) => a + b) / gaps.length;
    final variance =
        gaps.map((g) => (g - mean) * (g - mean)).reduce((a, b) => a + b) /
        gaps.length;
    return math.sqrt(variance) <= 3 ? Confidence.high : Confidence.medium;
  }

  /// D27: confidence-scaled band width — low confidence = wider band (§3).
  /// The single source of truth for band size; views read this, never re-derive.
  int get bandDays => switch (confidence) {
    Confidence.high => 2,
    Confidence.medium => 3,
    Confidence.low => 4,
  };

  // ---------- week outlook (4.5) ----------

  static const Map<Phase, Map<OutlookAxis, Traffic>> _axisMap = {
    Phase.menstrual: {
      OutlookAxis.favor: Traffic.yellow,
      OutlookAxis.news: Traffic.red,
      OutlookAxis.out: Traffic.yellow,
      OutlookAxis.energy: Traffic.red,
    },
    Phase.follicular: {
      OutlookAxis.favor: Traffic.green,
      OutlookAxis.news: Traffic.green,
      OutlookAxis.out: Traffic.green,
      OutlookAxis.energy: Traffic.green,
    },
    Phase.ovulation: {
      OutlookAxis.favor: Traffic.green,
      OutlookAxis.news: Traffic.green,
      OutlookAxis.out: Traffic.green,
      OutlookAxis.energy: Traffic.green,
    },
    Phase.luteal: {
      OutlookAxis.favor: Traffic.yellow,
      OutlookAxis.news: Traffic.yellow,
      OutlookAxis.out: Traffic.green,
      OutlookAxis.energy: Traffic.yellow,
    },
    Phase.pms: {
      OutlookAxis.favor: Traffic.red,
      OutlookAxis.news: Traffic.red,
      OutlookAxis.out: Traffic.yellow,
      OutlookAxis.energy: Traffic.red,
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
    // first day of PMS window
    final pms = pmsStart(today);
    if (pms != null && daysBetween(pms, tomorrow) == 0) return true;
    // phase change between today and tomorrow
    if (pToday != pTomorrow) return true;
    // day after a red day
    if (isRedDay(today)) return true;
    // red-flag day (bad-news warning), even in "quiet" phases
    if (axisRating(pTomorrow, OutlookAxis.news) == Traffic.red) return true;
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

  /// Regular cycle (D27 owner call): high confidence → definite predicted
  /// ranges with no ± buffer. Labels still say "previsto" — §3 soft wording.
  bool get isRegular => confidence == Confidence.high;

  bool periodBandAt(DateTime date) {
    if (inSilenceMode || _inLoggedPeriod(date)) return false;
    final d = dateOnly(date);
    if (isRegular) {
      // solid block: predicted start .. start + avgPeriod - 1
      // (dateOnly: predicted starts can carry a time component)
      return _predictedStarts.any((p) {
        final s = dateOnly(p);
        return !d.isBefore(s) && daysBetween(s, d) < avgPeriod;
      });
    }
    final band = bandDays; // D27
    return _predictedStarts.any((s) => daysBetween(s, d).abs() <= band);
  }

  bool ovulationBandAt(DateTime date) {
    if (inSilenceMode) return false;
    final d = dateOnly(date);
    final anchors = [for (final l in logs) l.start, ..._predictedStarts];
    for (final a in anchors) {
      final c = _cycleAt(a);
      if (c == null) continue;
      final ovuDay = c.cycleLength - 14;
      if (ovuDay <= 0) continue;
      final ovu = addCalendarDays(a, ovuDay - 1);
      if (isRegular) {
        // fixed 6-day window ending on ovulation day
        final diff = daysBetween(ovu, d);
        if (diff <= 0 && diff >= -5) return true;
      } else if (daysBetween(ovu, d).abs() <= bandDays) {
        return true;
      }
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
