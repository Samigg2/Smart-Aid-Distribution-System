import 'package:flutter/foundation.dart';

/// Logger utility to replace print statements
/// In production, logs are disabled
/// In debug mode, logs are printed
class Logger {
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '[LOG]';
      debugPrint('$prefix $message');
    }
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ERROR' : '[ERROR]';
      debugPrint('$prefix $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack: $stackTrace');
      }
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] INFO' : '[INFO]';
      debugPrint('$prefix $message');
    }
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] WARN' : '[WARN]';
      debugPrint('$prefix $message');
    }
  }
}


