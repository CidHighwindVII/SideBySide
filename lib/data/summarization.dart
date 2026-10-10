import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../engine/models.dart';
import '../log.dart';

/// Outcomes of a runtime capability check against the on-device provider.
/// `installed AI apps do not imply an accessible local model` — the app only
/// trusts what this check returns, never assumptions.
enum SummaryCapability {
  available,
  needsDownload,
  unavailable,
  unsupportedLanguage,
  checkFailed,
}

SummaryCapability capabilityFromName(String name) =>
    SummaryCapability.values.firstWhere((c) => c.name == name,
        orElse: () => SummaryCapability.unavailable);

/// Platform seam for on-device summarization. Deliberately kept out of the
/// pure engine and out of the load/save/ranking path: nothing in core state
/// depends on it, and no user note text ever crosses this seam except into
/// the local provider itself — there is no cloud fallback anywhere.
abstract class SummarizationPlatform {
  /// Provider support check for a language code ('en', 'pt', …).
  Future<SummaryCapability> capability(String languageCode);

  Future<SummaryCapability> prepare(String languageCode);

  /// Local inference over joined note text. Throws [PlatformException] /
  /// [TimeoutException] on provider failure.
  Future<String> summarize(String text, String languageCode);

  /// Best-effort cancellation of the running inference.
  Future<void> cancel();
}

class MethodChannelSummarization implements SummarizationPlatform {
  static const _channel = MethodChannel('sidebyside/summarization');

  @override
  Future<SummaryCapability> capability(String languageCode) async {
    final state =
        await _channel.invokeMethod<String>('capability', {'lang': languageCode});
    return capabilityFromName(state ?? 'unavailable');
  }

  @override
  Future<SummaryCapability> prepare(String languageCode) async {
    final state = await _channel.invokeMethod<String>('prepare', {'lang': languageCode});
    return capabilityFromName(state ?? 'unavailable');
  }

  @override
  Future<String> summarize(String text, String languageCode) =>
      _channel.invokeMethod<String>('summarize',
              {'text': text, 'lang': languageCode})
          .then((value) => value ?? '');

  @override
  Future<void> cancel() => _channel.invokeMethod<void>('cancel');
}

/// Lifecycle of the History summary control.
enum SummaryStage {
  idle,
  checking,
  downloadable,
  unavailable,
  unsupportedLanguage,
  running,
  done,
  failed,
  cancelled,
}

/// Controller for one History summary panel. Results are transient by design:
/// summaries are presentation, never stored as records, and are dropped when
/// their source notes change (stale-work protection via [invalidate]).
class SummarizationController extends ChangeNotifier {
  SummarizationController(this._platform);

  final SummarizationPlatform _platform;

  SummaryStage _stage = SummaryStage.idle;
  String _summary = '';
  String _language = 'en';

  /// One counter guards probing and inference together: any mutation of the
  /// note set (edit/delete/wipe), a cancel, or a reset bumps it, so older
  /// async work can never publish into a newer view.
  int _gen = 0;
  bool _disposed = false;
  bool _available = false;

  SummaryStage get stage => _stage;
  String get summary => _summary;
  bool get busy => _stage == SummaryStage.checking || _stage == SummaryStage.running;
  /// Exposed for tests of stale-result rejection.
  int get generation => _gen;

  static const int _maxInputChars = 8000;
  static const int _minWords = 6;
  static const Duration _timeout = Duration(seconds: 45);

  /// Short-input rule: fewer than [_minWords] words or blank text is treated
  /// as insufficient — we never summarise noise into a false "pattern".
  static bool hasEnoughInput(List<QuickEntry> entries) {
    final words = entries.map((e) => e.text).join(' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .length;
    return words >= _minWords;
  }

  /// Notes are only summarised while the device language is provider-supported
  /// (documented set as of 2026-10: en/ja/ko). Portuguese is NOT promised.
  static bool isLanguageSupported(String lang) =>
      lang == 'en' || lang == 'ja' || lang == 'ko';

  /// Probing is triggered by the History panel when it has notes to offer.
  Future<void> probe({required List<QuickEntry> entries, required String lang}) async {
    if (_disposed) return;
    if (_stage == SummaryStage.running) unawaited(_cancelPlatform());
    final gen = ++_gen;
    _available = false;
    _summary = '';
    if (!isLanguageSupported(lang)) {
      _publish(SummaryStage.unsupportedLanguage, gen);
      return;
    }
    if (!hasEnoughInput(entries)) {
      _publish(SummaryStage.idle, gen);
      return;
    }
    _language = lang;
    _stage = SummaryStage.checking;
    notifyListeners();
    try {
      final cap = await _platform.capability(lang).timeout(_timeout);
      if (gen == _gen && !_disposed) _available = cap == SummaryCapability.available;
      _publish(_stageFor(cap), gen);
    } catch (e, s) {
      logErr('summarize', e, s);
      _publish(SummaryStage.unavailable, gen);
    }
  }

  Future<void> prepare() async {
    if (_disposed || _stage != SummaryStage.downloadable) return;
    final gen = ++_gen;
    _stage = SummaryStage.checking;
    notifyListeners();
    try {
      final cap = await _platform.prepare(_language).timeout(_timeout);
      if (gen == _gen && !_disposed) _available = cap == SummaryCapability.available;
      _publish(_stageFor(cap), gen);
    } catch (e, s) {
      logErr('summarize', e, s);
      _publish(SummaryStage.failed, gen);
    }
  }

  SummaryStage _stageFor(SummaryCapability cap) => switch (cap) {
        SummaryCapability.available => SummaryStage.idle,
        SummaryCapability.needsDownload => SummaryStage.downloadable,
        SummaryCapability.unavailable => SummaryStage.unavailable,
        SummaryCapability.unsupportedLanguage =>
          SummaryStage.unsupportedLanguage,
        SummaryCapability.checkFailed => SummaryStage.unavailable,
      };

  Future<void> summarize(List<QuickEntry> entries) async {
    if (_disposed || busy || !_available) return;
    final joined = entries
        .map((e) => e.text.trim())
        .where((t) => t.isNotEmpty)
        .join('\n');
    final clipped = joined.length > _maxInputChars
        ? joined.substring(0, _maxInputChars)
        : joined;
    if (!hasEnoughInput(entries)) return;
    final gen = ++_gen;
    _stage = SummaryStage.running;
    _summary = '';
    notifyListeners();
    try {
      final result =
          await _platform.summarize(clipped, _language).timeout(_timeout);
      _publish(SummaryStage.done, gen, text: result.trim());
    } on Exception catch (e, s) {
      if (gen != _gen) return; // a newer generation owns the panel
      if (e is TimeoutException) unawaited(_cancelPlatform());
      logErr('summarize', e, s);
      _publish(_stageForFailure(e), gen);
    }
  }

  SummaryStage _stageForFailure(Object e) {
    if (e is TimeoutException) return SummaryStage.failed;
    if (e is PlatformException && e.code == 'cancelled') {
      return SummaryStage.cancelled;
    }
    return SummaryStage.failed;
  }

  Future<void> cancelRun() async {
    if (_disposed || !busy) return;
    _gen++; // orphan the running future
    _stage = SummaryStage.cancelled;
    _summary = '';
    notifyListeners();
    try {
      await _platform.cancel();
    } catch (e, s) {
      logErr('summarize', e, s);
    }
  }

  /// Notes edited/deleted/wiped: drop any transient output and stale in-flight
  /// results — the panel must never show a summary over changed sources.
  void invalidate() {
    if (_disposed) return;
    final wasRunning = _stage == SummaryStage.running;
    _gen++;
    _available = false;
    _stage = SummaryStage.idle;
    _summary = '';
    notifyListeners();
    if (wasRunning) unawaited(_cancelPlatform());
  }

  Future<void> _cancelPlatform() async {
    try { await _platform.cancel(); }
    catch (e, s) { logErr('summarize', e, s); }
  }

  void reset() {
    invalidate();
    _stage = SummaryStage.idle;
    notifyListeners();
  }

  void _publish(SummaryStage stage, int gen, {String? text}) {
    if (_disposed || gen != _gen) return; // superseded work must not publish
    _stage = stage;
    if (text != null) _summary = text;
    notifyListeners();
  }

  @override
  void dispose() {
    final running = _stage == SummaryStage.running;
    _disposed = true;
    _gen++;
    if (running) unawaited(_cancelPlatform());
    super.dispose();
  }
}

/// Wipe/delete integration hook: callers that mutate notes notify the live
/// controller through this listener registry (kept off the store pipeline).
class SummarizationSessions {
  SummarizationSessions._();
  static final instance = SummarizationSessions._();
  final List<SummarizationController> _live = [];

  void register(SummarizationController c) => _live.add(c);
  void unregister(SummarizationController c) => _live.remove(c);
  void invalidateAll() => _live.toList().forEach((c) => c.invalidate());
}

/// Shared provider wiring lives in state/providers; this file stays free of
/// Riverpod so the adapter is testable with plain fakes.
final defaultSummarization = MethodChannelSummarization();

/// Test seam: historyProvider uses this when overridden in app startup.
SummarizationPlatform summarizationPlatformOverrideForTests =
    defaultSummarization;
