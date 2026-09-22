import 'package:sidebyside/engine/models.dart';
import 'package:sidebyside/notify/schedule_plan.dart';
import 'package:test/test.dart';

DateTime at(int h) => DateTime(2026, 10, 5, h);

void main() {
  group('NotificationPlan — reminders are independent of cycle history', () {
    test('a personal reminder schedules with zero period logs', () {
      final data = AppData(
        settings: const Settings(),
        reminders: [Reminder(id: 7, title: 'Pick up', when: at(18))],
      );
      final plan = NotificationPlan.build(data, at(9));
      expect(plan.where((p) => p.kind == 'reminder').length, 1);
      expect(plan.first.payload, 'reminder:7');
    });
    test('no briefing/heads-up is produced without logs', () {
      final data = AppData(
        settings: const Settings(),
        reminders: [Reminder(id: 1, title: 'x', when: at(18))],
      );
      final plan = NotificationPlan.build(data, at(9));
      expect(plan.every((p) => p.kind == 'reminder'), isTrue);
    });
    test('done and past reminders are skipped', () {
      final data = AppData(
        settings: const Settings(),
        reminders: [
          Reminder(id: 1, title: 'done', when: at(18), done: true),
          Reminder(id: 2, title: 'past', when: at(7)),
          Reminder(id: 3, title: 'future', when: at(18)),
        ],
      );
      final plan = NotificationPlan.build(data, at(9));
      expect(plan.map((p) => p.id).toList(), [NotificationPlan.reminderId(3)]);
    });
    test('reminders beyond the rolling horizon are deferred', () {
      final data = AppData(
        settings: const Settings(),
        reminders: [
          Reminder(id: 1, title: 'far', when: DateTime(2026, 10, 40, 9)),
        ],
      );
      final plan = NotificationPlan.build(data, at(9));
      expect(plan, isEmpty);
    });
    test('ids never collide across reminder, briefing and heads-up ranges', () {
      final logs = [
        PeriodLog(DateTime(2026, 9, 1), DateTime(2026, 9, 5)),
        PeriodLog(DateTime(2026, 9, 29), DateTime(2026, 10, 3)),
        PeriodLog(DateTime(2026, 10, 27), DateTime(2026, 10, 31)),
      ];
      final data = AppData(
        settings: const Settings(contraception: Contraception.none),
        logs: logs,
        reminders: [
          Reminder(id: 1, title: 'a', when: at(10)),
          Reminder(id: 2, title: 'b', when: at(11)),
        ],
      );
      final plan = NotificationPlan.build(data, at(9));
      expect(NotificationPlan.idsUnique(plan), isTrue);
      // reminder ids sit in their own range, above the 14-day briefing window
      for (final p in plan.where((p) => p.kind == 'reminder')) {
        expect(p.id, greaterThanOrEqualTo(NotificationPlan.reminderBase));
      }
      for (final p in plan.where((p) => p.kind != 'reminder')) {
        expect(p.id, lessThan(NotificationPlan.reminderBase));
      }
    });
  });
}
