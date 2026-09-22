import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../engine/cycle_engine.dart';
import '../../engine/models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets.dart';
import '../../l10n/gen/app_localizations.dart';

class CalendarioScreen extends ConsumerStatefulWidget {
  const CalendarioScreen({super.key});

  @override
  ConsumerState<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends ConsumerState<CalendarioScreen> {
  DateTime _month = CycleEngine.dateOnly(DateTime.now());

  // Swipe = month pager over absolute month indices (year*12 + month-1).
  int _abs(DateTime m) => m.year * 12 + m.month - 1;
  DateTime _monthOf(int p) => DateTime(p ~/ 12, p % 12 + 1);
  late final PageController _pager = PageController(initialPage: _abs(_month));

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _step(int dir) => _pager.animateToPage(_abs(_month) + dir,
      duration: const Duration(milliseconds: 250), curve: Curves.easeOut);

  /// v0.3.0 (#4): quick log of what he observed that day — his notes,
  /// never clinical data (§3); phase is derived at read, never stored.
  void _logObservation(DateTime day) {
    final l = AppL.of(context);
    final lang = ref.read(langCodeProvider);
    final key = DateFormat('yyyy-MM-dd').format(day);
    final existing =
        AppData.observationFor(ref.read(appDataProvider).observations, key);
    final selected = <String>{...?existing?.tags};
    final tags = <(String, String)>[
      (l.obsCalm, 'calma'),
      (l.obsTired, 'cansada'),
      (l.obsSensitive, 'sensivel'),
      (l.obsGoodMood, 'bom-humor'),
      (l.obsIrritable, 'irritada'),
      (l.obsCramps, 'colicas'),
      (l.obsHeadache, 'dor-cabeca'),
      (l.obsBloating, 'incharo'),
      (l.obsCravings, 'desejos'),
      (l.obsSleepless, 'dormiu-mal'),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEEE, d MMMM', lang).format(day),
                    style: Theme.of(context).textTheme.titleMedium),
                Text(l.obsBody, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (label, id) in tags)
                      FilterChip(
                        label: Text(label),
                        selected: selected.contains(id),
                        onSelected: (v) => setState(
                            () => v ? selected.add(id) : selected.remove(id)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l.cancel)),
                    FilledButton(
                      onPressed: () {
                        ref
                            .read(appDataProvider.notifier)
                            .saveObservation(key, selected.toList());
                        Navigator.pop(ctx);
                      },
                      child: Text(l.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tap a day: mark/unmark period start, or set/edit the end of the latest period.
  void _tapDay(DateTime day) {
    final l = AppL.of(context);
    final logs = ref.read(appDataProvider).logs;
    final startLog = logs.where((x) => x.start == day).firstOrNull;
    final endLog = logs.where((x) => x.end == day).firstOrNull;
    final past = logs.where((x) => !x.start.isAfter(day)).toList();
    // Product floor: starts must be at least 21 calendar days apart (abs() also
    // catches retro-marking between two existing starts).
    final tooSoon = startLog == null &&
        logs.any((x) => CycleEngine.cycleTooShort(x.start, day));
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                  DateFormat('EEEE, d MMMM', ref.read(langCodeProvider))
                      .format(day),
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            if (startLog != null)
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: Text(l.calUnmarkStart),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(appDataProvider.notifier).deleteLog(startLog);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(l.calMarkStart),
                onTap: () {
                  Navigator.pop(ctx);
                  if (tooSoon) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.periodTooSoon)));
                    return;
                  }
                  ref.read(appDataProvider.notifier).saveLog(PeriodLog(day, null));
                },
              ),
            if (endLog != null)
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: Text(l.calUnmarkEnd),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(appDataProvider.notifier)
                      .saveLog(PeriodLog(endLog.start, null));
                },
              )
            else if (past.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.stop_circle_outlined),
                title: Text(l.calMarkEnd),
                onTap: () {
                  final log = past.last;
                  final end = day.isBefore(log.start) ? log.start : day;
                  // v0.6.0 (#2): a period spans at least 3 days (D21)
                  if (CycleEngine.periodTooShort(log.start, end)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.periodTooShort)));
                    return;
                  }
                  Navigator.pop(ctx);
                  ref
                      .read(appDataProvider.notifier)
                      .saveLog(log.copyWith(end: end));
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit_note_outlined),
              title: Text(l.obsTitle),
              onTap: () {
                Navigator.pop(ctx);
                _logObservation(day);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    final lang = ref.watch(langCodeProvider);
    final eng = ref.watch(engineProvider(_month));
    final today = CycleEngine.dateOnly(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      tooltip: DateFormat('MMMM yyyy', lang)
                          .format(DateTime(_month.year, _month.month - 1)),
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _step(-1)),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy', lang).format(_month).toUpperCase(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                      tooltip: DateFormat('MMMM yyyy', lang)
                          .format(DateTime(_month.year, _month.month + 1)),
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _step(1)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  for (var w = 0; w < 7; w++)
                    Expanded(
                      child: Center(
                          child: Text(
                              DateFormat.E(lang).format(DateTime(2024, 1, 7 + w)),
                              style: Theme.of(context).textTheme.bodySmall)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pager,
                onPageChanged: (p) => setState(() => _month = _monthOf(p)),
                itemBuilder: (context, p) =>
                    _MonthGrid(month: _monthOf(p), today: today, onTap: _tapDay),
              ),
            ),
            _patternCard(context, l, eng, ref.watch(appDataProvider).observations),
            _legend(context, l, eng),
          ],
        ),
      ),
    );
  }

  Widget _legend(BuildContext context, AppL l, CycleEngine eng) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            // D25: swatch + icon + label — the icon mirrors the cell mark,
            // so each key reads without colour.
            _key(phaseColors[Phase.menstrual]!, Icons.check, l.calendarLogged),
            _key(
                phaseColors[Phase.menstrual]!.withValues(alpha: 0.2),
                Icons.horizontal_rule,
                eng.isRegular
                    ? l.calendarExpectedPeriod
                    : l.calendarBandPeriod(eng.bandDays)),
            _key(
                phaseColors[Phase.ovulation]!,
                Icons.crop_square,
                eng.isRegular
                    ? l.calendarExpectedFertile
                    : l.calendarBandOvulation(eng.bandDays)),
            _key(null, Icons.event_available, l.calendarFuture),
          ],
        ),
      );

  Widget _key(Color? color, IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant))),
          const SizedBox(width: 4),
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 4),
          // long PT labels wrap instead of overflowing the 412dp grid
          Flexible(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        ],
      );

  /// D30: read-only pattern card — his own logged notes bucketed by the
  /// engine-derived phase over the last ≤6 cycles. Reads existing data only:
  /// no write path, no new keys, no clinical claims. Icon + label, never
  /// colour-only (D25). Empty-safe: renders nothing without observations.
  Widget _patternCard(
      BuildContext context, AppL l, CycleEngine eng, List<Observation> obs) {
    if (obs.isEmpty || eng.logs.isEmpty) return const SizedBox.shrink();
    final cutoff = CycleEngine.addCalendarDays(DateTime.now(), -6 * eng.avgCycle);
    final counts = <Phase, int>{};
    for (final o in obs) {
      final day = DateTime.tryParse(o.date);
      if (day == null || day.isBefore(cutoff)) continue;
      final p = eng.phaseOrNull(day); // silence mode → null → skipped
      if (p != null) counts[p] = (counts[p] ?? 0) + 1;
    }
    if (counts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.insights_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(l.patternTitle,
                          style: Theme.of(context).textTheme.titleMedium)),
                ],
              ),
              const SizedBox(height: 6),
              for (final p in Phase.values)
                if (counts[p] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(phaseIcon(p), size: 16, color: phaseColors[p]),
                        const SizedBox(width: 6),
                        Expanded(child: Text(phaseName(l, p))),
                        Text('${counts[p]}'),
                      ],
                    ),
                  ),
              const SizedBox(height: 4),
              Text(l.patternCaption,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// One page of the month pager — its own engine anchored at the month start.
class _MonthGrid extends ConsumerWidget {
  final DateTime month;
  final DateTime today;
  final ValueChanged<DateTime> onTap;
  const _MonthGrid(
      {required this.month, required this.today, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final eng = ref.watch(engineProvider(month));
    final obsDates = {
      for (final o in ref.watch(appDataProvider).observations) o.date
    };
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday % 7; // Sunday-first grid
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return GridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 7,
      childAspectRatio: 1 / scale.clamp(1.0, 2.5),
      children: [
        for (var i = 0; i < leading; i++) const SizedBox.shrink(),
        for (var d = 1; d <= daysInMonth; d++)
          _DayCell(
            eng: eng,
            day: DateTime(month.year, month.month, d),
            today: today,
            l: l,
            observed: obsDates.contains(DateFormat('yyyy-MM-dd')
                .format(DateTime(month.year, month.month, d))),
            onTap: onTap,
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final CycleEngine eng;
  final DateTime day;
  final DateTime today;
  final AppL l;
  final bool observed;
  final ValueChanged<DateTime> onTap;
  const _DayCell(
      {required this.eng,
      required this.day,
      required this.today,
      required this.l,
      this.observed = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final phase = eng.phaseOrNull(day);
    final logged = eng.logs.any((x) =>
        !x.start.isAfter(day) &&
        (x.end != null
            ? !x.end!.isBefore(day)
            : CycleEngine.daysBetween(x.start, day) < eng.avgPeriod));
    final futureLog = eng.logs.any((x) => x.start == day);
    final band = eng.periodBandAt(day);
    final ovu = eng.ovulationBandAt(day);
    final isToday = day == today;

    // v0.10: de-clutter — background wash ONLY for logged period (solid) and
    // expected period (faint). Fertile window stays the dot marker; the old
    // follicular/luteal/PMS/ovulation phase tints are gone.
    final color = logged
        ? phaseColors[Phase.menstrual]!.withValues(alpha: 0.55)
        : band
            ? phaseColors[Phase.menstrual]!.withValues(alpha: 0.18)
            : null;

    final label = [
      DateFormat('EEEE, d MMMM yyyy', Localizations.localeOf(context).languageCode)
          .format(day),
      if (isToday) l.calendarToday,
      if (phase != null) phaseName(l, phase),
      if (logged) l.calendarLogged,
      if (futureLog) l.calendarFuture,
      if (band && !logged)
        eng.isRegular
            ? l.calendarExpectedPeriod
            : l.calendarBandPeriod(eng.bandDays),
      if (ovu)
        eng.isRegular
            ? l.calendarExpectedFertile
            : l.calendarBandOvulation(eng.bandDays),
      if (observed) l.obsLegend,
    ].join(' · ');
    return Semantics(
      button: true,
      label: label,
      onTap: () => onTap(day),
      child: ExcludeSemantics(
        child: Tooltip(
          message: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onTap(day),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday
                      ? Theme.of(context).colorScheme.primaryContainer
                      : color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : futureLog
                            ? phaseColors[Phase.menstrual]!
                            : Theme.of(context).colorScheme.outlineVariant,
                    width: isToday ? 2 : futureLog ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${day.day}'),
                    Wrap(alignment: WrapAlignment.center, children: [
                      if (logged)
                        const Icon(Icons.check, size: 12)
                      else if (futureLog)
                        const Icon(Icons.event_available, size: 12),
                      if (band && !logged)
                        Container(
                            width: 12,
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            color: phaseColors[Phase.menstrual]),
                      if (ovu)
                        Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            color: phaseColors[Phase.ovulation]),
                      if (observed)
                        const Icon(Icons.edit_note, size: 12),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
