import 'package:sidebyside/engine/models.dart';
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
      final items = [a, b, c, sup];
      final leads = {
        for (final day in [d(10, 1), d(10, 2), d(10, 3), d(10, 4), d(10, 5)])
          SupportSelector.order(items, day).first,
      };
      // more than one distinct leader across five days → not date-fixed
      expect(leads.length, greaterThan(1));
    });
    test('explicit preferences rank before generic actions', () {
      expect(SupportSelector.order([a, pref, b, c], d(10, 5)).first,
          'preference:1');
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
      expect(SupportSelector.order([], d(10, 5)), isEmpty);
      expect(SupportSelector.leading([], 0), isNull);
    });
    test('boost raises previously-helpful ids to the front', () {
      final order = SupportSelector.order([a, b, c], d(10, 5), boost: {'a:z'});
      expect(order.first, 'a:z');
      expect(order.length, 3); // nothing removed
    });
    test('boost + supportPriority: feedback leads, both preserved', () {
      final order =
          SupportSelector.order([a, sup, b], d(10, 5), boost: {'a:x'}, supportPriority: true);
      // boosted first (stable partition), then apoio among the rest
      expect(order.first, 'a:x');
      expect(order.indexOf('a:sup'), lessThan(order.indexOf('a:y')));
    });
    test('recently-completed never leads over a boosted fresh item', () {
      final order = SupportSelector.order([a, b], d(10, 5),
          recentlyCompleted: {'a:x'}, boost: {'a:y'});
      expect(order.first, 'a:y');
    });
    test('a completed boosted action remains behind every fresh candidate', () {
      final order = SupportSelector.order([a, b], d(10, 5),
          recentlyCompleted: {'a:x'}, boost: {'a:x'});
      expect(order, ['a:y', 'a:x']);
    });
    test('empty and duplicate ids cannot share a selection identity', () {
      final order = SupportSelector.order([
        const SelectableItem(id: ''),
        a,
        a,
        b,
      ], d(10, 5));
      expect(order.toSet().length, order.length);
      expect(order, unorderedEquals(['a:x', 'a:y']));
    });
  });

  group('SupportSelector — cursor / swap', () {
    test('leading wraps within bounds and is stable for a fixed order', () {
      final order = SupportSelector.order([a, b, c], d(10, 5));
      for (var i = 0; i < 6; i++) {
        expect(order.contains(SupportSelector.leading(order, i)), isTrue);
      }
      expect(SupportSelector.leading(order, 0),
          SupportSelector.leading(order, 0));
    });
  });

  group('Support situations', () {
    test('Giving space never invites company or practical help categories', () {
      expect(SupportSituation.space.categories, {ActionCategory.space});
    });
    test('Listening maps to communication only', () {
      expect(SupportSituation.listening.categories, {ActionCategory.communicate});
    });
    test('apart/together override the cohabitation filter', () {
      expect(SupportSituation.apart.liveTogetherOverride, isFalse);
      expect(SupportSituation.together.liveTogetherOverride, isTrue);
      expect(SupportSituation.comfort.liveTogetherOverride, isNull);
    });
    test('apart keeps every category eligible', () {
      expect(SupportSituation.apart.categories, ActionCategory.values.toSet());
    });
    test('comfort excludes pure space items; space-excluding rule holds', () {
      expect(SupportSituation.comfort.categories,
          containsAll([ActionCategory.help, ActionCategory.prepare]));
      expect(SupportSituation.comfort.categories,
          isNot(contains(ActionCategory.space)));
    });
  });
}
