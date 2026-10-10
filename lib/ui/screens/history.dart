import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/summarization.dart';
import '../../engine/cycle_engine.dart';
import '../../engine/feeling_selector.dart';
import '../../engine/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';
import '../widgets.dart';
import 'feelings.dart';
import 'quick_entry.dart';

/// Four-stage history of dated feeling records (Phase 3).
///
/// Records belong to dates; the stage is derived when reading, so a corrected
/// period date re-groups the list on the next build. Records whose stage
/// cannot be derived stay visible under "Stage unknown" — never dropped and
/// never assigned a fake phase.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static const _order = [
    HistoryStage.menstrual,
    HistoryStage.follicular,
    HistoryStage.ovulatory,
    HistoryStage.luteal,
    HistoryStage.unknown,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final lang = ref.watch(langCodeProvider);
    final isPt = lang == 'pt';
    final data = ref.watch(appDataProvider);
    final catalog = ref.watch(feelingCatalogProvider).valueOrNull;
    final eng = ref.watch(engineProvider(ref.watch(todayProvider)));
    final groups =
        FeelingSelector.groupByStage(feelings: data.feelingLogs, eng: eng);
    final total = groups.values.fold<int>(0, (s, g) => s + g.length);
    String conceptLabel(String concept) {
      final c = catalog?.byId(concept);
      if (c != null) return c.label(isPt);
      if (concept.startsWith('custom:')) {
        final id = int.tryParse(concept.substring(7));
        return data.customFeelings
                .where((x) => x.id == id)
                .firstOrNull
                ?.label ??
            concept;
      }
      return concept;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.historyTitle)),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (total == 0)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.historyEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
                for (final stage in _order)
                  if (groups[stage]!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 4),
                      child: Text(
                          '${stageName(l, stage)} · ${groups[stage]!.length}',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    if (stage == HistoryStage.luteal)
                      Text(l.historyLutealNote,
                          style: Theme.of(context).textTheme.bodySmall),
                    if (stage == HistoryStage.unknown)
                      Text(l.historyUnknownNote,
                          style: Theme.of(context).textTheme.bodySmall),
                    for (final f in groups[stage]!)
                      Builder(builder: (context) {
                        final day = DateTime.tryParse(f.date);
                        return Card.outlined(
                          child: ListTile(
                            dense: true,
                            title: Text(day == null
                                ? f.date
                                : DateFormat('d MMM yyyy', lang).format(day)),
                            subtitle: Text(f.entries
                                .map((e) => e.intensity == null
                                    ? conceptLabel(e.concept)
                                    : '${conceptLabel(e.concept)} · '
                                        '${intensityLabel(l, e.intensity!)}')
                                .join(' · ')),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              if (day == null) return;
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => FeelingsScreen(day: day)));
                            },
                          ),
                        );
                      }),
                  ],
                _SummaryPanel(entries: data.entries),
              ],
            ),
    );
  }
}

/// Optional on-device note summaries — presentation only. Results stay
/// transient (never persisted as records), are produced solely by the local
/// adapter (no cloud fallback), and are dropped whenever the note set changes.
class _SummaryPanel extends ConsumerStatefulWidget {
  final List<QuickEntry> entries;
  const _SummaryPanel({required this.entries});

  @override
  ConsumerState<_SummaryPanel> createState() => _SummaryPanelState();
}

class _SummaryPanelState extends ConsumerState<_SummaryPanel> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _probeAfterFrame();
  }

  void _probeAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(summarizationControllerProvider).probe(
          entries: _recentNotes, lang: ref.read(langCodeProvider));
    });
  }

  @override
  void didUpdateWidget(covariant _SummaryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.entries, widget.entries)) _probeAfterFrame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(summarizationControllerProvider).cancelRun();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Notes from the last 90 days, newest first — a bounded local window.
  List<QuickEntry> get _recentNotes {
    final today = ref.read(todayProvider);
    final sorted = widget.entries.where((e) {
      final day = DateTime.tryParse(e.date);
      if (day == null) return false;
      final age = CycleEngine.daysBetween(day, today);
      return age >= 0 && age <= 90;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(20).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    ref.listen(langCodeProvider, (_, _) => _probeAfterFrame());
    if (_recentNotes.isEmpty || !SummarizationController.hasEnoughInput(_recentNotes)) {
      return const SizedBox.shrink();
    }
    final controller = ref.watch(summarizationControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(l.summaryTitle,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) => switch (controller.stage) {
            SummaryStage.unavailable =>
              _msg(l.summaryUnavailable),
            SummaryStage.unsupportedLanguage =>
              _msg(l.summaryUnsupported),
            SummaryStage.downloadable => Row(children: [
                Expanded(child: _msg(l.summaryDownloading)),
                TextButton(
                    onPressed: controller.prepare,
                    child: Text(l.summarySetup)),
              ]),
            SummaryStage.running => Row(children: [
                const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Expanded(child: _msg(l.summaryRunning)),
                TextButton(
                    onPressed: controller.cancelRun,
                    child: Text(l.cancel)),
              ]),
            SummaryStage.failed => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _msg(l.summaryFailed),
                  TextButton(
                    onPressed: () async {
                      await controller.probe(entries: _recentNotes,
                          lang: ref.read(langCodeProvider));
                      if (mounted) await controller.summarize(_recentNotes);
                    },
                      child: Text(l.summaryRetry)),
                ]),
            SummaryStage.done => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card.filled(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.summaryTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium),
                            const SizedBox(height: 6),
                            Text(controller.summary.isEmpty
                                ? l.summaryFailed
                                : controller.summary),
                          ]),
                    ),
                  ),
                  TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const QuickEntryScreen())),
                      icon: const Icon(Icons.note_outlined, size: 18),
                      label: Text(l.summarySources)),
                ],
              ),
            SummaryStage.idle ||
            SummaryStage.checking ||
            SummaryStage.cancelled => Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                    onPressed: controller.stage == SummaryStage.checking
                        ? null
                        : () async {
                            await controller.probe(entries: _recentNotes,
                                lang: ref.read(langCodeProvider));
                            if (mounted) await controller.summarize(_recentNotes);
                          },
                    icon: const Icon(Icons.short_text),
                    label: Text(l.summaryAction)),
              ),
          },
        ),
      ],
    );
  }

  Widget _msg(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      );
}
