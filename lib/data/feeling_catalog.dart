import 'dart:convert';

import '../engine/models.dart';

/// Search categories agreed in `new-implementation.md`. Order is presentation
/// metadata only — every category stays searchable regardless of ranking.
enum FeelingCategory { emotion, physical, energy, sleep, focus, positive, neutral }

FeelingCategory feelingCategoryFromName(String? name) =>
    FeelingCategory.values.firstWhere((c) => c.name == name,
        orElse: () => FeelingCategory.neutral);

HistoryStage? historyStageFromName(String? name) {
  for (final s in HistoryStage.values) {
    if (s.name == name) return s;
  }
  return null;
}

/// A canonical feeling concept with stable English id, EN/PT-PT labels and
/// per-language search aliases. `stages` is evidence-backed applicability;
/// `general` is a separate editorial fallback flag and never follows from
/// searchability alone.
class FeelingConcept {
  final String id;
  final String en;
  final String pt;
  final FeelingCategory category;
  final List<String> aliasesEn;
  final List<String> aliasesPt;
  final Set<HistoryStage> stages;
  final bool general;
  final List<String> evidence;
  final Set<ActionCategory> supportCategories;

  const FeelingConcept({
    required this.id,
    required this.en,
    required this.pt,
    required this.category,
    this.aliasesEn = const [],
    this.aliasesPt = const [],
    this.stages = const {},
    this.general = false,
    this.evidence = const [],
    this.supportCategories = const {},
  });

  String label(bool isPt) => isPt ? pt : en;

  /// Every text a search query may hit, in one language.
  List<String> terms(bool isPt) =>
      [label(isPt), ...(isPt ? aliasesPt : aliasesEn)];

  /// Total searchable entries = one label per language plus every alias.
  int get searchableEntries => 2 + aliasesEn.length + aliasesPt.length;
}

/// One reviewed "how to respond" cue for a stage group.
class ResponseCue {
  final String en;
  final String pt;
  const ResponseCue(this.en, this.pt);
  String text(bool isPt) => isPt ? pt : en;
}

/// Packaged, reviewed feelings library. Separate from user data: it never
/// lives in the app-data JSON file, and custom user terms are never merged
/// into its general stage suggestions.
class FeelingCatalog {
  final List<FeelingConcept> concepts;
  final Map<HistoryStage, List<ResponseCue>> cues;
  final Map<String, FeelingEvidence> sources;

  const FeelingCatalog(this.concepts, this.cues, {this.sources = const {}});

  FeelingConcept? byId(String id) {
    for (final c in concepts) {
      if (c.id == canonicalFeelingId(id)) return c;
    }
    return null;
  }

  /// Canonical concepts eligible as general suggestions for [stage]:
  /// stage-applicable where reviewed, and for the unknown stage the explicitly
  /// curated everyday pool. Searchability alone never grants eligibility.
  List<String> eligibleFor(HistoryStage stage) => [
        for (final c in concepts)
          if (stage == HistoryStage.unknown
              ? c.general
              : c.stages.contains(stage))
            c.id,
      ];

  Set<String> get discomfortConcepts => {
    for (final c in concepts) if (c.supportCategories.isNotEmpty) c.id,
  };

  /// Accent- and case-insensitive search over EN/PT labels and aliases.
  List<FeelingConcept> search(String query) {
    final needle = searchFold(query.trim().toLowerCase());
    if (needle.isEmpty) return const [];
    return concepts
        .where((c) => [...c.terms(true), ...c.terms(false)]
            .any((t) => searchFold(t.toLowerCase()).contains(needle)))
        .toList();
  }

  /// Concepts ranked for [stage]: reviewed stage-applicable ones first, then
  /// the rest. Every concept remains findable through [search] regardless.
  List<FeelingConcept> rankFor(HistoryStage stage) => [
        ...concepts.where((c) => c.stages.contains(stage)),
        ...concepts.where((c) => !c.stages.contains(stage)),
      ];

  int get conceptCount => concepts.length;
  int get searchableEntryCount =>
      concepts.fold(0, (sum, c) => sum + c.searchableEntries);

  List<ResponseCue> cuesFor(HistoryStage stage) => cues[stage] ?? const [];

  static FeelingCatalog parse(String source) {
    final root = jsonDecode(source) as Map<String, dynamic>;
    final general = _strList(root['generalPool'] as List?).toSet();
    final associations = root['guidanceEvidence'] as Map<String, dynamic>? ?? {};
    final needs = root['supportNeeds'] as Map<String, dynamic>? ?? {};
    final sources = <String, FeelingEvidence>{
      for (final e in (root['sources'] as Map<String, dynamic>? ?? {}).entries)
        e.key: FeelingEvidence.fromJson(e.value as Map<String, dynamic>),
    };
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final raw in root['concepts'] as List? ?? []) {
      final j = raw as Map<String, dynamic>;
      grouped.putIfAbsent(canonicalFeelingId(j['id'] as String), () => []).add(j);
    }
    final canonicalIds = grouped.keys.toSet();
    final unknownGeneral = general.difference(canonicalIds);
    final unknownAssociations = associations.keys.toSet().difference(canonicalIds);
    final unknownNeeds = needs.keys.toSet().difference(canonicalIds);
    if (unknownGeneral.isNotEmpty || unknownAssociations.isNotEmpty || unknownNeeds.isNotEmpty) {
      throw FormatException('Feeling metadata references unknown IDs: '
          '${[...unknownGeneral, ...unknownAssociations, ...unknownNeeds].join(', ')}');
    }
    final concepts = <FeelingConcept>[];
    for (final entry in grouped.entries) {
      final j = entry.value.firstWhere((j) => j['id'] == entry.key,
          orElse: () => entry.value.first);
      final base = _concept(j);
      final refs = _strList(associations[entry.key] as List?);
      if (base.stages.isNotEmpty && refs.isEmpty) {
        throw FormatException('Stage-associated feeling lacks evidence: ${entry.key}');
      }
      if (refs.any((id) => !sources.containsKey(id))) {
        throw FormatException('Unknown feeling evidence: ${entry.key}');
      }
      final groupedStages = entry.value.expand((item) => _concept(item).stages).toSet();
      if (groupedStages.length > 1) {
        throw FormatException('Equivalent feeling IDs have conflicting stages: ${entry.key}');
      }
      final aliases = entry.value.map(_concept).toList();
      final supportCategoryNames = _strList(needs[entry.key] as List?);
      final unknownCategories = supportCategoryNames.where((name) =>
          !ActionCategory.values.any((category) => category.name == name));
      if (unknownCategories.isNotEmpty) {
        throw FormatException('Unknown support category for ${entry.key}: '
            '${unknownCategories.join(', ')}');
      }
      concepts.add(FeelingConcept(
        id: entry.key, en: base.en, pt: base.pt, category: base.category,
        aliasesEn: {for (final c in aliases) ...c.terms(false)}.difference({base.en}).toList(),
        aliasesPt: {for (final c in aliases) ...c.terms(true)}.difference({base.pt}).toList(),
        stages: refs.isEmpty ? const {} : groupedStages,
        general: general.contains(entry.key), evidence: refs,
        supportCategories: {
          for (final name in supportCategoryNames)
            ActionCategory.values.firstWhere((category) => category.name == name),
        },
      ));
    }
    final cues = <HistoryStage, List<ResponseCue>>{};
    final cuesJson = root['cues'] as Map<String, dynamic>? ?? {};
    for (final entry in cuesJson.entries) {
      final stage = historyStageFromName(entry.key);
      if (stage == null) continue;
      cues[stage] = ((entry.value as List? ?? [])
          .map((c) => ResponseCue(
              c['en'] as String? ?? '', c['pt'] as String? ?? ''))
          .toList());
    }
    return FeelingCatalog(concepts, cues, sources: sources);
  }

  static List<String> _strList(List? l) =>
      [for (final e in l ?? const []) e as String];

  static FeelingConcept _concept(Map<String, dynamic> j) {
    final aliases = j['aliases'] as Map<String, dynamic>? ?? {};
    return FeelingConcept(
      id: j['id'] as String,
      en: j['en'] as String? ?? '',
      pt: j['pt'] as String? ?? '',
      category: feelingCategoryFromName(j['cat'] as String?),
      aliasesEn: _strList(aliases['en'] as List?),
      aliasesPt: _strList(aliases['pt'] as List?),
      stages: {
        for (final s in _strList(j['stages'] as List?))
          if (historyStageFromName(s) != null) historyStageFromName(s)!,
      },
    );
  }

  /// Light accent folding so "inchaço" also matches "inchaco" queries and vice
  /// versa, in both languages.
  static String searchFold(String s) {
    const table = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'ñ': 'n', 'ý': 'y', 'ÿ': 'y',
    };
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final lower = ch.toLowerCase();
      final folded = table[lower];
      if (folded == null) {
        b.write(ch);
      } else {
        b.write(lower == ch ? folded : folded.toUpperCase());
      }
    }
    return b.toString();
  }
}

class FeelingEvidence {
  final String url;
  final ResponseCue title;
  final ResponseCue limits;
  const FeelingEvidence(this.url, this.title, this.limits);
  factory FeelingEvidence.fromJson(Map<String, dynamic> j) => FeelingEvidence(
    j['url'] as String,
    ResponseCue(j['en'] as String, j['pt'] as String),
    ResponseCue(j['limits']['en'] as String, j['limits']['pt'] as String),
  );
}
