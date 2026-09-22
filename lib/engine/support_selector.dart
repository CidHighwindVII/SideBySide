import 'models.dart';

/// A suggestion the daily selector can rank — a catalog action or a user
/// preference, reduced to what ordering depends on (never translated text).
class SelectableItem {
  final String id; // stable slug: a:* or preference:<id>
  final bool support; // "apoio intensivo" boost
  final bool preferred; // user-authored preference
  final ActionCategory category;
  const SelectableItem(
      {required this.id,
      this.support = false,
      this.preferred = false,
      this.category = ActionCategory.help});
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

  /// Builds the day's ordering of eligible ids.
  ///
  /// - [suppressed]: ids with negative feedback in the last 7 days — removed.
  /// - [recentlyCompleted]: ids completed in the last 7 days — sunk to the end
  ///   so finished actions stop leading, without dropping them entirely.
  /// - [supportPriority]: `apoio` items come first *within* the rotation.
  ///
  /// A preference is `preferred` but never pinned to slot 0: the date-seeded
  /// hash re-ranks every day, so no single item permanently occupies the top.
  static List<String> order(
    List<SelectableItem> items,
    DateTime date, {
    Set<String> suppressed = const {},
    Set<String> recentlyCompleted = const {},
    bool supportPriority = false,
  }) {
    final eligible =
        items.where((i) => !suppressed.contains(i.id)).toList();
    final seed = _daySeed(date);
    int key(SelectableItem i) => _hash(i.id, seed);
    // 1. deterministic per-day permutation
    eligible.sort((a, b) => key(a).compareTo(key(b)));
    // 2. sink recently-completed items to the tail (stable within the split)
    final fresh = eligible.where((i) => !recentlyCompleted.contains(i.id)).toList();
    final done = eligible.where((i) => recentlyCompleted.contains(i.id)).toList();
    var ranked = [...fresh, ...done];
    // 3. support re-rank as a stable partition of the (already rotated) order
    if (supportPriority) {
      ranked = [
        ...ranked.where((i) => i.support),
        ...ranked.where((i) => !i.support),
      ];
    }
    return ranked.map((i) => i.id).toList();
  }

  /// The leading id for [cursor] within [order], wrapping when the user keeps
  /// swapping. Returns null when there are no eligible candidates.
  static String? leading(List<String> order, int cursor) {
    if (order.isEmpty) return null;
    return order[cursor % order.length];
  }
}
