import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// A service for organizing and renaming built APK files.
/// A service for organizing and renaming built APK files.
class ApkOrganizerService {
  static final Logger _logger = Logger('ApkOrganizerService');

  /// Creates an instance of [ApkOrganizerService].
  const ApkOrganizerService();

  /// Organizes a built APK file by moving and renaming it based on the
  /// provided options.
  ///
  /// Returns the final path to the organized APK file.
  Future<String> organize(
    String originalApkPath,
    String? projectPath,
    String? customName,
    String? environment,
    String? outputDir,
  ) async {
    final originalFile = File(originalApkPath);
    if (!await originalFile.exists()) {
      _logger.severe('Original APK file not found at: $originalApkPath');
      throw Exception('Built APK file not found.');
    }

    if (customName == null && environment == null && outputDir == null) {
      _logger.info(
        'No organization options provided. Using original APK path.',
      );
      return originalApkPath;
    }

    final appInfo = _getAppInfo(projectPath);
    final fileName = _generateFileName(customName, appInfo);
    final destDir = _createDestinationDirectory(
      outputDir,
      environment,
      projectPath,
    );
    final finalApkPath = p.join(destDir, '$fileName.apk');

    _logger.info('Organizing APK to: $finalApkPath');

    try {
      await originalFile.copy(finalApkPath);
      _logger.info('Successfully copied APK to final destination.');
    } catch (e) {
      _logger.severe('Failed to copy APK to destination: $e');
      throw Exception('Failed to organize APK.');
    }

    return finalApkPath;
  }

  Map<String, String> _getAppInfo(String? projectPath) {
    final pubspecPath = p.join(projectPath ?? '.', 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);

    if (!pubspecFile.existsSync()) {
      _logger.warning('pubspec.yaml not found at $pubspecPath');
      return {'name': 'app', 'version': '1.0.0'};
    }

    try {
      final content = pubspecFile.readAsStringSync();
      final yaml = loadYaml(content);

      return {
        'name': yaml['name']?.toString() ?? 'app',
        'version': yaml['version']?.toString() ?? '1.0.0',
      };
    } catch (e) {
      _logger.warning('Error reading pubspec.yaml: $e');
      return {'name': 'app', 'version': '1.0.0'};
    }
  }

  String _generateFileName(String? customName, Map<String, String> appInfo) {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.T-]'), '_')
        .split('_')
        .take(6)
        .join('_');

    final appName = customName ?? appInfo['name']!;
    final version = appInfo['version']!;
    return '${appName}_${version}_$timestamp';
  }

  String _createDestinationDirectory(
    String? outputDir,
    String? environment,
    String? projectPath,
  ) {
    String baseDir;
    if (outputDir != null) {
      baseDir = outputDir;
    } else {
      baseDir = p.join(projectPath ?? '.', 'build', 'apk');
    }

    String finalDir = baseDir;
    if (environment != null && environment.isNotEmpty) {
      finalDir = p.join(baseDir, environment);
    }

    final directory = Directory(finalDir);
    if (!directory.existsSync()) {
      _logger.info('Creating directory: $finalDir');
      directory.createSync(recursive: true);
    }

    return finalDir;
  }
}
