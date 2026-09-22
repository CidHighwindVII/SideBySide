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
  /// **'Hoje'**
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
  /// **'datas registadas mais estáveis'**
  String get confHigh;

  /// No description provided for @confMedium.
  ///
  /// In pt, this message translates to:
  /// **'estimativa com alguns registos'**
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
  /// **'Procurar ideias de apoio'**
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

  /// No description provided for @catalogUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as sugestões. Reinicia a app para tentar de novo.'**
  String get catalogUnavailable;

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
  /// **'Priorizar sugestões de ajuda'**
  String get supportTitle;

  /// No description provided for @supportBody.
  ///
  /// In pt, this message translates to:
  /// **'Mostra primeiro ofertas de ajuda, sem inferir as preferências dela a partir do ciclo.'**
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

  /// No description provided for @widgetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Widget no ecrã inicial'**
  String get widgetTitle;

  /// No description provided for @widgetBody.
  ///
  /// In pt, this message translates to:
  /// **'Mostra apenas um lembrete neutro para abrir a app. Só Android.'**
  String get widgetBody;

  /// No description provided for @widgetPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Consulta a app'**
  String get widgetPrompt;

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
  /// **'Esta sugestão foi útil?'**
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
  /// **'Sem previsão atual — regista uma data para voltar a estimar.'**
  String get noForecast;

  /// No description provided for @noDataYet.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há datas registadas. Podes começar pela data do último período.'**
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
  /// **'período estimado; a data pode mudar'**
  String get calendarExpectedPeriod;

  /// No description provided for @calendarExpectedFertile.
  ///
  /// In pt, this message translates to:
  /// **'janela fértil estimada (6 dias)'**
  String get calendarExpectedFertile;

  /// No description provided for @calendarFertileUncertainty.
  ///
  /// In pt, this message translates to:
  /// **'incerteza da janela fértil (±{n} dias)'**
  String calendarFertileUncertainty(int n);

  /// No description provided for @calendarNoBand.
  ///
  /// In pt, this message translates to:
  /// **'Sem estimativas de período ou janela fértil (contracetivo hormonal). O sangamento registado continua visível.'**
  String get calendarNoBand;

  /// No description provided for @unknownContrNote.
  ///
  /// In pt, this message translates to:
  /// **'A contraceção está marcada como desconhecida. As estimativas assumem um ciclo natural e podem não se aplicar — confirma nas Definições.'**
  String get unknownContrNote;

  /// No description provided for @unknownContrAction.
  ///
  /// In pt, this message translates to:
  /// **'Definir contraceção'**
  String get unknownContrAction;

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

  /// No description provided for @prepTitle.
  ///
  /// In pt, this message translates to:
  /// **'Preparar com cuidado'**
  String get prepTitle;

  /// No description provided for @prepBody.
  ///
  /// In pt, this message translates to:
  /// **'O próximo período pode estar perto. Se fizer sentido para vocês, pergunta do que ela precisa e prepara o essencial — a previsão pode mudar.'**
  String get prepBody;

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
  /// **'Lembrete de preparação (detalhes só na app)'**
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
  /// **'Próximo período estimado: {date}'**
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
  /// **'Nesta app, os inícios dos períodos registados precisam de estar separados por pelo menos 21 dias.'**
  String get periodTooSoon;

  /// No description provided for @notifBriefTitle.
  ///
  /// In pt, this message translates to:
  /// **'SideBySide'**
  String get notifBriefTitle;

  /// No description provided for @notifBriefBody.
  ///
  /// In pt, this message translates to:
  /// **'Tens uma atualização para veres na app.'**
  String get notifBriefBody;

  /// No description provided for @notifHeadsUpTitle.
  ///
  /// In pt, this message translates to:
  /// **'SideBySide'**
  String get notifHeadsUpTitle;

  /// No description provided for @notifHeadsUpBody.
  ///
  /// In pt, this message translates to:
  /// **'Tens uma nota para consultar na app.'**
  String get notifHeadsUpBody;

  /// No description provided for @notifReminderTitle.
  ///
  /// In pt, this message translates to:
  /// **'SideBySide'**
  String get notifReminderTitle;

  /// No description provided for @notifReminderBody.
  ///
  /// In pt, this message translates to:
  /// **'Tens um lembrete para ver na app.'**
  String get notifReminderBody;

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
  /// **'Regista apenas datas que conheces. As necessidades dela são sempre para perguntar, não para prever.'**
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
  /// **'À hora que escolheres, recebes um lembrete genérico para consultar a app. Podes desligá-lo depois.'**
  String get onbTimeBody;

  /// No description provided for @preferenceTitle.
  ///
  /// In pt, this message translates to:
  /// **'O que combinaram que ajuda'**
  String get preferenceTitle;

  /// No description provided for @preferenceConsent.
  ///
  /// In pt, this message translates to:
  /// **'Guarda apenas preferências de que falaram. Podes editar ou apagar quando quiseres; a app não confirma o consentimento dela.'**
  String get preferenceConsent;

  /// No description provided for @preferenceAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar preferência combinada'**
  String get preferenceAdd;

  /// No description provided for @preferenceEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar preferência'**
  String get preferenceEdit;

  /// No description provided for @preferenceDelete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar preferência'**
  String get preferenceDelete;

  /// No description provided for @preferenceCategory.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de apoio'**
  String get preferenceCategory;

  /// No description provided for @preferenceCheckIn.
  ///
  /// In pt, this message translates to:
  /// **'Perguntar como está'**
  String get preferenceCheckIn;

  /// No description provided for @preferenceHelp.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda prática'**
  String get preferenceHelp;

  /// No description provided for @preferenceSpace.
  ///
  /// In pt, this message translates to:
  /// **'Dar espaço'**
  String get preferenceSpace;

  /// No description provided for @preferenceText.
  ///
  /// In pt, this message translates to:
  /// **'O que gostariam que te lembrasses?'**
  String get preferenceText;

  /// No description provided for @agreedPreference.
  ///
  /// In pt, this message translates to:
  /// **'Preferência que guardaste — confirma sempre se ainda faz sentido.'**
  String get agreedPreference;

  /// No description provided for @actionQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação foi útil para ti?'**
  String get actionQuestion;

  /// No description provided for @actionUseful.
  ///
  /// In pt, this message translates to:
  /// **'Útil'**
  String get actionUseful;

  /// No description provided for @actionNotUseful.
  ///
  /// In pt, this message translates to:
  /// **'Ver menos disto por 7 dias'**
  String get actionNotUseful;

  /// No description provided for @actionThanks.
  ///
  /// In pt, this message translates to:
  /// **'Obrigado pelo feedback.'**
  String get actionThanks;

  /// No description provided for @actionDone.
  ///
  /// In pt, this message translates to:
  /// **'Feito'**
  String get actionDone;

  /// No description provided for @actionDoneThanks.
  ///
  /// In pt, this message translates to:
  /// **'Marcado como feito.'**
  String get actionDoneThanks;

  /// No description provided for @actionAnother.
  ///
  /// In pt, this message translates to:
  /// **'Outra sugestão'**
  String get actionAnother;

  /// No description provided for @actionCompletedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Feito hoje'**
  String get actionCompletedLabel;

  /// No description provided for @allActionsSeen.
  ///
  /// In pt, this message translates to:
  /// **'Já viste as sugestões disponíveis hoje. Pergunta diretamente o que ajudaria.'**
  String get allActionsSeen;

  /// No description provided for @legacyNotes.
  ///
  /// In pt, this message translates to:
  /// **'Notas antigas por fase (editar ou apagar)'**
  String get legacyNotes;

  /// No description provided for @logDateAction.
  ///
  /// In pt, this message translates to:
  /// **'Registar uma data'**
  String get logDateAction;

  /// No description provided for @estimateFallback.
  ///
  /// In pt, this message translates to:
  /// **'Poucos registos: cálculo inicial de {n} dias, não personalizado.'**
  String estimateFallback(int n);

  /// No description provided for @estimateFromLogs.
  ///
  /// In pt, this message translates to:
  /// **'Com base em {n} intervalos registados; margem indicativa de ±{band} dias.'**
  String estimateFromLogs(int n, int band);

  /// No description provided for @estimateNotCertain.
  ///
  /// In pt, this message translates to:
  /// **'A data pode mudar; não descreve como ela se sente.'**
  String get estimateNotCertain;

  /// No description provided for @estimateEvidence.
  ///
  /// In pt, this message translates to:
  /// **'Datas não confirmam fases ou ovulação (Henry et al., 2024; Johnson et al., 2018).'**
  String get estimateEvidence;

  /// No description provided for @phaseDetailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ver fase aproximada (opcional)'**
  String get phaseDetailTitle;

  /// No description provided for @phaseDetailBody.
  ///
  /// In pt, this message translates to:
  /// **'É uma aproximação baseada em datas. Não indica humor, energia ou disponibilidade.'**
  String get phaseDetailBody;

  /// No description provided for @onbSampleTitle.
  ///
  /// In pt, this message translates to:
  /// **'É assim que vais receber'**
  String get onbSampleTitle;

  /// No description provided for @onbSampleBody.
  ///
  /// In pt, this message translates to:
  /// **'As notificações mostram apenas uma mensagem neutra — os detalhes ficam na app.'**
  String get onbSampleBody;

  /// No description provided for @onbNotifyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ligar notificações'**
  String get onbNotifyTitle;

  /// No description provided for @onbNotifyBody.
  ///
  /// In pt, this message translates to:
  /// **'Opcional: toca no botão para permitir lembretes genéricos. Podes começar sem os ligar e mudar depois nas Definições.'**
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

  /// No description provided for @learningTitle.
  ///
  /// In pt, this message translates to:
  /// **'Aprender'**
  String get learningTitle;

  /// No description provided for @learningIntro.
  ///
  /// In pt, this message translates to:
  /// **'Cartões curtos sobre ciclos, variabilidade e apoio. Não são diagnóstico — abre, lê e marca como concluído quando quiseres.'**
  String get learningIntro;

  /// No description provided for @learningSource.
  ///
  /// In pt, this message translates to:
  /// **'De onde vem'**
  String get learningSource;

  /// No description provided for @learningQuiz.
  ///
  /// In pt, this message translates to:
  /// **'Testa o que aprendeste'**
  String get learningQuiz;

  /// No description provided for @learningCheckRight.
  ///
  /// In pt, this message translates to:
  /// **'Correto.'**
  String get learningCheckRight;

  /// No description provided for @learningCheckWrong.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não — vê a explicação.'**
  String get learningCheckWrong;

  /// No description provided for @learningDone.
  ///
  /// In pt, this message translates to:
  /// **'Marcar como concluído'**
  String get learningDone;

  /// No description provided for @learningCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get learningCompleted;

  /// No description provided for @entriesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Notas rápidas'**
  String get entriesTitle;

  /// No description provided for @entryAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar nota'**
  String get entryAdd;

  /// No description provided for @entrySharedKind.
  ///
  /// In pt, this message translates to:
  /// **'Informação partilhada'**
  String get entrySharedKind;

  /// No description provided for @entryReflectionKind.
  ///
  /// In pt, this message translates to:
  /// **'Reflexão tua'**
  String get entryReflectionKind;

  /// No description provided for @entryPrompt.
  ///
  /// In pt, this message translates to:
  /// **'O que queres registar?'**
  String get entryPrompt;

  /// No description provided for @entryKindHint.
  ///
  /// In pt, this message translates to:
  /// **'\"Informação partilhada\" é algo que ela te contou; \"Reflexão tua\" é o que tu pensas. Só as reflexões contam como momento de cuidado.'**
  String get entryKindHint;

  /// No description provided for @entryEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar nota'**
  String get entryEdit;

  /// No description provided for @entryDelete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar nota'**
  String get entryDelete;

  /// No description provided for @entryToPreference.
  ///
  /// In pt, this message translates to:
  /// **'Transformar em preferência'**
  String get entryToPreference;

  /// No description provided for @entryToReminder.
  ///
  /// In pt, this message translates to:
  /// **'Transformar em lembrete'**
  String get entryToReminder;

  /// No description provided for @remindersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lembretes'**
  String get remindersTitle;

  /// No description provided for @reminderAdd.
  ///
  /// In pt, this message translates to:
  /// **'Novo lembrete'**
  String get reminderAdd;

  /// No description provided for @reminderTitleField.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get reminderTitleField;

  /// No description provided for @reminderWhen.
  ///
  /// In pt, this message translates to:
  /// **'Quando'**
  String get reminderWhen;

  /// No description provided for @reminderComplete.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get reminderComplete;

  /// No description provided for @reminderDelete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar lembrete'**
  String get reminderDelete;

  /// No description provided for @reminderEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Sem lembretes por agora.'**
  String get reminderEmpty;

  /// No description provided for @reminderDoneLabel.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get reminderDoneLabel;

  /// No description provided for @todayQuickEntry.
  ///
  /// In pt, this message translates to:
  /// **'Nota rápida'**
  String get todayQuickEntry;

  /// No description provided for @todayReminders.
  ///
  /// In pt, this message translates to:
  /// **'Lembretes de hoje'**
  String get todayReminders;

  /// No description provided for @todayLearning.
  ///
  /// In pt, this message translates to:
  /// **'Aprender um pouco'**
  String get todayLearning;

  /// No description provided for @todayOpenLearning.
  ///
  /// In pt, this message translates to:
  /// **'Ver cartões'**
  String get todayOpenLearning;

  /// No description provided for @catHelp.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda prática'**
  String get catHelp;

  /// No description provided for @catCommunicate.
  ///
  /// In pt, this message translates to:
  /// **'Comunicar'**
  String get catCommunicate;

  /// No description provided for @catCompany.
  ///
  /// In pt, this message translates to:
  /// **'Companhia'**
  String get catCompany;

  /// No description provided for @catSpace.
  ///
  /// In pt, this message translates to:
  /// **'Espaço'**
  String get catSpace;

  /// No description provided for @catPrepare.
  ///
  /// In pt, this message translates to:
  /// **'Preparar'**
  String get catPrepare;

  /// No description provided for @saveFailedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível guardar'**
  String get saveFailedTitle;

  /// No description provided for @saveFailedBody.
  ///
  /// In pt, this message translates to:
  /// **'Os teus dados estão nesta sessão, mas ainda não ficaram no telefone. Tenta guardar outra vez.'**
  String get saveFailedBody;

  /// No description provided for @saveRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar guardar'**
  String get saveRetry;

  /// No description provided for @calcDetailsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Como estimamos (opcional)'**
  String get calcDetailsTitle;

  /// No description provided for @gardenTitle.
  ///
  /// In pt, this message translates to:
  /// **'Jardim'**
  String get gardenTitle;

  /// No description provided for @gardenIntro.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo de volta. Cada cuidado conta — nada morre nem perde progresso quando fazes uma pausa.'**
  String get gardenIntro;

  /// No description provided for @gardenOpen.
  ///
  /// In pt, this message translates to:
  /// **'Abrir jardim'**
  String get gardenOpen;

  /// No description provided for @gardenEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem plantas. Um momento de cuidado começa uma semente.'**
  String get gardenEmpty;

  /// No description provided for @gardenActivePlant.
  ///
  /// In pt, this message translates to:
  /// **'A crescer'**
  String get gardenActivePlant;

  /// No description provided for @gardenCollection.
  ///
  /// In pt, this message translates to:
  /// **'Plantas maduras'**
  String get gardenCollection;

  /// No description provided for @gardenWeeklyGoal.
  ///
  /// In pt, this message translates to:
  /// **'Cuidados esta semana: {n}/3'**
  String gardenWeeklyGoal(int n);

  /// No description provided for @gardenMoments.
  ///
  /// In pt, this message translates to:
  /// **'{n} de 12 momentos'**
  String gardenMoments(int n);

  /// No description provided for @gardenStageSeed.
  ///
  /// In pt, this message translates to:
  /// **'Semente'**
  String get gardenStageSeed;

  /// No description provided for @gardenStageSprout.
  ///
  /// In pt, this message translates to:
  /// **'Brote'**
  String get gardenStageSprout;

  /// No description provided for @gardenStageLeaves.
  ///
  /// In pt, this message translates to:
  /// **'Folhas'**
  String get gardenStageLeaves;

  /// No description provided for @gardenStageBuds.
  ///
  /// In pt, this message translates to:
  /// **'Botões'**
  String get gardenStageBuds;

  /// No description provided for @gardenStageFlowering.
  ///
  /// In pt, this message translates to:
  /// **'Em flor'**
  String get gardenStageFlowering;

  /// No description provided for @gardenStageMature.
  ///
  /// In pt, this message translates to:
  /// **'Madura'**
  String get gardenStageMature;

  /// No description provided for @gardenVariety0.
  ///
  /// In pt, this message translates to:
  /// **'Samambaia'**
  String get gardenVariety0;

  /// No description provided for @gardenVariety1.
  ///
  /// In pt, this message translates to:
  /// **'Alfazema'**
  String get gardenVariety1;

  /// No description provided for @gardenVariety2.
  ///
  /// In pt, this message translates to:
  /// **'Suculenta'**
  String get gardenVariety2;

  /// No description provided for @gardenName.
  ///
  /// In pt, this message translates to:
  /// **'Dar um nome'**
  String get gardenName;

  /// No description provided for @gardenPotStyle.
  ///
  /// In pt, this message translates to:
  /// **'Estilo do vaso'**
  String get gardenPotStyle;

  /// No description provided for @gardenDetailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Detalhe da planta'**
  String get gardenDetailTitle;

  /// No description provided for @gardenGrowthDates.
  ///
  /// In pt, this message translates to:
  /// **'Datas de crescimento'**
  String get gardenGrowthDates;

  /// No description provided for @gardenTotals.
  ///
  /// In pt, this message translates to:
  /// **'Momentos por tipo'**
  String get gardenTotals;

  /// No description provided for @gardenCatLearn.
  ///
  /// In pt, this message translates to:
  /// **'Aprender'**
  String get gardenCatLearn;

  /// No description provided for @gardenCatAct.
  ///
  /// In pt, this message translates to:
  /// **'Agir'**
  String get gardenCatAct;

  /// No description provided for @gardenCatReflect.
  ///
  /// In pt, this message translates to:
  /// **'Refletir'**
  String get gardenCatReflect;

  /// No description provided for @gardenNextHint.
  ///
  /// In pt, this message translates to:
  /// **'Próximo cuidado'**
  String get gardenNextHint;

  /// No description provided for @gardenShowTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar o jardim'**
  String get gardenShowTitle;

  /// No description provided for @gardenShowBody.
  ///
  /// In pt, this message translates to:
  /// **'Esconde o jardim na app sem perder nenhum progresso.'**
  String get gardenShowBody;

  /// No description provided for @gardenUnnamed.
  ///
  /// In pt, this message translates to:
  /// **'Sem nome'**
  String get gardenUnnamed;
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
