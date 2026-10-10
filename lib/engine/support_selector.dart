import 'models.dart';

/// A suggestion the daily selector can rank — a catalog action or a user
/// preference, reduced to what ordering depends on (never translated text).
class SelectableItem {
  final String id; // stable slug: a:* or preference:<id>
  final bool support; // "apoio intensivo" boost
  final bool preferred; // user-authored preference
  final ActionCategory category;
  final int relevance; // current observation=1, history=2, stage=3, general=4
  const SelectableItem(
      {required this.id,
      this.support = false,
      this.preferred = false,
      this.category = ActionCategory.help,
      this.relevance = 4});
}

/// Deterministic, date-aware daily action selection (implementation.md P4).
///
/// Pure Dart — no Flutter, no clock reads (the caller injects the local date),
/// so it is stable across rebuilds and app restarts and testable with
/// `dart test`. The same inputs + date always yield the same order.
class SupportSelector {
  const SupportSelector._();

  /// Calendar-day seed so the leading pick rotates each day but is fixed within
  /// a day. Uses year/month/day (not elapsed time) to stay DST-safe.
  static int _daySeed(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  static int _hash(String s, int seed) {
    // FNV-1a over the id (64-bit), then a splitmix64 finalizer applied to
    // (hash ^ seed). The finalizer avalanches every input bit through the whole
    // word, so a one-day seed change fully reorders same-length ids too. The
    // mask keeps the key non-negative for a stable `compareTo`.
    var h = 0xcbf29ce484222325;
    for (final c in s.codeUnits) {
      h = (h ^ c) * 0x100000001b3;
    }
    h = h ^ seed;
    h = (h ^ (h >> 30)) * 0xbf58476d1ce4e5b9;
    h = (h ^ (h >> 27)) * 0x94d049bb133111eb;
    h = h ^ (h >> 31);
    return h & 0x7fffffffffffffff;
  }

  /// The public day-ranked key for [id] — the same primitive the action
  /// rotation uses, so every date-seeded selection is deterministic and
  /// stable across rebuilds and restarts.
  static int dayRank(String id, DateTime date) => _hash(id, _daySeed(date));

  /// Builds the day's ordering of eligible ids.
  ///
  /// - [suppressed]: ids with negative feedback in the last 7 days — removed.
  /// - [recentlyCompleted]: ids completed in the last 7 days — sunk to the end
  ///   so finished actions stop leading, without dropping them entirely.
  /// - [boost]: ids with prior *positive* action feedback — raised to the
  ///   front as "previously helpful" claims. Feedback is the only evidence an
  ///   action worked; feeling history never boosts here.
  /// - [supportPriority]: `apoio` items come first *within* the rotation.
  ///
  /// Preferences lead within fresh/done partitions. Date-seeded rotation and
  /// feedback break ties within relevance tiers, never override explicit needs.
  static List<String> order(
    List<SelectableItem> items,
    DateTime date, {
    Set<String> suppressed = const {},
    Set<String> recentlyCompleted = const {},
    Set<String> boost = const {},
    bool supportPriority = false,
  }) {
    final seen = <String>{};
    final eligible = items.where((i) => i.id.isNotEmpty &&
        !suppressed.contains(i.id) && seen.add(i.id)).toList();
    final seed = _daySeed(date);
    int key(SelectableItem i) => _hash(i.id, seed);
    eligible.sort((a, b) {
      final done = (recentlyCompleted.contains(a.id) ? 1 : 0)
          .compareTo(recentlyCompleted.contains(b.id) ? 1 : 0);
      if (done != 0) return done;
      final tier = (a.preferred ? 0 : a.relevance)
          .compareTo(b.preferred ? 0 : b.relevance);
      if (tier != 0) return tier;
      final feedback = (boost.contains(a.id) ? 0 : 1)
          .compareTo(boost.contains(b.id) ? 0 : 1);
      if (feedback != 0) return feedback;
      if (supportPriority && a.support != b.support) return a.support ? -1 : 1;
      final rank = key(a).compareTo(key(b));
      return rank != 0 ? rank : a.id.compareTo(b.id);
    });
    return eligible.map((i) => i.id).toList();
  }

  /// The leading id for [cursor] within [order], wrapping when the user keeps
  /// swapping. Returns null when there are no eligible candidates.
  static String? leading(List<String> order, int cursor) {
    if (order.isEmpty) return null;
    return order[cursor % order.length];
  }
}
