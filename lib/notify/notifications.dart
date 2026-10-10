import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../engine/models.dart';
import '../l10n/gen/app_localizations.dart';
import '../log.dart';
import 'schedule_plan.dart';

/// Briefing + heads-up scheduling. Payloads: 'tomorrow' | 'today'.
/// Legacy payloads 'amanha'/'hoje' (pre-rename schedules) are still routed
/// by `ui/app.dart`.
class Notifications {
  Notifications._();
  static final instance = Notifications._();

  final plugin = FlutterLocalNotificationsPlugin();
  final tapPayload = ValueNotifier<String?>(null);
  bool _ready = false;
  ({AppData data, Map<Phase, Map<OutlookAxis, Traffic>>? axes})? _requested;
  Future<void>? _running;
  int _revision = 0;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'briefing',
      'Briefings',
      channelDescription: 'Previsões diárias',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz
          .getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (r) => tapPayload.value = r.payload,
      );
      _ready = true;
      logInfo('notify', 'ready');
    } catch (e, s) {
      logErr('notify', e, s); // init failed — permission/reschedule calls no-op
    }
  }

  Future<String?> launchPayload() async {
    final launch = await plugin.getNotificationAppLaunchDetails();
    return launch?.didNotificationLaunchApp ?? false
        ? launch!.notificationResponse?.payload
        : null;
  }

  Future<bool?> requestPermission() async {
    if (!_ready) return null;
    return plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleSampleBriefing(String body) async {
    try {
      if (!_ready) return;
      await plugin.show(
          id: 999,
          title: 'SideBySide',
          body: body,
          notificationDetails: _details);
    } catch (e, s) {
      logErr('notify', e, s); // sample briefing failed
    }
  }

  /// Only one cancel/schedule pass may run at once. During a pass, keep the
  /// newest snapshot and cancel obsolete work before scheduling it. This
  /// prevents an older async pass from overwriting the latest notification set.
  Future<void> reschedule(AppData data,
      {Map<Phase, Map<OutlookAxis, Traffic>>? axes}) async {
    if (!_ready) return;
    _requested = (data: data, axes: axes);
    _revision++;
    _running ??= _drain();
    await _running;
  }

  Future<void> _drain() async {
    try {
      while (_requested != null) {
        final request = _requested!;
        final revision = _revision;
        _requested = null;
        try {
          await _reschedule(request.data, revision, request.axes);
          if (revision == _revision) logInfo('notify', 'rescheduled');
        } catch (e, s) {
          logErr('notify', e, s);
        }
      }
    } finally {
      _running = null;
    }
  }

  Future<void> _reschedule(AppData data, int revision,
      Map<Phase, Map<OutlookAxis, Traffic>>? axes) async {
    tz.setLocalLocation(tz
        .getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
    if (revision != _revision) return;
    await plugin.cancelAll();
    if (revision != _revision) return;
    final android =
        plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final exact = await android?.canScheduleExactNotifications() ?? false;
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final l10n = await AppL.delegate.load(Locale(_deviceLang()));
    if (revision != _revision) return;
    final now = tz.TZDateTime.now(tz.local);
    final plan = NotificationPlan.build(
        data, DateTime(now.year, now.month, now.day, now.hour, now.minute),
        axes: axes);

    for (final item in plan) {
      if (revision != _revision) return;
      final when = tz.TZDateTime(
          tz.local, item.at.year, item.at.month, item.at.day, item.at.hour, item.at.minute);
      if (!when.isAfter(now)) continue;
      // Lock-screen copy is always generic; reminder details stay in-app only.
      final title = switch (item.kind) {
        'reminder' => l10n.notifReminderTitle,
        'headsUp' => l10n.notifHeadsUpTitle,
        _ => l10n.notifBriefTitle,
      };
      final body = switch (item.kind) {
        'reminder' => l10n.notifReminderBody,
        'headsUp' => l10n.notifHeadsUpBody,
        _ => l10n.notifBriefBody,
      };
      await plugin.zonedSchedule(
          id: item.id,
          title: title,
          body: body,
          scheduledDate: when,
          notificationDetails: _details,
          androidScheduleMode: mode,
          payload: item.payload);
    }
  }

  String _deviceLang() =>
      PlatformDispatcher.instance.locale.languageCode.startsWith('pt') ? 'pt' : 'en';
}
