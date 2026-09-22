// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLPt extends AppL {
  AppLPt([String locale = 'pt']) : super(locale);

  @override
  String get tabHoje => 'Dashboard';

  @override
  String get tabCalendario => 'Calendário';

  @override
  String get tabSugestoes => 'Sugestões';

  @override
  String get tabDefinicoes => 'Definições';

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
  String get confHigh => 'confiança alta';

  @override
  String get confMedium => 'confiança média';

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
  String get searchTitle => 'Procurar em todas as sugestões';

  @override
  String get searchHint => 'Escreve para procurar';

  @override
  String get searchEmpty => 'Nada encontrado.';

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
  String get supportTitle => 'Apoio intensivo';

  @override
  String get supportBody =>
      'Mostra primeiro as notas de apoio da fase lútea. É uma preferência tua, não um diagnóstico.';

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
  String get lockTitle => 'Bloqueio da app';

  @override
  String get lockBody =>
      'Biometria ou PIN para abrir. O PIN fica só no teu telefone.';

  @override
  String get lockDisable => 'PIN para desativar';

  @override
  String get lockTitleScreen => 'Desbloqueiar SideBySide';

  @override
  String get lockPinField => 'PIN';

  @override
  String get lockPinSet => 'Define um PIN (4–6 dígitos)';

  @override
  String get lockPinConfirm => 'Repete o PIN';

  @override
  String get lockPinMismatch => 'Os PINs não coincidem';

  @override
  String get lockPinBad => 'PIN errado';

  @override
  String get lockUnlock => 'Desbloquear';

  @override
  String get lockBiometric => 'Usar biometria';

  @override
  String get lockBiometricReason => 'Desbloqueiar o SideBySide';

  @override
  String get widgetTitle => 'Widget no ecrã inicial';

  @override
  String get widgetBody =>
      'Mostra a fase provável e o semáforo de amanhã. Só Android.';

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
  String get feedbackQuestion => 'A previsão acertou?';

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
  String get hormonalBanner =>
      'Com contracetivo hormonal, as fases podem não refletir a realidade.';

  @override
  String get healthNudge =>
      'Os teus ciclos variam bastante — vale a pena espreitar com um profissional. Não é alarme nem diagnóstico.';

  @override
  String get healthNudgeOk => 'Entendi';

  @override
  String get noForecast => 'Sem previsão — regista um período para reativar.';

  @override
  String get noDataYet =>
      'Toca num dia no Calendário para marcar o início do período.';

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
  String get calendarExpectedPeriod => 'período previsto';

  @override
  String get calendarExpectedFertile => 'janela fértil prevista';

  @override
  String get calendarToday => 'Hoje';

  @override
  String get tipOfDayTitle => 'Dica do dia';

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
  String get settingsHeadsUp => 'Aviso \"período esperado em ~2 dias\"';

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
    return 'Próximo período: $date';
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
      'A menstruação não costuma começar menos de ~10 dias depois da anterior.';

  @override
  String get notifBriefTitle => 'SideBySide';

  @override
  String get notifBriefRed =>
      'Previsão de amanhã: 🔴 dia delicado. Vê as recomendações.';

  @override
  String get notifBriefYellow =>
      'Previsão de amanhã: 🟡 dia com cautela. Vê as recomendações.';

  @override
  String get notifBriefGreen =>
      'Previsão de amanhã: 🟢 dia favorável. Vê as recomendações.';

  @override
  String get notifHeadsUpTitle => 'SideBySide';

  @override
  String get notifHeadsUpBody =>
      'Período esperado em ~2 dias. Vê as recomendações.';

  @override
  String get ofToday => 'de hoje';

  @override
  String get onbSetupTitle => 'Começar';

  @override
  String get onbSetupBody =>
      'Como são as coisas em casa? A app aprende os teus ritmos a partir dos registos.';

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
      'Uma vez por dia, à hora que escolheres, uma previsão neutra de amanhã.';

  @override
  String get onbSampleTitle => 'É assim que vais receber';

  @override
  String get onbSampleBody =>
      'No ecrã bloqueado só vêes o semáforo — os detalhes ficam na app.';

  @override
  String get onbNotifyTitle => 'Ligar notificações';

  @override
  String get onbNotifyBody =>
      'Sem permissão, o briefing não chega. Podes mudar isto depois nas Definições.';

  @override
  String get onbNotifyAction => 'Ligar e ver exemplo';

  @override
  String get onbBack => 'Voltar';

  @override
  String get onbNext => 'Continuar';

  @override
  String get onbDone => 'Começar';
}
