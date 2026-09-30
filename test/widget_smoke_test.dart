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

  testWidgets('Today foregrounds estimate, phase is opt-in detail', (tester) async {
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

    expect(find.text('Lútea'), findsNothing);
    expect(find.textContaining('Próximo período estimado'), findsOneWidget);
    expect(find.text('Esta ação foi útil para ti?'), findsOneWidget);
    await tester.tap(find.text('Ver fase aproximada (opcional)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Fase provável: Lútea'), findsOneWidget);
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

  testWidgets('Today action feedback rotates a declined suggestion',
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
    await tester.tap(find.text('Ver menos disto por 7 dias'));
    await tester.pumpAndSettle();
    expect(notifier.state.actionFeedback.length, 1);
    expect(notifier.state.actionFeedback.first.useful, isFalse);
    await tester.tap(find.text('Útil'));
    await tester.pumpAndSettle();
    expect(notifier.state.actionFeedback.length, 2);
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
    expect(find.textContaining('lembrete genérico'), findsOneWidget);
    await tester.tap(find.text('Continuar')); // → sample briefing
    await tester.pumpAndSettle();
    expect(find.text('É assim que vais receber'), findsOneWidget);
    await tester.tap(find.text('Continuar')); // → notifications
    await tester.pumpAndSettle();
    expect(find.text('Ligar notificações'), findsOneWidget);
    await tester.tap(find.text('Começar')); // finish
    await tester.pumpAndSettle();
    expect(notifier.state.settings.onboarded, isTrue);
    expect(find.text('Registar uma data'), findsOneWidget);
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

  testWidgets('support preferences, search and legacy observations',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    final notifier = await pumpApp(tester);

    // v0.10: "Na cozinha" removed; v0.11: content lives on the Sugestões tab
    expect(find.text('Na cozinha'), findsNothing);
    await tester.tap(find.text('Sugestões'));
    await tester.pumpAndSettle();
    expect(find.text('Dica do dia'), findsOneWidget);
    // search entry (#17)
    await tester.dragUntilVisible(find.text('Procurar ideias de apoio'),
        find.byType(ListView), const Offset(0, -150));
    await tester.tap(find.text('Procurar ideias de apoio'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'pergunta');
    await tester.pump();
    expect(find.textContaining('Pergunta o que seria útil'), findsWidgets);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(find.text('Adicionar preferência combinada'),
        find.byType(ListView), const Offset(0, -150));
    await tester.tap(find.text('Adicionar preferência combinada'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(TextField)),
        'prefiro ajuda com o jantar');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(notifier.state.preferences.length, 1);
    expect(find.text('prefiro ajuda com o jantar'), findsWidgets);
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(notifier.state.preferences, isEmpty);

    // Definições: weekend + support toggles (#15)
    await tester.tap(find.text('Definições'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hora diferente ao fim de semana'));
    await tester.pumpAndSettle();
    expect(notifier.state.settings.weekendTimeEnabled, isTrue);
    await tester.dragUntilVisible(find.text('Priorizar sugestões de ajuda'),
        find.byType(ListView), const Offset(0, -150));
    await tester.tap(find.text('Priorizar sugestões de ajuda'));
    await tester.pumpAndSettle();
    expect(notifier.state.settings.intensiveSupport, isTrue);

    // Existing observations remain accessible and editable in the calendar.
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
    expect(find.text('Variância dos ciclos'), findsOneWidget);
    await tester.tap(find.text('Calendário'));
    await tester.pumpAndSettle();
    expect(find.textContaining('±4 dias'), findsWidgets);
    expect(find.textContaining('±2 dias'), findsNothing);

    // Regular history still shows a buffered estimate, not a definite range.
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
    expect(find.textContaining('±2 dias'), findsWidgets);
    expect(find.text('janela fértil prevista'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  // Historic observations survive the redesign but no longer drive a pattern
  // card that implies behaviour by phase.
  testWidgets('historic observations remain stored without a phase pattern',
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

    // Existing tags still load from the same model.
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
    expect(find.text('Padrão das tuas notas'), findsNothing);
    expect(seeded.observations.length, 3);
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp(r'.*observação registada.*')), findsWidgets);
    semantics.dispose();
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
       await tester.dragUntilVisible(find.text('Procurar ideias de apoio'),
           find.byType(ListView), const Offset(0, -150));
       await tester.ensureVisible(find.text('Procurar ideias de apoio'));
       await tester.pumpAndSettle();
       await tester.tap(find.text('Procurar ideias de apoio'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'search @ $scale');
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'textScale $scale');
      await tester.binding.setSurfaceSize(null);
    }
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });

  testWidgets('Today shows picked support, uncertainty and timely preparation',
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
    expect(find.textContaining('Poucos registos'), findsOneWidget);
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

  testWidgets('no logs still shows a picked action and a direct logging path',
      (tester) async {
    await pumpApp(tester, data: const AppData(settings: Settings(onboarded: true)));
    expect(find.text('Dica do dia'), findsOneWidget);
    expect(find.text('Registar uma data'), findsOneWidget);
    await tester.tap(find.text('Registar uma data'));
    await tester.pumpAndSettle();
    expect(find.text('Marcar início do período'), findsOneWidget);
  });

  testWidgets('agreed preference leads Today without showing a phase',
      (tester) async {
    await pumpApp(tester, data: AppData(
      settings: const Settings(onboarded: true),
      preferences: [const SupportPreference(1, 'help', 'Make dinner together')],
    ));
    expect(find.text('Make dinner together'), findsOneWidget);
    expect(find.text('Ver fase aproximada (opcional)'), findsNothing);
  });

  testWidgets('declining three actions uncovers the next filtered catalog pick',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    final notifier = await pumpApp(tester,
        data: const AppData(settings: Settings(onboarded: true)));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Ver menos disto por 7 dias'));
      await tester.pumpAndSettle();
    }
    expect(notifier.state.actionFeedback.length, 3);
    expect(find.text('Pergunta se há alguma tarefa da casa que possas fazer'),
        findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('a declined action stays out of Suggestions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    await pumpApp(tester, data: const AppData(settings: Settings(onboarded: true)));
    await tester.tap(find.text('Ver menos disto por 7 dias'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sugestões'));
    await tester.pumpAndSettle();
    expect(find.text('Pergunta o que seria útil hoje e ouve a resposta'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('silence never shows the overdue date as next period',
      (tester) async {
    final today = DateTime(2026, 9, 30);
    await pumpApp(tester, today: today, data: AppData(
      settings: const Settings(onboarded: true),
      logs: [PeriodLog(DateTime(2026, 8, 1), null)],
    ));
    expect(find.textContaining('Próximo período estimado'), findsNothing);
    expect(find.textContaining('Sem previsão atual'), findsOneWidget);
    expect(find.text('Registar uma data'), findsOneWidget);
  });

  testWidgets('legacy phase notes can still be edited and removed',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    final notifier = await pumpApp(tester, data: const AppData(
      settings: Settings(onboarded: true),
      customCards: [CustomCard(Phase.luteal, 'old note')],
    ));
    await tester.tap(find.text('Sugestões'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(find.text('Notas antigas por fase (editar ou apagar)'),
        find.byType(ListView), const Offset(0, -150));
    await tester.tap(find.text('Notas antigas por fase (editar ou apagar)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('old note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextField)), 'edited note');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(notifier.state.customCards.single.text, 'edited note');
    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();
    expect(notifier.state.customCards, isEmpty);
    await tester.binding.setSurfaceSize(null);
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
