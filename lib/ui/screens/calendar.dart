import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../engine/cycle_engine.dart';
import '../../engine/models.dart';
import '../../state/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../theme.dart';
import 'feelings.dart';
import 'history.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  const CalendarScreen({this.initialDate, super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month;

  // Swipe = month pager over absolute month indices (year*12 + month-1).
  int _abs(DateTime m) => m.year * 12 + m.month - 1;
  DateTime _monthOf(int p) => DateTime(p ~/ 12, p % 12 + 1);
  late final PageController _pager;

  @override
  void initState() {
    super.initState();
    _month = widget.initialDate ?? ref.read(todayProvider);
    _pager = PageController(initialPage: _abs(_month));
    if (widget.initialDate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tapDay(widget.initialDate!);
      });
    }
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _step(int dir) => _pager.animateToPage(_abs(_month) + dir,
      duration: const Duration(milliseconds: 250), curve: Curves.easeOut);

  /// Tap a day: mark/unmark period start, or set/edit the end of the latest period.
  void _tapDay(DateTime day) {
    final l = AppL.of(context);
    final data = ref.read(appDataProvider);
    final logs = data.logs;
    final startLog = logs.where((x) => x.start == day).firstOrNull;
    final endLog = logs.where((x) => x.end == day).firstOrNull;
    final past = logs.where((x) => !x.start.isAfter(day)).toList();
    // Product rule: starts must be at least 21 calendar days apart. Checking
    // every existing start in both directions stops retroactive marking; the
    // action stays visible-but-disabled with an inline reason, so the known
    // invalid tap never reaches the rejection path.
    final tooSoon = startLog == null &&
        !CycleEngine.startSpacingOk(logs, day);
    final eng = ref.read(engineProvider(day));
    final dateKey = CycleEngine.dayKey(day);
    final feelings = AppData.feelingLogFor(data.feelingLogs, dateKey);
    final isOvuDay = eng.ovulationDayAt(day);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
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
              if (isOvuDay)
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: Text(l.calendarOvulationDay),
                  subtitle: Text(l.calendarOvulationDetailsBody(eng.bandDays)),
                  trailing: IconButton(
                      tooltip: l.calendarOvulationDetailsTitle,
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => _showOvulationDetails(day)),
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
                  enabled: !tooSoon,
                  leading: Icon(tooSoon
                      ? Icons.block_outlined
                      : Icons.play_circle_outline),
                  title: Text(l.calMarkStart),
                  subtitle: tooSoon ? Text(l.startTooCloseReason) : null,
                  onTap: tooSoon
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          ref.read(appDataProvider.notifier)
                              .saveLog(PeriodLog(day, null));
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
                leading: const Icon(Icons.emoji_emotions_outlined),
                title: Text(l.calFeelings),
                subtitle: Text(feelings == null || feelings.entries.isEmpty
                    ? l.feelingSuggestedGeneral
                    : feelings.entries
                        .map((e) => _feelingName(context, e.concept))
                        .join(' · ')),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FeelingsScreen(day: day)));
                },
              ),
              ..._dayDetails(context, l, day),
            ],
          ),
        ),
      ),
    );
  }

  String _feelingName(BuildContext context, String concept) {
    final catalog = ref.read(feelingCatalogProvider).valueOrNull;
    final c = catalog?.byId(concept);
    if (c != null) return c.label(ref.read(langCodeProvider) == 'pt');
    final custom = ref
        .read(appDataProvider)
        .customFeelings
        .where((x) => x.concept == concept)
        .firstOrNull;
    return custom?.label ?? concept;
  }

  /// Concise explanation of the ovulation estimate and its uncertainty —
  /// reuses the provider-backed engine estimate, never a second calculation.
  void _showOvulationDetails(DateTime day) {
    final l = AppL.of(context);
    final eng = ref.read(engineProvider(day));
    final lang = ref.read(langCodeProvider);
    final ovu = eng.ovulationDayAt(day) ? day : eng.nextOvulationDay();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.calendarOvulationDetailsTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ovu != null)
              Text(l.calendarOvulationEstimatedOn(
                  DateFormat('d MMM yyyy', lang).format(ovu))),
            Text(l.calendarOvulationDetailsBody(eng.bandDays)),
            const SizedBox(height: 6),
            Text(l.calendarExpectedFertile,
                style: Theme.of(ctx).textTheme.bodySmall),
            Text(l.calendarFertileUncertainty(eng.bandDays),
                style: Theme.of(ctx).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        ],
      ),
    );
  }

  /// Read-only day details: quick entries and reminders logged for this date.
  List<Widget> _dayDetails(BuildContext context, AppL l, DateTime day) {
    final lang = ref.read(langCodeProvider);
    final key = CycleEngine.dayKey(day);
    final data = ref.read(appDataProvider);
    final entries = data.entries.where((e) => e.date == key).toList();
    final reminders =
        data.reminders.where((r) => _dateKey(r.when) == key).toList();
    if (entries.isEmpty && reminders.isEmpty) return const [];
    return [
      const Divider(height: 24),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Text(l.entriesTitle,
            style: Theme.of(context).textTheme.labelLarge),
      ),
      for (final e in entries)
        ListTile(
          dense: true,
          leading: Icon(e.kind == EntryKind.reflection
              ? Icons.self_improvement
              : Icons.groups_outlined),
          title: Text(e.text),
          subtitle: Text(e.kind == EntryKind.reflection
              ? l.entryReflectionKind
              : l.entrySharedKind),
        ),
      for (final r in reminders)
        ListTile(
          dense: true,
          leading: Icon(
              r.done ? Icons.check_circle_outline : Icons.alarm_outlined),
          title: Text(r.title),
          subtitle: Text(DateFormat('HH:mm', lang).format(r.when)),
        ),
    ];
  }

  static String _dateKey(DateTime d) => CycleEngine.dayKey(d);

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    final lang = ref.watch(langCodeProvider);
    final eng = ref.watch(engineProvider(_month));

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
                  IconButton(
                    tooltip: l.historyTitle,
                    icon: const Icon(Icons.history),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const HistoryScreen())),
                  ),
                ],
              ),
            ),
            _estimateSummary(context, l, lang),
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
                    _MonthGrid(month: _monthOf(p), onTap: _tapDay),
              ),
            ),
            // The legend stays in a bounded, scrollable band so long PT labels
            // at large text scales can never squeeze the grid off-screen on
            // small phones (360×640-class).
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 88),
              child: SingleChildScrollView(
                child: _legend(context, l, eng),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact summary row: next-period countdown plus the estimated ovulation
  /// day, both from the shared engine. Unavailable states say so explicitly.
  Widget _estimateSummary(BuildContext context, AppL l, String lang) {
    final today = ref.watch(todayProvider);
    final eng = ref.watch(engineProvider(today));
    final next = eng.nextExpectedStart();
    final daysUntil = next == null ? null : CycleEngine.daysBetween(today, next);
    final ovu = eng.nextOvulationDay();
    final String text;
    if (!eng.canPredict || (daysUntil != null && daysUntil < 0)) {
      text = eng.inSilenceMode ? l.noForecast
          : daysUntil != null && daysUntil < 0 ? l.confirmTitle : l.calendarOvulationNone;
    } else {
      final parts = <String>[
        if (daysUntil != null && daysUntil >= 0)
          '${l.todayNextPeriodLabel} · ${l.todayDaysUntil(daysUntil)}',
        if (ovu != null)
          '${l.calendarOvulationSummary} · ${DateFormat('d MMM', lang).format(ovu)}',
      ];
      text = parts.join('   ·   ');
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: eng.canPredict && ovu != null
            ? () => _showOvulationDetails(ovu)
            : null,
        child: Row(
          children: [
            Expanded(
              child: Text(text,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            Icon(Icons.info_outline,
                size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _legend(BuildContext context, AppL l, CycleEngine eng) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                // D25: swatch + icon + label — the icon mirrors the cell mark,
                // so each key reads without colour.
                _key(phaseColors[Phase.menstrual]!, Icons.check, l.calendarLogged),
                if (eng.canPredict) ...[
                  _key(
                      phaseColors[Phase.menstrual]!.withValues(alpha: 0.2),
                      Icons.horizontal_rule,
                      l.calendarBandPeriod(eng.bandDays)),
                  _key(null, Icons.star_outline, l.calendarOvulationDay),
                  _key(phaseColors[Phase.ovulation]!.withValues(alpha: 0.30),
                      Icons.circle, l.calendarExpectedFertile),
                  _key(phaseColors[Phase.ovulation]!.withValues(alpha: 0.12),
                      Icons.circle_outlined, l.calendarFertileUncertainty(eng.bandDays)),
                ],
                _key(null, Icons.event_available, l.calendarFuture),
                _key(null, Icons.emoji_emotions_outlined, l.feelingLoggedLegend),
              ],
            ),
            if (!eng.canPredict)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(l.calendarNoBand,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
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

}

/// One page of the month pager — its own engine anchored at the month start.
class _MonthGrid extends ConsumerWidget {
  final DateTime month;
  final ValueChanged<DateTime> onTap;
  const _MonthGrid({required this.month, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final eng = ref.watch(engineProvider(month));
    final today = ref.watch(todayProvider);
    final feelingDates = {
      for (final f in ref.watch(appDataProvider).feelingLogs) f.date
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
            hasFeelings: feelingDates.contains(
                CycleEngine.dayKey(DateTime(month.year, month.month, d))),
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
  final bool hasFeelings;
  final ValueChanged<DateTime> onTap;
  const _DayCell(
      {required this.eng,
      required this.day,
      required this.today,
      required this.l,
      this.hasFeelings = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final logged = eng.logs.any((x) =>
        !x.start.isAfter(day) &&
        (x.end != null
            ? !x.end!.isBefore(day)
            : CycleEngine.daysBetween(x.start, day) < eng.avgPeriod));
    final futureLog = eng.logs.any((x) => x.start == day);
    final band = eng.periodBandAt(day);
    final ovuCore = !logged && !band && eng.fertileIntervalAt(day);
    final ovuUnc = !logged && !band && !ovuCore && eng.ovulationBandAt(day);
    final isOvulationDay = eng.ovulationDayAt(day);
    final isToday = day == today;

    // v0.14: fertile window paints a background wash (core = solid-ish
    // ovulation tint, uncertainty = fainter). The estimated ovulation day
    // carries its own star marker on top — a distinct non-colour indicator.
    // Logged period stays the strongest tint; expected-period band wins over
    // fertile overlap.
    final color = logged
        ? phaseColors[Phase.menstrual]!.withValues(alpha: 0.55)
        : band
            ? phaseColors[Phase.menstrual]!.withValues(alpha: 0.18)
            : ovuCore
                ? phaseColors[Phase.ovulation]!.withValues(alpha: 0.30)
                : ovuUnc
                    ? phaseColors[Phase.ovulation]!.withValues(alpha: 0.12)
                    : null;

    final label = [
      DateFormat('EEEE, d MMMM yyyy', Localizations.localeOf(context).languageCode)
          .format(day),
      if (isToday) l.calendarToday,
      if (logged) l.calendarLogged,
      if (futureLog) l.calendarFuture,
      if (band && !logged) l.calendarBandPeriod(eng.bandDays),
      if (ovuCore) l.calendarExpectedFertile,
      if (ovuUnc) l.calendarFertileUncertainty(eng.bandDays),
      if (isOvulationDay) l.calendarOvulationDay,
      if (hasFeelings) l.feelingLoggedLegend,
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
                        : isOvulationDay
                            ? phaseColors[Phase.ovulation]!
                            : futureLog
                                ? phaseColors[Phase.menstrual]!
                                : Theme.of(context).colorScheme.outlineVariant,
                    width: (isToday || futureLog || isOvulationDay) ? 2 : 1,
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
                      if (isOvulationDay && !logged && !futureLog)
                        const Icon(Icons.star_outline, size: 12),
                      if (band && !logged)
                        Container(
                            width: 12,
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            color: phaseColors[Phase.menstrual]),
                      if (hasFeelings)
                        const Icon(Icons.emoji_emotions_outlined, size: 12),
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
