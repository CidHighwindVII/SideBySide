import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/cycle_engine.dart';
import '../../engine/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';

class LogDateScreen extends ConsumerWidget {
  final DateTime? initialDate;
  const LogDateScreen({this.initialDate, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    return Scaffold(appBar: AppBar(title: Text(l.logDateAction)),
      body: Center(child: FilledButton.icon(
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(l.calMarkStart),
        onPressed: () async {
          final today = ref.read(todayProvider);
          final picked = await showDatePicker(context: context,
              initialDate: initialDate ?? today, firstDate: DateTime(today.year - 1),
              lastDate: CycleEngine.addCalendarDays(today, 365));
          if (picked == null || !context.mounted) return;
          final logs = ref.read(appDataProvider).logs;
          if (logs.any((log) => CycleEngine.cycleTooShort(log.start, picked))) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.periodTooSoon)));
            return;
          }
          ref.read(appDataProvider.notifier).saveLog(PeriodLog(picked, null));
          Navigator.of(context).pop();
        },
      )));
  }
}
