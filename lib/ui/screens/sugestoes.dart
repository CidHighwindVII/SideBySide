import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/models.dart';
import '../../state/providers.dart';
import '../widgets.dart';
import '../theme.dart';
import '../../l10n/gen/app_localizations.dart';
import 'procurar.dart';

/// v0.11: content moved out of the Dashboard — tip of the day, phase
/// suggestions/warnings/context, your notes and the catalog search.
class SugestoesScreen extends ConsumerWidget {
  const SugestoesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final data = ref.watch(appDataProvider);
    final s = data.settings;
    final day = ref.watch(todayProvider);
    final eng = ref.watch(engineProvider(day));
    final catalogState = ref.watch(catalogProvider);
    final catalog = catalogState.valueOrNull;
    final isPt = ref.watch(langCodeProvider) == 'pt';
    final phase = eng.phaseOrNull(day);

    if (catalog == null) {
      return SafeArea(
          child: Center(
              child: catalogState.hasError
                  ? Text(l.catalogUnavailable)
                  : const CircularProgressIndicator()));
    }
    if (data.logs.isEmpty || phase == null) {
      return SafeArea(
        child: Center(
            child: Text(data.logs.isEmpty ? l.noDataYet : l.noForecast)),
      );
    }

    final support = s.intensiveSupport && phase == Phase.luteal;
    final picks = phasePicks(catalog[phase], s, support: support);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            PhaseBadge(phase),
            ConfidenceChip(eng.confidence),
          ]),
          const SizedBox(height: 16),
          // The lead action comes from the same filtered pick as the rest.
          if (picks.actionable.isNotEmpty) ...[
            SupportActionCard(
              title: l.tipOfDayTitle,
              action: picks.actionable.first.text(isPt),
              why: picks.actionable.first.why(isPt),
            ),
            const SizedBox(height: 12),
          ],
          Section(title: l.suggestionsTitle, icon: Icons.lightbulb_outline, items: [
            for (final i in picks.actionable.skip(1)) (i.text(isPt), null)
          ]),
          _NotesSection(phase: phase),
          Section(title: l.warningsTitle, icon: Icons.do_not_disturb_alt_outlined, items: [
            for (final i in picks.warnings) (i.text(isPt), null)
          ]),
          Section(title: l.contextTitle, icon: Icons.wb_twilight, items: [
            for (final i in picks.context) (i.text(isPt), null)
          ]),
          // v0.2.0 (#17): catalog search entry
          const SizedBox(height: 16),
          Card.filled(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: const Icon(Icons.search),
              title: Text(l.searchTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ProcurarScreen())),
            ),
          ),
        ],
      ),
    );
  }
}

/// v0.6.0 (#5): phase-bound notes; v0.11: lives in Sugestões, not Definições.
class _NotesSection extends ConsumerWidget {
  final Phase phase;
  const _NotesSection({required this.phase});

  Future<void> _add(BuildContext context, WidgetRef ref, AppL l) async {
    final text = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.customAdd),
        content: TextField(
          controller: text,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(labelText: l.customText),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
        ],
      ),
    );
    if (ok == true && text.text.trim().isNotEmpty) {
      ref
          .read(appDataProvider.notifier)
          .addCustomCard(CustomCard(phase, text.text.trim()));
    }
    // no dispose: the pop animation still reads the controller (GC handles it)
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final cards = ref
        .watch(appDataProvider)
        .customCards
        .where((c) => c.phase == phase)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(Icons.edit_note, l.customTitle,
            color: phaseColors[phase],
            trailing: IconButton(
              icon: const Icon(Icons.add),
              tooltip: l.customAdd,
              onPressed: () => _add(context, ref, l),
            )),
        for (final c in cards)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(c.text),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  ref.read(appDataProvider.notifier).deleteCustomCard(c),
            ),
          ),
      ],
    );
  }
}
