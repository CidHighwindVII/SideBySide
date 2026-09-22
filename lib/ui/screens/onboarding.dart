import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../engine/cycle_engine.dart';
import '../../engine/models.dart';
import '../../notify/notifications.dart';
import '../../state/providers.dart';
import '../../l10n/gen/app_localizations.dart';

/// §5.5 first-run flow: averages + contraception + cohabitation →
/// log last period → briefing time → sample briefing → POST_NOTIFICATIONS at
/// the end (§8). Language follows the device — no picker.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  DateTime? _start;
  DateTime? _end;

  static const _lastStep = 4;

  Future<void> _pickDate({required bool isStart}) async {
    final now = CycleEngine.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      // v0.8.0 (#3): the start picker opens on today; now is always inside
      // firstDate..lastDate so no clamp is needed.
      initialDate: isStart
          ? (_start ?? now)
           : (_end ?? CycleEngine.addCalendarDays(_start!, 4)),
      // v0.6.0 (#1): future start allowed (D2); (#2) end ≥ start+2 (min 3 days)
      firstDate: isStart ? DateTime(now.year - 1) : CycleEngine.addCalendarDays(_start!, 2),
      lastDate: CycleEngine.addCalendarDays(now, 365),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end != null && CycleEngine.periodTooShort(picked, _end!)) _end = null;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _next() async {
    final l = AppL.of(context);
    final notifier = ref.read(appDataProvider.notifier);
    if (_step == 1 && _start != null) {
      final end = _end != null && !CycleEngine.periodTooShort(_start!, _end!)
          ? _end
          : null;
      notifier.saveLog(PeriodLog(_start!, end));
    }
    if (_step == 4) {
      await Notifications.instance.requestPermission();
      await Notifications.instance.scheduleSampleBriefing(l.notifBriefBody);
      if (!mounted) return;
      notifier.updateSettings(
          ref.read(appDataProvider).settings.copyWith(onboarded: true));
      return;
    }
    setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    final s = ref.watch(appDataProvider).settings;
    final notifier = ref.read(appDataProvider.notifier);
    final lang = ref.watch(langCodeProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                    minHeight: 6, value: (_step + 1) / (_lastStep + 1)),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Icon(
                    switch (_step) {
                      0 => Icons.tune_outlined,
                      1 => Icons.calendar_today_outlined,
                      2 => Icons.schedule_outlined,
                      3 => Icons.notifications_active_outlined,
                      _ => Icons.notifications_outlined,
                    },
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(switch (_step) {
                    0 => l.onbSetupTitle,
                    1 => l.onbLogTitle,
                    2 => l.onbTimeTitle,
                    3 => l.onbSampleTitle,
                    _ => l.onbNotifyTitle,
                  }, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(switch (_step) {
                    0 => l.onbSetupBody,
                    1 => l.onbLogBody,
                    2 => l.onbTimeBody,
                    3 => l.onbSampleBody,
                    _ => l.onbNotifyBody,
                  }),
                  const SizedBox(height: 24),
                  ...switch (_step) {
                    0 => [
                      Text(l.avgFromLogs,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 24),
                      Text(l.contraception,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final (value, label) in [
                          (Contraception.none, l.contrNone),
                          (Contraception.hormonal, l.contrHormonal),
                          (Contraception.unknown, l.contrUnknown),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: s.contraception == value,
                            onSelected: (_) => notifier.updateSettings(
                                s.copyWith(contraception: value)),
                          ),
                      ]),
                      const SizedBox(height: 16),
                      Text(l.liveTogether,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(value: true, label: Text(l.yes)),
                          ButtonSegment(value: false, label: Text(l.no)),
                        ],
                        selected: {s.liveTogether},
                        onSelectionChanged: (v) => notifier.updateSettings(
                            s.copyWith(liveTogether: v.first)),
                      ),
                    ],
                    1 => [
                      Card.filled(child: ListTile(
                        leading: const Icon(Icons.play_circle_outline),
                        title: Text(l.onbLogStart),
                        subtitle: Text(_start == null
                            ? l.onbNotSet
                            : DateFormat('d MMM yyyy', lang).format(_start!)),
                        onTap: () => _pickDate(isStart: true),
                      )),
                      if (_start != null) ...[
                        const SizedBox(height: 8),
                        Card.filled(child: ListTile(
                          leading: const Icon(Icons.stop_circle_outlined),
                          title: Text(l.onbLogEnd),
                          subtitle: Text(_end == null
                              ? l.onbNotSet
                              : DateFormat('d MMM yyyy', lang).format(_end!)),
                          onTap: () => _pickDate(isStart: false),
                        )),
                      ],
                    ],
                    2 => [
                      Card.filled(child: ListTile(
                        leading: const Icon(Icons.nightlight_outlined),
                        title: Text(l.settingsBriefingTime),
                        subtitle: Text(
                            '${s.briefingHour.toString().padLeft(2, '0')}:${s.briefingMinute.toString().padLeft(2, '0')}'),
                        onTap: () async {
                          final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                  hour: s.briefingHour,
                                  minute: s.briefingMinute));
                          if (t != null) {
                            notifier.updateSettings(s.copyWith(
                                briefingHour: t.hour,
                                briefingMinute: t.minute));
                          }
                        },
                      )),
                    ],
                    3 => [
                      Card.filled(
                        child: ListTile(
                          leading: const Icon(Icons.notifications_active),
                          title: Text(l.notifBriefTitle),
                           subtitle: Text(l.notifBriefBody),
                          trailing: Text(
                              '${s.briefingHour.toString().padLeft(2, '0')}:${s.briefingMinute.toString().padLeft(2, '0')}'),
                        ),
                      ),
                    ],
                    _ => [
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          await Notifications.instance.requestPermission();
                          await Notifications.instance
                               .scheduleSampleBriefing(l.notifBriefBody);
                        },
                        icon: const Icon(Icons.notifications_outlined),
                        label: Text(l.onbNotifyAction),
                      ),
                    ],
                  },
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  // v0.8.0 (#4): real back navigation; _start/_end are state
                  // fields so a round-trip through the log step loses nothing.
                  if (_step > 0)
                    TextButton(onPressed: () => setState(() => _step--),
                        child: Text(l.onbBack)),
                  if (_step == 1)
                    TextButton(onPressed: () => setState(() => _step++),
                        child: Text(l.onbSkip)),
                  Text('${_step + 1}/${_lastStep + 1}'),
                  FilledButton(
                      onPressed: _next,
                      child: Text(_step == _lastStep ? l.onbDone : l.onbNext)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
