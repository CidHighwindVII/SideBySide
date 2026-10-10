import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/feeling_catalog.dart';
import '../../engine/cycle_engine.dart';
import '../../engine/feeling_selector.dart';
import '../../engine/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';
import '../widgets.dart';
import 'learning.dart';
import 'log_date.dart';
import 'quick_entry.dart';
import 'support.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const SafeArea(child: ForecastView(offsetDays: 0));
}

class TomorrowScreen extends StatelessWidget {
  const TomorrowScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(AppL.of(context).tomorrowCard)),
      body: const ForecastView(offsetDays: 1, compact: true));
}

class ForecastView extends ConsumerWidget {
  final int offsetDays;
  final bool compact;
  const ForecastView({required this.offsetDays, this.compact = false, super.key});

  /// Access to the contraception setting without leaving Today — the estimates
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

  /// Calculation, confidence and phase detail stay behind this disclosure —
  /// the default briefing never shows paragraphs.
  Future<void> _showDetails(BuildContext context, WidgetRef ref,
      CycleEngine eng, DateTime day, AppL l) async {
    final data = ref.read(appDataProvider);
    final phase = eng.phaseOrNull(day);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(l.calcDetailsTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (data.logs.isNotEmpty) ConfidenceChip(eng.confidence),
            const SizedBox(height: 12),
            Text(eng.cycleGaps.length < 3
                ? l.estimateFallback(eng.avgCycle)
                : l.estimateFromLogs(eng.cycleGaps.length, eng.bandDays)),
            const SizedBox(height: 6),
            Text(l.estimateNotCertain),
            Text(l.estimateEvidence,
                style: Theme.of(context).textTheme.bodySmall),
            if (data.settings.contraception == Contraception.unknown) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: Text(l.unknownContrNote,
                        style: Theme.of(context).textTheme.bodyMedium)),
                TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pickContraception(context, ref);
                    },
                    child: Text(l.unknownContrAction)),
              ]),
            ],
            const Divider(height: 32),
            Text(l.phaseDetailTitle,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(phase == null
                ? l.stageUnknownNote
                : '${l.statusLabel}: ${phaseName(l, phase)}'),
            Text(l.phaseDetailBody,
                style: Theme.of(context).textTheme.bodySmall),
            const Divider(height: 32),
            if (eng.cycleGaps.isNotEmpty) ...[
              Text(l.varianceTitle,
                  style: Theme.of(context).textTheme.titleSmall),
              Text(l.varianceAvg(eng.avgCycle),
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(l.todayLearning),
              subtitle: Text(l.learningIntro),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const LearningPage()));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _explainFeeling(BuildContext context, WidgetRef ref, AppL l,
      FeelingConcept? concept, CustomFeeling? custom, HistoricalPick? hist,
      DateTime day) {
    final lang = ref.read(langCodeProvider);
    final title = concept?.label(ref.read(langCodeProvider) == 'pt') ??
        custom?.label ??
        l.sheMayNotice;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hist != null
                ? (hist.cycles >= FeelingSelector.recurrenceCycles
                    ? l.feelingExplainHistory(hist.cycles)
                    : l.feelingExplainPrevious)
                : concept != null && concept.stages.isEmpty
                    ? l.feelingExplainEveryday : l.feelingExplainGeneral),
            if (hist != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    l.feelingLastLogged(
                        DateFormat('d MMM yyyy', lang).format(hist.lastLogged)),
                    style: Theme.of(ctx).textTheme.bodySmall),
              ),
            if (hist == null && concept != null)
              for (final id in concept.evidence)
                if (ref.read(feelingCatalogProvider).valueOrNull?.sources[id] case final source?) ...[
                  const SizedBox(height: 12),
                  Text(source.title.text(lang == 'pt'),
                      style: Theme.of(ctx).textTheme.titleSmall),
                  Text(source.limits.text(lang == 'pt')),
                  if (source.url.isNotEmpty)
                    SourceLink(label: source.title.text(lang == 'pt'), url: source.url),
                ],
          ],
        )),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Historical items link to a contributing record's date;
                // general possibilities open the day being explained.
                Navigator.of(context).pushNamed('/log-feelings',
                    arguments: hist?.lastLogged ?? day);
              },
              child: Text(l.feelingOpenCalendar)),
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final data = ref.watch(appDataProvider);
    final day = CycleEngine.addCalendarDays(ref.watch(todayProvider), offsetDays);
    final eng = ref.watch(engineProvider(day));
    final catalogState = ref.watch(catalogProvider);
    final catalog = catalogState.valueOrNull;
    final feelingsState = ref.watch(feelingCatalogProvider);
    final feelingCatalog = feelingsState.valueOrNull;
    final lang = ref.watch(langCodeProvider);
    final isToday = offsetDays == 0;
    final phase = eng.phaseOrNull(day);
    final stage = historyStageOf(phase);
    final next = eng.nextExpectedStart();
    final daysUntil = next == null ? null : CycleEngine.daysBetween(day, next);
    final briefing = eng.canPredict && feelingCatalog != null
        ? ref.watch(feelingBriefingProvider(day))
        : null;
    final dateKey = CycleEngine.dayKey(day);
    final logged = AppData.feelingLogFor(data.feelingLogs, dateKey);
    final cues = feelingCatalog?.cuesFor(stage) ?? const [];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 32), children: [
      if (catalogState.hasError)
        Text(l.catalogLoadFailPreferences,
            style: Theme.of(context).textTheme.bodySmall),
      // 1. next-period countdown — the headline, estimates behind disclosure
      Card.filled(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('d MMMM', lang).format(day).toUpperCase(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.1,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  ),
                  if (!compact)
                    IconButton(
                      tooltip: l.calcDetailsTitle,
                      icon: const Icon(Icons.info_outline, size: 20),
                      onPressed: () => _showDetails(context, ref, eng, day, l),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(l.todayNextPeriodLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer)),
              const SizedBox(height: 2),
              if (daysUntil != null && daysUntil >= 0)
                Text(l.todayDaysUntil(daysUntil),
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer))
              else
                Text(
                    data.logs.isEmpty
                        ? l.noDataYet
                        : eng.inSilenceMode
                            ? l.noForecast
                            : next == null
                                ? l.calendarNoBand
                                : l.confirmTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onPrimaryContainer)),
              if (daysUntil != null && daysUntil >= 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      '${l.todayExpectedRange(_expectedRange(next!, eng.bandDays, lang))} · '
                      '${l.estimateNotCertain}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer)),
                ),
            ],
          ),
        ),
      ),
      // 2. honest mode banners
      if (data.settings.contraception == Contraception.unknown)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Card.outlined(child: Padding(
              padding: const EdgeInsets.all(16),
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.help_outline),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(l.unknownContrNote,
                      style: Theme.of(context).textTheme.bodyMedium)),
            ]),
            const SizedBox(height: 8),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () => _pickContraception(context, ref),
                    child: Text(l.unknownContrAction))),
          ]))),
        ),
      if (eng.healthNudgeEligible)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Card.outlined(
              child: ListTile(
                  title: Text(l.healthNudge),
                  trailing: TextButton(
                      onPressed: () => ref
                          .read(appDataProvider.notifier)
                          .updateSettings(
                              data.settings.copyWith(healthNudgeShown: true)),
                      child: Text(l.healthNudgeOk)))),
        ),
      if (eng.missedPeriodCard && next != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Card.outlined(
              child: ListTile(
                  title: Text(l.confirmTitle),
                  subtitle: Text(l.confirmBody),
                  trailing: TextButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  LogDateScreen(initialDate: next))),
                      child: Text(l.confirmAction)))),
        ),
      // 3. she may notice — three glanceable items, provenance labelled
      SectionHeader(Icons.wb_twilight_outlined, l.sheMayNotice),
      if (briefing == null || briefing.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(!eng.canPredict
              ? (data.logs.isEmpty ? l.todayFeelNoData : l.todayFeelUnavailable)
              : l.todayFeelNoData,
              style: Theme.of(context).textTheme.bodyMedium),
        )
      else ...[
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final h in briefing.historical)
            _FeelingChip(
              label: feelingLabel(context, ref, h.concept),
              icon: Icons.history,
              provenance: h.cycles >= FeelingSelector.recurrenceCycles
                  ? l.fromHistoryTag
                  : l.previouslyLoggedTag,
              onTap: () => _explainFeeling(context, ref, l,
                  feelingCatalog?.byId(h.concept),
                  data.customFeelings.where((c) => c.concept == h.concept).firstOrNull,
                  h,
                  day),
            ),
          for (final g in briefing.general)
            _FeelingChip(
              label: feelingLabel(context, ref, g),
              icon: feelingCategoryIcon(feelingCatalog?.byId(g)?.category ??
                  FeelingCategory.neutral),
              provenance: l.generalTag,
              onTap: () => _explainFeeling(context, ref, l,
                  feelingCatalog?.byId(g),
                  data.customFeelings.where((c) => c.concept == g).firstOrNull,
                  null,
                  day),
            ),
        ]),
        if (!compact && isToday)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => ref.read(appDataProvider.notifier).setFeelingRotation(
                  dateKey,
                  (data.feelingRotations
                          .where((r) => r.date == dateKey)
                          .firstOrNull
                          ?.cursor ??
                      0) +
                      1),
              icon: const Icon(Icons.autorenew, size: 18),
              label: Text(l.showOthers),
            ),
          ),
      ],
      if (logged != null && logged.entries.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Card.outlined(
            child: ListTile(
              leading: const Icon(Icons.how_to_reg_outlined),
              title: Text(l.loggedTodayLabel),
              subtitle: Text(logged.entries
                  .map((e) => e.intensity == null
                      ? feelingLabel(context, ref, e.concept)
                      : '${feelingLabel(context, ref, e.concept)} · '
                          '${intensityLabel(l, e.intensity!)}')
                  .join(' · ')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context)
                  .pushNamed('/log-feelings', arguments: day),
            ),
          ),
        ),
      // 4. how to respond — direct cues plus one support entry
      SectionHeader(Icons.waving_hand_outlined, l.howToRespond),
      if (cues.isNotEmpty)
        Text(cues.take(2).map((c) => c.text(lang == 'pt')).join(' · '),
            style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      if (isToday)
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SupportScreen(
                  // A contextual entry opens one situation directly; a plain
                  // entry opens the situation choices.
                  initial: data.preferences.any((p) => p.category == 'space')
                      ? SupportSituation.space
                      : ref.read(supportPriorityProvider(day))
                          ? SupportSituation.comfort : null),
            )),
            icon: const Icon(Icons.volunteer_activism_outlined),
            label: Text(l.seeSupportIdea),
          ),
        )
      else if (catalog != null)
        SupportToday(
            general: catalog.general,
            compact: compact,
            day: day,
            readOnly: true),
      // 5. compact tail: notes, reminders, tomorrow
      if (isToday) ...[
        const Divider(height: 40),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => QuickEntryScreen(day: day))),
              icon: const Icon(Icons.edit_note_outlined),
              label: Text(l.todayQuickEntry)),
          OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/tomorrow'),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(l.tomorrowCard)),
        ]),
        RemindersSection(day: day),
      ],
      if (!isToday) ...[
        const SizedBox(height: 12),
        RemindersSection(day: day, editable: false),
      ],
    ]);
  }

  /// "Expected 18–22 Oct" — the confidence band rendered as a readable range.
  String _expectedRange(DateTime next, int bandDays, String lang) {
    final lo = CycleEngine.addCalendarDays(next, -bandDays);
    final hi = CycleEngine.addCalendarDays(next, bandDays);
    final sameMonth = lo.year == hi.year && lo.month == hi.month;
    if (sameMonth) {
      return '${lo.day}–${DateFormat('d MMM', lang).format(hi)}';
    }
    return '${DateFormat('d MMM', lang).format(lo)} – '
        '${DateFormat('d MMM', lang).format(hi)}';
  }
}

class _FeelingChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String provenance;
  final VoidCallback onTap;
  const _FeelingChip(
      {required this.label,
      required this.icon,
      required this.provenance,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Flexible(child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
            ]),
            Text(provenance,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
