import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/learning_catalog.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';

/// Short bilingual learning cards. Opening a card is only education; the
/// explicit "mark as done" action is what records a completion (and can earn a
/// garden `learn` moment). Nothing here asserts mood from a phase.
class LearningScreen extends ConsumerWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final state = ref.watch(learningProvider);
    final catalog = state.valueOrNull;
    final isPt = ref.watch(langCodeProvider) == 'pt';
    final doneIds = {
      for (final lc in ref.watch(appDataProvider).learning) lc.cardId,
    };
    if (catalog == null) {
      return Scaffold(
          appBar: AppBar(title: Text(l.learningTitle)),
          body: Center(
              child: state.hasError
                  ? Text(l.catalogUnavailable)
                  : const CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.learningTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(l.learningIntro, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          for (final item in catalog.items)
            Card.outlined(
              child: ListTile(
                leading: Icon(doneIds.contains(item.id)
                    ? Icons.check_circle
                    : Icons.menu_book_outlined),
                title: Text(item.title(isPt)),
                subtitle: Text(item.body(isPt), maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _LearningDetail(item: item))),
              ),
            ),
        ],
      ),
    );
  }
}

class _LearningDetail extends ConsumerStatefulWidget {
  final LearningItem item;
  const _LearningDetail({required this.item});

  @override
  ConsumerState<_LearningDetail> createState() => _LearningDetailState();
}

class _LearningDetailState extends ConsumerState<_LearningDetail> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    final isPt = ref.watch(langCodeProvider) == 'pt';
    final item = widget.item;
    final dateKey =
        DateFormat('yyyy-MM-dd').format(ref.watch(todayProvider));
    final completed = ref
        .watch(appDataProvider)
        .learning
        .any((x) => x.cardId == item.id);
    final quiz = item.quiz;
    return Scaffold(
      appBar: AppBar(title: Text(item.title(isPt))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(item.body(isPt), style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.learningSource, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(item.source(isPt), style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ),
          if (quiz != null) ...[
            const SizedBox(height: 16),
            Text(l.learningQuiz, style: Theme.of(context).textTheme.titleMedium),
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
                Icon(_picked == quiz.answer ? Icons.check_circle : Icons.info_outline),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_picked == quiz.answer
                        ? l.learningCheckRight
                        : l.learningCheckWrong)),
              ]),
              const SizedBox(height: 4),
              Text(quiz.explain(isPt), style: Theme.of(context).textTheme.bodySmall),
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
              onPressed: () => ref
                  .read(appDataProvider.notifier)
                  .completeLearning(item.id, dateKey),
              icon: const Icon(Icons.done),
              label: Text(l.learningDone),
            ),
        ],
      ),
    );
  }
}
