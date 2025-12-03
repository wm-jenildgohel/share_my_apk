import 'dart:io';
import 'package:logging/logging.dart';

/// Utility for checking Flutter SDK version compatibility.
class FlutterVersionChecker {
  static final Logger _logger = Logger('FlutterVersionChecker');

  /// Minimum recommended Flutter version.
  static const int minMajorVersion = 3;
  static const int minMinorVersion = 10;
  static const String minVersionString = '$minMajorVersion.$minMinorVersion.0';

  /// Checks if the installed Flutter SDK meets minimum requirements.
  ///
  /// Returns true if version is acceptable, false otherwise.
  /// Logs warnings if version is below recommended.
  static Future<bool> checkFlutterVersion() async {
    try {
      _logger.fine('Checking Flutter SDK version...');

      final result = await Process.run('flutter', ['--version']);

      if (result.exitCode != 0) {
        _logger.warning(
          '⚠️  Could not verify Flutter version. Assuming compatible.',
        );
        return true; // Assume compatible if we can't check
      }

      final output = result.stdout as String;
      _logger.finest('Flutter version output: $output');

      // Parse version from output
      final versionMatch = RegExp(r'Flutter (\d+)\.(\d+)\.(\d+)').firstMatch(output);

      if (versionMatch != null) {
        final major = int.parse(versionMatch.group(1)!);
        final minor = int.parse(versionMatch.group(2)!);
        final patch = int.parse(versionMatch.group(3)!);

        final currentVersion = '$major.$minor.$patch';
        _logger.fine('Detected Flutter version: $currentVersion');

        // Check if version meets minimum requirements
        if (major < minMajorVersion ||
            (major == minMajorVersion && minor < minMinorVersion)) {
          _logger.warning(
            '⚠️  Flutter version $currentVersion detected. '
            'Minimum recommended: $minVersionString.',
          );
          _logger.warning(
            '   Some features may not work correctly with older versions.',
          );
          _logger.info(
            '💡 Update Flutter: flutter upgrade',
          );
          return false;
        } else {
          _logger.fine('✓ Flutter version $currentVersion is compatible');
          return true;
        }
      } else {
        _logger.warning(
          '⚠️  Could not parse Flutter version from output. '
          'Assuming compatible.',
        );
        return true;
      }
    } catch (e) {
      _logger.warning(
        '⚠️  Error checking Flutter version: $e. Assuming compatible.',
      );
      return true; // Don't block if we can't check
    }
  }

  /// Gets the current Flutter SDK version as a string.
  ///
  /// Returns null if version cannot be determined.
  static Future<String?> getFlutterVersion() async {
    try {
      final result = await Process.run('flutter', ['--version']);

      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final versionMatch = RegExp(r'Flutter (\d+\.\d+\.\d+)').firstMatch(output);
        return versionMatch?.group(1);
      }
    } catch (e) {
      _logger.fine('Could not get Flutter version: $e');
    }
    return null;
  }

  /// Checks if Flutter SDK is installed and accessible.
  static Future<bool> isFlutterInstalled() async {
    try {
      final result = await Process.run('flutter', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
