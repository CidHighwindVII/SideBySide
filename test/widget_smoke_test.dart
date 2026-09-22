import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sidebyside/data/catalog.dart';
import 'package:sidebyside/data/store.dart';
import 'package:sidebyside/engine/models.dart';
import 'package:sidebyside/state/providers.dart';
import 'package:sidebyside/ui/app.dart';

/// rootBundle asset loads don't survive multiple widget tests in one file.
final catalogOverride = catalogProvider
    .overrideWith((_) async => Catalog.parse(File('assets/catalog.json').readAsStringSync()));

void main() {
  // Language now follows the device — pin the test device to PT-PT so the
  // hardcoded PT assertions keep meaning the same thing. MaterialApp resolves
  // from `locales` (plural); langCodeProvider reads `locale` (singular), so
  // pin both.
  setUp(() {
    final d =
        WidgetsBinding.instance.platformDispatcher as TestPlatformDispatcher;
    d.localesTestValue = [const Locale('pt')];
    d.localeTestValue = const Locale('pt');
  });
  tearDown(() =>
      (WidgetsBinding.instance.platformDispatcher as TestPlatformDispatcher)
          .clearAllTestValues());

  testWidgets('Hoje renders phase card for a known log', (tester) async {
    final now = DateTime.now();
    // a period that started 20 days ago → luteal (day 21 of a 28-day cycle;
    // v0.9.0 D28 moved day 22+ into PMS)
    final start = DateTime(now.year, now.month, now.day - 20);
    final data = AppData(
      settings: const Settings(onboarded: true),
      logs: [PeriodLog(start, start.add(const Duration(days: 4)))],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogOverride,
        appDataProvider.overrideWith((_) => AppDataNotifier(Store(), data)),
      ],
      child: const SideBySideApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Lútea'), findsWidgets);
    expect(find.textContaining('do ciclo'), findsOneWidget);
    expect(find.textContaining('Próximo período'), findsOneWidget);
    // v0.6.0 (#7) ask card removed (UX pass): axis chips are gone from Hoje
    expect(find.text('É boa altura para…?'), findsNothing);
    await tester.dragUntilVisible(
        find.text('A previsão acertou?'),
        find.byType(ListView),
        const Offset(0, -150));
    expect(find.text('A previsão acertou?'), findsOneWidget);
  });

  testWidgets('calendar day tap marks and unmarks period start/end',
      (tester) async {
    final data = AppData(
      settings: const Settings(onboarded: true),
      logs: [],
    );
    final notifier = AppDataNotifier(Store(), data);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogOverride,
        appDataProvider.overrideWith((_) => notifier),
      ],
      child: const SideBySideApp(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendário'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar início do período'));
    await tester.pumpAndSettle();
    expect(notifier.state.logs.length, 1);
    expect(notifier.state.logs.first.end, isNull);

    // mark the end a few days later — same two-tap flow defines the range
    await tester.tap(find.text('19'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar fim do período'));
    await tester.pumpAndSettle();
    expect(notifier.state.logs.first.end, isNotNull);

    // unmark the end on day 19
    await tester.tap(find.text('19'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desmarcar fim do período'));
    await tester.pumpAndSettle();
    expect(notifier.state.logs.first.end, isNull);

    // unmark the start on day 15 removes the whole log
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desmarcar início do período'));
    await tester.pumpAndSettle();
    expect(notifier.state.logs, isEmpty);
  });

  testWidgets('calendar rejects a period start <21 days after a logged start',
      (tester) async {
    // tall surface so the day-20 cell isn't obscured by the bottom nav
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    final now = DateTime.now();
    final day15 = DateTime(now.year, now.month, 15);
    final notifier = AppDataNotifier(
        Store(),
        AppData(
            settings: const Settings(onboarded: true),
            logs: [PeriodLog(day15, null)]));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogOverride,
        appDataProvider.overrideWith((_) => notifier),
      ],
      child: const SideBySideApp(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendário'));
    await tester.pumpAndSettle();
    // day 20 is 5 days after the logged start — impossible, sheet warns
    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar início do período'));
    await tester.pump(); // snackbar timer would hang pumpAndSettle
    expect(notifier.state.logs.length, 1);
    expect(find.textContaining('pelo menos 21 dias'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  // Click-everything smoke: flutter_test fails the test if any tap throws,
  // so these assert "no exceptions across all interactive features".
  AppData lutealData() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - 20); // day 21 → luteal
    return AppData(
      settings: const Settings(onboarded: true),
      logs: [PeriodLog(start, start.add(const Duration(days: 4)))],
    );
  }

  Future<AppDataNotifier> pumpApp(WidgetTester tester,
      {AppData? data, DateTime? today}) async {
    final notifier = AppDataNotifier(Store(), data ?? lutealData());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogOverride,
        if (today != null) todayProvider.overrideWithValue(today),
        appDataProvider.overrideWith((_) => notifier),
      ],
      child: const SideBySideApp(),
    ));
    await tester.pumpAndSettle();
    return notifier;
  }

  testWidgets('clicking every tab, setting control and dialog is exception-free',
      (tester) async {
    // tall surface so no control hides under the nav bar / FAB
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    await pumpApp(tester);
    for (final tab in [
      'Calendário',
      'Sugestões',
      'Definições',
      'Hoje',
      'Definições',
    ]) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
    }
    // segmented buttons: every option
    for (final opt in [
      'Nenhum', 'Hormonal', 'Desconhecido', // contraception
      'Sim', 'Não', 'Sim', // live together
    ]) {
      await tester.tap(find.text(opt));
      await tester.pumpAndSettle();
    }
    // v0.8.0 (#7): support toggle moved to Perfil, so .first is no longer
    // briefing — tap it by label.
    await tester.tap(find.text('Briefing de amanhã'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Lembrete de preparação')); // heads-up
    await tester.pumpAndSettle();
    // time picker opens and cancels
    await tester.tap(find.text('Hora do briefing'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar'), findsWidgets);
    await tester.tap(find.text('Cancelar').last);
    await tester.pumpAndSettle();
    // wipe dialog opens and is cancelled (never confirmed)
    await tester.dragUntilVisible(find.text('Apagar todos os dados'),
        find.byType(ListView), const Offset(0, -150));
    await tester.tap(find.text('Apagar todos os dados'));
    await tester.pumpAndSettle();
    expect(find.textContaining('remove todos os dados'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('clicking calendar navigation and day sheet is exception-free',
      (tester) async {
    await pumpApp(tester,
        data: const AppData(settings: Settings(onboarded: true)));
    await tester.tap(find.text('Calendário'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(find.text('Marcar início do período'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10)); // tap the barrier above the sheet
    await tester.pumpAndSettle();
    expect(find.text('Marcar início do período'), findsNothing);
  });

  // v0.10: horizontal swipe on the grid pages the calendar month
  testWidgets('swiping the calendar changes month', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    await pumpApp(tester,
        data: const AppData(settings: Settings(onboarded: true)));
    await tester.tap(find.text('Calendário'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final fmt = DateFormat('MMMM yyyy', 'pt');
    expect(find.text(fmt.format(now).toUpperCase()), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 800);
    await tester.pumpAndSettle();
    expect(find.text(fmt.format(DateTime(now.year, now.month + 1)).toUpperCase()),
        findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(300, 0), 800);
    await tester.pumpAndSettle();
    expect(find.text(fmt.format(now).toUpperCase()), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('clicking hoje preview and feedback controls is exception-free',
      (tester) async {
    // tall surface so the feedback row is fully visible
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    final notifier = await pumpApp(tester);
    // tomorrow preview → Amanhã screen → back
    await tester.tap(find.text('Ver amanhã ↓'));
    await tester.pumpAndSettle();
    expect(find.text('Amanhã'), findsWidgets);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    // feedback thumbs
    await tester.tap(find.byIcon(Icons.thumb_up_outlined).last);
    await tester.pumpAndSettle();
    expect(notifier.state.feedback.length, 1);
    await tester.tap(find.byIcon(Icons.thumb_down_outlined).last);
    await tester.pumpAndSettle();
    expect(notifier.state.feedback.length, 1);
    expect(notifier.state.feedback.first.thumbsUp, false);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('onboarding: setup-first, back-and-forth, walks all 5 steps',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    final notifier = AppDataNotifier(
        Store(), const AppData(settings: Settings()));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogOverride,
        appDataProvider.overrideWith((_) => notifier),
      ],
      child: const SideBySideApp(),
    ));
    await tester.pumpAndSettle();
    // language follows the device — step 0 is setup, no picker
    expect(find.text('Contracetivos'), findsOneWidget);
    // v0.6.0 (D20): setup still doesn't set averages — history-only
    expect(find.text('Duração média do ciclo'), findsNothing);
    // v0.8.0 (#4): forward to log and back to setup without losing the step
    await tester.tap(find.text('Continuar')); // → log step
    await tester.pumpAndSettle();
    expect(find.text('Regista o último período'), findsOneWidget);
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Contracetivos'), findsOneWidget);
    expect(notifier.state.settings.onboarded, isFalse);
    await tester.tap(find.text('Continuar')); // → log step
    await tester.pumpAndSettle();
    expect(find.text('Regista o último período'), findsOneWidget);
    await tester.tap(find.text('Saltar')); // → briefing time
    await tester.pumpAndSettle();
    expect(find.textContaining('uma previsão neutra de amanhã'), findsOneWidget);
    await tester.tap(find.text('Continuar')); // → sample briefing
    await tester.pumpAndSettle();
    expect(find.text('É assim que vais receber'), findsOneWidget);
    await tester.tap(find.text('Continuar')); // → notifications
    await tester.pumpAndSettle();
    expect(find.text('Ligar notificações'), findsOneWidget);
    await tester.tap(find.text('Começar')); // finish
    await tester.pumpAndSettle();
    expect(notifier.state.settings.onboarded, isTrue);
    expect(find.textContaining('Toca num dia no Calendário'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  // Large text must remain legible: chips wrap instead of shrinking their copy.
  testWidgets('onboarding choices remain readable at 3× text scale',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1600));
    tester.platformDispatcher.textScaleFactorTestValue = 3.0; // = 3× scaler
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final notifier = AppDataNotifier(
        Store(), const AppData(settings: Settings()));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogOverride,
        appDataProvider.overrideWith((_) => notifier),
      ],
      child: const SideBySideApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Contracetivos'), findsOneWidget); // setup = step 0
    expect(tester.takeException(), isNull);
    expect(find.text('Desconhecido'), findsOneWidget);
    expect(find.byType(FittedBox), findsNothing);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('v0.2/v0.3/v0.6: tip, search, notes-on-Sugestões, observation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    final notifier = await pumpApp(tester);

    // v0.10: "Na cozinha" removed; v0.11: content lives on the Sugestões tab
    expect(find.text('Na cozinha'), findsNothing);
    await tester.tap(find.text('Sugestões'));
    await tester.pumpAndSettle();
    expect(find.text('Dica do dia'), findsOneWidget);
    // search entry (#17)
    await tester.dragUntilVisible(find.text('Procurar em todas as sugestões'),
        find.byType(ListView), const Offset(0, -150));
    await tester.tap(find.text('Procurar em todas as sugestões'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'chocolate');
    await tester.pump();
    expect(find.textContaining('chocolate'), findsWidgets);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // v0.6.0 (#5): custom note CRUD now lives on Sugestões, not Definições
    await tester.dragUntilVisible(find.text('As tuas notas'),
        find.byType(ListView), const Offset(0, -150));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(TextField)),
        'nota de teste');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(notifier.state.customCards.length, 1);
    expect(find.text('nota de teste'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(notifier.state.customCards, isEmpty);

    // Definições: weekend + support toggles (#15)
    await tester.tap(find.text('Definições'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hora diferente ao fim de semana'));
    await tester.pumpAndSettle();
    expect(notifier.state.settings.weekendTimeEnabled, isTrue);
    await tester.dragUntilVisible(find.text('Apoio intensivo'),
        find.byType(ListView), const Offset(0, -150));
    await tester.tap(find.text('Apoio intensivo'));
    await tester.pumpAndSettle();
    expect(notifier.state.settings.intensiveSupport, isTrue);

    // Calendar observation quick-log (#4)
    await tester.tap(find.text('Calendário'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registar observação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cólicas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(notifier.state.observations.length, 1);
    expect(notifier.state.observations.first.tags, ['colicas']);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('v0.6.0 (D20): averages are read-only — no sliders, no pin',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    await pumpApp(tester);
    await tester.tap(find.text('Definições'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(find.text('Médias usadas'),
        find.byType(ListView), const Offset(0, -150));
    // 1 log → <3 gaps → honest "starting average" source line, twice
    expect(find.textContaining('média inicial'), findsNWidgets(2));
    // the manual-override UI is gone
    expect(find.byType(Slider), findsNothing);
    expect(find.text('Fixar duração do ciclo'), findsNothing);
    expect(find.text('Fixar duração da menstruação'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  // v0.9.0 D27 + v0.10: low/medium confidence → ±bandDays band in the legend;
  // HIGH confidence now renders definite ranges (no ±). The variance-card
  // painter is private, so the calendar legend (same source) is the probe.
  testWidgets('v0.9.0 D27: low confidence → wider band in the UI',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    final now = DateTime.now();
    day(int back) => DateTime(now.year, now.month, now.day - back);

    // hormonal caps confidence at low → bandDays 4; variance card still paints
    await pumpApp(tester,
        data: AppData(
          settings: const Settings(
              onboarded: true, contraception: Contraception.hormonal),
          logs: [PeriodLog(day(49), day(45)), PeriodLog(day(21), day(17))],
        ));
    await tester.dragUntilVisible(find.text('Variância dos ciclos'),
        find.byType(ListView), const Offset(0, -150));
    expect(find.byType(CustomPaint), findsWidgets);
    await tester.tap(find.text('Calendário'));
    await tester.pumpAndSettle();
    expect(find.textContaining('±4 dias'), findsWidgets);
    expect(find.textContaining('±2 dias'), findsNothing);

    // regular 28-day history → high confidence → v0.10: definite ranges.
    // Re-pumping a same-type ProviderScope reuses the element and ignores
    // new overrides, so unmount first.
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpApp(tester,
        data: AppData(
          settings: const Settings(onboarded: true),
          logs: [
            for (final back in [105, 77, 49, 21])
              PeriodLog(day(back), day(back - 4)),
          ],
        ));
    await tester.tap(find.text('Calendário'));
    await tester.pumpAndSettle();
    expect(find.text('período previsto'), findsWidgets);
    expect(find.text('janela fértil prevista'), findsWidgets);
    expect(find.textContaining('±'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  // v0.9.0 D30: read-only pattern card from his own notes, bucketed by
  // engine-derived phase; renders nothing when there are no notes.
  testWidgets('v0.9.0 D30: pattern card renders seeded notes, empty-safe',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - 21);
    final base = AppData(
      settings: const Settings(onboarded: true),
      logs: [PeriodLog(start, start.add(const Duration(days: 4)))],
    );

    // empty-safe: no observations → no card at all
    await pumpApp(tester, data: base);
    await tester.tap(find.text('Calendário'));
    await tester.pumpAndSettle();
    expect(find.text('Padrão das tuas notas'), findsNothing);

    // day 22 = PMS (D28), day 21 = luteal, day 12 = ovulation
    final seeded = base.copyWith(observations: [
      Observation(DateFormat('yyyy-MM-dd').format(now), ['irritada']),
      Observation(DateFormat('yyyy-MM-dd')
          .format(DateTime(now.year, now.month, now.day - 1)), ['colicas']),
      Observation(DateFormat('yyyy-MM-dd')
          .format(DateTime(now.year, now.month, now.day - 10)), ['cansada']),
    ]);
    await tester.pumpWidget(const SizedBox.shrink()); // fresh scope, see D27
    await pumpApp(tester, data: seeded);
    await tester.tap(find.text('Calendário'));
    await tester.pumpAndSettle();
    final card = find.ancestor(
        of: find.text('Padrão das tuas notas'), matching: find.byType(Card));
    expect(card, findsOneWidget);
    for (final phase in ['PMS', 'Lútea', 'Ovulação']) {
      expect(find.descendant(of: card, matching: find.text(phase)),
          findsOneWidget,
          reason: phase);
    }
    // one note each → three "1" counters inside the card; caption keeps the frame
    expect(find.descendant(of: card, matching: find.text('1')), findsNWidgets(3));
    expect(
        find.descendant(of: card, matching: find.textContaining('não dados clínicos')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  // v0.12 (M3 restyle): Pixel 10 — 412×915 dp. Walk all tabs, the day sheet,
  // the wipe dialog and the search screen at 1.0× and 1.3× text scale; any
  // RenderFlex overflow lands in takeException and fails this test.
  testWidgets('v0.12: Pixel 10 size, all tabs, no overflow at 1.3× text',
      (tester) async {
    for (final scale in [1.0, 1.3]) {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      await tester.binding.setSurfaceSize(const Size(412, 915));
      await tester.pumpWidget(const SizedBox.shrink()); // fresh scope, see D27
      await pumpApp(tester);
      expect(tester.takeException(), isNull, reason: 'boot @ $scale');
      for (final tab in ['Calendário', 'Sugestões', 'Definições', 'Hoje']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'tab $tab @ $scale');
      }
      // day sheet opens and closes
      await tester.tap(find.text('Calendário'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      expect(find.text('Marcar início do período'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'day sheet @ $scale');
      await tester.tapAt(const Offset(10, 10)); // barrier
      await tester.pumpAndSettle();
      // wipe dialog opens and cancels
      await tester.tap(find.text('Definições'));
      await tester.pumpAndSettle();
      // centre the tile — at 915dp the list bottom sits under the nav bar
      await tester.dragUntilVisible(find.text('Apagar todos os dados'),
          find.byType(ListView), const Offset(0, -150));
      await tester.ensureVisible(find.text('Apagar todos os dados'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar todos os dados'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'wipe dialog @ $scale');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      // search screen renders
      await tester.tap(find.text('Sugestões'));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(find.text('Procurar em todas as sugestões'),
          find.byType(ListView), const Offset(0, -150));
      await tester.ensureVisible(find.text('Procurar em todas as sugestões'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Procurar em todas as sugestões'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'search @ $scale');
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'textScale $scale');
      await tester.binding.setSurfaceSize(null);
    }
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });

  testWidgets('Today shows picked support, context and timely preparation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    final today = DateTime(2026, 9, 30);
    final start = DateTime(2026, 9, 4);
    await pumpApp(tester,
        today: today,
        data: AppData(
          settings: const Settings(onboarded: true),
          logs: [PeriodLog(start, start.add(const Duration(days: 4)))],
        ));
    expect(find.text('Dica do dia'), findsOneWidget);
    expect(find.text('Preparar com cuidado'), findsOneWidget);
    expect(find.text('Para enquadramento'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('English locale resolves the preparation prompt', (tester) async {
    final d = WidgetsBinding.instance.platformDispatcher as TestPlatformDispatcher;
    d.localeTestValue = const Locale('en');
    d.localesTestValue = [const Locale('en')];
    final today = DateTime(2026, 9, 30);
    final start = DateTime(2026, 9, 4);
    await pumpApp(tester,
        today: today,
        data: AppData(
          settings: const Settings(onboarded: true),
          logs: [PeriodLog(start, start.add(const Duration(days: 4)))],
        ));
    expect(find.text('Prepare thoughtfully'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('calendar exposes full dated labels to assistive technology',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester);
    await tester.tap(find.text('Calendário'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'.*15.*')), findsWidgets);
    semantics.dispose();
  });
}
