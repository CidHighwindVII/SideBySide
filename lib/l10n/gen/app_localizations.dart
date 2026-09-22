import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL
/// returned by `AppL.of(context)`.
///
/// Applications need to include `AppL.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL.localizationsDelegates,
///   supportedLocales: AppL.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL.supportedLocales
/// property.
abstract class AppL {
  AppL(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL of(BuildContext context) {
    return Localizations.of<AppL>(context, AppL)!;
  }

  static const LocalizationsDelegate<AppL> delegate = _AppLDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @tabHoje.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard'**
  String get tabHoje;

  /// No description provided for @tabCalendario.
  ///
  /// In pt, this message translates to:
  /// **'Calendário'**
  String get tabCalendario;

  /// No description provided for @tabSugestoes.
  ///
  /// In pt, this message translates to:
  /// **'Sugestões'**
  String get tabSugestoes;

  /// No description provided for @tabDefinicoes.
  ///
  /// In pt, this message translates to:
  /// **'Definições'**
  String get tabDefinicoes;

  /// No description provided for @phaseMenstrual.
  ///
  /// In pt, this message translates to:
  /// **'Menstrual'**
  String get phaseMenstrual;

  /// No description provided for @phaseFollicular.
  ///
  /// In pt, this message translates to:
  /// **'Folicular'**
  String get phaseFollicular;

  /// No description provided for @phaseOvulation.
  ///
  /// In pt, this message translates to:
  /// **'Ovulação'**
  String get phaseOvulation;

  /// No description provided for @phaseLuteal.
  ///
  /// In pt, this message translates to:
  /// **'Lútea'**
  String get phaseLuteal;

  /// No description provided for @phasePms.
  ///
  /// In pt, this message translates to:
  /// **'PMS'**
  String get phasePms;

  /// No description provided for @statusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Fase provável'**
  String get statusLabel;

  /// No description provided for @confHigh.
  ///
  /// In pt, this message translates to:
  /// **'confiança alta'**
  String get confHigh;

  /// No description provided for @confMedium.
  ///
  /// In pt, this message translates to:
  /// **'confiança média'**
  String get confMedium;

  /// No description provided for @confLow.
  ///
  /// In pt, this message translates to:
  /// **'estimativa limitada'**
  String get confLow;

  /// No description provided for @suggestionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Para hoje'**
  String get suggestionsTitle;

  /// No description provided for @warningsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Melhor evitar'**
  String get warningsTitle;

  /// No description provided for @contextTitle.
  ///
  /// In pt, this message translates to:
  /// **'Para enquadramento'**
  String get contextTitle;

  /// No description provided for @axisFavor.
  ///
  /// In pt, this message translates to:
  /// **'Pedir favores'**
  String get axisFavor;

  /// No description provided for @axisNews.
  ///
  /// In pt, this message translates to:
  /// **'Dar más notícias'**
  String get axisNews;

  /// No description provided for @axisOut.
  ///
  /// In pt, this message translates to:
  /// **'Sair e planear'**
  String get axisOut;

  /// No description provided for @axisEnergy.
  ///
  /// In pt, this message translates to:
  /// **'Energia'**
  String get axisEnergy;

  /// No description provided for @searchTitle.
  ///
  /// In pt, this message translates to:
  /// **'Procurar em todas as sugestões'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In pt, this message translates to:
  /// **'Escreve para procurar'**
  String get searchHint;

  /// No description provided for @searchEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nada encontrado.'**
  String get searchEmpty;

  /// No description provided for @searchAllPhases.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get searchAllPhases;

  /// No description provided for @varianceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Variância dos ciclos'**
  String get varianceTitle;

  /// No description provided for @varianceAvg.
  ///
  /// In pt, this message translates to:
  /// **'média: {n} dias'**
  String varianceAvg(int n);

  /// No description provided for @weekendTimeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Hora diferente ao fim de semana'**
  String get weekendTimeTitle;

  /// No description provided for @weekendBriefingTime.
  ///
  /// In pt, this message translates to:
  /// **'Hora do briefing (fim de semana)'**
  String get weekendBriefingTime;

  /// No description provided for @supportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Apoio intensivo'**
  String get supportTitle;

  /// No description provided for @supportBody.
  ///
  /// In pt, this message translates to:
  /// **'Mostra primeiro as notas de apoio da fase lútea. É uma preferência tua, não um diagnóstico.'**
  String get supportBody;

  /// No description provided for @obsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registar observação'**
  String get obsTitle;

  /// No description provided for @obsBody.
  ///
  /// In pt, this message translates to:
  /// **'O que observaste hoje — notas tuas, não dados clínicos.'**
  String get obsBody;

  /// No description provided for @obsLegend.
  ///
  /// In pt, this message translates to:
  /// **'observação registada'**
  String get obsLegend;

  /// No description provided for @patternTitle.
  ///
  /// In pt, this message translates to:
  /// **'Padrão das tuas notas'**
  String get patternTitle;

  /// No description provided for @patternCaption.
  ///
  /// In pt, this message translates to:
  /// **'Distribuição pelas fases — notas tuas, não dados clínicos.'**
  String get patternCaption;

  /// No description provided for @obsCalm.
  ///
  /// In pt, this message translates to:
  /// **'Calma'**
  String get obsCalm;

  /// No description provided for @obsTired.
  ///
  /// In pt, this message translates to:
  /// **'Cansada'**
  String get obsTired;

  /// No description provided for @obsSensitive.
  ///
  /// In pt, this message translates to:
  /// **'Sensível'**
  String get obsSensitive;

  /// No description provided for @obsGoodMood.
  ///
  /// In pt, this message translates to:
  /// **'De bom humor'**
  String get obsGoodMood;

  /// No description provided for @obsIrritable.
  ///
  /// In pt, this message translates to:
  /// **'Irritada'**
  String get obsIrritable;

  /// No description provided for @obsCramps.
  ///
  /// In pt, this message translates to:
  /// **'Cólicas'**
  String get obsCramps;

  /// No description provided for @obsHeadache.
  ///
  /// In pt, this message translates to:
  /// **'Dor de cabeça'**
  String get obsHeadache;

  /// No description provided for @obsBloating.
  ///
  /// In pt, this message translates to:
  /// **'Inchaço'**
  String get obsBloating;

  /// No description provided for @obsCravings.
  ///
  /// In pt, this message translates to:
  /// **'Desejos'**
  String get obsCravings;

  /// No description provided for @obsSleepless.
  ///
  /// In pt, this message translates to:
  /// **'Dormiu mal'**
  String get obsSleepless;

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @customTitle.
  ///
  /// In pt, this message translates to:
  /// **'As tuas notas'**
  String get customTitle;

  /// No description provided for @customAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar nota'**
  String get customAdd;

  /// No description provided for @customText.
  ///
  /// In pt, this message translates to:
  /// **'O que queres lembrar'**
  String get customText;

  /// No description provided for @lockTitle.
  ///
  /// In pt, this message translates to:
  /// **'Bloqueio da app'**
  String get lockTitle;

  /// No description provided for @lockBody.
  ///
  /// In pt, this message translates to:
  /// **'Biometria ou PIN para abrir. O PIN fica só no teu telefone.'**
  String get lockBody;

  /// No description provided for @lockDisable.
  ///
  /// In pt, this message translates to:
  /// **'PIN para desativar'**
  String get lockDisable;

  /// No description provided for @lockTitleScreen.
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueiar SideBySide'**
  String get lockTitleScreen;

  /// No description provided for @lockPinField.
  ///
  /// In pt, this message translates to:
  /// **'PIN'**
  String get lockPinField;

  /// No description provided for @lockPinSet.
  ///
  /// In pt, this message translates to:
  /// **'Define um PIN (4–6 dígitos)'**
  String get lockPinSet;

  /// No description provided for @lockPinConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Repete o PIN'**
  String get lockPinConfirm;

  /// No description provided for @lockPinMismatch.
  ///
  /// In pt, this message translates to:
  /// **'Os PINs não coincidem'**
  String get lockPinMismatch;

  /// No description provided for @lockPinBad.
  ///
  /// In pt, this message translates to:
  /// **'PIN errado'**
  String get lockPinBad;

  /// No description provided for @lockUnlock.
  ///
  /// In pt, this message translates to:
  /// **'Desbloquear'**
  String get lockUnlock;

  /// No description provided for @lockBiometric.
  ///
  /// In pt, this message translates to:
  /// **'Usar biometria'**
  String get lockBiometric;

  /// No description provided for @lockBiometricReason.
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueiar o SideBySide'**
  String get lockBiometricReason;

  /// No description provided for @widgetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Widget no ecrã inicial'**
  String get widgetTitle;

  /// No description provided for @widgetBody.
  ///
  /// In pt, this message translates to:
  /// **'Mostra a fase provável e o semáforo de amanhã. Só Android.'**
  String get widgetBody;

  /// No description provided for @dataTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dados'**
  String get dataTitle;

  /// No description provided for @deviceFail.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir neste dispositivo.'**
  String get deviceFail;

  /// No description provided for @calTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar ao calendário'**
  String get calTitle;

  /// No description provided for @calBody.
  ///
  /// In pt, this message translates to:
  /// **'Escreve os próximos 14 dias no teu calendário com o título neutro \"SxS\" — nada revelador. Atenção: se o calendário sincroniza com Google/Apple, esses eventos saem do telefone.'**
  String get calBody;

  /// No description provided for @avgTitle.
  ///
  /// In pt, this message translates to:
  /// **'Médias usadas'**
  String get avgTitle;

  /// No description provided for @avgAuto.
  ///
  /// In pt, this message translates to:
  /// **'automática — mediana dos teus registos'**
  String get avgAuto;

  /// No description provided for @avgFallback.
  ///
  /// In pt, this message translates to:
  /// **'média inicial — ainda com poucos registos'**
  String get avgFallback;

  /// No description provided for @avgFromLogs.
  ///
  /// In pt, this message translates to:
  /// **'A app calcula a duração do ciclo e da menstruação a partir dos teus registos — não precisas de as definir.'**
  String get avgFromLogs;

  /// No description provided for @trafficGreen.
  ///
  /// In pt, this message translates to:
  /// **'bom'**
  String get trafficGreen;

  /// No description provided for @trafficYellow.
  ///
  /// In pt, this message translates to:
  /// **'atenção'**
  String get trafficYellow;

  /// No description provided for @trafficRed.
  ///
  /// In pt, this message translates to:
  /// **'evitar'**
  String get trafficRed;

  /// No description provided for @tomorrowCard.
  ///
  /// In pt, this message translates to:
  /// **'Amanhã'**
  String get tomorrowCard;

  /// No description provided for @tomorrowPreview.
  ///
  /// In pt, this message translates to:
  /// **'Ver amanhã ↓'**
  String get tomorrowPreview;

  /// No description provided for @feedbackQuestion.
  ///
  /// In pt, this message translates to:
  /// **'A previsão acertou?'**
  String get feedbackQuestion;

  /// No description provided for @feedbackThanks.
  ///
  /// In pt, this message translates to:
  /// **'Thanks — guardado.'**
  String get feedbackThanks;

  /// No description provided for @confirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar data'**
  String get confirmTitle;

  /// No description provided for @confirmBody.
  ///
  /// In pt, this message translates to:
  /// **'A tua previsão de período passou por registar. Confirmas a data real?'**
  String get confirmBody;

  /// No description provided for @confirmAction.
  ///
  /// In pt, this message translates to:
  /// **'Registar agora'**
  String get confirmAction;

  /// No description provided for @confirmDismiss.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não'**
  String get confirmDismiss;

  /// No description provided for @hormonalBanner.
  ///
  /// In pt, this message translates to:
  /// **'Com contracetivo hormonal, as fases podem não refletir a realidade.'**
  String get hormonalBanner;

  /// No description provided for @healthNudge.
  ///
  /// In pt, this message translates to:
  /// **'Os teus ciclos variam bastante — vale a pena espreitar com um profissional. Não é alarme nem diagnóstico.'**
  String get healthNudge;

  /// No description provided for @healthNudgeOk.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get healthNudgeOk;

  /// No description provided for @noForecast.
  ///
  /// In pt, this message translates to:
  /// **'Sem previsão — regista um período para reativar.'**
  String get noForecast;

  /// No description provided for @noDataYet.
  ///
  /// In pt, this message translates to:
  /// **'Toca num dia no Calendário para marcar o início do período.'**
  String get noDataYet;

  /// No description provided for @calendarBandPeriod.
  ///
  /// In pt, this message translates to:
  /// **'período previsto (±{n} dias)'**
  String calendarBandPeriod(int n);

  /// No description provided for @calendarBandOvulation.
  ///
  /// In pt, this message translates to:
  /// **'janela fértil prevista (±{n} dias)'**
  String calendarBandOvulation(int n);

  /// No description provided for @calendarLogged.
  ///
  /// In pt, this message translates to:
  /// **'registado'**
  String get calendarLogged;

  /// No description provided for @calendarFuture.
  ///
  /// In pt, this message translates to:
  /// **'previsto por ti'**
  String get calendarFuture;

  /// No description provided for @calendarExpectedPeriod.
  ///
  /// In pt, this message translates to:
  /// **'período previsto'**
  String get calendarExpectedPeriod;

  /// No description provided for @calendarExpectedFertile.
  ///
  /// In pt, this message translates to:
  /// **'janela fértil prevista'**
  String get calendarExpectedFertile;

  /// No description provided for @calendarToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get calendarToday;

  /// No description provided for @tipOfDayTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dica do dia'**
  String get tipOfDayTitle;

  /// No description provided for @contraception.
  ///
  /// In pt, this message translates to:
  /// **'Contracetivos'**
  String get contraception;

  /// No description provided for @contrNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum'**
  String get contrNone;

  /// No description provided for @contrHormonal.
  ///
  /// In pt, this message translates to:
  /// **'Hormonal'**
  String get contrHormonal;

  /// No description provided for @contrUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Desconhecido'**
  String get contrUnknown;

  /// No description provided for @liveTogether.
  ///
  /// In pt, this message translates to:
  /// **'Moram juntos?'**
  String get liveTogether;

  /// No description provided for @yes.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get no;

  /// No description provided for @profileTitle.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @settingsBriefing.
  ///
  /// In pt, this message translates to:
  /// **'Briefing de amanhã'**
  String get settingsBriefing;

  /// No description provided for @settingsBriefingTime.
  ///
  /// In pt, this message translates to:
  /// **'Hora do briefing'**
  String get settingsBriefingTime;

  /// No description provided for @settingsHeadsUp.
  ///
  /// In pt, this message translates to:
  /// **'Aviso \"período esperado em ~2 dias\"'**
  String get settingsHeadsUp;

  /// No description provided for @settingsWipe.
  ///
  /// In pt, this message translates to:
  /// **'Apagar todos os dados'**
  String get settingsWipe;

  /// No description provided for @settingsWipeConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Apagar remove todos os dados. Não há recuperação.'**
  String get settingsWipeConfirm;

  /// No description provided for @todayCycleDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia {day} do ciclo'**
  String todayCycleDay(int day);

  /// No description provided for @todayNextPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Próximo período: {date}'**
  String todayNextPeriod(String date);

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @calMarkStart.
  ///
  /// In pt, this message translates to:
  /// **'Marcar início do período'**
  String get calMarkStart;

  /// No description provided for @calMarkEnd.
  ///
  /// In pt, this message translates to:
  /// **'Marcar fim do período'**
  String get calMarkEnd;

  /// No description provided for @calUnmarkStart.
  ///
  /// In pt, this message translates to:
  /// **'Desmarcar início do período'**
  String get calUnmarkStart;

  /// No description provided for @calUnmarkEnd.
  ///
  /// In pt, this message translates to:
  /// **'Desmarcar fim do período'**
  String get calUnmarkEnd;

  /// No description provided for @periodTooShort.
  ///
  /// In pt, this message translates to:
  /// **'Uma menstruação costuma durar pelo menos ~3 dias.'**
  String get periodTooShort;

  /// No description provided for @periodTooSoon.
  ///
  /// In pt, this message translates to:
  /// **'A menstruação não costuma começar menos de ~10 dias depois da anterior.'**
  String get periodTooSoon;

  /// No description provided for @notifBriefTitle.
  ///
  /// In pt, this message translates to:
  /// **'SideBySide'**
  String get notifBriefTitle;

  /// No description provided for @notifBriefRed.
  ///
  /// In pt, this message translates to:
  /// **'Previsão de amanhã: 🔴 dia delicado. Vê as recomendações.'**
  String get notifBriefRed;

  /// No description provided for @notifBriefYellow.
  ///
  /// In pt, this message translates to:
  /// **'Previsão de amanhã: 🟡 dia com cautela. Vê as recomendações.'**
  String get notifBriefYellow;

  /// No description provided for @notifBriefGreen.
  ///
  /// In pt, this message translates to:
  /// **'Previsão de amanhã: 🟢 dia favorável. Vê as recomendações.'**
  String get notifBriefGreen;

  /// No description provided for @notifHeadsUpTitle.
  ///
  /// In pt, this message translates to:
  /// **'SideBySide'**
  String get notifHeadsUpTitle;

  /// No description provided for @notifHeadsUpBody.
  ///
  /// In pt, this message translates to:
  /// **'Período esperado em ~2 dias. Vê as recomendações.'**
  String get notifHeadsUpBody;

  /// No description provided for @ofToday.
  ///
  /// In pt, this message translates to:
  /// **'de hoje'**
  String get ofToday;

  /// No description provided for @onbSetupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get onbSetupTitle;

  /// No description provided for @onbSetupBody.
  ///
  /// In pt, this message translates to:
  /// **'Como são as coisas em casa? A app aprende os teus ritmos a partir dos registos.'**
  String get onbSetupBody;

  /// No description provided for @onbAvgCycle.
  ///
  /// In pt, this message translates to:
  /// **'Duração média do ciclo'**
  String get onbAvgCycle;

  /// No description provided for @onbAvgPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Duração da menstruação'**
  String get onbAvgPeriod;

  /// No description provided for @onbDays.
  ///
  /// In pt, this message translates to:
  /// **'{n} dias'**
  String onbDays(int n);

  /// No description provided for @onbLogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Regista o último período'**
  String get onbLogTitle;

  /// No description provided for @onbLogBody.
  ///
  /// In pt, this message translates to:
  /// **'Quando começou? O fim é opcional — podes saltar e marcar depois no Calendário.'**
  String get onbLogBody;

  /// No description provided for @onbLogStart.
  ///
  /// In pt, this message translates to:
  /// **'Início do período'**
  String get onbLogStart;

  /// No description provided for @onbLogEnd.
  ///
  /// In pt, this message translates to:
  /// **'Fim do período (opcional)'**
  String get onbLogEnd;

  /// No description provided for @onbNotSet.
  ///
  /// In pt, this message translates to:
  /// **'Toca para escolher'**
  String get onbNotSet;

  /// No description provided for @onbSkip.
  ///
  /// In pt, this message translates to:
  /// **'Saltar'**
  String get onbSkip;

  /// No description provided for @onbTimeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Hora do briefing'**
  String get onbTimeTitle;

  /// No description provided for @onbTimeBody.
  ///
  /// In pt, this message translates to:
  /// **'Uma vez por dia, à hora que escolheres, uma previsão neutra de amanhã.'**
  String get onbTimeBody;

  /// No description provided for @onbSampleTitle.
  ///
  /// In pt, this message translates to:
  /// **'É assim que vais receber'**
  String get onbSampleTitle;

  /// No description provided for @onbSampleBody.
  ///
  /// In pt, this message translates to:
  /// **'No ecrã bloqueado só vêes o semáforo — os detalhes ficam na app.'**
  String get onbSampleBody;

  /// No description provided for @onbNotifyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ligar notificações'**
  String get onbNotifyTitle;

  /// No description provided for @onbNotifyBody.
  ///
  /// In pt, this message translates to:
  /// **'Sem permissão, o briefing não chega. Podes mudar isto depois nas Definições.'**
  String get onbNotifyBody;

  /// No description provided for @onbNotifyAction.
  ///
  /// In pt, this message translates to:
  /// **'Ligar e ver exemplo'**
  String get onbNotifyAction;

  /// No description provided for @onbBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get onbBack;

  /// No description provided for @onbNext.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get onbNext;

  /// No description provided for @onbDone.
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get onbDone;
}

class _AppLDelegate extends LocalizationsDelegate<AppL> {
  const _AppLDelegate();

  @override
  Future<AppL> load(Locale locale) {
    return SynchronousFuture<AppL>(lookupAppL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLDelegate old) => false;
}

AppL lookupAppL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLEn();
    case 'pt':
      return AppLPt();
  }

  throw FlutterError(
    'AppL.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
