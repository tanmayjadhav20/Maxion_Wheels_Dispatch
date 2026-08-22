import 'package:flutter/foundation.dart';

void perfLog(String message) {
  if (kDebugMode) {
    debugPrint('[PERF] ${DateTime.now().toIso8601String()} - $message');
  }
}
