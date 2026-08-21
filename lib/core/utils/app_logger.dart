import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
  );

  static void d(String tag, String message) {
    _logger.d('[$tag] $message');
  }

  static void i(String tag, String message) {
    _logger.i('[$tag] $message');
  }

  static void w(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _logger.w('[$tag] $message', error: error, stackTrace: stackTrace);
  }

  static void e(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e('[$tag] $message', error: error, stackTrace: stackTrace);
  }
}
