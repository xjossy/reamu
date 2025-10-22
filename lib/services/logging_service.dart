import 'dart:developer' as dev;

/// Simple centralized logging helper.
/// Usage: Log.d('message'), Log.i('message'), Log.w('warn'),
/// Log.e('error message', error: e, stackTrace: st)
class Log {
  static const String _defaultTag = 'Reamu';

  static void d(String message, {String? tag}) {
    dev.log(message, name: tag ?? _defaultTag, level: 500); // fine level
  }

  static void i(String message, {String? tag}) {
    dev.log(message, name: tag ?? _defaultTag, level: 800); // info
  }

  static void w(String message, {String? tag}) {
    dev.log(message, name: tag ?? _defaultTag, level: 900); // warning
  }

  static void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    dev.log(
      message,
      name: tag ?? _defaultTag,
      level: 1000, // severe
      error: error,
      stackTrace: stackTrace,
    );
  }
}


