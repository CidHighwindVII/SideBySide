import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../engine/garden_engine.dart';
import '../../engine/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';
import '../garden/garden_card.dart';
import '../garden/plant_illustration.dart';

/// Full garden: the single active plant (name + pot), the retained collection of
/// mature plants, and a per-plant detail sheet with growth dates and category
/// totals. Later varieties reveal as earlier plants mature. Progress never
/// decays; there are no dead plants, lost streaks or guilt messages.
class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final g = ref.watch(gardenProvider);
    final data = ref.watch(appDataProvider);
    final lang = ref.watch(langCodeProvider);

    Plant plantMeta(int index) {
      final p = data.plants.where((x) => x.index == index).firstOrNull;
      return p ?? Plant(index: index, variety: index % 3);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.gardenTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(l.gardenIntro, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Text(l.gardenActivePlant,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _ActivePlantCard(
            index: g.activePlantIndex,
            variety: g.variety,
            stage: g.stage,
            momentsOnActive: g.momentsOnActive,
            meta: plantMeta(g.activePlantIndex),
          ),
          if (g.completedPlants > 0) ...[
            const SizedBox(height: 20),
            Text(l.gardenCollection,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, c) {
              final columns = (c.maxWidth / 140).floor().clamp(2, 4);
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < g.completedPlants; i++)
                    _CollectionTile(
                      index: i,
                      meta: plantMeta(i),
                      lang: lang,
                    ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _ActivePlantCard extends ConsumerWidget {
  final int index;
  final int variety;
  final PlantStage stage;
  final int momentsOnActive;
  final Plant meta;
  const _ActivePlantCard({
    required this.index,
    required this.variety,
    required this.stage,
    required this.momentsOnActive,
    required this.meta,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          PlantIllustration(
              variety: variety, stage: stage, potStyle: meta.potStyle, size: 140),
          const SizedBox(height: 8),
          Text(meta.name?.isNotEmpty == true ? meta.name! : varietyName(l, variety),
              style: Theme.of(context).textTheme.titleMedium),
          Text('${stageLabel(l, stage)} · ${l.gardenMoments(momentsOnActive)}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            TextButton.icon(
              onPressed: () => _rename(context, ref),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l.gardenName),
            ),
            _PotPicker(index: index, variety: variety, potStyle: meta.potStyle),
          ]),
        ]),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final l = AppL.of(context);
    final controller = TextEditingController(text: meta.name);
    final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(l.gardenName),
              content: TextField(
                  controller: controller,
                  maxLength: 40,
                  autofocus: true,
                  decoration: InputDecoration(hintText: l.gardenUnnamed)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
                FilledButton(
                    onPressed: () =>
                        Navigator.pop(ctx, controller.text.trim()),
                    child: Text(l.save)),
              ],
            ));
    if (name != null && context.mounted) {
      ref.read(appDataProvider.notifier).namePlant(index, variety, name);
    }
  }
}

class _PotPicker extends ConsumerWidget {
  final int index;
  final int variety;
  final int potStyle;
  const _PotPicker(
      {required this.index, required this.variety, required this.potStyle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    return PopupMenuButton<int>(
      tooltip: l.gardenPotStyle,
      icon: const Icon(Icons.style_outlined),
      onSelected: (v) =>
          ref.read(appDataProvider.notifier).setPlantStyle(index, variety, v),
      itemBuilder: (ctx) => [
        for (var s = 0; s < 3; s++)
          PopupMenuItem(value: s, child: Text('${l.gardenPotStyle} ${s + 1}')),
      ],
    );
  }
}

class _CollectionTile extends ConsumerWidget {
  final int index;
  final Plant meta;
  final String lang;
  const _CollectionTile(
      {required this.index, required this.meta, required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    return Card.outlined(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _PlantDetailSheet(index: index, meta: meta),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            PlantIllustration(
                variety: meta.variety,
                stage: PlantStage.flowering,
                potStyle: meta.potStyle,
                mature: true,
                size: 84),
            Text(meta.name?.isNotEmpty == true ? meta.name! : varietyName(l, meta.variety),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge),
          ]),
        ),
      ),
    );
  }
}

class _PlantDetailSheet extends ConsumerWidget {
  final int index;
  final Plant meta;
  const _PlantDetailSheet({required this.index, required this.meta});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final lang = ref.watch(langCodeProvider);
    final events = ref.watch(appDataProvider).careEvents;
    final engine = GardenEngine(
        events: events, today: ref.watch(todayProvider));
    final plantEvents = engine.eventsForPlant(index);
    final totals = engine.state();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.gardenDetailTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Center(
                child: PlantIllustration(
                    variety: meta.variety,
                    stage: PlantStage.flowering,
                    potStyle: meta.potStyle,
                    mature: true,
                    size: 160),
              ),
              const SizedBox(height: 12),
              Text(l.gardenGrowthDates,
                  style: Theme.of(context).textTheme.labelLarge),
              for (final e in plantEvents)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(DateFormat('d MMM yyyy', lang)
                      .format(DateTime.parse(e.date))),
                ),
              const SizedBox(height: 12),
              Text(l.gardenTotals,
                  style: Theme.of(context).textTheme.labelLarge),
              Text('${l.gardenCatLearn}: ${totals.learn} · '
                  '${l.gardenCatAct}: ${totals.act} · '
                  '${l.gardenCatReflect}: ${totals.reflect}'),
            ],
          ),
        ),
      ),
    );
  }
}
