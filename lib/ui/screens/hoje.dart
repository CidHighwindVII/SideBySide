import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../engine/cycle_engine.dart';
import '../../engine/models.dart';
import '../../state/providers.dart';
import '../widgets.dart';
import '../theme.dart';
import '../../l10n/gen/app_localizations.dart';

class HojeScreen extends ConsumerWidget {
  const HojeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const SafeArea(child: ForecastView(offsetDays: 0));
}

class AmanhaScreen extends ConsumerWidget {
  const AmanhaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: Text(AppL.of(context).tomorrowCard)),
        body: const ForecastView(offsetDays: 1, compact: true),
      );
}

class ForecastView extends ConsumerWidget {
  final int offsetDays;
  final bool compact;
  const ForecastView({required this.offsetDays, this.compact = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final data = ref.watch(appDataProvider);
    final s = data.settings;
    final now = ref.watch(todayProvider);
    final day = CycleEngine.addCalendarDays(now, offsetDays);
    final eng = ref.watch(engineProvider(day));
    final catalogState = ref.watch(catalogProvider);
    final catalog = catalogState.valueOrNull;
    final isPt = ref.watch(langCodeProvider) == 'pt';
    final phase = eng.phaseOrNull(day);

    if (catalog == null) {
      return catalogState.hasError
          ? Center(child: Text(l.catalogUnavailable))
          : const Center(child: CircularProgressIndicator());
    }
    if (data.logs.isEmpty) {
      return Center(child: Text(l.noDataYet));
    }
    if (phase == null) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        Card.filled(
          child: ListTile(
              leading: const Icon(Icons.cloud_off_outlined), title: Text(l.noForecast)),
        ),
        if (eng.missedDays > 0) _ConfirmCard(start: eng.nextExpectedStart()!),
      ]);
    }

    final pc = catalog[phase];
    // v0.3.0 (#15): "apoio intensivo" re-ranks Luteal content first
    final support = s.intensiveSupport && phase == Phase.luteal;
    final picks = phasePicks(pc, s, support: support);
    final nextStart = eng.nextExpectedStart();
    final daysToPeriod = nextStart == null ? null : CycleEngine.daysBetween(day, nextStart);
    final fb = AppData.forecastFeedbackFor(data.feedback, DateFormat('yyyy-MM-dd').format(day));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        if (s.contraception == Contraception.hormonal)
          _Banner(text: l.hormonalBanner, icon: Icons.info_outline),
        if (eng.missedPeriodCard) _ConfirmCard(start: eng.nextExpectedStart()!),
        if (eng.healthNudgeEligible)
          _HealthNudge(onOk: () => ref
              .read(appDataProvider.notifier)
              .updateSettings(s.copyWith(healthNudgeShown: true))),
        // The estimate leads, with support immediately beneath it.
        Card.filled(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 8,
                  decoration: BoxDecoration(
                      color: phaseColors[phase],
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(20))),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          PhaseBadge(phase),
                          ConfidenceChip(eng.confidence),
                        ]),
                        const SizedBox(height: 16),
                        Text(
                          '${l.statusLabel}: ${pc.status.text(isPt).toLowerCase()}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(DateFormat('d MMMM', isPt ? 'pt' : 'en').format(day),
                            style: Theme.of(context).textTheme.bodyLarge),
                        if (eng.dayOfCycle(day) > 0)
                          Text(l.todayCycleDay(eng.dayOfCycle(day))),
                        if (nextStart != null)
                          Text(l.todayNextPeriod(DateFormat('d MMM', isPt ? 'pt' : 'en')
                              .format(nextStart))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (picks.actionable.isNotEmpty) ...[
          SupportActionCard(
            title: compact ? l.suggestionsTitle : l.tipOfDayTitle,
            action: picks.actionable.first.text(isPt),
            why: picks.actionable.first.why(isPt),
          ),
          const SizedBox(height: 12),
        ],
        if (!compact && daysToPeriod != null &&
            daysToPeriod >= 0 && daysToPeriod <= 3) ...[
          Card.outlined(
            child: ListTile(
              leading: const Icon(Icons.checklist_outlined),
              title: Text(l.prepTitle),
              subtitle: Text(l.prepBody),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (picks.context.isNotEmpty) ...[
          Card.outlined(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l.contextTitle),
              subtitle: Text(picks.context.first.text(isPt)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (!compact) ...[
          if (offsetDays == 0) _TomorrowPreview(),
          const SizedBox(height: 12),
          _VarianceCard(eng: eng),
          const SizedBox(height: 12),
          _FeedbackRow(
              date: DateFormat('yyyy-MM-dd').format(day),
              given: fb,
              question: l.feedbackQuestion,
              thanks: l.feedbackThanks),
        ] else ...[
          Section(title: l.suggestionsTitle, icon: Icons.lightbulb_outline, items: [
            for (final i in picks.actionable.skip(1)) (i.text(isPt), null)
          ]),
          Section(title: l.warningsTitle, icon: Icons.do_not_disturb_alt_outlined, items: [
            for (final i in picks.warnings.take(3)) (i.text(isPt), null)
          ]),
        ],
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Banner({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) => Card.filled(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        child: ListTile(
            leading: Icon(icon,
                color: Theme.of(context).colorScheme.onTertiaryContainer),
            title: Text(text,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onTertiaryContainer))),
      );
}

class _ConfirmCard extends ConsumerWidget {
  final DateTime start;
  const _ConfirmCard({required this.start});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.confirmTitle, style: Theme.of(context).textTheme.titleMedium),
            Text(l.confirmBody),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => ref
                  .read(appDataProvider.notifier)
                  .saveLog(PeriodLog(start, null)),
              child: Text(l.confirmAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthNudge extends StatelessWidget {
  final VoidCallback onOk;
  const _HealthNudge({required this.onOk});

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    return Card.outlined(
      child: ListTile(
        leading: const Icon(Icons.medical_information_outlined),
        title: Text(l.healthNudge),
        trailing: TextButton(onPressed: onOk, child: Text(l.healthNudgeOk)),
      ),
    );
  }
}

/// v0.2.0 (#10): last ≤6 cycle gaps as bars, avg + ±bandDays band from the
/// engine — no recomputation in the view (engine-purity invariant).
class _VarianceCard extends StatelessWidget {
  final CycleEngine eng;
  const _VarianceCard({required this.eng});

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    final gaps = eng.cycleGaps.reversed.take(6).toList().reversed.toList();
    if (gaps.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_outlined, size: 18),
                const SizedBox(width: 6),
                Text(l.varianceTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(l.varianceAvg(eng.avgCycle),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: CustomPaint(
                size: const Size(double.infinity, 96),
                painter: _VariancePainter(
                    gaps: gaps,
                    avg: eng.avgCycle,
                    band: eng.bandDays, // D27: read, never re-derive
                    // D25: outlier reads as full vs faded primary, not red
                    barColor: scheme.primary.withValues(alpha: 0.45),
                    outlierColor: scheme.primary,
                    lineColor: scheme.outline,
                    bandColor: scheme.primary.withValues(alpha: 0.12)),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final g in gaps)
                  Expanded(
                      child: Text('${g}d',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VariancePainter extends CustomPainter {
  final List<int> gaps;
  final int avg;
  final int band;
  final Color barColor, outlierColor, lineColor, bandColor;
  _VariancePainter(
      {required this.gaps,
      required this.avg,
      required this.band,
      required this.barColor,
      required this.outlierColor,
      required this.lineColor,
      required this.bandColor});

  @override
  void paint(Canvas canvas, Size size) {
    double y(int days) =>
        size.height * (1 - ((days - 15).clamp(0, 30)) / 30);
    if (band > 0) {
      canvas.drawRect(Rect.fromLTRB(0, y(avg + band), size.width, y(avg - band)),
          Paint()..color = bandColor);
    }
    final slot = size.width / gaps.length;
    for (var i = 0; i < gaps.length; i++) {
      final g = gaps[i];
      final left = slot * i + slot * 0.25;
      canvas.drawRect(
        Rect.fromLTRB(left, y(g), left + slot * 0.5, size.height),
        Paint()..color = (g < 21 || g > 35) ? outlierColor : barColor,
      );
    }
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, y(avg)), Offset(size.width, y(avg)), line);
  }

  @override
  bool shouldRepaint(_VariancePainter old) =>
      old.gaps.join() != gaps.join() || old.avg != avg || old.band != band;
}

class _TomorrowPreview extends ConsumerWidget {
  const _TomorrowPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final day = CycleEngine.addCalendarDays(ref.watch(todayProvider), 1);
    final eng = ref.watch(engineProvider(CycleEngine.dateOnly(day)));
    final phase = eng.phaseOrNull(day);
    if (phase == null) return const SizedBox.shrink();
    final worst = [OutlookAxis.favor, OutlookAxis.news, OutlookAxis.out]
        .map((a) => eng.axisRating(phase, a))
        .fold(Traffic.green, (x, y) => x.index > y.index ? x : y);
    return Card.outlined(
      child: ListTile(
        onTap: () => Navigator.of(context).pushNamed('/amanha'),
        leading: Icon(trafficIcon(worst), color: trafficColors[worst]),
        title: Text('${l.tomorrowCard}: ${phaseName(l, phase)}'),
        subtitle: Text(trafficLabel(l, worst)),
        trailing: Text(l.tomorrowPreview),
      ),
    );
  }
}

class _FeedbackRow extends ConsumerWidget {
  final String date;
  final ForecastFeedback? given;
  final String question;
  final String thanks;
  const _FeedbackRow(
      {required this.date,
      required this.given,
      required this.question,
      required this.thanks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(child: Text(given == null ? question : thanks)),
        IconButton(
          isSelected: given?.thumbsUp,
          visualDensity: VisualDensity.compact,
          onPressed: () => ref
              .read(appDataProvider.notifier)
              .feedback(date, true),
          icon: const Icon(Icons.thumb_up_outlined),
          selectedIcon: const Icon(Icons.thumb_up),
        ),
        IconButton(
          isSelected: given != null && !given!.thumbsUp,
          visualDensity: VisualDensity.compact,
          onPressed: () => ref
              .read(appDataProvider.notifier)
              .feedback(date, false),
          icon: const Icon(Icons.thumb_down_outlined),
          selectedIcon: const Icon(Icons.thumb_down),
        ),
      ],
    );
  }
}
