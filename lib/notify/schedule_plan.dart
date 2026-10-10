import '../engine/cycle_engine.dart';
import '../engine/models.dart';

/// One planned local notification: a stable id, a local wall-clock time, the
/// tap payload and the channel kind. Pure data — no Flutter/plugin imports — so
/// plan construction and id allocation are testable with `dart test`.
class ScheduledNotif {
  final int id;
  final DateTime at; // local calendar date + wall time
  final String payload;
  final String kind; // 'brief' | 'headsUp' | 'reminder'
  const ScheduledNotif(this.id, this.at, this.payload, this.kind);
}

/// Builds the rolling notification plan for the next [horizonDays] days.
///
/// Briefing and heads-up are cycle-driven and only produced when there are
/// period logs (and not in silence). Personal reminders are scheduled
/// independently of any cycle history, so they work with zero logs. Ids are
/// partitioned into disjoint ranges so a reminder can never collide with a
/// briefing/heads-up id.
class NotificationPlan {
  const NotificationPlan._();

  static const int briefBase = 1000;
  static const int headsUpBase = 2000;
  static const int reminderBase = 3000;

  static int briefId(int offset) => briefBase + offset;
  static int headsUpId(int offset) => headsUpBase + offset;
  static int reminderId(int rid) => reminderBase + rid;

  static List<ScheduledNotif> build(
    AppData data,
    DateTime now, {
    Map<Phase, Map<OutlookAxis, Traffic>>? axes,
    int horizonDays = 14,
  }) {
    final s = data.settings;
    final today = CycleEngine.dateOnly(now);
    final out = <ScheduledNotif>[];

    if (data.logs.isNotEmpty) {
      for (var i = 0; i < horizonDays; i++) {
        final day = CycleEngine.addCalendarDays(today, i);
        final eng =
            CycleEngine(settings: s, logs: data.logs, today: day, axes: axes);
        if (s.briefingEnabled && eng.shouldBriefTonight()) {
          final weekend =
              s.weekendTimeEnabled && day.weekday >= DateTime.saturday;
          final at = DateTime(day.year, day.month, day.day,
              weekend ? s.weekendBriefingHour : s.briefingHour,
              weekend ? s.weekendBriefingMinute : s.briefingMinute);
          if (at.isAfter(now)) {
            out.add(ScheduledNotif(briefId(i), at, 'tomorrow', 'brief'));
          }
        }
        if (s.headsUpEnabled && !eng.inSilenceMode) {
          final next = eng.nextExpectedStart();
          if (next != null && CycleEngine.daysBetween(day, next) == 2) {
            final at = DateTime(day.year, day.month, day.day, 9, 0);
            if (at.isAfter(now)) {
              out.add(ScheduledNotif(headsUpId(i), at, 'today', 'headsUp'));
            }
          }
        }
      }
    }

    // Personal reminders — independent of period-log availability.
    for (final r in data.reminders) {
      if (r.done) continue;
      if (!r.when.isAfter(now)) continue;
      if (CycleEngine.daysBetween(today, CycleEngine.dateOnly(r.when)) >=
          horizonDays) {
        continue; // beyond the rolling window; picked up on a later refresh
      }
      out.add(ScheduledNotif(reminderId(r.id), r.when, 'reminder:${r.id}',
          'reminder'));
    }

    return out;
  }

  /// True when no two planned notifications share an id.
  static bool idsUnique(List<ScheduledNotif> plan) {
    final seen = <int>{};
    for (final p in plan) {
      if (!seen.add(p.id)) return false;
    }
    return true;
  }
}
