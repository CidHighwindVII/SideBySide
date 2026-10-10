import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalog.dart';
import '../../engine/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';
import '../widgets.dart';
import 'garden.dart';
import 'learning.dart';
import 'search.dart';

class SuggestionsScreen extends ConsumerWidget {
  const SuggestionsScreen({super.key});

  Future<void> _editLegacyNote(BuildContext context, WidgetRef ref,
      CustomCard card) async {
    final l = AppL.of(context);
    final controller = TextEditingController(text: card.text);
    final result = await showDialog<String>(context: context,
      builder: (ctx) => AlertDialog(title: Text(l.customTitle),
        content: TextField(controller: controller, maxLength: 180, maxLines: 3,
          decoration: InputDecoration(labelText: l.customText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(onPressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) Navigator.pop(ctx, text);
          }, child: Text(l.save)),
        ]));
    if (result != null && context.mounted) {
      ref.read(appDataProvider.notifier).updateCustomCard(card, result);
    }
  }

  Future<void> _editPreference(BuildContext context, WidgetRef ref,
      {SupportPreference? existing}) async {
    final l = AppL.of(context);
    final controller = TextEditingController(text: existing?.text);
    var category = existing?.category ?? 'checkIn';
    final result = await showDialog<({String text, String category})>(context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? l.preferenceAdd : l.preferenceEdit),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.preferenceConsent),
              DropdownButtonFormField<String>(initialValue: category,
                decoration: InputDecoration(labelText: l.preferenceCategory),
                items: [
                  DropdownMenuItem(value: 'checkIn', child: Text(l.preferenceCheckIn)),
                  DropdownMenuItem(value: 'help', child: Text(l.preferenceHelp)),
                  DropdownMenuItem(value: 'space', child: Text(l.preferenceSpace)),
                ], onChanged: (v) { if (v != null) setDialogState(() => category = v); }),
              TextField(controller: controller, maxLength: 180, maxLines: 3,
                  decoration: InputDecoration(labelText: l.preferenceText)),
            ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            FilledButton(onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, (text: text, category: category));
            }, child: Text(l.save)),
          ],
        )));
    // Dialog route may still be animating; no explicit dispose of its controller.
    if (result == null || !context.mounted) return;
    if (existing == null) {
      ref.read(appDataProvider.notifier).addPreference(result.category, result.text);
    } else {
      ref.read(appDataProvider.notifier).updatePreference(
          SupportPreference(existing.id, result.category, result.text));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final data = ref.watch(appDataProvider);
    final catalogState = ref.watch(catalogProvider);
    final catalog = catalogState.valueOrNull;
    final isPt = ref.watch(langCodeProvider) == 'pt';
    final today = ref.watch(todayProvider);
    if (catalog == null) return SafeArea(child: Center(child: catalogState.hasError
        ? Text(l.catalogUnavailable) : const CircularProgressIndicator()));
    final picks = phasePicks(catalog.general, data.settings,
        support: data.settings.intensiveSupport);
    final eligible = generalEligible(catalog.general, data.settings)
        .where((i) => !actionSuppressed(data, i.id, today))
        .toList();
    List<CatalogItem> byCat(ActionCategory c) =>
        eligible.where((i) => i.category == c).take(3).toList();
    IconData catIcon(ActionCategory c) => switch (c) {
          ActionCategory.help => Icons.handyman_outlined,
          ActionCategory.communicate => Icons.chat_bubble_outline,
          ActionCategory.company => Icons.people_outline,
          ActionCategory.space => Icons.self_improvement,
          ActionCategory.prepare => Icons.checklist_outlined,
        };
    return SafeArea(child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32), children: [
        Text(l.preferenceTitle, style: Theme.of(context).textTheme.titleLarge),
        Text(l.preferenceConsent),
        for (final p in data.preferences)
          Card.outlined(child: ListTile(title: Text(p.text),
            subtitle: Text(switch (p.category) {
              'help' => l.preferenceHelp, 'space' => l.preferenceSpace,
              _ => l.preferenceCheckIn,
            }),
            onTap: () => _editPreference(context, ref, existing: p),
            trailing: IconButton(tooltip: l.preferenceDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref.read(appDataProvider.notifier).deletePreference(p.id)))),
        TextButton.icon(onPressed: () => _editPreference(context, ref),
            icon: const Icon(Icons.add), label: Text(l.preferenceAdd)),
        const SizedBox(height: 12),
        SupportToday(general: catalog.general),
        const SizedBox(height: 12),
        Card.filled(child: ListTile(leading: const Icon(Icons.school_outlined),
          title: Text(l.learningTitle), subtitle: Text(l.learningIntro),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const LearningScreen())))),
        const SizedBox(height: 8),
        Section(title: l.catHelp, icon: catIcon(ActionCategory.help),
            items: [for (final i in byCat(ActionCategory.help)) (i.text(isPt), null)]),
        Section(title: l.catCommunicate, icon: catIcon(ActionCategory.communicate),
            items: [for (final i in byCat(ActionCategory.communicate)) (i.text(isPt), null)]),
        Section(title: l.catCompany, icon: catIcon(ActionCategory.company),
            items: [for (final i in byCat(ActionCategory.company)) (i.text(isPt), null)]),
        Section(title: l.catSpace, icon: catIcon(ActionCategory.space),
            items: [for (final i in byCat(ActionCategory.space)) (i.text(isPt), null)]),
        Section(title: l.catPrepare, icon: catIcon(ActionCategory.prepare),
            items: [for (final i in byCat(ActionCategory.prepare)) (i.text(isPt), null)]),
        Section(title: l.warningsTitle, icon: Icons.info_outline,
            items: [for (final i in picks.warnings) (i.text(isPt), null)]),
        Section(title: l.contextTitle, icon: Icons.menu_book_outlined,
            items: [for (final i in picks.context) (i.text(isPt), null)]),
        if (data.customCards.isNotEmpty) ExpansionTile(title: Text(l.legacyNotes),
          children: [for (final c in data.customCards)
            ListTile(title: Text(c.text), subtitle: Text(phaseName(l, c.phase)),
              onTap: () => _editLegacyNote(context, ref, c),
              trailing: IconButton(tooltip: l.preferenceDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref.read(appDataProvider.notifier).deleteCustomCard(c)))]),
        if (!data.settings.gardenHidden)
          Card.filled(child: ListTile(leading: const Icon(Icons.spa_outlined),
            title: Text(l.gardenTitle), subtitle: Text(l.gardenIntro),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const GardenScreen())))),
        Card.filled(child: ListTile(leading: const Icon(Icons.search),
          title: Text(l.searchTitle), trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const SearchScreen())))),
      ]));
  }
}
