import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

/// A service for parsing the output of the `flutter build apk` command to
/// find the path to the generated APK file.
/// A service for parsing the output of the `flutter build apk` command to
/// find the path to the generated APK file.
class ApkParserService {
  static final Logger _logger = Logger('ApkParserService');

  /// Creates an instance of [ApkParserService].
  const ApkParserService();

  /// Parses the build output and returns the path to the generated APK file.
  ///
  /// Returns `null` if the APK path cannot be determined from the output.
  String? getApkPath(String buildOutput, String? projectPath) {
    final regex = RegExp(r'Built\s+(.+\.apk)');
    final match = regex.firstMatch(buildOutput);

    if (match != null) {
      final capturedPath = match.group(1);
      if (capturedPath != null) {
        final fullPath = p.join(projectPath ?? '.', capturedPath);
        _logger.info('Found APK at: $fullPath');
        return fullPath;
      }
    }
    _logger.warning('Could not extract APK path from build output.');
    return null;
  }
}
