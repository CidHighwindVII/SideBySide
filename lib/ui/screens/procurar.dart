import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalog.dart';
import '../../engine/models.dart';
import '../../state/providers.dart';
import '../widgets.dart';
import '../../l10n/gen/app_localizations.dart';

/// v0.2.0 (#17): in-memory word search over the whole catalog.
/// ~150 cards — a `where()` filter is sub-millisecond; no FTS, no deps.
class ProcurarScreen extends ConsumerStatefulWidget {
  const ProcurarScreen({super.key});

  @override
  ConsumerState<ProcurarScreen> createState() => _ProcurarScreenState();
}

class _ProcurarScreenState extends ConsumerState<ProcurarScreen> {
  final _query = ValueNotifier<String>('');
  Phase? _phase; // v0.6.0 (#6): filter results by phase

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    final catalogState = ref.watch(catalogProvider);
    final catalog = catalogState.valueOrNull;
    final isPt = ref.watch(langCodeProvider) == 'pt';
    final settings = ref.watch(appDataProvider).settings;

    return Scaffold(
      appBar: AppBar(title: Text(l.searchTitle)),
      body: catalog == null
          ? Center(child: catalogState.hasError
              ? Text(l.catalogUnavailable)
              : const CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable: _query,
              builder: (context, q, _) {
                final needle = q.trim().toLowerCase();
                return ListView(
                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                   children: [
                     TextField(
                       autofocus: true,
                       decoration: InputDecoration(
                         hintText: l.searchHint,
                         labelText: l.searchTitle,
                         prefixIcon: const Icon(Icons.search),
                         border: const OutlineInputBorder(),
                       ),
                       onChanged: (v) => _query.value = v,
                     ),
                     const SizedBox(height: 16),
                    // v0.6.0 (#6): type/phase filter — search or browse by phase
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: Text(l.searchAllPhases),
                          selected: _phase == null,
                          onSelected: (_) => setState(() => _phase = null),
                        ),
                        for (final p in Phase.values)
                          FilterChip(
                            label: Text(phaseName(l, p)),
                            selected: _phase == p,
                            onSelected: (v) =>
                                setState(() => _phase = v ? p : null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (needle.isEmpty && _phase == null)
                      Center(child: Text(l.searchHint))
                    else
                       ..._hits(catalog, needle, _phase, settings, isPt, l),
                  ],
                );
              },
            ),
    );
  }

  List<Widget> _hits(Catalog catalog, String needle, Phase? phase,
      Settings settings, bool isPt, AppL l) {
    final hits = <(Phase, CatalogItem)>[];
    for (final p in Phase.values) {
      if (phase != null && p != phase) continue;
      final pc = catalog[p];
      for (final section in [pc.actionable, pc.warnings, pc.context, pc.nutrition]) {
        final matches = section.where((item) => needle.isEmpty ||
            item.text(isPt).toLowerCase().contains(needle) ||
            item.pt.toLowerCase().contains(needle) ||
            item.en.toLowerCase().contains(needle)).toList();
        for (final item in PhaseCatalog.pick(matches, settings.liveTogether, 3,
            supportPriority: settings.intensiveSupport && p == Phase.luteal)) {
          hits.add((p, item));
        }
      }
    }
    if (hits.isEmpty) {
      return [Center(child: Text(l.searchEmpty))];
    }
    return [
      for (final (p, item) in hits)
         Padding(
           padding: const EdgeInsets.only(bottom: 8),
           child: Card.filled(
             color: Theme.of(context).colorScheme.surfaceContainerLow,
             child: Padding(
               padding: const EdgeInsets.all(16),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   PhaseBadge(p),
                   const SizedBox(height: 10),
                   Text(item.text(isPt),
                       style: Theme.of(context).textTheme.titleMedium),
                   if (item.why(isPt) != null) ...[
                     const SizedBox(height: 6),
                     Text(item.why(isPt)!),
                   ],
                 ],
               ),
             ),
           ),
         ),
    ];
  }
}
