import 'dart:convert';

import '../engine/models.dart';

// ActionCategory + categoryFromName live in engine/models.dart (pure Dart) so
// the selector can depend on them without importing the data layer.

class CatalogItem {
  final String id; // stable language-independent slug (a:*)
  final String pt;
  final String en;
  final ItemTag tag;
  final ActionCategory category;
  final bool support; // v0.3.0 (#15): boosted when "apoio intensivo" is on
  final String? whyPt; // v0.6.0 (#8): one-line rationale, actionable cards only
  final String? whyEn;
  const CatalogItem(this.pt, this.en, this.tag,
      {this.id = '',
      this.category = ActionCategory.help,
      this.support = false,
      this.whyPt,
      this.whyEn});

  String text(bool isPt) => isPt ? pt : en;
  String? why(bool isPt) => isPt ? whyPt : whyEn;
}

class PhaseCatalog {
  final CatalogItem status;
  final Map<OutlookAxis, Traffic> axes;
  final List<CatalogItem> actionable;
  final List<CatalogItem> warnings;
  final List<CatalogItem> context;
  final List<CatalogItem> nutrition; // v0.2.0 (#5)

  const PhaseCatalog(
      {required this.status,
      required this.axes,
      required this.actionable,
      required this.warnings,
      required this.context,
      this.nutrition = const []});

  /// Filter by cohabitation tag (§4.1/D17) and cap to [n].
  /// With [supportPriority] (#15), `apoio`-flagged items come first —
  /// stable partition, not List.sort (which is not stable).
  static List<CatalogItem> pick(
          List<CatalogItem> items, bool liveTogether, int n,
          {bool supportPriority = false}) {
    final allowed = items.where((i) => switch (i.tag) {
          ItemTag.sempre => true,
          ItemTag.juntos => liveTogether,
          ItemTag.apartados => !liveTogether,
        });
    if (!supportPriority) return allowed.take(n).toList();
    return [
      ...allowed.where((i) => i.support),
      ...allowed.where((i) => !i.support),
    ].take(n).toList();
  }
}

class Catalog {
  final Map<Phase, PhaseCatalog> phases;
  final PhaseCatalog general;
  const Catalog(this.phases, this.general);

  PhaseCatalog operator [](Phase p) => phases[p]!;

  static Catalog parse(String source) {
    final root = jsonDecode(source) as Map<String, dynamic>;
    return Catalog(
      {for (final p in Phase.values) p: _phase(root[p.name] as Map<String, dynamic>)},
      _phase(root['general'] as Map<String, dynamic>, general: true),
    );
  }

  static PhaseCatalog _phase(Map<String, dynamic> j, {bool general = false}) {
    List<CatalogItem> list(String key) =>
        (j[key] as List? ?? []).map((e) => _item(e as Map<String, dynamic>)).toList();
    final axesJson = general ? <String, dynamic>{} : j['axes'] as Map<String, dynamic>;
    return PhaseCatalog(
      status: general
          ? const CatalogItem('', '', ItemTag.sempre)
          : _item(j['status'] as Map<String, dynamic>),
      axes: {
        for (final a in OutlookAxis.values)
          a: Traffic.values.firstWhere((t) => t.name == axesJson[a.name],
              orElse: () => Traffic.yellow)
      },
      actionable: list('actionable'),
      warnings: list('warnings'),
      context: list('context'),
      nutrition: list('nutrition'),
    );
  }

  static CatalogItem _item(Map<String, dynamic> j) {
    final why = j['why'] as Map<String, dynamic>?;
    return CatalogItem(
      j['pt'] as String,
      j['en'] as String,
      ItemTag.values.firstWhere((t) => t.name == (j['tag'] ?? 'sempre')),
      id: j['id'] as String? ?? '',
      category: categoryFromName(j['cat'] as String?),
      support: j['apoio'] == true,
      whyPt: why?['pt'] as String?,
      whyEn: why?['en'] as String?,
    );
  }

  /// Maps the legacy text-based feedback key `general:<pt>` to the stable
  /// catalog id, so old ratings/suppressions survive the switch to slugs
  /// (implementation.md P3). Empty-id items are skipped.
  Map<String, String> legacyActionIdMap() {
    final m = <String, String>{};
    for (final i in general.actionable) {
      if (i.id.isNotEmpty) m['general:${i.pt}'] = i.id;
    }
    return m;
  }
}
