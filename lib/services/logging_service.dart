import 'package:logger/logger.dart';

/// Simple centralized logging helper using logger package.
/// Usage: Log.d('message'), Log.i('message'), Log.w('warn'),
/// Log.e('error message', error: e, stackTrace: st)
class Log {
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      printEmojis: true,
      colors: true,
    ),
  );

  static void d(String message, {String? tag}) {
    _logger.d('${tag != null ? "[$tag] " : ""}$message');
  }

  static void i(String message, {String? tag}) {
    _logger.i('${tag != null ? "[$tag] " : ""}$message');
  }

  static void w(String message, {String? tag}) {
    _logger.w('${tag != null ? "[$tag] " : ""}$message');
  }

  static void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _logger.e(
      '${tag != null ? "[$tag] " : ""}$message',
      error: error,
      stackTrace: stackTrace,
    );
  }
}


