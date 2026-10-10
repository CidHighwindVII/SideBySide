import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/feeling_catalog.dart';
import '../../engine/cycle_engine.dart';
import '../../engine/feeling_selector.dart';
import '../../engine/models.dart';
import '../../engine/support_selector.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';
import '../widgets.dart';

/// Searchable, multi-select feeling editor for one Calendar date.
///
/// Selections are always explicit user taps — nothing is ever preselected
/// from an inference. Suggestions rank for the *selected date's* estimated
/// stage and position; every concept stays searchable regardless of ranking,
/// and a missing match can become a custom concept immediately.
class FeelingsScreen extends ConsumerStatefulWidget {
  final DateTime day;
  const FeelingsScreen({required this.day, super.key});

  @override
  ConsumerState<FeelingsScreen> createState() => _FeelingsScreenState();
}

class _FeelingsScreenState extends ConsumerState<FeelingsScreen> {
  final _search = TextEditingController();
  String _query = '';
  final Map<String, FeelingEntry> _selected = {};

  @override
  void initState() {
    super.initState();
    final key = CycleEngine.dayKey(widget.day);
    final saved =
        AppData.feelingLogFor(ref.read(appDataProvider).feelingLogs, key);
    for (final e in saved?.entries ?? const <FeelingEntry>[]) {
      final id = canonicalFeelingId(e.concept);
      _selected[id] = FeelingEntry(id, intensity: e.intensity);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.containsKey(id)) {
        _selected.remove(id);
      } else {
        _selected[id] = FeelingEntry(id);
      }
    });
  }

  void _setIntensity(String id, FeelingIntensity? intensity) {
    setState(() {
      final e = _selected[id];
      if (e == null) return;
      _selected[id] = intensity == null
          ? FeelingEntry(e.concept)
          : e.copyWith(intensity: intensity);
    });
  }

  void _save() {
    final key = CycleEngine.dayKey(widget.day);
    ref
        .read(appDataProvider.notifier)
        .saveFeelingLog(key, _selected.values.toList());
    Navigator.of(context).pop();
  }

  Future<String?> _promptLabel({String? initial}) async {
    final l = AppL.of(context);
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.feelingCustomCreate),
        content: TextField(
          controller: controller,
          maxLength: 60,
          autofocus: true,
          decoration: InputDecoration(labelText: l.feelingCustomLabel),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                if (t.isNotEmpty) Navigator.pop(ctx, t);
              },
              child: Text(l.save)),
        ],
      ),
    );
    return result;
  }

  Future<void> _createCustom() async {
    final label = await _promptLabel(
        initial: _query.trim().isEmpty ? null : _query.trim());
    if (label == null) return;
    final concept = ref.read(appDataProvider.notifier).addCustomFeeling(label);
    setState(() {
      _selected[concept] = FeelingEntry(concept);
      _query = '';
      _search.clear();
    });
  }

  /// Custom-concept management: rename and merge with consistent historical
  /// references; merged/duplicate dated selections collapse on merge.
  Future<void> _manageCustoms() async {
    final l = AppL.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        final customs = ref.read(appDataProvider).customFeelings;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              Text(l.feelingCustomManage,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (customs.isEmpty) Text(l.feelingCustomNone),
              for (final c in customs)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.label_outline),
                  title: Text(c.label),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'rename') {
                        final label =
                            await _promptLabel(initial: c.label);
                        if (label != null) {
                          ref
                              .read(appDataProvider.notifier)
                              .renameCustomFeeling(c.id, label);
                        }
                      } else if (v == 'merge') {
                        final target = await _pickMergeTarget(c);
                        if (target != null) {
                          ref
                              .read(appDataProvider.notifier)
                               .mergeCustomFeeling(c.id, target);
                          setState(() {
                            final mapped = AppData.dedupeEntries([
                              for (final e in _selected.values)
                                FeelingEntry(e.concept == c.concept ? target : e.concept,
                                    intensity: e.intensity),
                            ]);
                            _selected..clear()..addEntries(mapped.map((e) => MapEntry(e.concept, e)));
                          });
                        }
                      } else if (v == 'delete') {
                        ref
                            .read(appDataProvider.notifier)
                            .deleteCustomFeeling(c.id);
                        setState(() => _selected.remove(c.concept));
                      }
                      if (ctx.mounted) setSheet(() {});
                    },
                    itemBuilder: (pctx) => [
                      PopupMenuItem(value: 'rename', child: Text(l.feelingRename)),
                      PopupMenuItem(value: 'merge', child: Text(l.feelingMerge)),
                      PopupMenuItem(
                          value: 'delete', child: Text(l.feelingDeleteCustom)),
                    ],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Future<String?> _pickMergeTarget(CustomFeeling from) async {
    final l = AppL.of(context);
    final catalog = ref.read(feelingCatalogProvider).valueOrNull;
    final data = ref.read(appDataProvider);
    final options = <({String concept, String label})>[
      for (final c in catalog?.concepts ?? const <FeelingConcept>[])
        (concept: c.id, label: c.label(ref.read(langCodeProvider) == 'pt')),
      for (final c in data.customFeelings)
        if (c.id != from.id) (concept: c.concept, label: c.label),
    ];
    if (options.isEmpty) return null;
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.feelingMergeInto),
        children: [
          for (final o in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, o.concept),
              child: Text(o.label),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    final lang = ref.watch(langCodeProvider);
    final isPt = lang == 'pt';
    final catalogState = ref.watch(feelingCatalogProvider);
    final catalog = catalogState.valueOrNull;
    final data = ref.watch(appDataProvider);
    if (catalog == null) {
      return Scaffold(
          appBar: AppBar(title: Text(l.feelingsTitle)),
          body: Center(
              child: catalogState.hasError
                  ? Text(l.catalogUnavailable)
                  : const CircularProgressIndicator()));
    }
    final eng = ref.watch(engineProvider(widget.day));
    final stage = historyStageOf(eng.phaseForRecord(widget.day));
    final needle = _query.trim();
    final hits = needle.isEmpty
        ? <FeelingConcept>[]
        : catalog.search(needle);
    final exactLabel = FeelingCatalog.searchFold(needle.toLowerCase());
    final customHits = data.customFeelings.where((c) => needle.isNotEmpty &&
        FeelingCatalog.searchFold(c.label.toLowerCase()).contains(exactLabel)).toList();
    final allTerms = [
      ...catalog.concepts.expand((c) => [...c.terms(true), ...c.terms(false)]),
      ...data.customFeelings.map((c) => c.label),
    ];
    final alreadyNamed = allTerms
        .any((t) => FeelingCatalog.searchFold(t.toLowerCase()) == exactLabel);
    final historical = FeelingSelector.history(logs: data.logs,
        feelings: data.feelingLogs, eng: eng, date: widget.day,
        maxItems: catalog.concepts.length + data.customFeelings.length)
      ..sort((a, b) {
        final cycles = b.cycles.compareTo(a.cycles);
        if (cycles != 0) return cycles;
        final recent = b.lastLogged.compareTo(a.lastLogged);
        return recent != 0 ? recent : a.concept.compareTo(b.concept);
      });
    final ranked = _suggest(catalog, stage, historical);
    final customs = [...data.customFeelings]..sort((a, b) {
      int index(String id) {
        final i = historical.indexWhere((h) => h.concept == id);
        return i < 0 ? historical.length : i;
      }
      return index(a.concept).compareTo(index(b.concept));
    });
    final selectedList = _selected.values.toList()
      ..sort((a, b) => feelingLabel(context, ref, a.concept)
          .compareTo(feelingLabel(context, ref, b.concept)));
    return Scaffold(
      appBar: AppBar(
        title: Text(l.feelingsTitle),
        actions: [
          IconButton(
            tooltip: l.feelingCustomManage,
            icon: const Icon(Icons.tune),
            onPressed: data.customFeelings.isEmpty
                ? _createCustom
                : _manageCustoms,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton(onPressed: _save, child: Text(_selected.isEmpty
            ? l.feelingClearSave : l.feelingSaveCount(_selected.length))),
      )),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                labelText: l.feelingSearch,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (selectedList.isNotEmpty)
            Card.filled(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: ListTile(
                title: Text('${l.feelingSelected} · ${selectedList.length}'),
                subtitle: Text(selectedList
                    .map((e) => feelingLabel(context, ref, e.concept))
                    .join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _showSelectedFeelings,
              ),
            ),
           Padding(
               padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
               child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (needle.isEmpty) ...[
                  Text(eng.canPredict
                      ? l.feelingSuggestedFor(stageName(l, stage))
                      : l.feelingSuggestedGeneral),
                  const SizedBox(height: 8),
                   Wrap(spacing: 8, runSpacing: 8, children: [
                     for (final c in customs.where((c) => historical.any((h) => h.concept == c.concept)))
                       _feelingChip(c.concept, c.label, catalog),
                     for (final c in ranked)
                      _feelingChip(c.id, c.label(isPt), catalog),
                  ]),
                  if (data.customFeelings.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(l.feelingYourOwn),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                       for (final c in customs.where((c) => !historical.any((h) => h.concept == c.concept)))
                        _feelingChip(c.concept, c.label, catalog),
                    ]),
                  ],
                 ] else if (hits.isEmpty && customHits.isEmpty) ...[
                  Text(l.searchEmpty,
                      style: Theme.of(context).textTheme.bodyMedium),
                  if (!alreadyNamed) ...[
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                        onPressed: _createCustom,
                        icon: const Icon(Icons.add),
                        label: Text(l.feelingCustomCreate)),
                  ],
                ] else ...[
                   Text(l.feelingSearchResults(hits.length + customHits.length)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                     for (final c in hits) _feelingChip(c.id, c.label(isPt), catalog),
                     for (final c in customHits) _feelingChip(c.concept, c.label, catalog),
                  ]),
                  if (!alreadyNamed && needle.length >= 2) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                        onPressed: _createCustom,
                        icon: const Icon(Icons.add),
                        label: Text(l.feelingCustomCreate)),
                  ],
                ],
               ]),
          ),
        ],
      ),
    );
  }

  Future<void> _showSelectedFeelings() async {
    final l = AppL.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            for (final e in _selected.values.toList()
              ..sort((a, b) => feelingLabel(context, ref, a.concept)
                  .compareTo(feelingLabel(context, ref, b.concept))))
              ListTile(
                title: Text(feelingLabel(context, ref, e.concept)),
                subtitle: Text(e.intensity == null
                    ? l.feelingIntensityNone
                    : intensityLabel(l, e.intensity!)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  PopupMenuButton<String>(
                    tooltip: l.feelingIntensityHint,
                    onSelected: (value) {
                      _setIntensity(e.concept,
                          value == 'none' ? null : FeelingIntensity.values.byName(value));
                      setSheet(() {});
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'none', child: Text(l.feelingIntensityNone)),
                      for (final intensity in FeelingIntensity.values)
                        PopupMenuItem(value: intensity.name, child: Text(intensityLabel(l, intensity))),
                    ],
                    icon: const Icon(Icons.tune),
                  ),
                  IconButton(
                    tooltip: l.feelingRemove,
                    onPressed: () {
                      setState(() => _selected.remove(e.concept));
                      setSheet(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
                ]),
              ),
          ],
        ),
      ),
    ));
  }

  /// Deterministic suggestion order for the *selected date*: reviewed
  /// stage-applicable concepts first, then the general pool — each internally
  /// rank-shuffled by the date seed so ordering is stable across rebuilds.
  List<FeelingConcept> _suggest(FeelingCatalog catalog, HistoryStage stage,
      List<HistoricalPick> historical) {
    final eng = ref.read(engineProvider(widget.day));
    final lateLuteal = eng.phaseForRecord(widget.day) == Phase.pms;
    int tier(FeelingConcept c) {
      final i = historical.indexWhere((h) => h.concept == c.id);
      if (i >= 0) return i;
      final stageRelevant = c.stages.contains(stage) &&
          (stage != HistoryStage.luteal || lateLuteal);
      return historical.length + (stageRelevant ? 0 : c.general ? 1 : 2);
    }
    int rank(String id) => SupportSelector.dayRank(id, widget.day);
    return [...catalog.concepts]..sort((a, b) {
      final relevance = tier(a).compareTo(tier(b));
      return relevance != 0 ? relevance : rank(a.id).compareTo(rank(b.id));
    });
  }

  Widget _feelingChip(String concept, String label, FeelingCatalog catalog) {
    final selected = _selected.containsKey(concept);
    return FilterChip(
      avatar: Icon(
          feelingCategoryIcon(
              catalog.byId(concept)?.category ?? FeelingCategory.neutral),
          size: 16),
      label: Text(label),
      selected: selected,
      onSelected: (_) => _toggle(concept),
    );
  }
}
