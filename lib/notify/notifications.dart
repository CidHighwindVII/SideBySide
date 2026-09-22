import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../engine/cycle_engine.dart';
import '../engine/models.dart';
import '../l10n/gen/app_localizations.dart';
import '../log.dart';

/// Briefing + heads-up scheduling. Payloads: 'amanha' | 'hoje'.
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
    final s = data.settings;
    if (data.logs.isEmpty) return;
    final android =
        plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final exact = await android?.canScheduleExactNotifications() ?? false;
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final l10n = await AppL.delegate.load(Locale(_deviceLang()));
    if (revision != _revision) return;
    final now = tz.TZDateTime.now(tz.local);

    for (var i = 0; i < 14; i++) {
      if (revision != _revision) return;
      final day = DateTime(now.year, now.month, now.day + i);
      final eng = CycleEngine(settings: s, logs: data.logs, today: day, axes: axes);
      if (s.briefingEnabled && eng.shouldBriefTonight()) {
        // v0.2.0 (#9): Sat/Sun can use a separate briefing time.
        final weekend =
            s.weekendTimeEnabled && day.weekday >= DateTime.saturday;
        final when = tz.TZDateTime(
            tz.local, day.year, day.month, day.day,
            weekend ? s.weekendBriefingHour : s.briefingHour,
            weekend ? s.weekendBriefingMinute : s.briefingMinute);
        if (when.isAfter(now)) {
          await plugin.zonedSchedule(
              id: 1000 + i,
              title: l10n.notifBriefTitle,
               body: l10n.notifBriefBody,
              scheduledDate: when,
              notificationDetails: _details,
              androidScheduleMode: mode,
              payload: 'amanha');
        }
      }
      // silence halts everything (§4.8)
      if (s.headsUpEnabled && !eng.inSilenceMode) {
        final next = eng.nextExpectedStart();
        if (next != null && CycleEngine.daysBetween(day, next) == 2) {
          final when = tz.TZDateTime(tz.local, day.year, day.month, day.day, 9, 0);
          if (when.isAfter(now)) {
            await plugin.zonedSchedule(
                id: 2000 + i,
                title: l10n.notifHeadsUpTitle,
                body: l10n.notifHeadsUpBody,
                scheduledDate: when,
                notificationDetails: _details,
                androidScheduleMode: mode,
                payload: 'hoje');
          }
        }
      }
    }
  }

  String _deviceLang() =>
      PlatformDispatcher.instance.locale.languageCode.startsWith('pt') ? 'pt' : 'en';
}
