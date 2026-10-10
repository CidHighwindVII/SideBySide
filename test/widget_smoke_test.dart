import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sidebyside/data/catalog.dart';
import 'package:sidebyside/data/feeling_catalog.dart';
import 'package:sidebyside/data/learning_catalog.dart';
import 'package:sidebyside/data/store.dart';
import 'package:sidebyside/engine/cycle_engine.dart';
import 'package:sidebyside/engine/models.dart';
import 'package:sidebyside/l10n/gen/app_localizations.dart';
import 'package:sidebyside/state/providers.dart';
import 'package:sidebyside/ui/app.dart';
import 'package:sidebyside/ui/screens/feelings.dart';
import 'package:sidebyside/ui/screens/today.dart';
import 'package:sidebyside/ui/theme.dart';
import 'package:sidebyside/ui/widgets.dart';

/// rootBundle asset loads don't survive multiple widget tests in one file.
final catalogOverride = catalogProvider.overrideWith(
    (_) async => Catalog.parse(File('assets/catalog.json').readAsStringSync()));

final feelingsOverride = feelingCatalogProvider.overrideWith((_) async =>
    FeelingCatalog.parse(File('assets/feelings.json').readAsStringSync()));

final learningOverride = learningProvider.overrideWith((_) async =>
    LearningCatalog.parse(File('assets/learning.json').readAsStringSync()));

void main() {
  // Language follows the device — pin the test device to PT-PT. MaterialApp
  // resolves from `locales` (plural); langCodeProvider reads `locale`
  // (singular), so pin both.
  setUp(() {
    final d =
        WidgetsBinding.instance.platformDispatcher as TestPlatformDispatcher;
    d.localesTestValue = [const Locale('pt')];
    d.localeTestValue = const Locale('pt');
  });
  tearDown(() =>
      (WidgetsBinding.instance.platformDispatcher as TestPlatformDispatcher)
          .clearAllTestValues());

  // Fixed "today" for deterministic stage/feeling selection: start 2026-09-20
  // → day 21 (luteal) at 2026-10-10, predicted next start 2026-10-18 (~8d).
  final fixedToday = DateTime(2026, 10, 10);
  final lutealStart = DateTime(2026, 9, 20);
  AppData lutealData() => AppData(
        settings: const Settings(onboarded: true),
        logs: [PeriodLog(lutealStart, DateTime(2026, 9, 24))],
      );

  Future<AppDataNotifier> pumpApp(WidgetTester tester,
      {AppData? data, DateTime? today}) async {
    final notifier = AppDataNotifier(Store(), data ?? lutealData());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogOverride,
        feelingsOverride,
        learningOverride,
        todayProvider.overrideWithValue(today ?? fixedToday),
        appDataProvider.overrideWith((_) => notifier),
      ],
      child: const SideBySideApp(),
    ));
    await tester.pumpAndSettle();
    return notifier;
  }

  group('Today briefing', () {
    testWidgets('leads with countdown, feeling items and support entry',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      final notifier = await pumpApp(tester);
      expect(find.text('Próxima menstruação'), findsOneWidget);
      expect(find.text('~8 dias'), findsOneWidget);
      expect(find.textContaining('Previsto'), findsOneWidget);
      expect(find.text('Ela pode notar'), findsOneWidget);
      expect(find.text('Geral'), findsWidgets);
      expect(find.text('Como responder'), findsOneWidget);
      // Support is now a route, not an inline competing card
      expect(find.text('Dica do dia'), findsNothing);
      await tester.tap(find.text('Ver uma ideia de apoio'));
      await tester.pumpAndSettle();
      expect(find.text('Qual é a situação agora?'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      // calculation details stay behind the info control
      expect(find.textContaining('Poucos registos'), findsNothing);
      await tester.tap(find.byIcon(Icons.info_outline).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Poucos registos'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mostrar outras'));
      await tester.pumpAndSettle();
      expect(notifier.state.feelingRotations.single.cursor, 1);
      expect(find.text('Geral'), findsWidgets);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('logged feelings appear separately from possibilities',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      final data = lutealData().copyWith(feelingLogs: [
        const FeelingLog('2026-10-10', [FeelingEntry('cramps')]),
      ]);
      await pumpApp(tester, data: data);
      expect(find.text('Registado hoje'), findsOneWidget);
      expect(find.text('Cólicas'), findsWidgets);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('no logs shows honest no-data states', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      await pumpApp(tester,
          data: const AppData(settings: Settings(onboarded: true)));
      expect(find.textContaining('Ainda não há datas registadas'),
          findsOneWidget);
      expect(find.textContaining('As possibilidades gerais'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('silence never shows the overdue date as next period',
        (tester) async {
      await pumpApp(tester,
          today: DateTime(2026, 9, 30),
          data: AppData(
            settings: const Settings(onboarded: true),
            logs: [PeriodLog(DateTime(2026, 8, 1), null)],
          ));
      expect(find.textContaining('Sem previsão atual'), findsOneWidget);
    });

    testWidgets('hormonal mode: no estimates, no feeling suggestions',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      await pumpApp(tester,
          data: AppData(
            settings: const Settings(
                onboarded: true, contraception: Contraception.hormonal),
            logs: [PeriodLog(DateTime(2026, 9, 20), DateTime(2026, 9, 24))],
          ));
      expect(find.textContaining('Sem sugestões de sentimento'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Tomorrow stays a compact read-only preview', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      final notifier = await pumpApp(tester);
      await tester.tap(find.text('Amanhã').last);
      await tester.pumpAndSettle();
      expect(find.text('Amanhã'), findsWidgets);
      expect(find.text('Outra sugestão'), findsNothing);
      expect(find.text('Mostrar outras'), findsNothing);
      expect(notifier.state.selections, isEmpty);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('English locale resolves the briefing copy', (tester) async {
      final d = WidgetsBinding.instance.platformDispatcher
          as TestPlatformDispatcher;
      d.localeTestValue = const Locale('en');
      d.localesTestValue = [const Locale('en')];
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      await pumpApp(tester);
      expect(find.text('Next period'), findsOneWidget);
      expect(find.text('~8 days'), findsOneWidget);
      expect(find.text('She may notice'), findsOneWidget);
      expect(find.text('How to respond'), findsOneWidget);
      expect(find.text('See a support idea'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('Calendar', () {
    testWidgets('day sheet: feelings entry, start validation inline',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      final notifier = await pumpApp(tester);
      await tester.tap(find.text('Calendário'));
      await tester.pumpAndSettle();
      // day 2 is 12 days after the 2026-09-20 start — too close, disabled with
      // a visible reason and no snackbar
      await tester.tap(find.text('2').first);
      await tester.pumpAndSettle();
      expect(find.text('Marcar início do período'), findsOneWidget);
      expect(find.text('Demasiado perto de outro início registado'),
          findsOneWidget);
      await tester.tap(find.text('Marcar início do período'));
      await tester.pump();
      expect(notifier.state.logs.length, 1);
      expect(find.textContaining('pelo menos 21 dias'), findsNothing);
      expect(find.text('Sentimentos'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      // exactly 21 days after 2026-09-20 → 2026-10-11 may be marked
      await tester.tap(find.text('11'));
      await tester.pumpAndSettle();
      expect(find.text('Demasiado perto de outro início registado'),
          findsNothing);
      await tester.tap(find.text('Marcar início do período'));
      await tester.pumpAndSettle();
      expect(notifier.state.logs.length, 2);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('start/end marking still works on free days', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      final notifier = await pumpApp(tester,
          data: const AppData(settings: Settings(onboarded: true)));
      await tester.tap(find.text('Calendário'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar início do período'));
      await tester.pumpAndSettle();
      expect(notifier.state.logs.length, 1);
      expect(notifier.state.logs.first.end, isNull);
      await tester.tap(find.text('19'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar fim do período'));
      await tester.pumpAndSettle();
      expect(notifier.state.logs.first.end, isNotNull);
      await tester.tap(find.text('19'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desmarcar fim do período'));
      await tester.pumpAndSettle();
      expect(notifier.state.logs.first.end, isNull);
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desmarcar início do período'));
      await tester.pumpAndSettle();
      expect(notifier.state.logs, isEmpty);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('ovulation estimate is visible with its own marker',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      await pumpApp(tester);
      await tester.tap(find.text('Calendário'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ovulação estimada'), findsOneWidget);
      expect(find.byIcon(Icons.star_outline), findsWidgets);
      expect(find.text('dia de ovulação estimada'), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(tester,
          data: AppData(
            settings: const Settings(
                onboarded: true, contraception: Contraception.hormonal),
            logs: [PeriodLog(DateTime(2026, 9, 20), DateTime(2026, 9, 24))],
          ));
      await tester.tap(find.text('Calendário'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sem estimativa de ovulação'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('D27 band width + hormonal suppression in the legend',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      day(int back) => fixedToday.subtract(Duration(days: back));

      await pumpApp(tester,
          data: AppData(
            settings: const Settings(
                onboarded: true, contraception: Contraception.hormonal),
            logs: [PeriodLog(day(49), day(45)), PeriodLog(day(21), day(17))],
          ));
      await tester.tap(find.text('Calendário'));
      await tester.pumpAndSettle();
      expect(find.textContaining('±'), findsNothing);
      expect(find.textContaining('Sem estimativas'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(tester,
          data: AppData(
            settings: const Settings(
                onboarded: true, contraception: Contraception.none),
            logs: [PeriodLog(day(20), day(16))],
          ));
      await tester.tap(find.text('Calendário'));
      await tester.pumpAndSettle();
      expect(find.textContaining('±4 dias'), findsWidgets);
      expect(find.text('janela fértil estimada (6 dias)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(tester,
          data: AppData(
            settings: const Settings(
                onboarded: true, contraception: Contraception.none),
            logs: [
              for (final back in [105, 77, 49, 21])
                PeriodLog(day(back), day(back - 4)),
            ],
          ));
      await tester.tap(find.text('Calendário'));
      await tester.pumpAndSettle();
      expect(find.textContaining('±2 dias'), findsWidgets);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('logged feeling markers reach assistive tech', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester);
      await tester.tap(find.text('Calendário'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp(r'.*15.*')), findsWidgets);
      semantics.dispose();
    });

    testWidgets('swiping the calendar changes month', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      await pumpApp(tester,
          data: const AppData(settings: Settings(onboarded: true)));
      await tester.tap(find.text('Calendário'));
      await tester.pumpAndSettle();
      final fmt = DateFormat('MMMM yyyy', 'pt');
      expect(find.text(fmt.format(fixedToday).toUpperCase()), findsOneWidget);
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 800);
      await tester.pumpAndSettle();
      expect(
          find.text(
              fmt.format(DateTime(fixedToday.year, fixedToday.month + 1))
                  .toUpperCase()),
          findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('Feelings editor', () {
    testWidgets('select, intensity, save, reload, clear', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      final notifier = await pumpApp(tester);
      await tester.tap(find.text('Calendário'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sentimentos'));
      await tester.pumpAndSettle();
      // suggestions are never preselected beyond explicit saves
      expect(find.text('Guardar 0'), findsNothing);
      expect(find.textContaining('Selecionados'), findsNothing);
      final editorList = find.descendant(
          of: find.byType(FeelingsScreen), matching: find.byType(ListView));
      await tester.dragUntilVisible(
          find.text('Cólicas'), editorList, const Offset(0, -260),
          maxIteration: 140);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cólicas'));
      await tester.pumpAndSettle();
      // the selection tile sits at the top of the lazy list — scroll far back
      await tester.dragUntilVisible(
          find.textContaining('Selecionados'), editorList, const Offset(0, 500),
          maxIteration: 120);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Selecionados'));
      await tester.pumpAndSettle();
      // the selection sheet carries intensity (behind its own control) + removal
      expect(find.text('Sem intensidade'), findsOneWidget);
      await tester.tap(find.byTooltip('Definir intensidade'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forte'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10)); // dismiss the selection sheet
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar 1'));
      await tester.pumpAndSettle();
      expect(notifier.state.feelingLogs.single.date, '2026-10-10');
      expect(notifier.state.feelingLogs.single.entries.single.concept, 'cramps');
      expect(notifier.state.feelingLogs.single.entries.single.intensity,
          FeelingIntensity.strong);
      // reopen shows the saved selection in the tile and sheet
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sentimentos'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Selecionados'));
      await tester.pumpAndSettle();
      expect(find.text('Forte'), findsWidgets);
      // clearing the day: remove in the sheet, close, then save the empty set
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Selecionados'), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar (vazio limpa o dia)'));
      await tester.pumpAndSettle();
      expect(notifier.state.feelingLogs, isEmpty);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('search aliases and custom creation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      final notifier = await pumpApp(tester);
      await tester.tap(find.text('Calendário'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sentimentos'));
      await tester.pumpAndSettle();
      // accent-insensitive alias search (PT alias for cramps)
      await tester.enterText(find.byType(TextField), 'dores de barriga');
      await tester.pumpAndSettle();
      expect(find.text('1 resultados'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'totalmente inedito xyz');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Criar sentimento personalizado'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.descendant(
              of: find.byType(AlertDialog), matching: find.byType(TextField)),
          'zumbido');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      // searching the new custom name finds it AND the canonical ear-ringing
      // concept — the custom is auto-selected after creation.
      await tester.enterText(find.byType(TextField), 'zumbido');
      await tester.pumpAndSettle();
      expect(find.text('2 resultados'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'zumbido'), findsWidgets);
      expect(find.textContaining('Selecionados · 1'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar 1'));
      await tester.pumpAndSettle();
      expect(notifier.state.customFeelings.single.label, 'zumbido');
      expect(notifier.state.feelingLogs.single.entries.single.concept,
          'custom:1');
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('History + personalization', () {
    AppData twoCycles() {
      final starts = [
        DateTime(2026, 8, 20),
        DateTime(2026, 9, 10),
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 22),
      ];
      return AppData(
        settings:
            const Settings(onboarded: true, contraception: Contraception.none),
        logs: [
          for (final s in starts)
            PeriodLog(s, CycleEngine.addCalendarDays(s, 4)),
        ],
        feelingLogs: [
          const FeelingLog('2026-08-27', [FeelingEntry('good-mood')]),
          const FeelingLog('2026-09-17', [FeelingEntry('good-mood')]),
          const FeelingLog('2026-10-24', [FeelingEntry('cramps')]),
        ],
      );
    }

    testWidgets('Today shows historical provenance and links to the record',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      await pumpApp(tester, today: DateTime(2026, 10, 29), data: twoCycles());
      expect(find.text('Do histórico'), findsOneWidget);
      expect(find.text('Bom humor'), findsOneWidget);
      await tester.tap(find.text('Bom humor'));
      await tester.pumpAndSettle();
      expect(find.textContaining('2 ciclos anteriores'), findsOneWidget);
      // the link routes through the Calendar to the contributing record's date
      await tester.tap(find.text('Registar sentimentos nesta data'));
      await tester.pumpAndSettle();
      expect(find.text('Sentimentos'), findsWidgets); // date sheet on 17 Sep
      await tester.tap(find.text('Sentimentos'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Selecionados · 1'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10)); // dismiss the date sheet
      await tester.pumpAndSettle();
      // the pushed CalendarScreen has no app bar — use system back
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hoje'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mostrar outras'));
      await tester.pumpAndSettle();
      expect(find.text('Do histórico'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('calendar History button opens the four-stage grouped view',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      await pumpApp(tester, today: DateTime(2026, 10, 29), data: twoCycles());
      await tester.tap(find.text('Calendário'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Histórico'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ovulação'), findsWidgets);
      expect(find.textContaining('Menstrual'), findsWidgets);
      // a record row opens the editor for that date, prefilled from the log
      await tester.tap(find.textContaining('24 out'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Selecionados · 1'), findsOneWidget);
      await tester.tap(find.textContaining('Selecionados'));
      await tester.pumpAndSettle();
      expect(find.text('Cólicas'), findsWidgets);
      expect(find.text('Sem intensidade'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('Support', () {
    testWidgets('situation → one action → another → I did this', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      final notifier = await pumpApp(tester);
      await tester.tap(find.text('Ver uma ideia de apoio'));
      await tester.pumpAndSettle();
      expect(find.text('Qual é a situação agora?'), findsOneWidget);
      expect(find.text('Ouvir'), findsOneWidget);
      expect(find.text('Dar espaço'), findsOneWidget);
      expect(find.text('Estamos longe'), findsOneWidget);
      await tester.tap(find.text('Ouvir'));
      await tester.pumpAndSettle();
      expect(find.text('Para hoje'), findsOneWidget);
      expect(find.text('Outra ideia'), findsOneWidget);
      expect(find.text('Fiz isto'), findsOneWidget);
      expect(find.text('Porquê isto?'), findsOneWidget);
      expect(find.text('Esta ação foi útil para ti?'), findsNothing);
      await tester.tap(find.text('Porquê isto?'));
      await tester.pumpAndSettle();
      expect(find.text('Esta ação foi útil para ti?'), findsOneWidget);
      await tester.tap(find.text('Fiz isto'));
      await tester.pumpAndSettle();
      expect(notifier.state.completions, hasLength(1));
      expect(
          notifier.state.careEvents
              .where((c) => c.category == CareCategory.act)
              .length,
          1);
      await tester.tap(find.text('Outra ideia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mudar a situação'));
      await tester.pumpAndSettle();
      expect(find.text('Qual é a situação agora?'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Giving space never surfaces company or preparing items',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      await pumpApp(tester);
      await tester.tap(find.text('Ver uma ideia de apoio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dar espaço'));
      await tester.pumpAndSettle();
      final seen = <String>[];
      for (var i = 0; i < 8; i++) {
        final card = find.descendant(
            of: find.byType(SupportActionCard), matching: find.byType(Text));
        seen.add(tester.widget<Text>(card.at(1)).data!);
        await tester.tap(find.text('Outra ideia'));
        await tester.pumpAndSettle();
      }
      final joined = seen.join(' | ');
      expect(joined, isNot(contains('noite calma')));
      expect(joined, isNot(contains('Repõe o essencial')));
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('previously-helpful tag comes only from action feedback',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      final data = lutealData().copyWith(actionFeedback: [
        const ActionFeedback('2026-10-05', 'a:ask-what-helps', true),
      ]);
      await pumpApp(tester, data: data);
      await tester.tap(find.text('Ver uma ideia de apoio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ouvir'));
      await tester.pumpAndSettle();
      var sawTag = false;
      for (var i = 0; i < 10 && !sawTag; i++) {
        if (find.text('Já ajudou antes').evaluate().isNotEmpty) {
          sawTag = true;
          break;
        }
        await tester.tap(find.text('Outra ideia'));
        await tester.pumpAndSettle();
      }
      expect(sawTag, isTrue);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('What helps her keeps preferences and legacy notes editable',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      final notifier = await pumpApp(tester, data: const AppData(
        settings: Settings(onboarded: true),
        customCards: [CustomCard(Phase.luteal, 'old note')],
      ));
      await tester.tap(find.text('Ver uma ideia de apoio'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('O que a ajuda a ela'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar preferência combinada'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.descendant(
              of: find.byType(AlertDialog), matching: find.byType(TextField)),
          'prefiro ajuda com o jantar');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(notifier.state.preferences.length, 1);
      expect(find.text('old note'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('agreed preference is offered for its situation',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      await pumpApp(tester, data: AppData(
        settings: const Settings(onboarded: true),
        preferences: [const SupportPreference(1, 'help', 'Make dinner together')],
      ));
      await tester.tap(find.text('Ver uma ideia de apoio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajuda prática'));
      await tester.pumpAndSettle();
      var found = false;
      for (var i = 0; i < 15 && !found; i++) {
        if (find.text('Make dinner together').evaluate().isNotEmpty) {
          found = true;
          break;
        }
        await tester.tap(find.text('Outra ideia'));
        await tester.pumpAndSettle();
      }
      expect(found, isTrue);
      await tester.binding.setSurfaceSize(null);
    });
    testWidgets('contextual entry opens Comfort directly after logged discomfort',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      final data = lutealData().copyWith(feelingLogs: [
        const FeelingLog('2026-10-09', [
          FeelingEntry('low-energy', intensity: FeelingIntensity.strong),
        ]),
      ]);
      await pumpApp(tester, data: data);
      await tester.tap(find.text('Ver uma ideia de apoio'));
      await tester.pumpAndSettle();
      // straight into the comfort situation — no situation menu first
      expect(find.text('Qual é a situação agora?'), findsNothing);
      expect(find.text('Para hoje'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets("We're apart offers remote-friendly ideas even when living together",
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      await pumpApp(tester,
          data: lutealData().copyWith(
              settings: const Settings(onboarded: true, liveTogether: true)));
      await tester.tap(find.text('Ver uma ideia de apoio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Estamos longe'));
      await tester.pumpAndSettle();
      final seen = <String>[];
      for (var i = 0; i < 10; i++) {
        final card = find.descendant(
            of: find.byType(SupportActionCard), matching: find.byType(Text));
        seen.add(tester.widget<Text>(card.at(1)).data!);
        await tester.tap(find.text('Outra ideia'));
        await tester.pumpAndSettle();
      }
      final joined = seen.join(' | ');
      // joint-only suggestions must not appear in the apart rotation
      expect(joined, isNot(contains('Cozinha ou pede uma refeição')));
      expect(joined, isNot(contains('noite calma')));
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('Learn + Garden', () {
    testWidgets('Learn tab recommends, tracks progress and hosts Garden',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      final notifier = await pumpApp(tester,
          today: DateTime(2026, 10, 10),
          data: const AppData(
            settings: Settings(onboarded: true),
            careEvents: [CareEvent(1, CareCategory.act, '2026-10-10', 'a:x')],
          ));
      await tester.tap(find.text('Aprender'));
      await tester.pumpAndSettle();
      expect(find.text('A escolha de hoje'), findsOneWidget);
      expect(find.textContaining('de 30 lições concluídas'), findsOneWidget);
      expect(find.text('Explorar por tema'), findsOneWidget);
      expect(find.text('Jardim'), findsOneWidget);
      await tester.tap(find.text('Jardim'));
      await tester.pumpAndSettle();
      expect(find.text('A crescer'), findsOneWidget);
      await tester.tap(find.text('Dar um nome'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.descendant(
              of: find.byType(AlertDialog), matching: find.byType(TextField)),
          'Minha planta');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(notifier.state.plants.any((p) => p.name == 'Minha planta'), isTrue);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A escolha de hoje'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar como concluído'));
      await tester.pumpAndSettle();
      expect(notifier.state.learning.length, 1);
      expect(
          notifier.state.careEvents
              .where((c) => c.category == CareCategory.learn)
              .length,
          1);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('lesson detail shows cards, takeaway and explicit completion',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      await pumpApp(tester);
      await tester.tap(find.text('Aprender'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A escolha de hoje'));
      await tester.pumpAndSettle();
      expect(find.text('Para levar'), findsOneWidget);
      expect(find.text('De onde vem'), findsOneWidget);
      expect(find.text('Marcar como concluído'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('hiding the garden removes its Learn entry but keeps progress',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      await pumpApp(tester,
          data: const AppData(
            settings: Settings(onboarded: true, gardenHidden: true),
            careEvents: [CareEvent(1, CareCategory.act, '2026-10-10', 'a:x')],
          ));
      await tester.tap(find.text('Aprender'));
      await tester.pumpAndSettle();
      expect(find.text('Jardim'), findsNothing);
      expect(find.text('A crescer'), findsNothing);
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('Notes, reminders and settings', () {
    testWidgets('quick reflection entry persists and earns a reflect moment',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      final notifier = await pumpApp(tester);
      await tester.tap(find.text('Nota rápida'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar nota'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reflexão tua'));
      await tester.enterText(
          find.descendant(
              of: find.byType(AlertDialog), matching: find.byType(TextField)),
          'fiquei a pensar');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(notifier.state.entries.length, 1);
      expect(notifier.state.entries.first.kind, EntryKind.reflection);
      expect(
          notifier.state.careEvents
              .where((c) => c.category == CareCategory.reflect)
              .length,
          1);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('completing a reminder earns an act moment', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      final reminder = Reminder(
          id: 1,
          title: 'Ligar à farmácia',
          when: DateTime(2026, 10, 10, 10));
      final notifier = await pumpApp(tester,
          data: AppData(
              settings: const Settings(onboarded: true),
              reminders: [reminder]));
      expect(find.text('Ligar à farmácia'), findsOneWidget);
      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();
      expect(notifier.state.reminders.first.done, isTrue);
      expect(
          notifier.state.careEvents
              .where((c) => c.category == CareCategory.act)
              .length,
          1);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('clicking every tab, setting control and dialog is '
        'exception-free', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await pumpApp(tester);
      for (final tab in [
        'Calendário',
        'Aprender',
        'Definições',
        'Hoje',
        'Definições',
      ]) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
      }
      for (final opt in [
        'Nenhum', 'Hormonal', 'Desconhecido',
        'Sim', 'Não', 'Sim',
      ]) {
        await tester.tap(find.text(opt));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Briefing de amanhã'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Lembrete de preparação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hora do briefing'));
      await tester.pumpAndSettle();
      expect(find.text('Cancelar'), findsWidgets);
      await tester.tap(find.text('Cancelar').last);
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(find.text('Apagar todos os dados'),
          find.byType(ListView), const Offset(0, -150));
      await tester.tap(find.text('Apagar todos os dados'));
      await tester.pumpAndSettle();
      expect(find.textContaining('remove todos os dados'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('v0.6.0 D20: averages are read-only — no sliders, no pin',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await pumpApp(tester);
      await tester.tap(find.text('Definições'));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
          find.text('Médias usadas'), find.byType(ListView), const Offset(0, -150));
      expect(find.textContaining('média inicial'), findsNWidgets(2));
      expect(find.byType(Slider), findsNothing);
      expect(find.text('Fixar duração do ciclo'), findsNothing);
      expect(find.text('Fixar duração da menstruação'), findsNothing);
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('Onboarding', () {
    testWidgets('setup-first, back-and-forth, walks all 5 steps', (tester) async {
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
      expect(find.text('Contracetivos'), findsOneWidget);
      expect(find.text('Duração média do ciclo'), findsNothing);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Regista o último período'), findsOneWidget);
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Contracetivos'), findsOneWidget);
      expect(notifier.state.settings.onboarded, isFalse);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saltar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('lembrete genérico'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('É assim que vais receber'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Ligar notificações'), findsOneWidget);
      await tester.tap(find.text('Começar'));
      await tester.pumpAndSettle();
      expect(notifier.state.settings.onboarded, isTrue);
      expect(find.text('Nota rápida'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('choices remain readable at 3× text scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1600));
      tester.platformDispatcher.textScaleFactorTestValue = 3.0;
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
      expect(find.text('Contracetivos'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text('Desconhecido'), findsOneWidget);
      expect(find.byType(FittedBox), findsNothing);
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('Repair-pass regression coverage', () {
    testWidgets('catalog failure keeps Today usable and preferences reachable',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      final notifier = AppDataNotifier(
          Store(),
          AppData(
            settings: const Settings(onboarded: true),
            logs: [PeriodLog(lutealStart, DateTime(2026, 9, 24))],
            preferences: const [SupportPreference(1, 'help', 'jantar cedo')],
          ));
      final failingCatalog = catalogProvider.overrideWith((_) async {
        throw Exception('catalog unavailable');
      });
      await tester.pumpWidget(ProviderScope(
        overrides: [
          failingCatalog,
          feelingsOverride,
          learningOverride,
          todayProvider.overrideWithValue(fixedToday),
          appDataProvider.overrideWith((_) => notifier),
        ],
        child: const SideBySideApp(),
      ));
      await tester.pumpAndSettle();
      // degraded notice, but the briefing and the Support entry stay usable
      expect(find.textContaining('não estão disponíveis agora'), findsOneWidget);
      expect(find.text('Próxima menstruação'), findsOneWidget);
      await tester.tap(find.text('Ver uma ideia de apoio'));
      await tester.pumpAndSettle();
      expect(find.text('O que a ajuda a ela'), findsWidgets);
      await tester.tap(find.byTooltip('O que a ajuda a ela'));
      await tester.pumpAndSettle();
      expect(find.text('jantar cedo'), findsOneWidget);
      // the sheet is live: adding a preference refreshes its list
      await tester.tap(find.text('Adicionar preferência combinada'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.descendant(
              of: find.byType(AlertDialog), matching: find.byType(TextField)),
          'chá à noite');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('chá à noite'), findsOneWidget);
      expect(notifier.state.preferences.length, 2);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Support rotation persists per date and situation on reopen',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      final notifier = await pumpApp(tester);
      await tester.tap(find.text('Ver uma ideia de apoio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ouvir'));
      await tester.pumpAndSettle();
      final firstAction = tester
          .widget<Text>(find
              .descendant(of: find.byType(SupportActionCard), matching: find.byType(Text))
              .at(1))
          .data!;
      await tester.tap(find.text('Outra ideia'));
      await tester.pumpAndSettle();
      final secondAction = tester
          .widget<Text>(find
              .descendant(of: find.byType(SupportActionCard), matching: find.byType(Text))
              .at(1))
          .data!;
      expect(secondAction, isNot(firstAction));
      // persisted under the listening scope for today's date
      final sel = notifier.state.selections.where((s) => s.scope == 'listening');
      expect(sel, isNotEmpty);
      expect(sel.first.cursor, greaterThanOrEqualTo(1));
      // close and reopen the same situation: the rotation survives
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver uma ideia de apoio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ouvir'));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<Text>(find
                  .descendant(of: find.byType(SupportActionCard), matching: find.byType(Text))
                  .at(1))
              .data,
          secondAction);
      // a different situation starts its own rotation
      await tester.tap(find.text('Mudar a situação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dar espaço'));
      await tester.pumpAndSettle();
      expect(notifier.state.selections.where((s) => s.scope == 'space'), isEmpty);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('merging while the editor is open remaps the draft, keeps intensity',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      final base = lutealData().copyWith(customFeelings: [
        const CustomFeeling(1, 'zumbido'),
      ], feelingLogs: [
        const FeelingLog('2026-10-05', [FeelingEntry('custom:1')]),
      ]);
      final notifier = await pumpApp(tester, data: base);
      await tester.tap(find.text('Calendário'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sentimentos'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'zumbido');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'zumbido'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Selecionados'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Definir intensidade'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moderada'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10)); // close selection sheet
      await tester.pumpAndSettle();
      // manage customs → merge zumbido into the canonical cramps concept
      await tester.tap(find.byTooltip('Gerir sentimentos personalizados'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Juntar a outro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cólicas'));
      await tester.pumpAndSettle();
      // merge keeps the manage sheet open — dismiss it deterministically
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      // the pending draft now references the merge target with its intensity
      await tester.tap(find.textContaining('Selecionados'));
      await tester.pumpAndSettle();
      expect(find.text('Moderada'), findsOneWidget);
      await tester.enterText(find.byType(TextField), ''); // drop the search term
      await tester.pumpAndSettle();
      expect(find.text('zumbido'), findsNothing);
      await tester.binding.handlePopRoute(); // close the selection sheet
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar 1'));
      await tester.pumpAndSettle();
      final saved = notifier.state.feelingLogs
          .firstWhere((f) => f.date == '2026-10-10')
          .entries
          .single;
      expect(saved.concept, 'cramps');
      expect(saved.intensity, FeelingIntensity.moderate);
      // the old custom reference is gone everywhere, including the earlier day
      expect(
          notifier.state.feelingLogs.any((f) =>
              f.entries.any((e) => e.concept == 'custom:1')),
          isFalse);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('source links are copyable and never earn completion credit',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 2400));
      final notifier = await pumpApp(tester);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.hasStrings') {
          return const <String, dynamic>{'value': false};
        }
        return null;
      });
      addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
              SystemChannels.platform, null));
      await tester.tap(find.text('Aprender'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Variabilidade')); // topic ExpansionTile
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ovulação é difícil de prever'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fontes e leitura adicional'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Copiar ligação da fonte'));
      await tester.pumpAndSettle();
      expect(find.text('Ligação da fonte copiada'), findsOneWidget);
      // viewing/copying sources must not complete the lesson
      expect(notifier.state.learning, isEmpty);
      expect(notifier.state.careEvents
          .where((c) => c.category == CareCategory.learn), isEmpty);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('feelings editor works on small viewports with keyboard inset',
        (tester) async {
      for (final size in const [Size(360, 640), Size(390, 844)]) {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(const SizedBox.shrink());
        final notifier = await pumpApp(tester);
        await tester.tap(find.text('Calendário'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('10'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sentimentos'));
        await tester.pumpAndSettle();
        // keyboard open: fake bottom inset, still usable
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'inchaço');
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilterChip, 'Inchaço'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Selecionados'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Definir intensidade'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Suave'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'editor ${size.width}');
        await tester.tap(find.byIcon(Icons.close).last);
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(10, 10)); // close the sheet
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar (vazio limpa o dia)'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'save ${size.width}');
        expect(notifier.state.feelingLogs, isEmpty);
        tester.view.resetViewInsets();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await tester.binding.setSurfaceSize(null);
      }
    });
  });

  group('Layout resilience', () {
    testWidgets('four tabs, day sheet and support open with no overflow at '
        '1.3× text', (tester) async {
      for (final scale in [1.0, 1.3]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await tester.binding.setSurfaceSize(const Size(412, 915));
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpApp(tester);
        expect(tester.takeException(), isNull, reason: 'boot @ $scale');
        for (final tab in ['Calendário', 'Aprender', 'Definições', 'Hoje']) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'tab $tab @ $scale');
        }
        await tester.tap(find.text('Calendário'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();
        expect(find.text('Marcar início do período'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'day sheet @ $scale');
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hoje'));
        await tester.pumpAndSettle();
        await tester.dragUntilVisible(find.text('Ver uma ideia de apoio'),
            find.byType(ListView), const Offset(0, -150));
        // lift it clear of the bottom navigation bar before tapping
        await tester.drag(find.byType(ListView).last, const Offset(0, -220));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ver uma ideia de apoio'));
        await tester.pumpAndSettle();
        expect(find.text('Qual é a situação agora?'), findsOneWidget,
            reason: 'support open @ $scale');
        expect(tester.takeException(), isNull,
            reason: 'support situations @ $scale');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'textScale $scale');
        await tester.binding.setSurfaceSize(null);
      }
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    testWidgets('learnings, feelings and quick entry render at 1.3× text',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.binding.setSurfaceSize(const Size(412, 3200));
      await pumpApp(tester, today: DateTime(2026, 10, 10));
      await tester.tap(find.text('Aprender'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('A escolha de hoje'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calendário'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sentimentos'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hoje'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nota rápida'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('light and dark themes both render the briefing', (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.binding.setSurfaceSize(const Size(412, 1400));
        final notifier = AppDataNotifier(Store(), lutealData());
        await tester.pumpWidget(ProviderScope(
          overrides: [
            catalogOverride,
            feelingsOverride,
            learningOverride,
            todayProvider.overrideWithValue(fixedToday),
            appDataProvider.overrideWith((_) => notifier),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            locale: const Locale('pt'),
            localizationsDelegates: AppL.localizationsDelegates,
            supportedLocales: AppL.supportedLocales,
            home: const Scaffold(body: TodayScreen()),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Próxima menstruação'), findsOneWidget,
            reason: 'brightness $brightness');
        expect(tester.takeException(), isNull, reason: 'brightness $brightness');
        await tester.binding.setSurfaceSize(null);
      }
    });
  });
}
