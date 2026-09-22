import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/store.dart';
import 'log.dart';
import 'notify/notifications.dart';
import 'state/providers.dart';
import 'ui/app.dart';

class DebugProviderObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    logErr('riverpod:${provider.name ?? provider.runtimeType}', error,
        stackTrace);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logErr('flutter', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logErr('async', error, stack);
    return true;
  };
  logInfo('app', 'starting');
  await Notifications.instance.init();
  Notifications.instance.tapPayload.value =
      !kIsWeb && (Platform.isAndroid || Platform.isIOS)
          ? await Notifications.instance.launchPayload()
          : null;
  final store = Store();
  final data = await store.load();
  runApp(ProviderScope(
    observers: kDebugMode ? [DebugProviderObserver()] : const [],
    overrides: [
      storeProvider.overrideWithValue(store),
      appDataProvider.overrideWith((_) => AppDataNotifier(store, data)),
    ],
    child: const SideBySideApp(),
  ));
}
