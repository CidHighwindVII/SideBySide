import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/device.dart';
import '../../engine/models.dart';
import '../../state/providers.dart';
import '../lock.dart';
import '../../l10n/gen/app_localizations.dart';

class DefinicoesScreen extends ConsumerWidget {
  const DefinicoesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL.of(context);
    final s = ref.watch(appDataProvider).settings;
    final notifier = ref.read(appDataProvider.notifier);
    final eng = ref.watch(engineProvider(ref.watch(todayProvider)));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // v0.8.0 (#7): personal facts vs. app config split — Perfil holds
            // the profile-driven inputs, everything below is pure settings.
            Text(l.profileTitle, style: Theme.of(context).textTheme.titleMedium),
            Text(l.privacyIntro),
            Text(l.contraception),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final (value, label) in [
                (Contraception.none, l.contrNone),
                (Contraception.hormonal, l.contrHormonal),
                (Contraception.unknown, l.contrUnknown),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: s.contraception == value,
                  onSelected: (_) =>
                      notifier.updateSettings(s.copyWith(contraception: value)),
                ),
            ]),
            const SizedBox(height: 16),
            Text(l.liveTogether),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l.yes)),
                ButtonSegment(value: false, label: Text(l.no)),
              ],
              selected: {s.liveTogether},
              onSelectionChanged: (v) =>
                  notifier.updateSettings(s.copyWith(liveTogether: v.first)),
            ),
            const Divider(height: 32),
            // v0.6.0 (D20): averages are history-only — read-only, no sliders/pin.
            Text(l.avgTitle, style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${l.onbAvgCycle}: ${l.onbDays(eng.avgCycle)} — '
              '${eng.cycleGaps.length >= 3 ? l.avgAuto : l.avgFallback}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${l.onbAvgPeriod}: ${l.onbDays(eng.avgPeriod)} — '
              '${eng.periodLengths.length >= 3 ? l.avgAuto : l.avgFallback}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            // v0.3.0 (#15): user-declared support preference, no clinical
            // claims. v0.8.0 (#7): a content preference → belongs in Perfil.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.supportTitle),
              subtitle: Text(l.supportBody),
              value: s.intensiveSupport,
              onChanged: (v) =>
                  notifier.updateSettings(s.copyWith(intensiveSupport: v)),
            ),
            const Divider(height: 32),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.settingsBriefing),
              value: s.briefingEnabled,
              onChanged: (v) =>
                  notifier.updateSettings(s.copyWith(briefingEnabled: v)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.nightlight_outlined),
              title: Text(l.settingsBriefingTime),
              subtitle: Text(
                  '${s.briefingHour.toString().padLeft(2, '0')}:${s.briefingMinute.toString().padLeft(2, '0')}'),
              onTap: () async {
                final t = await showTimePicker(
                    context: context,
                    initialTime:
                        TimeOfDay(hour: s.briefingHour, minute: s.briefingMinute));
                if (t != null && context.mounted) {
                  notifier.updateSettings(ref.read(appDataProvider).settings.copyWith(
                      briefingHour: t.hour, briefingMinute: t.minute));
                }
              },
            ),
            // v0.2.0 (#9): separate weekend briefing time
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.weekendTimeTitle),
              value: s.weekendTimeEnabled,
              onChanged: (v) =>
                  notifier.updateSettings(s.copyWith(weekendTimeEnabled: v)),
            ),
            if (s.weekendTimeEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.weekend_outlined),
                title: Text(l.weekendBriefingTime),
                subtitle: Text(
                    '${s.weekendBriefingHour.toString().padLeft(2, '0')}:${s.weekendBriefingMinute.toString().padLeft(2, '0')}'),
                onTap: () async {
                  final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                          hour: s.weekendBriefingHour,
                          minute: s.weekendBriefingMinute));
                  if (t != null && context.mounted) {
                    notifier.updateSettings(ref.read(appDataProvider).settings.copyWith(
                        weekendBriefingHour: t.hour,
                        weekendBriefingMinute: t.minute));
                  }
                },
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.settingsHeadsUp),
              value: s.headsUpEnabled,
              onChanged: (v) =>
                  notifier.updateSettings(s.copyWith(headsUpEnabled: v)),
            ),
            const Divider(height: 32),
            // v0.3.0 (#3): biometric gate + salted PIN fallback in the one JSON
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.lockTitle),
              subtitle: Text(l.lockBody),
              value: s.appLockEnabled,
              onChanged: (v) async {
                String? pin;
                if (v) {
                  pin = await askPin(context, setup: true);
                } else {
                  pin = await askPin(context, title: l.lockDisable);
                }
                if (pin == null) return;
                if (!context.mounted) return;
                final current = ref.read(appDataProvider).settings;
                if (v) {
                  final salt = newPinSalt();
                  notifier.updateSettings(current.copyWith(
                      appLockEnabled: true,
                      pinSalt: salt,
                      pinHash: hashPin(salt, pin)));
                } else {
                  if (current.pinSalt == null ||
                      hashPin(current.pinSalt!, pin) != current.pinHash) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(l.lockPinBad)));
                    }
                    return;
                  }
                  notifier.updateSettings(current.copyWith(
                      appLockEnabled: false, clearPin: true));
                }
              },
            ),
            const Divider(height: 32),
            // v0.4.0 (#7/#16): device surfaces — widget + calendar export
            if (deviceSurfacesAvailable)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.widgetTitle),
                subtitle: Text(l.widgetBody),
                value: s.widgetEnabled,
                onChanged: (v) =>
                    notifier.updateSettings(s.copyWith(widgetEnabled: v)),
              ),
            Text(l.dataTitle,
                style: Theme.of(context).textTheme.titleMedium),
            Text(l.privacyData),
            if (deviceSurfacesAvailable)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(l.calTitle),
                // v0.5.0 (#16): pick the target calendar, then confirm+write.
                onTap: () async {
                  final cals = await Device.listCalendars();
                  if (!context.mounted) return;
                  if (cals.isEmpty) {
                    _snack(context, l.deviceFail);
                    return;
                  }
                  var picked = cals.first.id;
                  final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => StatefulBuilder(
                            builder: (ctx, setState) => AlertDialog(
                              title: Text(l.calTitle),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(l.calBody,
                                      textAlign: TextAlign.start),
                                  const SizedBox(height: 8),
                                  for (final c in cals)
                                    ListTile(
                                      title: Text(c.name),
                                      trailing: picked == c.id
                                          ? const Icon(Icons.check)
                                          : null,
                                      onTap: () =>
                                          setState(() => picked = c.id),
                                    ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(l.cancel)),
                                FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(l.calTitle)),
                              ],
                            ),
                          ));
                  if (ok != true) return;
                  if (!await Device.writeToCalendar(calendarId: picked) &&
                      context.mounted) {
                    _snack(context, l.deviceFail);
                  }
                },
              ),
            const Divider(height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              // destructive affordance stays quiet — icon + text carry it,
              // no accent colour.
              leading: const Icon(Icons.delete_forever_outlined),
              title: Text(l.settingsWipe),
              onTap: () async {
                final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                          content: Text(l.settingsWipeConfirm),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(l.cancel)),
                            FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(l.settingsWipe)),
                          ],
                        ));
                if (ok == true && context.mounted) {
                  final messenger = ScaffoldMessenger.of(context);
                  final cleared = await ref.read(appDataProvider.notifier).wipe();
                  if (!cleared && messenger.mounted) {
                    messenger.showSnackBar(SnackBar(content: Text(l.deviceFail)));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _snack(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
