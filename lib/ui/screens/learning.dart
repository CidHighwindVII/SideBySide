import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/learning_catalog.dart';
import '../../engine/cycle_engine.dart';
import '../../engine/support_selector.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';
import '../widgets.dart';
import 'garden.dart';

/// Learn tab: motivation without a wall of content.
///
/// A recommended lesson (deterministic per day, never nagging), topic browsing,
/// visible progress and the Garden entry live here. Explicit completion is the
/// only thing that records progress or earns garden credit — opening a lesson
/// never does. Lesson ids and completion records are stable across the move
/// from the old Suggestions surface.
class LearningPage extends StatelessWidget {
  const LearningPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(AppL.of(context).learningTitle)),
        body: SafeArea(child: const LearningScreen()),
      );
}

class LearningScreen extends ConsumerWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final state = ref.watch(learningProvider);
    final catalog = state.valueOrNull;
    final isPt = ref.watch(langCodeProvider) == 'pt';
    final data = ref.watch(appDataProvider);
    final today = ref.watch(todayProvider);
    final doneIds = {for (final lc in data.learning) lc.cardId};
    if (catalog == null) {
      return Center(
          child: state.hasError
              ? Text(l.catalogUnavailable)
              : const CircularProgressIndicator());
    }
    final ordered = catalog.byTopic();
    final remaining =
        ordered.where((i) => !doneIds.contains(i.id)).toList();
    // Recommended lesson: deterministic date-seeded rotation over whatever is
    // still uncompleted; when everything is done, rotate the full library.
    final pool = remaining.isEmpty ? ordered : remaining;
    final recommended = pool.isEmpty ? null : pool[SupportSelector.dayRank(
            pool.first.id, today) % pool.length];
    final topics = catalog.topics;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text(l.learningTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(l.learningIntro, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        if (pool.isEmpty && ordered.isEmpty)
          Text(l.catalogUnavailable)
        else if (recommended != null)
          Card.filled(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _LessonDetail(item: recommended))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.learnRecommended,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer)),
                    const SizedBox(height: 4),
                    Text(recommended.title(isPt),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer)),
                    if (recommended.takeaway != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(recommended.takeaway!.text(isPt),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer)),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.chevron_right,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(l.learnProgress(doneIds.length, ordered.length),
            style: Theme.of(context).textTheme.bodySmall),
        if (!data.settings.gardenHidden) ...[
          const SizedBox(height: 12),
          Card.outlined(
            child: ListTile(
                leading: const Icon(Icons.spa_outlined),
                title: Text(l.gardenTitle),
                subtitle: Text(l.gardenIntro),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const GardenScreen()))),
          ),
        ],
        const SizedBox(height: 16),
        Text(l.learnTopics, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        for (final entry in topics.entries)
          Builder(builder: (context) {
            final items =
                ordered.where((i) => i.topic == entry.key).toList();
            if (items.isEmpty) return const SizedBox.shrink();
            final done = items.where((i) => doneIds.contains(i.id)).length;
            return Card.outlined(
              margin: const EdgeInsets.only(top: 8),
              child: ExpansionTile(
                shape: const Border(),
                leading: const Icon(Icons.folder_outlined),
                title: Text(entry.value.text(isPt)),
                subtitle: Text('$done/${items.length}'),
                children: [
                  for (final item in items)
                    ListTile(
                      dense: true,
                      leading: Icon(doneIds.contains(item.id)
                          ? Icons.check_circle
                          : Icons.menu_book_outlined),
                      title: Text(item.title(isPt)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => _LessonDetail(item: item))),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _LessonDetail extends ConsumerStatefulWidget {
  final LearningItem item;
  const _LessonDetail({required this.item});

  @override
  ConsumerState<_LessonDetail> createState() => _LessonDetailState();
}

class _LessonDetailState extends ConsumerState<_LessonDetail> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    final isPt = ref.watch(langCodeProvider) == 'pt';
    final item = widget.item;
    final dateKey = CycleEngine.dayKey(ref.watch(todayProvider));
    final completed = ref
        .watch(appDataProvider)
        .learning
        .any((x) => x.cardId == item.id);
    final quiz = item.quiz;
    final cards = item.cards.isNotEmpty ? item.cards : const <BiText>[];
    return Scaffold(
      appBar: AppBar(title: Text(item.title(isPt))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(item.body(isPt), style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          for (final card in cards)
            Card.filled(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(card.text(isPt),
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          if (item.takeaway != null) ...[
            const SizedBox(height: 4),
            Card.outlined(
              child: ListTile(
                leading:
                    Icon(Icons.lightbulb_outline,
                        color: Theme.of(context).colorScheme.primary),
                title: Text(l.learnTakeaway,
                    style: Theme.of(context).textTheme.labelLarge),
                subtitle: Text(item.takeaway!.text(isPt),
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.learningSource,
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(item.source(isPt),
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
            ),
          ),
          if (item.refs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: const Icon(Icons.link_outlined),
                title: Text(l.learnReadMore,
                    style: Theme.of(context).textTheme.titleSmall),
                children: [
                  for (final r in item.refs)
                    SourceLink(label: r.label(isPt), url: r.url),
                ],
              ),
            ),
          ],
          if (quiz != null) ...[
            const SizedBox(height: 16),
            Text(l.learningQuiz,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(quiz.question(isPt)),
            const SizedBox(height: 8),
            for (var i = 0; i < quiz.options.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: ChoiceChip(
                  label: Text(quiz.options[i].text(isPt)),
                  selected: _picked == i,
                  onSelected: (_) => setState(() => _picked = i),
                ),
              ),
            if (_picked != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(_picked == quiz.answer
                    ? Icons.check_circle
                    : Icons.info_outline),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_picked == quiz.answer
                        ? l.learningCheckRight
                        : l.learningCheckWrong)),
              ]),
              const SizedBox(height: 4),
              Text(quiz.explain(isPt),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
          const SizedBox(height: 20),
          if (completed)
            Row(children: [
              const Icon(Icons.check_circle),
              const SizedBox(width: 8),
              Text(l.learningCompleted),
            ])
          else
            FilledButton.icon(
              onPressed: () =>
                  ref.read(appDataProvider.notifier).completeLearning(
                      item.id, dateKey),
              icon: const Icon(Icons.done),
              label: Text(l.learningDone),
            ),
        ],
      ),
    );
  }
}
