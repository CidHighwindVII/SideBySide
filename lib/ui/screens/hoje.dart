import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../engine/cycle_engine.dart';
import '../../engine/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';
import '../garden/garden_card.dart';
import '../widgets.dart';
import 'learning.dart';
import 'log_date.dart';
import 'quick_entry.dart';

class HojeScreen extends StatelessWidget {
  const HojeScreen({super.key});
  @override
  Widget build(BuildContext context) => const SafeArea(child: ForecastView(offsetDays: 0));
}

class AmanhaScreen extends StatelessWidget {
  const AmanhaScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(AppL.of(context).tomorrowCard)),
      body: const ForecastView(offsetDays: 1, compact: true));
}

class ForecastView extends ConsumerWidget {
  final int offsetDays;
  final bool compact;
  const ForecastView({required this.offsetDays, this.compact = false, super.key});

  /// Access to the contraception setting without leaving Hoje — the estimates
  /// above depend on it, so "unknown" must be resolvable in place.
  Future<void> _pickContraception(BuildContext context, WidgetRef ref) async {
    final l = AppL.of(context);
    final current = ref.read(appDataProvider).settings;
    final chosen = await showDialog<Contraception>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.contraception),
        children: [
          for (final (value, label) in [
            (Contraception.none, l.contrNone),
            (Contraception.hormonal, l.contrHormonal),
            (Contraception.unknown, l.contrUnknown),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, value),
              child: Row(children: [
                Icon(current.contraception == value
                    ? Icons.check_circle
                    : Icons.circle_outlined),
                const SizedBox(width: 12),
                Expanded(child: Text(label)),
              ]),
            ),
        ],
      ),
    );
    if (chosen != null) {
      ref.read(appDataProvider.notifier)
          .updateSettings(current.copyWith(contraception: chosen));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final data = ref.watch(appDataProvider);
    final day = CycleEngine.addCalendarDays(ref.watch(todayProvider), offsetDays);
    final eng = ref.watch(engineProvider(day));
    final catalogState = ref.watch(catalogProvider);
    final catalog = catalogState.valueOrNull;
    final lang = ref.watch(langCodeProvider);
    if (catalog == null) return Center(child: catalogState.hasError
        ? Text(l.catalogUnavailable) : const CircularProgressIndicator());
    final phase = eng.phaseOrNull(day);
    final next = eng.nextExpectedStart();
    final daysUntil = next == null ? null : CycleEngine.daysBetween(day, next);
    final isToday = offsetDays == 0;
    final near = daysUntil != null && daysUntil >= 0 && daysUntil <= 3;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 32), children: [
      // 1. date + concise cycle context
      Card.filled(child: Padding(padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(DateFormat('d MMMM', lang).format(day),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(data.logs.isEmpty ? l.noDataYet : eng.inSilenceMode || next == null
            ? l.noForecast
            : l.todayNextPeriod(DateFormat('d MMM', lang).format(next)),
            style: Theme.of(context).textTheme.titleMedium),
        if (data.logs.isNotEmpty && phase != null) ...[
          const SizedBox(height: 8),
          ConfidenceChip(eng.confidence),
          ExpansionTile(title: Text(l.calcDetailsTitle), children: [
            ListTile(subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(eng.cycleGaps.length < 3 ? l.estimateFallback(eng.avgCycle)
                  : l.estimateFromLogs(eng.cycleGaps.length, eng.bandDays)),
              const SizedBox(height: 6),
              Text(l.estimateNotCertain),
              Text(l.estimateEvidence, style: Theme.of(context).textTheme.bodySmall),
            ])),
          ]),
          ExpansionTile(title: Text(l.phaseDetailTitle), children: [
            ListTile(title: Text('${l.statusLabel}: ${phaseName(l, phase)}'),
                subtitle: Text(l.phaseDetailBody)),
          ]),
        ],
      ]))),
      // 2. honest mode banners
      if (data.settings.contraception == Contraception.unknown)
        Padding(padding: const EdgeInsets.only(top: 12),
            child: Card.outlined(child: Padding(padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.help_outline),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.unknownContrNote,
                      style: Theme.of(context).textTheme.bodyMedium)),
                ]),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: TextButton(
                    onPressed: () => _pickContraception(context, ref),
                    child: Text(l.unknownContrAction))),
              ])))),
      if (eng.healthNudgeEligible)
        Padding(padding: const EdgeInsets.only(top: 12),
            child: Card.outlined(child: ListTile(title: Text(l.healthNudge),
                trailing: TextButton(onPressed: () => ref.read(appDataProvider.notifier)
                    .updateSettings(data.settings.copyWith(healthNudgeShown: true)),
                    child: Text(l.healthNudgeOk))))),
      if (eng.missedPeriodCard && next != null)
        Padding(padding: const EdgeInsets.only(top: 12),
            child: Card.outlined(child: ListTile(title: Text(l.confirmTitle),
              subtitle: Text(l.confirmBody),
              trailing: TextButton(onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => LogDateScreen(initialDate: next))),
                  child: Text(l.confirmAction))))),
      // 3. one practical action (read-only on the tomorrow preview)
      const SizedBox(height: 12),
      SupportToday(general: catalog.general, compact: compact,
          day: day, readOnly: !isToday),
      ...(isToday
          ? _todayTail(context, ref, l, eng, day, near)
          : _tomorrowTail(context, ref, l, eng, day, near)),
    ]);
  }

  /// Hoje-only sections: quick entry, reminders, preparation, learning, tomorrow
  /// preview and variance. Returned as a list so the build literal stays simple.
  List<Widget> _todayTail(BuildContext context, WidgetRef ref, AppL l,
      CycleEngine eng, DateTime day, bool near) {
    final data = ref.watch(appDataProvider);
    return [
      const SizedBox(height: 12),
      OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => QuickEntryScreen(day: day))),
          icon: const Icon(Icons.edit_note_outlined),
          label: Text(l.todayQuickEntry)),
      const SizedBox(height: 12),
      RemindersSection(day: day),
      if (near) ...[
        const SizedBox(height: 8),
        Card.outlined(child: ListTile(leading: const Icon(Icons.checklist_outlined),
            title: Text(l.prepTitle), subtitle: Text(l.prepBody))),
      ],
      const SizedBox(height: 12),
      Card.outlined(child: ListTile(
        leading: const Icon(Icons.school_outlined),
        title: Text(l.todayLearning),
        subtitle: Text(l.learningIntro),
        trailing: Text(l.todayOpenLearning),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const LearningScreen())))),
      const SizedBox(height: 12),
      const GardenCard(),
      if (data.logs.isNotEmpty) ...[
        const SizedBox(height: 12),
        Card.outlined(child: ListTile(
          leading: const Icon(Icons.calendar_today_outlined),
          title: Text(l.tomorrowCard), subtitle: Text(l.estimateNotCertain),
          trailing: Text(l.tomorrowPreview),
          onTap: () => Navigator.of(context).pushNamed('/amanha'))),
        if (eng.cycleGaps.isNotEmpty)
          Card.outlined(child: ListTile(title: Text(l.varianceTitle),
              subtitle: Text(l.varianceAvg(eng.avgCycle)))),
      ],
    ];
  }

  /// Amanhã-only sections: read-only reminders and preparation. Never completes
  /// or earns anything for a future day.
  List<Widget> _tomorrowTail(BuildContext context, WidgetRef ref, AppL l,
      CycleEngine eng, DateTime day, bool near) {
    return [
      const SizedBox(height: 12),
      RemindersSection(day: day, editable: false),
      if (near) ...[
        const SizedBox(height: 8),
        Card.outlined(child: ListTile(leading: const Icon(Icons.checklist_outlined),
            title: Text(l.prepTitle), subtitle: Text(l.prepBody))),
      ],
    ];
  }
}
