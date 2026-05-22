import 'package:flutter/foundation.dart';

const int _ringBufferSize = 20;

final List<String> _buffer = [];

void _log(String tag, String message) {
  final entry = '[${DateTime.now().toIso8601String()}] $tag $message';
  if (kDebugMode) {
    // ignore: avoid_print
    print(entry);
  }
  _buffer.add(entry);
  if (_buffer.length > _ringBufferSize) _buffer.removeAt(0);
}

abstract final class Log {
  static void auth(String msg) => _log('[AUTH]', msg);
  static void chat(String msg) => _log('[CHAT]', msg);
  static void rtc(String msg) => _log('[RTC]', msg);
  static void schedule(String msg) => _log('[SCHEDULE]', msg);
  static void api(String msg) => _log('[API]', msg);
  static void store(String msg) => _log('[STORE]', msg);
  static void debug(String msg) => _log('[DEBUG]', msg);

  static List<String> get buffer => List.unmodifiable(_buffer);
  static void clear() => _buffer.clear();

  static String copyable() => _buffer.join('\n');
}
