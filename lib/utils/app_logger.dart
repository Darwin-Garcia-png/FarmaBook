import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error }

class AppLogger {
  AppLogger._();
  static final AppLogger _instance = AppLogger._();
  static AppLogger get instance => _instance;

  static const int _maxFileSize = 5 * 1024 * 1024; // 5 MB
  static const String _fileName = 'farmabook_log.txt';

  static File? _file;
  static final StreamController<String> _queue = StreamController<String>.broadcast();
  static StreamSubscription<String>? _worker;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    String dirPath;
    try {
      if (Platform.isWindows) {
        dirPath = '${Platform.environment['APPDATA'] ?? Directory.current.path}\\FarmaBook';
      } else if (Platform.isLinux || Platform.isMacOS) {
        dirPath = '${Platform.environment['HOME'] ?? Directory.current.path}/.farmabook';
      } else {
        dirPath = Directory.current.path;
      }
      final dir = Directory(dirPath);
      if (!await dir.exists()) await dir.create(recursive: true);

      _file = File('${dir.path}\\$_fileName');
      if (await _file!.exists() && await _file!.length() > _maxFileSize) {
        await _file!.writeAsString('');
      }
      await _file!.writeAsString(
        '\n=== FarmaBook Log Started at ${_ts()} ===\n',
        mode: FileMode.append,
      );
    } catch (e) {
      _file = null;
    }

    _worker = _queue.stream.listen((line) async {
      try {
        await _file?.writeAsString(line, mode: FileMode.append);
      } catch (_) {}
    });
  }

  static void _log(LogLevel level, String message, [Object? error, StackTrace? stack]) {
    final icon = switch (level) {
      LogLevel.debug => '🔍',
      LogLevel.info  => 'ℹ️',
      LogLevel.warn  => '⚠️',
      LogLevel.error => '❌',
    };
    final label = level.name.toUpperCase();
    final ts = _ts();
    final sb = StringBuffer('[$ts][$label] ');
    if (message.isNotEmpty) sb.write(message);
    if (error != null) sb.write(' | $error');
    if (stack != null) sb.write('\n$stack');
    final line = '${sb.toString()}\n';

    // Also print to console in debug mode
    debugPrint(line.trim());

    // Queue for file write (non-blocking)
    _queue.add(line);
  }

  static void d(String message) => _log(LogLevel.debug, message);
  static void i(String message) => _log(LogLevel.info, message);
  static void w(String message) => _log(LogLevel.warn, message);
  static void e(String message, [Object? error, StackTrace? stack]) => _log(LogLevel.error, message, error, stack);

  static void api(String method, String path, int statusCode, [Map<String, dynamic>? body]) {
    final truncated = body != null ? ' | ${body.toString().length.clamp(0, 500)}' : '';
    i('[API] $method $path → $statusCode$truncated');
  }

  static void screen(String name) => i('[SCREEN] $name');
  static void action(String action) => i('[ACTION] $action');
  static void auth(String msg) => i('[AUTH] $msg');

  static Future<void> dispose() async {
    await _worker?.cancel();
    await _queue.close();
  }

  static String _ts() {
    final n = DateTime.now();
    final ms = '${n.millisecond}'.padLeft(3, '0');
    return '${n.year}-${_p(n.month)}-${_p(n.day)} ${_p(n.hour)}:${_p(n.minute)}:${_p(n.second)}.$ms';
  }

  static String _p(int v) => v.toString().padLeft(2, '0');
}
