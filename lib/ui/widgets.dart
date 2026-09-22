import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../engine/models.dart';
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

/// A picked catalog action with optional explanation, shared by the forecast
/// and suggestions surfaces. Callers supply items from phasePicks only.
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

/// Catalog picks for a phase — cohabitation filter + ≤3 cap + #15 re-rank.
/// Single source for Hoje, Amanhã and Sugestões.
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
