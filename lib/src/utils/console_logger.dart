import 'package:intl/intl.dart';
import 'package:logging/logging.dart';


const String reset = '[0m';
const String red = '[31m';
const String green = '[32m';
const String yellow = '[33m';
const String blue = '[34m';
const String cyan = '[36m';
const String magenta = '[35m';

class ConsoleLogger {
  final Logger _logger;

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

  void startSpinner(String message) {
    info(message);
  }

  void stopSpinner({bool success = true, String? message}) {
    if (success) {
      info(message ?? 'Done.');
    } else {
      severe(message ?? 'Failed.');
    }
  }

  static void initialize() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final emoji = _getEmojiForLevel(record.level);
      
      final time = DateFormat('HH:mm:ss').format(record.time);

      // Using print here is acceptable for CLI logging output
      // ignore: avoid_print
      print('$emoji [$time] ${record.message}');
    });
  }

  

  static String _getEmojiForLevel(Level level) {
    if (level == Level.SEVERE) {
      return '💥';
    } else if (level == Level.WARNING) {
      return '⚠️';
    } else if (level == Level.INFO) {
      return 'ℹ️';
    } else if (level == Level.CONFIG) {
      return '⚙️';
    } else if (level == Level.FINE) {
      return '✨';
    } else if (level == Level.FINER) {
      return '🔍';
    } else if (level == Level.FINEST) {
      return '🔬';
    }
    return '✅';
  }
}
