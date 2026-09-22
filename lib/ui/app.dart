import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/device.dart';
import '../engine/models.dart';
import '../log.dart';
import '../notify/notifications.dart';
import '../state/providers.dart';
import '../l10n/gen/app_localizations.dart';
import 'lock.dart';
import 'screens/calendario.dart';
import 'screens/definicoes.dart';
import 'screens/hoje.dart';
import 'screens/onboarding.dart';
import 'screens/sugestoes.dart';
import 'theme.dart';
import 'widgets.dart';

class _Shell extends ConsumerStatefulWidget {
  const _Shell();

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    Notifications.instance.tapPayload.addListener(_onTap);
    if (Notifications.instance.tapPayload.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onTap());
    }
  }

  void _onTap() {
    final payload = Notifications.instance.tapPayload.value;
    Notifications.instance.tapPayload.value = null;
    if (payload == null) return;
    logInfo('notify', 'notification tapped: $payload');
    if (payload == 'amanha') {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AmanhaScreen()));
    } else if (payload == 'hoje') {
      setState(() => _tab = 0);
    }
  }

  @override
  void dispose() {
    Notifications.instance.tapPayload.removeListener(_onTap);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          HojeScreen(),
          CalendarioScreen(),
          SugestoesScreen(),
          DefinicoesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: l.tabHoje),
          NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: l.tabCalendario),
          NavigationDestination(
              icon: const Icon(Icons.lightbulb_outline),
              selectedIcon: const Icon(Icons.lightbulb),
              label: l.tabSugestoes),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l.tabDefinicoes),
        ],
      ),
    );
  }
}

/// Wide screens: phone-width column between 2px rules so lists and the
/// 7-col calendar don't stretch into unreadable lines.
class _Frame extends StatelessWidget {
  final Widget child;
  const _Frame({required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width <= 840) return child;
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640),
          decoration: BoxDecoration(
              color: scheme.surface,
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16), bottom: Radius.circular(16))),
          child: child,
        ),
      ),
    );
  }
}

class SideBySideApp extends ConsumerStatefulWidget {
  const SideBySideApp({super.key});

  @override
  ConsumerState<SideBySideApp> createState() => _SideBySideAppState();
}

class _SideBySideAppState extends ConsumerState<SideBySideApp>
    with WidgetsBindingObserver {
  bool? _locked; // null until first build: cold start locks if enabled
  Future<void> _widgetSync = Future<void>.value();
  Timer? _dayRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _armDayRefresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduleNotifications(ref.read(appDataProvider));
      _syncWidget(ref.read(appDataProvider));
    });
  }

  @override
  void dispose() {
    _dayRefresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // v0.3.0 (#3): re-lock on background/resume when the lock is enabled.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(todayProvider);
      final data = ref.read(appDataProvider);
      if (data.settings.appLockEnabled) setState(() => _locked = true);
      _scheduleNotifications(data); // time zone / calendar day may have changed
      _syncWidget(data);
      _armDayRefresh();
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    ref.invalidate(langCodeProvider);
    _scheduleNotifications(ref.read(appDataProvider));
    _syncWidget(ref.read(appDataProvider));
    _armDayRefresh();
  }

  void _armDayRefresh() {
    _dayRefresh?.cancel();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _dayRefresh = Timer(midnight.difference(now) + const Duration(milliseconds: 50), () {
      if (!mounted) return;
      ref.invalidate(todayProvider);
      final data = ref.read(appDataProvider);
      _scheduleNotifications(data);
      _syncWidget(data);
      _armDayRefresh();
    });
  }

  /// v0.4.0 (#7): mirror Hoje's headline onto the Android home-screen widget
  /// whenever data changes; blanked when the switch is off.
  void _syncWidget(AppData data) {
    if (!deviceSurfacesAvailable) return;
    _widgetSync = _widgetSync.then((_) => _writeWidget(data)).catchError(
      (Object error, StackTrace stack) => logErr('widget', error, stack),
    );
  }

  Future<void> _writeWidget(AppData data) async {
    if (!mounted || !identical(data, ref.read(appDataProvider))) return;
    final eng = ref.read(engineProvider(DateTime.now()));
    final s = data.settings;
    final l =
        await AppL.delegate.load(Locale(ref.read(langCodeProvider)));
    if (!mounted || !identical(data, ref.read(appDataProvider))) return;
    final phase = eng.phaseOrNull(eng.today);
    final day = eng.dayOfCycle(eng.today);
    await Device.syncWidget(
      enabled: s.widgetEnabled,
      phaseLabel: phase == null ? 'SideBySide' : phaseName(l, phase),
      dayLabel: phase == null || day == 0 ? '' : l.todayCycleDay(day),
      dotColor: trafficColors[eng.tomorrowTeaser()]!.toARGB32(),
    );
  }

  void _scheduleNotifications(AppData data) {
    final catalog = ref.read(catalogProvider).valueOrNull;
    Notifications.instance.reschedule(data,
        axes: catalog == null ? null : catalogAxes(catalog));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appDataProvider).settings;
    // keep scheduled notifications in sync with data/settings changes
    ref.listen(appDataProvider, (_, next) {
      _scheduleNotifications(next);
      _syncWidget(next);
    });
    ref.listen(catalogProvider, (_, next) {
      if (next.valueOrNull != null) {
        _scheduleNotifications(ref.read(appDataProvider));
      }
    });
    final unlocked = _unlockedScreen(settings);
    return MaterialApp(
      localizationsDelegates: AppL.localizationsDelegates,
      supportedLocales: AppL.supportedLocales,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      builder: (context, child) => _Frame(child: child!),
      home: unlocked,
      routes: {
        '/amanha': (_) => const AmanhaScreen(),
      },
    );
  }

  Widget _unlockedScreen(Settings settings) {
    if (!settings.onboarded) return const OnboardingScreen();
    // cold start (_locked==null): lock if enabled. resume: observer sets true.
    final needsLock = settings.appLockEnabled && (_locked ?? true);
    if (needsLock) {
      return LockScreen(
        settings: settings,
        onUnlock: () => setState(() => _locked = false),
      );
    }
    return const _Shell();
  }
}
