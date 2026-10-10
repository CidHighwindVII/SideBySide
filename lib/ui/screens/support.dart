import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalog.dart';
import '../../engine/cycle_engine.dart';
import '../../engine/models.dart';
import '../../engine/support_selector.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';
import '../widgets.dart';
import 'calendar.dart';

/// The focused Support route opened from Today's "See a support idea".
///
/// Responsibilities kept distinct: Today briefs, this screen helps choose one
/// practical action, Learn explains. Recognition over search: six labeled
/// situations open the choice, then exactly one action at a time with an
/// optional offering example, **Another idea**, and an explicit **I did this**.
/// Usefulness feedback and rationale stay secondary. All candidates flow
/// through the untouched `PhaseCatalog.pick` filter/priority/cap contract and
/// the existing suppression, rotation and completion semantics.
class SupportScreen extends ConsumerStatefulWidget {
  final SupportSituation? initial; // contextual entries open one situation
  const SupportScreen({this.initial, super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  SupportSituation? _situation;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _situation = widget.initial;
  }

  (String, IconData) _labels(AppL l, SupportSituation s) => switch (s) {
        SupportSituation.comfort => (l.sitComfort, Icons.self_improvement),
        SupportSituation.practical => (l.sitPractical, Icons.handyman_outlined),
        SupportSituation.listening => (l.sitListening, Icons.hearing_outlined),
        SupportSituation.space => (l.sitSpace, Icons.door_front_door_outlined),
        SupportSituation.together => (l.sitTogether, Icons.local_cafe_outlined),
        SupportSituation.apart => (l.sitApart, Icons.flight_takeoff),
      };

  String _bodies(AppL l, SupportSituation s) => switch (s) {
        SupportSituation.comfort => l.sitComfortBody,
        SupportSituation.practical => l.sitPracticalBody,
        SupportSituation.listening => l.sitListeningBody,
        SupportSituation.space => l.sitSpaceBody,
        SupportSituation.together => l.sitTogetherBody,
        SupportSituation.apart => l.sitApartBody,
      };

  Future<void> _editPreference(AppL l, {SupportPreference? existing}) async {
    final controller = TextEditingController(text: existing?.text);
    var category = existing?.category ?? 'checkIn';
    final result = await showDialog<({String text, String category})>(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
              return AlertDialog(
                title:
                    Text(existing == null ? l.preferenceAdd : l.preferenceEdit),
                content: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      Text(l.preferenceConsent),
                      DropdownButtonFormField<String>(
                          initialValue: category,
                          isExpanded: true,
                          decoration:
                              InputDecoration(labelText: l.preferenceCategory),
                          items: [
                            DropdownMenuItem(
                                value: 'checkIn',
                                child: Text(l.preferenceCheckIn,
                                    overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(
                                value: 'help',
                                child: Text(l.preferenceHelp,
                                    overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(
                                value: 'space',
                                child: Text(l.preferenceSpace,
                                    overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) {
                            if (v != null) setDialogState(() => category = v);
                          }),
                      TextField(
                          controller: controller,
                          maxLength: 180,
                          maxLines: 3,
                          decoration:
                              InputDecoration(labelText: l.preferenceText)),
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l.cancel)),
                  FilledButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isNotEmpty) {
                          Navigator.pop(ctx,
                              (text: text, category: category));
                        }
                      },
                      child: Text(l.save)),
                ],
              );
            }));
    if (result == null || !mounted) return;
    final notifier = ref.read(appDataProvider.notifier);
    if (existing == null) {
      notifier.addPreference(result.category, result.text);
    } else {
      notifier.updatePreference(
          SupportPreference(existing.id, result.category, result.text));
    }
  }

  Future<void> _editLegacyNote(AppL l, CustomCard card) async {
    final controller = TextEditingController(text: card.text);
    final result = await showDialog<String>(context: context,
        builder: (ctx) => AlertDialog(
            title: Text(l.customTitle),
            content: TextField(
                controller: controller,
                maxLength: 180,
                maxLines: 3,
                decoration: InputDecoration(labelText: l.customText)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
              FilledButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) Navigator.pop(ctx, text);
                  },
                  child: Text(l.save)),
            ]));
    if (result != null && mounted) {
      ref.read(appDataProvider.notifier).updateCustomCard(card, result);
    }
  }

  Future<void> _whatHelpsHer(AppL l) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Consumer(builder: (ctx, sheetRef, _) {
        final data = sheetRef.watch(appDataProvider);
        return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.whatHelpsHer,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(l.preferenceConsent,
                  style: Theme.of(context).textTheme.bodySmall),
              for (final p in data.preferences)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.text),
                  subtitle: Text(switch (p.category) {
                    'help' => l.preferenceHelp,
                    'space' => l.preferenceSpace,
                    _ => l.preferenceCheckIn,
                  }),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        tooltip: l.preferenceEdit,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _editPreference(l, existing: p)),
                    IconButton(
                        tooltip: l.preferenceDelete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref
                            .read(appDataProvider.notifier)
                            .deletePreference(p.id)),
                  ]),
                ),
              TextButton.icon(
                  onPressed: () => _editPreference(l),
                  icon: const Icon(Icons.add),
                  label: Text(l.preferenceAdd)),
              if (data.customCards.isNotEmpty) ...[
                const Divider(height: 32),
                Text(l.legacyNotes,
                    style: Theme.of(context).textTheme.titleSmall),
                for (final c in data.customCards)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.text),
                    subtitle: Text(phaseName(l, c.phase)),
                    trailing: IconButton(
                        tooltip: l.preferenceDelete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref
                            .read(appDataProvider.notifier)
                            .deleteCustomCard(c)),
                    onTap: () => _editLegacyNote(l, c),
                  ),
              ],
            ],
          ),
        ),
      );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    final data = ref.watch(appDataProvider);
    final catalogState = ref.watch(catalogProvider);
    final catalog = catalogState.valueOrNull;
    final isPt = ref.watch(langCodeProvider) == 'pt';
    final today = ref.watch(todayProvider);
    final dateKey = CycleEngine.dayKey(today);
    final situation = _situation;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.supportTitle),
        actions: [
          IconButton(
            tooltip: l.whatHelpsHer,
            icon: const Icon(Icons.favorite_outline),
            onPressed: () => _whatHelpsHer(l),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (catalog == null) ...[
              // Catalog failure keeps preferences reachable.
              Text(catalogState.hasError
                  ? l.catalogLoadFailPreferences
                  : l.learningIntro,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Card.outlined(
                child: ListTile(
                  leading: const Icon(Icons.favorite_outline),
                  title: Text(l.whatHelpsHer),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _whatHelpsHer(l),
                ),
              ),
            ] else if (situation == null) ...[
              Text(l.supportSituationPrompt,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final s in SupportSituation.values)
                Card.outlined(
                  child: ListTile(
                    leading: Icon(_labels(l, s).$2),
                    title: Text(_labels(l, s).$1),
                    subtitle: Text(_bodies(l, s)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => setState(() {
                      _situation = s;
                      _showDetails = false;
                    }),
                  ),
                ),
            ] else ...[
              _buildAction(context, l, data, catalog, situation, isPt, today,
                  dateKey),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, AppL l, AppData data,
      Catalog catalog, SupportSituation situation, bool isPt, DateTime today,
      String dateKey) {
    final (label, icon) = _labels(l, situation);
    final live = situation.liveTogetherOverride ?? data.settings.liveTogether;
    final categories = situation.categories;
    final supportContext = ref.watch(supportContextProvider(today));
    final phaseEng = ref.watch(engineProvider(today));
    final currentPhase =
        phaseEng.canPredict ? phaseEng.phaseOrNull(today) : null;
    // Pool = general actionable filtered to this situation (+ the current
    // phase's own actionable as general stage context). PhaseCatalog.pick does
    // the cohabitation filtering only; ordering/rotation stays with the
    // selector contract.
    final pool = {
      for (final i in catalog.general.actionable)
        if (categories.contains(i.category)) i,
      if (currentPhase != null)
        for (final i in catalog.phases[currentPhase]!.actionable)
          if (categories.contains(i.category)) i,
    }.toList();
    final eligible = PhaseCatalog.pick(pool, live, pool.length,
        supportPriority: ref.watch(supportPriorityProvider(today)));
    final prefs = data.preferences
        .where((p) => situation.preferenceCategories.contains(p.category))
        .toList();
    final items = <SelectableItem>[
      for (final p in prefs)
        SelectableItem(id: 'preference:${p.id}', preferred: true),
      for (final i in eligible)
        SelectableItem(id: i.id, support: i.support, category: i.category,
            relevance: supportContext.current.contains(i.category) ? 1
                : supportContext.historical.contains(i.category) ? 2
                : currentPhase != null && catalog[currentPhase].actionable.contains(i) ? 3 : 4),
    ];
    // "Previously helpful" claims come ONLY from action-usefulness feedback —
    // feeling history is never evidence that an action worked.
    final boosted = {
      for (final f in data.actionFeedback)
        if (f.useful) f.actionId,
    };
    final order = SupportSelector.order(items, today,
        suppressed: _suppressed(data, today),
        recentlyCompleted: _completedRecently(data, today),
        boost: boosted,
        supportPriority: ref.watch(supportPriorityProvider(today)));
    final display = <String, ({String text, String? why, String? offer})>{
      for (final p in prefs)
        'preference:${p.id}': (text: p.text, why: l.agreedPreference, offer: null),
      for (final i in eligible)
        i.id: (text: i.text(isPt), why: i.why(isPt), offer: i.offer(isPt)),
    };
     final selection = data.selections.where((s) => s.date == dateKey &&
        s.scope == situation.name).firstOrNull;
    final cursor = selection?.cursor ?? 0;
    // Preserve the choice on reopen, but rerank when relevance inputs change.
     final sameOrder = selection != null && selection.order.length == order.length &&
        List.generate(order.length, (i) => selection.order[i] == order[i]).every((same) => same);
    final leadingId = order.isEmpty ? null : order[(sameOrder ? cursor : 0) % order.length];
    if (leadingId == null || !display.containsKey(leadingId)) {
      // No suitable action → clear check-in fallback, never fake relevance.
      return Card.filled(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(label,
                        style: Theme.of(context).textTheme.titleMedium)),
              ]),
              const SizedBox(height: 10),
              Text(l.checkInFallback,
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                TextButton(
                    onPressed: () => setState(() => _situation = null),
                    child: Text(l.changeSituation)),
                TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => CalendarScreen(initialDate: today))),
                    child: Text(l.calFeelings)),
              ]),
            ],
          ),
        ),
      );
    }
    final action = display[leadingId]!;
    final done = data.completions
        .any((c) => c.date == dateKey && c.actionId == leadingId);
    final wasHelpful = boosted.contains(leadingId) &&
        !leadingId.startsWith('preference:');
    final rating = data.actionFeedback
        .where((f) => f.date == dateKey && f.actionId == leadingId)
        .firstOrNull;
    final notifier = ref.read(appDataProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.titleMedium)),
          TextButton(
              onPressed: () => setState(() => _situation = null),
              child: Text(l.changeSituation)),
        ]),
        const SizedBox(height: 12),
        SupportActionCard(title: l.suggestionsTitle, action: action.text),
        if (action.offer != null) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
                '${l.actionOfferLabel}\n“${action.offer!}”',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
        if (wasHelpful) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.check_circle_outline, size: 16),
            const SizedBox(width: 6),
            Text(l.previouslyHelpfulTag,
                style: Theme.of(context).textTheme.labelMedium),
          ]),
        ],
        if (done) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.task_alt, size: 18),
            const SizedBox(width: 6),
            Text(l.actionCompletedLabel),
          ]),
        ],
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton(
              onPressed: () => notifier.completeAction(dateKey, leadingId),
              child: Text(l.didThis)),
          OutlinedButton.icon(
              onPressed: () => notifier.setSelection(dateKey, order,
                  (sameOrder ? cursor : 0) + 1, scope: situation.name),
              icon: const Icon(Icons.autorenew, size: 18),
              label: Text(l.anotherIdea)),
        ]),
        const SizedBox(height: 8),
        // Explanation and usefulness feedback stay secondary.
        TextButton.icon(
            onPressed: () => setState(() => _showDetails = !_showDetails),
            icon: Icon(_showDetails
                ? Icons.expand_less
                : Icons.expand_more),
            label: Text(l.whyThisLabel)),
        if (_showDetails) ...[
          if (action.why != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(action.why!,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          const SizedBox(height: 4),
          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center,
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
        if (done)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l.didThisDone,
                style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }

  Set<String> _suppressed(AppData data, DateTime day) => {
        for (final f in data.actionFeedback)
          if (!f.useful && _recent(f.date, day)) f.actionId,
      };

  Set<String> _completedRecently(AppData data, DateTime day) => {
        for (final c in data.completions)
          if (_recent(c.date, day)) c.actionId,
      };

  bool _recent(String date, DateTime day) {
    final d = DateTime.tryParse(date);
    if (d == null) return false;
    final diff = CycleEngine.daysBetween(d, day);
    return diff >= 0 && diff < 7;
  }
}
