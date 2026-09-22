import 'dart:developer' as dev;

/// App logging, visible in `flutter run`, DevTools and logcat.
/// Invariant: never log user data (dates, logs, settings values) — events
/// and errors only. This is a cycle-tracking app; logs must stay private-safe.
void logInfo(String tag, String message) => dev.log(message, name: tag);

void logWarn(String tag, String message) =>
    dev.log(message, name: tag, level: 900);

void logErr(String tag, Object error, [StackTrace? stack]) =>
    dev.log('$error', name: tag, error: error, stackTrace: stack, level: 1000);
