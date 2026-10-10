// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLPt extends AppL {
  AppLPt([String locale = 'pt']) : super(locale);

  @override
  String get feelingExplainEveryday =>
      'Uma possibilidade quotidiana, sem associação estabelecida à fase do ciclo. Pergunta como se sente em vez de presumir.';

  @override
  String get copySource => 'Copiar ligação da fonte';

  @override
  String get sourceCopied => 'Ligação da fonte copiada';

  @override
  String get tabToday => 'Hoje';

  @override
  String get tabCalendar => 'Calendário';

  @override
  String get tabSuggestions => 'Sugestões';

  @override
  String get tabSettings => 'Definições';

  @override
  String get phaseMenstrual => 'Menstrual';

  @override
  String get phaseFollicular => 'Folicular';

  @override
  String get phaseOvulation => 'Ovulação';

  @override
  String get phaseLuteal => 'Lútea';

  @override
  String get phasePms => 'PMS';

  @override
  String get statusLabel => 'Fase provável';

  @override
  String get confHigh => 'datas registadas mais estáveis';

  @override
  String get confMedium => 'estimativa com alguns registos';

  @override
  String get confLow => 'estimativa limitada';

  @override
  String get suggestionsTitle => 'Para hoje';

  @override
  String get warningsTitle => 'Melhor evitar';

  @override
  String get contextTitle => 'Para enquadramento';

  @override
  String get axisFavor => 'Pedir favores';

  @override
  String get axisNews => 'Dar más notícias';

  @override
  String get axisOut => 'Sair e planear';

  @override
  String get axisEnergy => 'Energia';

  @override
  String get searchTitle => 'Procurar ideias de apoio';

  @override
  String get searchHint => 'Escreve para procurar';

  @override
  String get searchEmpty => 'Nada encontrado.';

  @override
  String get catalogUnavailable =>
      'Não foi possível carregar as sugestões. Reinicia a app para tentar de novo.';

  @override
  String get searchAllPhases => 'Todas';

  @override
  String get varianceTitle => 'Variância dos ciclos';

  @override
  String varianceAvg(int n) {
    return 'média: $n dias';
  }

  @override
  String get weekendTimeTitle => 'Hora diferente ao fim de semana';

  @override
  String get weekendBriefingTime => 'Hora do briefing (fim de semana)';

  @override
  String get supportTitle => 'Apoio';

  @override
  String get supportBody =>
      'Mostra primeiro ofertas de ajuda, sem inferir as preferências dela a partir do ciclo.';

  @override
  String get obsTitle => 'Registar observação';

  @override
  String get obsBody =>
      'O que observaste hoje — notas tuas, não dados clínicos.';

  @override
  String get obsLegend => 'observação registada';

  @override
  String get patternTitle => 'Padrão das tuas notas';

  @override
  String get patternCaption =>
      'Distribuição pelas fases — notas tuas, não dados clínicos.';

  @override
  String get obsCalm => 'Calma';

  @override
  String get obsTired => 'Cansada';

  @override
  String get obsSensitive => 'Sensível';

  @override
  String get obsGoodMood => 'De bom humor';

  @override
  String get obsIrritable => 'Irritada';

  @override
  String get obsCramps => 'Cólicas';

  @override
  String get obsHeadache => 'Dor de cabeça';

  @override
  String get obsBloating => 'Inchaço';

  @override
  String get obsCravings => 'Desejos';

  @override
  String get obsSleepless => 'Dormiu mal';

  @override
  String get save => 'Guardar';

  @override
  String get customTitle => 'As tuas notas';

  @override
  String get customAdd => 'Adicionar nota';

  @override
  String get customText => 'O que queres lembrar';

  @override
  String get widgetTitle => 'Widget no ecrã inicial';

  @override
  String get widgetBody =>
      'Mostra apenas um lembrete neutro para abrir a app. Só Android.';

  @override
  String get widgetPrompt => 'Consulta a app';

  @override
  String get dataTitle => 'Dados';

  @override
  String get deviceFail => 'Não foi possível concluir neste dispositivo.';

  @override
  String get calTitle => 'Adicionar ao calendário';

  @override
  String get calBody =>
      'Escreve os próximos 14 dias no teu calendário com o título neutro \"SxS\" — nada revelador. Atenção: se o calendário sincroniza com Google/Apple, esses eventos saem do telefone.';

  @override
  String get avgTitle => 'Médias usadas';

  @override
  String get avgAuto => 'automática — mediana dos teus registos';

  @override
  String get avgFallback => 'média inicial — ainda com poucos registos';

  @override
  String get avgFromLogs =>
      'A app calcula a duração do ciclo e da menstruação a partir dos teus registos — não precisas de as definir.';

  @override
  String get trafficGreen => 'bom';

  @override
  String get trafficYellow => 'atenção';

  @override
  String get trafficRed => 'evitar';

  @override
  String get tomorrowCard => 'Amanhã';

  @override
  String get tomorrowPreview => 'Ver amanhã ↓';

  @override
  String get feedbackQuestion => 'Esta sugestão foi útil?';

  @override
  String get feedbackThanks => 'Thanks — guardado.';

  @override
  String get confirmTitle => 'Confirmar data';

  @override
  String get confirmBody =>
      'A tua previsão de período passou por registar. Confirmas a data real?';

  @override
  String get confirmAction => 'Registar agora';

  @override
  String get confirmDismiss => 'Ainda não';

  @override
  String get healthNudge =>
      'Os teus ciclos variam bastante — vale a pena espreitar com um profissional. Não é alarme nem diagnóstico.';

  @override
  String get healthNudgeOk => 'Entendi';

  @override
  String get noForecast =>
      'Sem previsão atual — regista uma data para voltar a estimar.';

  @override
  String get noDataYet =>
      'Ainda não há datas registadas. Podes começar pela data do último período.';

  @override
  String calendarBandPeriod(int n) {
    return 'período previsto (±$n dias)';
  }

  @override
  String calendarBandOvulation(int n) {
    return 'janela fértil prevista (±$n dias)';
  }

  @override
  String get calendarLogged => 'registado';

  @override
  String get calendarFuture => 'previsto por ti';

  @override
  String get calendarExpectedPeriod => 'período estimado; a data pode mudar';

  @override
  String get calendarExpectedFertile => 'janela fértil estimada (6 dias)';

  @override
  String calendarFertileUncertainty(int n) {
    return 'incerteza da janela fértil (±$n dias)';
  }

  @override
  String get calendarNoBand =>
      'Sem estimativas de período ou janela fértil (contracetivo hormonal). O sangamento registado continua visível.';

  @override
  String get unknownContrNote =>
      'A contraceção está marcada como desconhecida. As estimativas assumem um ciclo natural e podem não se aplicar — confirma nas Definições.';

  @override
  String get unknownContrAction => 'Definir contraceção';

  @override
  String get calendarToday => 'Hoje';

  @override
  String get tipOfDayTitle => 'Dica do dia';

  @override
  String get prepTitle => 'Preparar com cuidado';

  @override
  String get prepBody =>
      'O próximo período pode estar perto. Se fizer sentido para vocês, pergunta do que ela precisa e prepara o essencial — a previsão pode mudar.';

  @override
  String get contraception => 'Contracetivos';

  @override
  String get contrNone => 'Nenhum';

  @override
  String get contrHormonal => 'Hormonal';

  @override
  String get contrUnknown => 'Desconhecido';

  @override
  String get liveTogether => 'Moram juntos?';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get settingsBriefing => 'Briefing de amanhã';

  @override
  String get settingsBriefingTime => 'Hora do briefing';

  @override
  String get settingsHeadsUp => 'Lembrete de preparação (detalhes só na app)';

  @override
  String get settingsWipe => 'Apagar todos os dados';

  @override
  String get settingsWipeConfirm =>
      'Apagar remove todos os dados. Não há recuperação.';

  @override
  String todayCycleDay(int day) {
    return 'Dia $day do ciclo';
  }

  @override
  String todayNextPeriod(String date) {
    return 'Próximo período estimado: $date';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get calMarkStart => 'Marcar início do período';

  @override
  String get calMarkEnd => 'Marcar fim do período';

  @override
  String get calUnmarkStart => 'Desmarcar início do período';

  @override
  String get calUnmarkEnd => 'Desmarcar fim do período';

  @override
  String get periodTooShort =>
      'Uma menstruação costuma durar pelo menos ~3 dias.';

  @override
  String get periodTooSoon =>
      'Nesta app, os inícios dos períodos registados precisam de estar separados por pelo menos 21 dias.';

  @override
  String get notifBriefTitle => 'SideBySide';

  @override
  String get notifBriefBody => 'Tens uma atualização para veres na app.';

  @override
  String get notifHeadsUpTitle => 'SideBySide';

  @override
  String get notifHeadsUpBody => 'Tens uma nota para consultar na app.';

  @override
  String get notifReminderTitle => 'SideBySide';

  @override
  String get notifReminderBody => 'Tens um lembrete para ver na app.';

  @override
  String get ofToday => 'de hoje';

  @override
  String get onbSetupTitle => 'Começar';

  @override
  String get onbSetupBody =>
      'Regista apenas datas que conheces. As necessidades dela são sempre para perguntar, não para prever.';

  @override
  String get onbAvgCycle => 'Duração média do ciclo';

  @override
  String get onbAvgPeriod => 'Duração da menstruação';

  @override
  String onbDays(int n) {
    return '$n dias';
  }

  @override
  String get onbLogTitle => 'Regista o último período';

  @override
  String get onbLogBody =>
      'Quando começou? O fim é opcional — podes saltar e marcar depois no Calendário.';

  @override
  String get onbLogStart => 'Início do período';

  @override
  String get onbLogEnd => 'Fim do período (opcional)';

  @override
  String get onbNotSet => 'Toca para escolher';

  @override
  String get onbSkip => 'Saltar';

  @override
  String get onbTimeTitle => 'Hora do briefing';

  @override
  String get onbTimeBody =>
      'À hora que escolheres, recebes um lembrete genérico para consultar a app. Podes desligá-lo depois.';

  @override
  String get preferenceTitle => 'O que combinaram que ajuda';

  @override
  String get preferenceConsent =>
      'Guarda apenas preferências de que falaram. Podes editar ou apagar quando quiseres; a app não confirma o consentimento dela.';

  @override
  String get preferenceAdd => 'Adicionar preferência combinada';

  @override
  String get preferenceEdit => 'Editar preferência';

  @override
  String get preferenceDelete => 'Apagar preferência';

  @override
  String get preferenceCategory => 'Tipo de apoio';

  @override
  String get preferenceCheckIn => 'Perguntar como está';

  @override
  String get preferenceHelp => 'Ajuda prática';

  @override
  String get preferenceSpace => 'Dar espaço';

  @override
  String get preferenceText => 'O que gostariam que te lembrasses?';

  @override
  String get agreedPreference =>
      'Preferência que guardaste — confirma sempre se ainda faz sentido.';

  @override
  String get actionQuestion => 'Esta ação foi útil para ti?';

  @override
  String get actionUseful => 'Útil';

  @override
  String get actionNotUseful => 'Ver menos disto por 7 dias';

  @override
  String get actionThanks => 'Obrigado pelo feedback.';

  @override
  String get actionDone => 'Feito';

  @override
  String get actionDoneThanks => 'Marcado como feito.';

  @override
  String get actionAnother => 'Outra sugestão';

  @override
  String get actionCompletedLabel => 'Feito hoje';

  @override
  String get allActionsSeen =>
      'Já viste as sugestões disponíveis hoje. Pergunta diretamente o que ajudaria.';

  @override
  String get legacyNotes => 'Notas antigas por fase (editar ou apagar)';

  @override
  String get logDateAction => 'Registar uma data';

  @override
  String estimateFallback(int n) {
    return 'Poucos registos: cálculo inicial de $n dias, não personalizado.';
  }

  @override
  String estimateFromLogs(int n, int band) {
    return 'Com base em $n intervalos registados; margem indicativa de ±$band dias.';
  }

  @override
  String get estimateNotCertain =>
      'A data pode mudar; não descreve como ela se sente.';

  @override
  String get estimateEvidence =>
      'Datas não confirmam fases ou ovulação (Henry et al., 2024; Johnson et al., 2018).';

  @override
  String get phaseDetailTitle => 'Ver fase aproximada (opcional)';

  @override
  String get phaseDetailBody =>
      'É uma aproximação baseada em datas. Não indica humor, energia ou disponibilidade.';

  @override
  String get onbSampleTitle => 'É assim que vais receber';

  @override
  String get onbSampleBody =>
      'As notificações mostram apenas uma mensagem neutra — os detalhes ficam na app.';

  @override
  String get onbNotifyTitle => 'Ligar notificações';

  @override
  String get onbNotifyBody =>
      'Opcional: toca no botão para permitir lembretes genéricos. Podes começar sem os ligar e mudar depois nas Definições.';

  @override
  String get onbNotifyAction => 'Ligar e ver exemplo';

  @override
  String get onbBack => 'Voltar';

  @override
  String get onbNext => 'Continuar';

  @override
  String get onbDone => 'Começar';

  @override
  String get learningTitle => 'Aprender';

  @override
  String get learningIntro =>
      'Cartões curtos sobre ciclos, variabilidade e apoio. Não são diagnóstico — abre, lê e marca como concluído quando quiseres.';

  @override
  String get learningSource => 'De onde vem';

  @override
  String get learningQuiz => 'Testa o que aprendeste';

  @override
  String get learningCheckRight => 'Correto.';

  @override
  String get learningCheckWrong => 'Ainda não — vê a explicação.';

  @override
  String get learningDone => 'Marcar como concluído';

  @override
  String get learningCompleted => 'Concluído';

  @override
  String get entriesTitle => 'Notas rápidas';

  @override
  String get entryAdd => 'Adicionar nota';

  @override
  String get entrySharedKind => 'Informação partilhada';

  @override
  String get entryReflectionKind => 'Reflexão tua';

  @override
  String get entryPrompt => 'O que queres registar?';

  @override
  String get entryKindHint =>
      '\"Informação partilhada\" é algo que ela te contou; \"Reflexão tua\" é o que tu pensas. Só as reflexões contam como momento de cuidado.';

  @override
  String get entryEdit => 'Editar nota';

  @override
  String get entryDelete => 'Apagar nota';

  @override
  String get entryToPreference => 'Transformar em preferência';

  @override
  String get entryToReminder => 'Transformar em lembrete';

  @override
  String get remindersTitle => 'Lembretes';

  @override
  String get reminderAdd => 'Novo lembrete';

  @override
  String get reminderTitleField => 'Título';

  @override
  String get reminderWhen => 'Quando';

  @override
  String get reminderComplete => 'Concluir';

  @override
  String get reminderDelete => 'Apagar lembrete';

  @override
  String get reminderEmpty => 'Sem lembretes por agora.';

  @override
  String get reminderDoneLabel => 'Concluído';

  @override
  String get todayQuickEntry => 'Nota rápida';

  @override
  String get todayReminders => 'Lembretes de hoje';

  @override
  String get todayLearning => 'Aprender um pouco';

  @override
  String get todayOpenLearning => 'Ver cartões';

  @override
  String get catHelp => 'Ajuda prática';

  @override
  String get catCommunicate => 'Comunicar';

  @override
  String get catCompany => 'Companhia';

  @override
  String get catSpace => 'Espaço';

  @override
  String get catPrepare => 'Preparar';

  @override
  String get saveFailedTitle => 'Não foi possível guardar';

  @override
  String get saveFailedBody =>
      'Os teus dados estão nesta sessão, mas ainda não ficaram no telefone. Tenta guardar outra vez.';

  @override
  String get saveRetry => 'Tentar guardar';

  @override
  String get calcDetailsTitle => 'Como estimamos (opcional)';

  @override
  String get gardenTitle => 'Jardim';

  @override
  String get gardenIntro =>
      'Bem-vindo de volta. Cada cuidado conta — nada morre nem perde progresso quando fazes uma pausa.';

  @override
  String get gardenOpen => 'Abrir jardim';

  @override
  String get gardenEmpty =>
      'Ainda sem plantas. Um momento de cuidado começa uma semente.';

  @override
  String get gardenActivePlant => 'A crescer';

  @override
  String get gardenCollection => 'Plantas maduras';

  @override
  String gardenWeeklyGoal(int n) {
    return 'Cuidados esta semana: $n/3';
  }

  @override
  String gardenMoments(int n) {
    return '$n de 12 momentos';
  }

  @override
  String get gardenStageSeed => 'Semente';

  @override
  String get gardenStageSprout => 'Brote';

  @override
  String get gardenStageLeaves => 'Folhas';

  @override
  String get gardenStageBuds => 'Botões';

  @override
  String get gardenStageFlowering => 'Em flor';

  @override
  String get gardenStageMature => 'Madura';

  @override
  String get gardenVariety0 => 'Samambaia';

  @override
  String get gardenVariety1 => 'Alfazema';

  @override
  String get gardenVariety2 => 'Suculenta';

  @override
  String get gardenName => 'Dar um nome';

  @override
  String get gardenPotStyle => 'Estilo do vaso';

  @override
  String get gardenDetailTitle => 'Detalhe da planta';

  @override
  String get gardenGrowthDates => 'Datas de crescimento';

  @override
  String get gardenTotals => 'Momentos por tipo';

  @override
  String get gardenCatLearn => 'Aprender';

  @override
  String get gardenCatAct => 'Agir';

  @override
  String get gardenCatReflect => 'Refletir';

  @override
  String get gardenNextHint => 'Próximo cuidado';

  @override
  String get gardenShowTitle => 'Mostrar o jardim';

  @override
  String get gardenShowBody =>
      'Esconde o jardim na app sem perder nenhum progresso.';

  @override
  String get gardenUnnamed => 'Sem nome';

  @override
  String get todayNextPeriodLabel => 'Próxima menstruação';

  @override
  String todayDaysUntil(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '~$n dias',
      one: '~1 dia',
      zero: 'Começa hoje',
    );
    return '$_temp0';
  }

  @override
  String todayExpectedRange(String range) {
    return 'Previsto $range';
  }

  @override
  String get stageUnknown => 'Fase desconhecida';

  @override
  String get stageUnknownNote =>
      'Fase incerta — a mostrar apenas possibilidades gerais.';

  @override
  String get sheMayNotice => 'Ela pode notar';

  @override
  String get todayFeelNoData =>
      'As possibilidades gerais aparecem depois de registares uma menstruação.';

  @override
  String get todayFeelUnavailable =>
      'Sem sugestões de sentimento neste modo — as estimativas precisam de datas registadas.';

  @override
  String get generalTag => 'Geral';

  @override
  String get fromHistoryTag => 'Do histórico';

  @override
  String get previouslyLoggedTag => 'Registado antes';

  @override
  String get loggedTodayLabel => 'Registado hoje';

  @override
  String get showOthers => 'Mostrar outras';

  @override
  String get howToRespond => 'Como responder';

  @override
  String get seeSupportIdea => 'Ver uma ideia de apoio';

  @override
  String get hideSupportEntry => 'Ocultar ideia de apoio';

  @override
  String get feelingExplainGeneral =>
      'Uma possibilidade geral para a fase estimada — nunca uma previsão do que ela sente. Só é um registo se o tiveres guardado no Calendário.';

  @override
  String feelingExplainHistory(int n) {
    return 'Registado à volta deste ponto em $n ciclos anteriores.';
  }

  @override
  String get feelingExplainPrevious => 'Registado antes num ciclo anterior.';

  @override
  String feelingLastLogged(String date) {
    return 'Último registo: $date';
  }

  @override
  String get feelingOpenCalendar => 'Registar sentimentos nesta data';

  @override
  String get feelingsTitle => 'Sentimentos';

  @override
  String get feelingSearch => 'Procurar sentimentos';

  @override
  String get feelingSelected => 'Selecionados';

  @override
  String get feelingRemove => 'Remover';

  @override
  String feelingSuggestedFor(String stage) {
    return 'Sugeridos por volta da fase $stage';
  }

  @override
  String get feelingSuggestedGeneral => 'Sugestões gerais — fase não estimada';

  @override
  String get feelingYourOwn => 'Os teus sentimentos personalizados';

  @override
  String get feelingCustomCreate => 'Criar sentimento personalizado';

  @override
  String get feelingCustomLabel => 'Dá um nome a este sentimento';

  @override
  String get feelingCustomManage => 'Gerir sentimentos personalizados';

  @override
  String get feelingCustomNone => 'Ainda não tens sentimentos personalizados.';

  @override
  String get feelingRename => 'Renomear';

  @override
  String get feelingMerge => 'Juntar a outro';

  @override
  String get feelingMergeInto => 'Juntar a que sentimento?';

  @override
  String get feelingDeleteCustom => 'Apagar sentimento personalizado';

  @override
  String feelingSearchResults(int n) {
    return '$n resultados';
  }

  @override
  String get feelingIntensityNone => 'Sem intensidade';

  @override
  String get feelingIntensityHint => 'Definir intensidade';

  @override
  String get intensityMild => 'Suave';

  @override
  String get intensityModerate => 'Moderada';

  @override
  String get intensityStrong => 'Forte';

  @override
  String feelingSaveCount(int n) {
    return 'Guardar $n';
  }

  @override
  String get feelingClearSave => 'Guardar (vazio limpa o dia)';

  @override
  String get calFeelings => 'Sentimentos';

  @override
  String get startTooCloseReason => 'Demasiado perto de outro início registado';

  @override
  String get calendarOvulationDay => 'dia de ovulação estimada';

  @override
  String get calendarOvulationSummary => 'Ovulação estimada';

  @override
  String get calendarOvulationDetailsTitle => 'Dia de ovulação estimado';

  @override
  String calendarOvulationDetailsBody(int n) {
    return 'Só datas do calendário não conseguem fixar a ovulação. Isto marca um dia estimado com ±$n dias de incerteza — não um evento confirmado.';
  }

  @override
  String calendarOvulationEstimatedOn(String date) {
    return 'Estimado por volta de $date.';
  }

  @override
  String get calendarOvulationNone =>
      'Sem estimativa de ovulação — poucos registos ou contracetivo hormonal.';

  @override
  String get feelingLoggedLegend => 'sentimentos registados';

  @override
  String get historyTitle => 'Histórico';

  @override
  String get historyEmpty =>
      'Ainda não há sentimentos registados. Regista-os a partir de uma data do Calendário.';

  @override
  String get historyLutealNote =>
      'As observações pré-menstruais ficam dentro da fase lútea.';

  @override
  String get historyUnknownNote =>
      'Estas datas não tiveram fase deduzível — regista menstruações para as agrupar.';

  @override
  String get tabLearn => 'Aprender';

  @override
  String get supportSituationPrompt => 'Qual é a situação agora?';

  @override
  String get sitComfort => 'Conforto';

  @override
  String get sitComfortBody => 'Ela receberia bem calor e cuidado.';

  @override
  String get sitPractical => 'Ajuda prática';

  @override
  String get sitPracticalBody => 'Algo fora do prato dela ajudaria.';

  @override
  String get sitListening => 'Ouvir';

  @override
  String get sitListeningBody => 'Ela quer ser ouvida, não consertada.';

  @override
  String get sitSpace => 'Dar espaço';

  @override
  String get sitSpaceBody => 'Ela pediu margem — respeita isso.';

  @override
  String get sitTogether => 'Tempo a dois';

  @override
  String get sitTogetherBody => 'Boa companhia sem pressão parece bem.';

  @override
  String get sitApart => 'Estamos longe';

  @override
  String get sitApartBody => 'Apoio à distância hoje.';

  @override
  String get actionOfferLabel => 'Como podes oferecer:';

  @override
  String get anotherIdea => 'Outra ideia';

  @override
  String get didThis => 'Fiz isto';

  @override
  String get didThisDone => 'Marcado como feito.';

  @override
  String get previouslyHelpfulTag => 'Já ajudou antes';

  @override
  String get whyThisLabel => 'Porquê isto?';

  @override
  String get changeSituation => 'Mudar a situação';

  @override
  String get checkInFallback =>
      'Nada mais se encaixa agora. O melhor próximo passo é perguntares-lhe diretamente o que ajudaria hoje.';

  @override
  String get whatHelpsHer => 'O que a ajuda a ela';

  @override
  String get catalogLoadFailPreferences =>
      'As ideias de apoio não estão disponíveis agora. As tuas preferências guardadas continuam acessíveis abaixo.';

  @override
  String get learnRecommended => 'A escolha de hoje';

  @override
  String get learnTopics => 'Explorar por tema';

  @override
  String learnProgress(int done, int total) {
    return '$done de $total lições concluídas';
  }

  @override
  String get learnTakeaway => 'Para levar';

  @override
  String get learnReadMore => 'Fontes e leitura adicional';

  @override
  String get summaryTitle => 'Resumo no dispositivo';

  @override
  String get summaryAction => 'Resumir notas recentes';

  @override
  String get summaryDownloading =>
      'É preciso preparar o modelo — a transferência fica no dispositivo.';

  @override
  String get summarySetup => 'Preparar modelo';

  @override
  String get summaryRunning => 'A resumir no dispositivo…';

  @override
  String get summaryUnavailable =>
      'Os resumos no dispositivo não estão disponíveis neste aparelho. As notas e o histórico funcionam exatamente da mesma forma.';

  @override
  String get summaryUnsupported =>
      'Os resumos no dispositivo suportam por agora apenas inglês, japonês ou coreano — notas em português ficam sem resumo.';

  @override
  String get summaryFailed =>
      'O resumo não foi concluído. Nada mudou — tenta de novo ou lê as notas diretamente.';

  @override
  String get summaryRetry => 'Tentar de novo';

  @override
  String get summarySources => 'Ver notas originais';
}
