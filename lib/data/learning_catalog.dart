import 'dart:convert';

/// A short bilingual learning card (implementation.md P4). Opening a card is
/// not completion — the user explicitly marks it done, which is what can earn a
/// garden `learn` moment. Nothing here asserts medical certainty; `source` is a
/// plain-language note, and phases are educational context only.
class QuizOption {
  final String pt;
  final String en;
  const QuizOption(this.pt, this.en);
  String text(bool isPt) => isPt ? pt : en;
}

class KnowledgeCheck {
  final String questionPt;
  final String questionEn;
  final List<QuizOption> options;
  final int answer;
  final String explainPt;
  final String explainEn;
  const KnowledgeCheck({
    required this.questionPt,
    required this.questionEn,
    required this.options,
    required this.answer,
    required this.explainPt,
    required this.explainEn,
  });

  String question(bool isPt) => isPt ? questionPt : questionEn;
  String explain(bool isPt) => isPt ? explainPt : explainEn;
}

/// A bilingual short text block used for lesson cards, takeaways and labels.
class BiText {
  final String pt;
  final String en;
  const BiText(this.pt, this.en);
  String text(bool isPt) => isPt ? pt : en;
}

/// A source link surfaced on demand ("Sources & deeper reading").
class LessonRef {
  final String labelPt;
  final String labelEn;
  final String url;
  const LessonRef(this.labelPt, this.labelEn, this.url);
  String label(bool isPt) => isPt ? labelPt : labelEn;
}

class LearningItem {
  final String id;
  final String titlePt;
  final String titleEn;
  final String bodyPt;
  final String bodyEn;
  final String sourcePt;
  final String sourceEn;
  final KnowledgeCheck? quiz;
  final String topic; // topic slug, resolved through [LearningCatalog.topics]
  final List<BiText> cards; // two or three short visual cards (~30-60 s read)
  final BiText? takeaway; // one practical takeaway
  final List<LessonRef> refs; // optional sources & deeper reading
  const LearningItem({
    required this.id,
    required this.titlePt,
    required this.titleEn,
    required this.bodyPt,
    required this.bodyEn,
    required this.sourcePt,
    required this.sourceEn,
    this.quiz,
    this.topic = 'basics',
    this.cards = const [],
    this.takeaway,
    this.refs = const [],
  });

  String title(bool isPt) => isPt ? titlePt : titleEn;
  String body(bool isPt) => isPt ? bodyPt : bodyEn;
  String source(bool isPt) => isPt ? sourcePt : sourceEn;
}

class LearningCatalog {
  final List<LearningItem> items;
  final Map<String, BiText> topics;

  const LearningCatalog(this.items, [this.topics = const {}]);

  static Map<String, String> _bi(Map<String, dynamic> j, String key) => {
        'pt': j[key]?['pt'] as String? ?? '',
        'en': j[key]?['en'] as String? ?? '',
      };

  static LearningItem _item(Map<String, dynamic> j) {
    KnowledgeCheck? quiz;
    final q = j['quiz'] as Map<String, dynamic>?;
    if (q != null) {
      quiz = KnowledgeCheck(
        questionPt: q['question']?['pt'] as String? ?? '',
        questionEn: q['question']?['en'] as String? ?? '',
        options: ((q['options'] as List? ?? [])
                .map((o) => QuizOption(o['pt'] as String? ?? '', o['en'] as String? ?? ''))
                .toList()),
        answer: q['answer'] as int? ?? 0,
        explainPt: q['explain']?['pt'] as String? ?? '',
        explainEn: q['explain']?['en'] as String? ?? '',
      );
    }
    final title = _bi(j, 'title');
    final body = _bi(j, 'body');
    final source = _bi(j, 'source');
    final takeaway = j['takeaway'] as Map<String, dynamic>?;
    return LearningItem(
      id: j['id'] as String,
      titlePt: title['pt']!, titleEn: title['en']!,
      bodyPt: body['pt']!, bodyEn: body['en']!,
      sourcePt: source['pt']!, sourceEn: source['en']!,
      quiz: quiz,
      topic: j['topic'] as String? ?? 'basics',
      cards: ((j['cards'] as List? ?? [])
              .map((c) => BiText(c['pt'] as String? ?? '',
                  c['en'] as String? ?? ''))
              .toList()),
      takeaway: takeaway == null
          ? null
          : BiText(takeaway['pt'] as String? ?? '',
              takeaway['en'] as String? ?? ''),
      refs: ((j['refs'] as List? ?? [])
              .map((r) => LessonRef(r['pt'] as String? ?? '',
                  r['en'] as String? ?? '', r['url'] as String? ?? ''))
              .toList()),
    );
  }

  static LearningCatalog parse(String source) {
    final root = jsonDecode(source) as Map<String, dynamic>;
    final topics = <String, BiText>{};
    for (final entry
        in (root['topics'] as Map<String, dynamic>? ?? {}).entries) {
      topics[entry.key] = BiText(
          entry.value['pt'] as String? ?? '',
          entry.value['en'] as String? ?? '');
    }
    return LearningCatalog(
      ((root['items'] as List? ?? [])
              .map((e) => _item(e as Map<String, dynamic>))
              .toList()),
      topics,
    );
  }

  /// Items in their topic's reading order; unknown topics sort last.
  List<LearningItem> byTopic() {
    final sorted = [...items];
    int rank(LearningItem i) {
      final keys = topics.keys.toList();
      final idx = keys.indexOf(i.topic);
      return idx < 0 ? keys.length : idx;
    }
    sorted.sort((a, b) {
      final byTopic = rank(a).compareTo(rank(b));
      return byTopic != 0 ? byTopic : a.id.compareTo(b.id);
    });
    return sorted;
  }

  LearningItem? byId(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }
}
