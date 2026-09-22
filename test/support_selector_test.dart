import 'package:sidebyside/engine/support_selector.dart';
import 'package:test/test.dart';

DateTime d(int m, int day) => DateTime(2026, m, day);

const a = SelectableItem(id: 'a:x');
const b = SelectableItem(id: 'a:y');
const c = SelectableItem(id: 'a:z');
const pref = SelectableItem(id: 'preference:1', preferred: true);
const sup = SelectableItem(id: 'a:sup', support: true);

void main() {
  group('SupportSelector — determinism', () {
    test('same day + inputs → identical order (rebuild/restart stable)', () {
      final one = SupportSelector.order([a, b, c], d(10, 5));
      final two = SupportSelector.order([c, b, a], d(10, 5));
      expect(one, two);
    });
    test('different days rotate the leading pick', () {
      final items = [a, b, c, sup, pref];
      final leads = {
        for (final day in [d(10, 1), d(10, 2), d(10, 3), d(10, 4), d(10, 5)])
          SupportSelector.order(items, day).first,
      };
      // more than one distinct leader across five days → not date-fixed
      expect(leads.length, greaterThan(1));
    });
    test('a preference is not pinned to slot 0 on every day', () {
      var prefFirst = 0;
      for (var day = 1; day <= 20; day++) {
        if (SupportSelector.order([pref, a, b, c], d(10, day)).first ==
            'preference:1') {
          prefFirst++;
        }
      }
      // leads sometimes, but not always
      expect(prefFirst, greaterThan(0));
      expect(prefFirst, lessThan(20));
    });
  });

  group('SupportSelector — filtering and ranking', () {
    test('suppressed ids are removed', () {
      final order = SupportSelector.order([a, b, c], d(10, 5), suppressed: {'a:y'});
      expect(order, isNot(contains('a:y')));
      expect(order.length, 2);
    });
    test('recently completed items sink to the tail but stay available', () {
      final order = SupportSelector.order([a, b, c], d(10, 5),
          recentlyCompleted: {'a:x'});
      expect(order.last, 'a:x');
      expect(order.length, 3);
    });
    test('supportPriority puts apoio items first (stable within rotation)', () {
      final order = SupportSelector.order([a, b, sup], d(10, 5), supportPriority: true);
      expect(order.first, 'a:sup');
    });
    test('without supportPriority, support is not forced first', () {
      // across many days, a plain item leads at least once
      var supFirst = 0;
      for (var day = 1; day <= 15; day++) {
        if (SupportSelector.order([a, sup], d(10, day)).first == 'a:sup') supFirst++;
      }
      expect(supFirst, lessThan(15));
    });
    test('empty candidates → empty order, leading null', () {
      final order = SupportSelector.order([a], d(10, 5), suppressed: {'a:x'});
      expect(order, isEmpty);
      expect(SupportSelector.leading(order, 0), isNull);
    });
  });

  group('SupportSelector — cursor / swap', () {
    test('leading wraps within bounds and is stable for a fixed order', () {
      final order = SupportSelector.order([a, b, c], d(10, 5));
      for (var i = 0; i < 6; i++) {
        expect(order.contains(SupportSelector.leading(order, i)), isTrue);
      }
      expect(SupportSelector.leading(order, 0), SupportSelector.leading(order, 0));
    });
  });
}
