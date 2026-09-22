import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/catalog.dart';
import '../engine/cycle_engine.dart';
import '../engine/models.dart';
import '../engine/support_selector.dart';
import '../state/providers.dart';
import '../l10n/gen/app_localizations.dart';
import 'theme.dart';

String phaseName(AppL l, Phase p) => switch (p) {
      Phase.menstrual => l.phaseMenstrual,
      Phase.follicular => l.phaseFollicular,
      Phase.ovulation => l.phaseOvulation,
      Phase.luteal => l.phaseLuteal,
      Phase.pms => l.phasePms,
    };

String trafficLabel(AppL l, Traffic t) => switch (t) {
      Traffic.green => l.trafficGreen,
      Traffic.yellow => l.trafficYellow,
      Traffic.red => l.trafficRed,
    };

IconData trafficIcon(Traffic t) => switch (t) {
      Traffic.green => Icons.check_circle_outline,
      Traffic.yellow => Icons.warning_amber_rounded,
      Traffic.red => Icons.block,
    };

/// v0.7.0 (D25): every phase hue ships a shape too — colour never alone.
IconData phaseIcon(Phase p) => switch (p) {
      Phase.menstrual => Icons.water_drop_outlined,
      Phase.follicular => Icons.trending_up,
      Phase.ovulation => Icons.star,
      Phase.luteal => Icons.bedtime_outlined,
      Phase.pms => Icons.bolt_outlined,
    };

class ConfidenceChip extends StatelessWidget {
  final Confidence c;
  const ConfidenceChip(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    final dots = switch (c) {
      Confidence.high => '●●●',
      Confidence.medium => '●●○',
      Confidence.low => '●○○',
    };
    final label = switch (c) {
      Confidence.high => l.confHigh,
      Confidence.medium => l.confMedium,
      Confidence.low => l.confLow,
    };
    return Chip(
      avatar: Text(dots, style: const TextStyle(fontSize: 12)),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class PhaseBadge extends StatelessWidget {
  final Phase phase;
  const PhaseBadge(this.phase, {super.key});

  @override
  Widget build(BuildContext context) {
    // swatch + icon + label (D25): phase hue identifies, the icon and text
    // carry the state without colour. v0.12: tonal M3 chip, default type.
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
                color: phaseColors[phase],
                borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Icon(phaseIcon(phase), size: 16),
        const SizedBox(width: 6),
        Text(phaseName(AppL.of(context), phase),
            style: Theme.of(context).textTheme.labelLarge),
      ]),
    );
  }
}

/// A picked catalog action or explicitly user-authored preference.
class SupportActionCard extends StatelessWidget {
  final String title;
  final String action;
  final String? why;
  const SupportActionCard({
    required this.title,
    required this.action,
    this.why,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.filled(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.favorite_border,
                color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer))),
          ]),
          const SizedBox(height: 12),
          Text(action, style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer)),
          if (why != null) ...[
            const SizedBox(height: 8),
            Text(why!, style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer)),
          ],
        ]),
      ),
    );
  }
}

/// Preferences are user-authored; all published suggestions use pick before
/// display. A negative rating rotates candidates and suppresses them for 7 days.
bool actionSuppressed(AppData data, String id, DateTime today) =>
    data.actionFeedback.any((f) {
      if (f.actionId != id || f.useful) return false;
      final logged = DateTime.tryParse(f.date);
      if (logged == null) return false;
      final days = CycleEngine.daysBetween(logged, today);
      return days >= 0 && days < 7;
    });

bool _within7(String date, DateTime today) {
  final d = DateTime.tryParse(date);
  if (d == null) return false;
  final days = CycleEngine.daysBetween(d, today);
  return days >= 0 && days < 7;
}

Set<String> _suppressedIds(AppData data, DateTime today) => {
      for (final f in data.actionFeedback)
        if (!f.useful && _within7(f.date, today)) f.actionId,
    };

Set<String> _recentlyCompleted(AppData data, DateTime today) => {
      for (final c in data.completions)
        if (_within7(c.date, today)) c.actionId,
    };

/// Tag-filtered general candidates (still via `PhaseCatalog.pick`) — a high cap
/// so pick only filters cohabitation, and the selector does the day rotation.
List<CatalogItem> generalEligible(PhaseCatalog general, Settings s) =>
    PhaseCatalog.pick(general.actionable, s.liveTogether, general.actionable.length);

List<CatalogItem> generalPicks(PhaseCatalog general, AppData data, DateTime today) =>
    PhaseCatalog.pick(general.actionable
        .where((i) => !actionSuppressed(data, i.id, today)).toList(),
        data.settings.liveTogether, 3,
        supportPriority: data.settings.intensiveSupport);

typedef _ActionDisplay = ({String text, String? why});

class SupportToday extends ConsumerWidget {
  final PhaseCatalog general;
  final bool compact;
  final DateTime? day; // the date being previewed (defaults to today)
  final bool readOnly; // future previews never complete/earn/swap
  const SupportToday(
      {required this.general,
      this.compact = false,
      this.day,
      this.readOnly = false,
      super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final data = ref.watch(appDataProvider);
    final isPt = ref.watch(langCodeProvider) == 'pt';
    final today = ref.watch(todayProvider);
    final DateTime date = day ?? today;
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final eligible = generalEligible(general, data.settings);
    final items = <SelectableItem>[
      for (final p in data.preferences)
        SelectableItem(id: 'preference:${p.id}', preferred: true),
      for (final i in eligible)
        SelectableItem(id: i.id, support: i.support, category: i.category),
    ];
    final display = <String, _ActionDisplay>{
      for (final p in data.preferences)
        'preference:${p.id}': (text: p.text, why: l.agreedPreference),
      for (final i in eligible)
        i.id: (text: i.text(isPt), why: i.why(isPt)),
    };
    final order = SupportSelector.order(items, date,
        suppressed: _suppressedIds(data, date),
        recentlyCompleted: _recentlyCompleted(data, date),
        supportPriority: data.settings.intensiveSupport);
    final persisted =
        data.selections.where((s) => s.date == dateKey).firstOrNull;
    final cursor = readOnly ? 0 : (persisted?.cursor ?? 0);
    final leadingId = SupportSelector.leading(order, cursor);
    if (leadingId == null || !display.containsKey(leadingId)) {
      return Text(l.allActionsSeen);
    }
    final action = display[leadingId]!;
    final done = data.completions
        .any((c) => c.date == dateKey && c.actionId == leadingId);
    final rating = data.actionFeedback
        .where((f) => f.date == dateKey && f.actionId == leadingId)
        .firstOrNull;
    final notifier = ref.read(appDataProvider.notifier);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SupportActionCard(
          title: compact ? l.suggestionsTitle : l.tipOfDayTitle,
          action: action.text,
          why: action.why),
      if (done)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            const Icon(Icons.check_circle_outline, size: 18),
            const SizedBox(width: 6),
            Text(l.actionCompletedLabel),
          ]),
        ),
      if (!compact && !readOnly) ...[
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.tonal(
              onPressed: () => notifier.completeAction(dateKey, leadingId),
              child: Text(l.actionDone)),
          TextButton(
              onPressed: () => notifier.setSelection(dateKey, order, cursor + 1),
              child: Text(l.actionAnother)),
        ]),
        const SizedBox(height: 4),
        Wrap(spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
          Text(rating == null ? l.actionQuestion : l.actionThanks),
          TextButton(
              onPressed: () => notifier.rateAction(dateKey, leadingId, true),
              child: Text(l.actionUseful)),
          TextButton(
              onPressed: () => notifier.rateAction(dateKey, leadingId, false),
              child: Text(l.actionNotUseful)),
        ]),
      ],
    ]);
  }
}

/// Section header: icon + title (M3 `titleMedium`), no rule.
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final Widget? trailing;
  const SectionHeader(this.icon, this.title, {this.color, this.trailing, super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            ?trailing,
          ],
        ),
      );
}

/// Dash-marked list under a [SectionHeader]; renders nothing when empty.
class Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<(String, IconData?)> items;
  const Section(
      {required this.title,
      required this.icon,
      required this.items,
      super.key});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(icon, title),
        for (final (text, mark) in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mark != null)
                  Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(mark, size: 18))
                else
                  const Text('— '),
                Expanded(child: Text(text)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Catalog picks for a section — cohabitation filter + ≤3 cap + support re-rank.
({List<CatalogItem> actionable, List<CatalogItem> warnings,
      List<CatalogItem> context})
    phasePicks(PhaseCatalog pc, Settings s, {required bool support}) =>
        (
          actionable: PhaseCatalog.pick(pc.actionable, s.liveTogether, 3,
              supportPriority: support),
          warnings: PhaseCatalog.pick(pc.warnings, s.liveTogether, 3),
          context: PhaseCatalog.pick(pc.context, s.liveTogether, 2,
              supportPriority: support),
        );

/// One-off local reminders for a given calendar day: add, complete, cancel.
/// Completing a reminder earns the day's `act` moment; creating one never does.
class RemindersSection extends ConsumerWidget {
  final DateTime day;
  final bool editable;
  const RemindersSection({required this.day, this.editable = true, super.key});

  static String _key(DateTime d) =>
      DateFormat('yyyy-MM-dd').format(CycleEngine.dateOnly(d));

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l = AppL.of(context);
    final lang = ref.read(langCodeProvider);
    final controller = TextEditingController();
    var when = DateTime(day.year, day.month, day.day, 9, 0);
    final today = CycleEngine.dateOnly(DateTime.now());
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
              return AlertDialog(
                title: Text(l.reminderAdd),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: controller,
                      maxLength: 80,
                      decoration: InputDecoration(labelText: l.reminderTitleField)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_available_outlined),
                    title: Text(DateFormat('d MMM yyyy', lang).format(when)),
                    subtitle: Text(DateFormat('HH:mm', lang).format(when)),
                    onTap: () async {
                      final d = await showDatePicker(
                          context: ctx,
                          initialDate: when.isBefore(today) ? today : when,
                          firstDate: today,
                          lastDate: CycleEngine.addCalendarDays(today, 365));
                      if (d == null || !ctx.mounted) return;
                      final t = await showTimePicker(
                          context: ctx, initialTime: TimeOfDay.fromDateTime(when));
                      if (t != null) {
                        set(() => when =
                            DateTime(d.year, d.month, d.day, t.hour, t.minute));
                      }
                    },
                  ),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l.cancel)),
                  FilledButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          Navigator.pop(ctx, true);
                        }
                      },
                      child: Text(l.save)),
                ],
              );
            }));
    if (ok == true && context.mounted) {
      ref.read(appDataProvider.notifier).addReminder(controller.text, when);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final lang = ref.watch(langCodeProvider);
    final key = _key(day);
    final reminders = ref
        .watch(appDataProvider)
        .reminders
        .where((r) => _key(r.when) == key)
        .toList()
      ..sort((a, b) => a.when.compareTo(b.when));
    final notifier = ref.read(appDataProvider.notifier);
    if (reminders.isEmpty && !editable) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(Icons.alarm_outlined, l.todayReminders),
      for (final r in reminders)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(r.done
              ? Icons.check_circle_outline
              : Icons.radio_button_unchecked),
          title: Text(r.title,
              style: r.done
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null),
          subtitle: Text(DateFormat('HH:mm', lang).format(r.when)),
          trailing: editable && !r.done
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  TextButton(
                      onPressed: () => notifier.completeReminder(r.id),
                      child: Text(l.reminderComplete)),
                  IconButton(
                      tooltip: l.reminderDelete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => notifier.deleteReminder(r.id)),
                ])
              : (r.done ? Text(l.reminderDoneLabel) : null),
        ),
      if (editable)
        TextButton.icon(
            onPressed: () => _add(context, ref),
            icon: const Icon(Icons.add_alarm_outlined),
            label: Text(l.reminderAdd)),
    ]);
  }
}
