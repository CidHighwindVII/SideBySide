import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../engine/cycle_engine.dart';
import '../../engine/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';

/// Quick notes: information the partner shared, or the user's own reflection.
/// A reflection earns a `reflect` care moment; a shared-information note is
/// stored normally and does not. Entries can be converted into a preference or
/// a one-off reminder.
class QuickEntryScreen extends ConsumerWidget {
  final DateTime? day; // when set, the sheet starts pre-filled for that date
  const QuickEntryScreen({this.day, super.key});

  Future<void> _compose(BuildContext context, WidgetRef ref,
      {QuickEntry? existing}) async {
    final l = AppL.of(context);
    final controller = TextEditingController(text: existing?.text);
    var kind = existing?.kind ?? EntryKind.shared;
    final lang = ref.read(langCodeProvider);
    final today = ref.read(todayProvider);
    DateTime date = existing != null
        ? DateTime.parse(existing.date)
        : (day ?? today);
    final result = await showDialog<({EntryKind kind, DateTime date, String text})>(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
              return AlertDialog(
                title: Text(existing == null ? l.entryAdd : l.entryEdit),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.entryKindHint,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: [
                        ChoiceChip(
                            label: Text(l.entrySharedKind),
                            selected: kind == EntryKind.shared,
                            onSelected: (_) =>
                                setDialogState(() => kind = EntryKind.shared)),
                        ChoiceChip(
                            label: Text(l.entryReflectionKind),
                            selected: kind == EntryKind.reflection,
                            onSelected: (_) =>
                                setDialogState(() => kind = EntryKind.reflection)),
                      ]),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: Text(DateFormat('d MMM yyyy', lang).format(date)),
                        onTap: () async {
                          final now = CycleEngine.dateOnly(DateTime.now());
                          final picked = await showDatePicker(
                              context: ctx,
                              initialDate: date,
                              firstDate: DateTime(now.year - 1),
                              lastDate: CycleEngine.addCalendarDays(now, 365));
                          if (picked != null) setDialogState(() => date = picked);
                        },
                      ),
                      TextField(
                        controller: controller,
                        maxLength: 240,
                        maxLines: 3,
                        decoration: InputDecoration(labelText: l.entryPrompt),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l.cancel)),
                  FilledButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        Navigator.pop(ctx, (kind: kind, date: date, text: text));
                      },
                      child: Text(l.save)),
                ],
              );
            }));
    if (result == null || !context.mounted) return;
    final key = DateFormat('yyyy-MM-dd').format(result.date);
    final notifier = ref.read(appDataProvider.notifier);
    if (existing != null) {
      notifier.updateEntry(existing, result.text);
    } else if (result.kind == EntryKind.reflection) {
      notifier.saveReflection(key, result.text);
    } else {
      notifier.addEntry(key, EntryKind.shared, result.text);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final lang = ref.watch(langCodeProvider);
    final data = ref.watch(appDataProvider);
    final notifier = ref.read(appDataProvider.notifier);
    final entries = [...data.entries]
      ..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(title: Text(l.entriesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _compose(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l.entryAdd),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          for (final e in entries)
            Card.outlined(
              child: ListTile(
                leading: Icon(e.kind == EntryKind.reflection
                    ? Icons.self_improvement
                    : Icons.groups_outlined),
                title: Text(e.text),
                subtitle: Text(
                    '${DateFormat('d MMM yyyy', lang).format(DateTime.parse(e.date))} · '
                    '${e.kind == EntryKind.reflection ? l.entryReflectionKind : l.entrySharedKind}'),
                onTap: () => _compose(context, ref, existing: e),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    switch (v) {
                      case 'pref':
                        notifier.entryToPreference(e);
                        break;
                      case 'remind':
                        _toReminder(context, ref, e);
                        break;
                      case 'delete':
                        notifier.deleteEntry(e.id);
                        break;
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(value: 'pref', child: Text(l.entryToPreference)),
                    PopupMenuItem(value: 'remind', child: Text(l.entryToReminder)),
                    PopupMenuItem(value: 'delete', child: Text(l.entryDelete)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toReminder(BuildContext context, WidgetRef ref,
      QuickEntry entry) async {
    final l = AppL.of(context);
    final base = DateTime.parse(entry.date);
    final now = CycleEngine.dateOnly(DateTime.now());
    final date = await showDatePicker(
        context: context,
        initialDate: base.isBefore(now) ? now : base,
        firstDate: now,
        lastDate: CycleEngine.addCalendarDays(now, 365));
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (time == null || !context.mounted) return;
    final when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    ref.read(appDataProvider.notifier).entryToReminder(entry, when);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.reminderAdd)));
  }
}
