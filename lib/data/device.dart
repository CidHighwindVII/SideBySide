import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../log.dart';

/// The surfaces that touch the device outside the app's own data file —
/// calendar writes (#16) and the home-screen widget (#7). All plugin
/// failures are caught here: callers get bool/null and show a snackbar.
class Device {
  static const widgetName = 'dev.sidebyside.sidebyside.CycleWidgetProvider';

  // ---------- #16 calendar ----------

  static const _calendar = MethodChannel('sidebyside/calendar');

  /// Visible calendars (empty list = failure or no permission granted).
  static Future<List<({int id, String name})>> listCalendars() async {
    try {
      final r = await _calendar.invokeMethod<List<Object?>>('listCalendars');
      return [
        for (final c in r ?? const <Object?>[])
          (id: (c as Map)['id'] as int, name: (c)['name'] as String? ?? '?'),
      ];
    } catch (e, s) {
      logErr('device', e, s); // calendar list failed
      return const [];
    }
  }

  /// Writes 14 all-day "SxS" events via the own Kotlin channel (see
  /// MainActivity.kt — device_calendar 4.x pins timezone <0.11, dead end).
  /// v0.5.0 (#16): optional [calendarId] from the picker; without one the
  /// channel keeps the first-visible-calendar fallback.
  static Future<bool> writeToCalendar({int? calendarId}) async {
    try {
      final r = await _calendar.invokeMethod<String>('addEvents', {
        'days': 14,
        'title': 'SxS',
        'calendarId': ?calendarId,
      });
      return r == 'ok';
    } catch (e, s) {
      logErr('device', e, s); // calendar write failed
      return false;
    }
  }

  // ---------- #7 home-screen widget ----------

  /// Writes widget labels to the home_widget SharedPreferences and nudges a
  /// refresh. When disabled, blanks the labels (no cycle data left behind).
  static Future<void> syncWidget(
      {required bool enabled,
      String phaseLabel = '',
      String dayLabel = '',
      int dotColor = 0xFF9E9E9E}) async {
    try {
      await HomeWidget.saveWidgetData<String>(
          'phaseLabel', enabled ? phaseLabel : 'SideBySide');
      await HomeWidget.saveWidgetData<String>('dayLabel', enabled ? dayLabel : '');
      await HomeWidget.saveWidgetData<int>('dotColor', enabled ? dotColor : 0xFF9E9E9E);
      await HomeWidget.updateWidget(qualifiedAndroidName: widgetName);
    } catch (e, s) {
      logErr('device', e, s); // widget sync failed (no plugin on win/web)
    }
  }
}

/// True where the device surfaces exist (calendar + widget are Android-only).
final bool deviceSurfacesAvailable = !kIsWeb && Platform.isAndroid;
