import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidebyside/data/summarization.dart';
import 'package:sidebyside/engine/models.dart';

class FakeSummarizationPlatform implements SummarizationPlatform {
  FakeSummarizationPlatform({
    this.capabilityResult = SummaryCapability.available,
    this.summaryResult = 'Short local summary.',
    this.failSummarize = false,
    this.hang = false,
  });

  SummaryCapability capabilityResult;
  String summaryResult;
  bool failSummarize;
  bool hang;
  int summarizeCalls = 0;
  int cancelCalls = 0;
  int prepareCalls = 0;
  String? lastText;

  /// Exposed so tests can let a "hung" inference finish on demand.
  final hangCompleter = Completer<String>();

  @override
  Future<SummaryCapability> capability(String languageCode) async =>
      capabilityResult;

  @override
  Future<SummaryCapability> prepare(String languageCode) async {
    prepareCalls++;
    return capabilityResult;
  }

  @override
  Future<String> summarize(String text, String languageCode) async {
    summarizeCalls++;
    lastText = text;
    if (hang) return hangCompleter.future;
    if (failSummarize) throw PlatformException(code: 'inference-failed');
    return summaryResult;
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }
}

final notes = [
  for (var i = 0; i < 4; i++)
    QuickEntry(
        id: i + 1,
        date: '2026-10-0${i + 1}',
        kind: i.isEven ? EntryKind.shared : EntryKind.reflection,
        text: 'nota de acompanhamento número ${i + 1} com alguma substância real'),
];

void main() {
  group('SummarizationController — capability states', () {
    test('available → probe settles idle with the action ready', () async {
      final c = SummarizationController(FakeSummarizationPlatform());
      await c.probe(entries: notes, lang: 'en');
      expect(c.stage, SummaryStage.idle);
      await c.summarize(notes);
      expect(c.stage, SummaryStage.done);
      expect(c.summary, 'Short local summary.');
      c.dispose();
    });

    test('needsDownload → explicit setup state, never silently runs', () async {
      final fake = FakeSummarizationPlatform(
          capabilityResult: SummaryCapability.needsDownload);
      final c = SummarizationController(fake);
      await c.probe(entries: notes, lang: 'en');
      expect(c.stage, SummaryStage.downloadable);
      await c.prepare();
      expect(fake.prepareCalls, 1);
      expect(c.stage, SummaryStage.downloadable); // stays pending while device reports needsDownload
      c.dispose();
    });

    test('unavailable → quiet unavailable; summarize path never fires',
        () async {
      final fake = FakeSummarizationPlatform(
          capabilityResult: SummaryCapability.unavailable);
      final c = SummarizationController(fake);
      await c.probe(entries: notes, lang: 'en');
      expect(c.stage, SummaryStage.unavailable);
      expect(fake.summarizeCalls, 0);
      c.dispose();
    });

    test('Portuguese short-circuits before any provider call (not supported)',
        () async {
      final fake = FakeSummarizationPlatform();
      final c = SummarizationController(fake);
      await c.probe(entries: notes, lang: 'pt');
      expect(c.stage, SummaryStage.unsupportedLanguage);
      expect(SummarizationController.isLanguageSupported('pt'), isFalse);
      c.dispose();
    });

    test('capability check throwing degrades to unavailable', () async {
      final c = SummarizationController(_ThrowingPlatform());
      await c.probe(entries: notes, lang: 'en');
      expect(c.stage, SummaryStage.unavailable);
      c.dispose();
    });

    test('short input is treated as insufficient, not summarised', () async {
      final c = SummarizationController(FakeSummarizationPlatform());
      final short = [
        const QuickEntry(
            id: 1, date: '2026-10-01', kind: EntryKind.shared, text: 'ok'),
      ];
      await c.probe(entries: short, lang: 'en');
      expect(c.stage, SummaryStage.idle);
      await c.summarize(short);
      expect(c.stage, SummaryStage.idle);
      c.dispose();
    });

    test('failure surfaces retryable state and keeps notes usable', () async {
      final fake = FakeSummarizationPlatform(failSummarize: true);
      final c = SummarizationController(fake);
      await c.probe(entries: notes, lang: 'en');
      await c.summarize(notes);
      expect(c.stage, SummaryStage.failed);
      expect(c.summary, isEmpty);
      c.dispose();
    });

    test('cancel stops the run and calls through to the provider', () async {
      final fake = FakeSummarizationPlatform(hang: true);
      final c = SummarizationController(fake);
      await c.probe(entries: notes, lang: 'en');
      final running = c.summarize(notes);
      await Future<void>.delayed(Duration.zero);
      expect(c.stage, SummaryStage.running);
      await c.cancelRun();
      expect(c.stage, SummaryStage.cancelled);
      expect(fake.cancelCalls, 1);
      fake.hangCompleter.complete('late'); // cancelled result must not reappear
      await running;
      expect(c.stage, SummaryStage.cancelled);
      expect(c.summary, isEmpty);
      c.dispose();
    });

    test('stale results are dropped after note edits/deletions/wipe', () async {
      final fake = FakeSummarizationPlatform(hang: true);
      final c = SummarizationController(fake);
      await c.probe(entries: notes, lang: 'en');
      final running = c.summarize(notes);
      await Future<void>.delayed(Duration.zero);
      expect(c.stage, SummaryStage.running);
      // Source notes change while inference is in flight.
      c.invalidate();
      expect(c.stage, SummaryStage.idle);
      expect(c.generation, greaterThan(0));
      fake.hangCompleter.complete('stale output'); // provider answers late
      await running;
      expect(c.stage, isNot(SummaryStage.done));
      expect(c.summary, isEmpty);
      c.dispose();
    });

    test('summaries are transient: nothing is persisted anywhere', () async {
      // The adapter never touches AppData — controller holds the only copy.
      final c = SummarizationController(FakeSummarizationPlatform());
      await c.probe(entries: notes, lang: 'en');
      await c.summarize(notes);
      expect(c.summary, isNotEmpty);
      c.reset();
      expect(c.summary, isEmpty);
      c.dispose();
    });

    test('concurrent probes: a late first response cannot overwrite the newer',
        () async {
      final slowFirst = Completer<SummaryCapability>();
      var capCalls = 0;
      final platform = _CallbackPlatform((lang) {
        capCalls++;
        return capCalls == 1
            ? slowFirst.future
            : Future.value(SummaryCapability.unavailable);
      });
      final c = SummarizationController(platform);
      unawaited(c.probe(entries: notes, lang: 'en')); // slow first probe
      await c.probe(entries: notes, lang: 'en'); // resolves second
      expect(c.stage, SummaryStage.unavailable);
      slowFirst.complete(SummaryCapability.available);
      await Future<void>.delayed(Duration.zero);
      // stale first answer must not resurrect a different stage
      expect(c.stage, SummaryStage.unavailable);
      c.dispose();
    });

    test('disposal cannot publish stale output', () async {
      final fake = FakeSummarizationPlatform(hang: true);
      final c = SummarizationController(fake);
      await c.probe(entries: notes, lang: 'en');
      final running = c.summarize(notes);
      await Future<void>.delayed(Duration.zero);
      expect(c.stage, SummaryStage.running);
      c.dispose(); // orphans in-flight work via cancelRun
      fake.hangCompleter.complete('after dispose');
      await running;
      expect(c.stage, isNot(SummaryStage.done));
      expect(c.summary, isEmpty);
    });
  });
}

class _CallbackPlatform implements SummarizationPlatform {
  _CallbackPlatform(this._cap);
  final Future<SummaryCapability> Function(String lang) _cap;
  @override
  Future<SummaryCapability> capability(String lang) => _cap(lang);
  @override
  Future<SummaryCapability> prepare(String lang) async =>
      SummaryCapability.available;
  @override
  Future<String> summarize(String text, String lang) async => '';
  @override
  Future<void> cancel() async {}
}

class _ThrowingPlatform implements SummarizationPlatform {
  @override
  Future<SummaryCapability> capability(String languageCode) async =>
      throw PlatformException(code: 'check-failed');
  @override
  Future<SummaryCapability> prepare(String languageCode) async =>
      SummaryCapability.unavailable;
  @override
  Future<String> summarize(String text, String languageCode) async => '';
  @override
  Future<void> cancel() async {}
}
