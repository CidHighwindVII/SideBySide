import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/garden_engine.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';
import '../screens/garden.dart';
import '../screens/learning.dart';
import 'plant_illustration.dart';

String stageLabel(AppL l, PlantStage s) => switch (s) {
      PlantStage.seed => l.gardenStageSeed,
      PlantStage.sprout => l.gardenStageSprout,
      PlantStage.leaves => l.gardenStageLeaves,
      PlantStage.buds => l.gardenStageBuds,
      PlantStage.flowering => l.gardenStageFlowering,
    };

String varietyName(AppL l, int v) => switch (v) {
      0 => l.gardenVariety0,
      1 => l.gardenVariety1,
      _ => l.gardenVariety2,
    };

/// Compact garden card for Hoje: the active plant, weekly care progress and a
/// next-care action. Hidden entirely when the garden setting is off (progress is
/// retained regardless). Growth pops once per newly earned moment and never
/// replays on unrelated rebuilds; honours reduced-motion.
class GardenCard extends ConsumerWidget {
  const GardenCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final hidden = ref.watch(appDataProvider).settings.gardenHidden;
    if (hidden) return const SizedBox.shrink();
    final g = ref.watch(gardenProvider);
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Card.filled(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const GardenScreen())),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Semantics(
                label:
                    '${varietyName(l, g.variety)} · ${stageLabel(l, g.stage)} · ${l.gardenMoments(g.momentsOnActive)}',
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(g.totalMoments),
                  tween: Tween(begin: 0.6, end: 1.0),
                  duration: reduce ? Duration.zero : const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  builder: (context, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: PlantIllustration(
                      variety: g.variety, stage: g.stage, size: 72),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.gardenActivePlant,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(l.gardenWeeklyGoal(g.weeklyGoal)),
                    Text(l.gardenMoments(g.momentsOnActive),
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const LearningScreen())),
                        icon: const Icon(Icons.spa_outlined, size: 18),
                        label: Text(l.gardenNextHint),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
