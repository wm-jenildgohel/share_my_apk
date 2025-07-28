import 'package:logging/logging.dart';

class ConsoleLogger {
  final Logger _logger;
  String? _currentProgressMessage;

  ConsoleLogger(String name) : _logger = Logger(name);

  void info(String message) {
    _logger.info(message);
  }

  void warning(String message) {
    _logger.warning(message);
  }

  void severe(String message) {
    _logger.severe(message);
  }

  void fine(String message) {
    _logger.fine(message);
  }

  void startProgress(String message) {
    _currentProgressMessage = message;
    info('$message...');
  }

  void stopProgress({bool success = true, String? message}) {
    if (_currentProgressMessage != null) {
      final status = success ? 'DONE' : 'FAILED';
      final statusMessage = message ?? _currentProgressMessage!;
      info('$statusMessage - $status');
      _currentProgressMessage = null;
    }
  }

  static void initialize() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final prefix = _getPrefixForLevel(record.level);
      final time = '${record.time.hour.toString().padLeft(2, '0')}:${record.time.minute.toString().padLeft(2, '0')}:${record.time.second.toString().padLeft(2, '0')}';

      // Using print here is acceptable for CLI logging output
      // ignore: avoid_print
      print('[$time] $prefix ${record.message}');
    });
  }

  static String _getPrefixForLevel(Level level) {
    if (level == Level.SEVERE) {
      return 'ERROR:';
    } else if (level == Level.WARNING) {
      return 'WARN: ';
    } else if (level == Level.INFO) {
      return 'INFO: ';
    } else if (level == Level.CONFIG) {
      return 'CONFIG:';
    } else if (level == Level.FINE) {
      return 'DEBUG:';
    }
    return 'LOG:  ';
  }
}
