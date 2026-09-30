import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalog.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';

class ProcurarScreen extends ConsumerStatefulWidget {
  const ProcurarScreen({super.key});
  @override
  ConsumerState<ProcurarScreen> createState() => _ProcurarScreenState();
}

class _ProcurarScreenState extends ConsumerState<ProcurarScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    final state = ref.watch(catalogProvider);
    final catalog = state.valueOrNull;
    final isPt = ref.watch(langCodeProvider) == 'pt';
    final settings = ref.watch(appDataProvider).settings;
    if (catalog == null) return Scaffold(appBar: AppBar(title: Text(l.searchTitle)),
        body: Center(child: state.hasError ? Text(l.catalogUnavailable)
            : const CircularProgressIndicator()));
    final needle = _query.trim().toLowerCase();
    List<CatalogItem> search(List<CatalogItem> section) => PhaseCatalog.pick(
        section.where((i) => needle.isNotEmpty &&
            (i.pt.toLowerCase().contains(needle) ||
             i.en.toLowerCase().contains(needle))).toList(),
        settings.liveTogether, 3, supportPriority: settings.intensiveSupport);
    final hits = [
      ...search(catalog.general.actionable),
      ...search(catalog.general.warnings),
      ...search(catalog.general.context),
    ];
    return Scaffold(appBar: AppBar(title: Text(l.searchTitle)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(autofocus: true, onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(labelText: l.searchTitle,
              hintText: l.searchHint, prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder())),
        const SizedBox(height: 16),
        if (needle.isEmpty) Text(l.searchHint)
        else if (hits.isEmpty) Text(l.searchEmpty)
        else for (final item in hits)
          Card.outlined(child: ListTile(title: Text(item.text(isPt)),
              subtitle: item.why(isPt) == null ? null : Text(item.why(isPt)!))),
      ]));
  }
}
