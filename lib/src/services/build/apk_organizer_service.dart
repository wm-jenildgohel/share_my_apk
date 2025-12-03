import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// A service for organizing and renaming built APK files.
class ApkOrganizerService {
  static final Logger _logger = Logger('ApkOrganizerService');

  /// Organizes a built APK file by moving and renaming it based on the
  /// provided options.
  ///
  /// Returns the final path to the organized APK file.
  /// Throws [ArgumentError] if inputs contain path traversal attempts.
  Future<String> organize(
    String originalApkPath,
    String? projectPath,
    String? customName,
    String? environment,
    String? outputDir,
  ) async {
    // Validate APK file
    _validateApkPath(originalApkPath);

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

    // Sanitize user inputs to prevent path traversal
    final safeName = customName != null ? _sanitizeFileName(customName) : null;
    final safeEnv = environment != null ? _sanitizeFileName(environment) : null;

    final appInfo = _getAppInfo(projectPath);
    final fileName = _generateFileName(safeName, appInfo);
    final destDir = _createDestinationDirectory(
      outputDir,
      safeEnv,
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

  /// Validates that the APK file path is safe and exists.
  void _validateApkPath(String path) {
    if (!path.endsWith('.apk')) {
      throw ArgumentError('File is not an APK: $path');
    }

    // Check for path traversal attempts in the file path
    if (path.contains('..')) {
      throw ArgumentError(
        'Invalid APK path: path traversal detected in "$path"',
      );
    }
  }

  /// Sanitizes a file name to prevent path traversal and dangerous characters.
  ///
  /// Removes/replaces:
  /// - Directory separators (/, \)
  /// - Path traversal sequences (..)
  /// - Special characters (<, >, :, ", |, ?, *)
  String _sanitizeFileName(String input) {
    if (input.isEmpty) {
      throw ArgumentError('File name cannot be empty');
    }

    // Remove/replace dangerous characters
    var sanitized = input
        .replaceAll(RegExp(r'[<>:"|?*\\/]'), '_')
        .replaceAll(RegExp(r'\.\.+'), '.');

    // Prevent path traversal
    if (sanitized.contains('..') ||
        sanitized.startsWith('/') ||
        sanitized.startsWith('\\') ||
        sanitized.contains(r'\') ||
        sanitized.contains('/')) {
      throw ArgumentError(
        'Invalid file name: path traversal detected in "$input"',
      );
    }

    // Limit length to prevent file system issues
    if (sanitized.length > 200) {
      sanitized = sanitized.substring(0, 200);
      _logger.warning('File name truncated to 200 characters');
    }

    // Remove leading/trailing whitespace and dots
    sanitized = sanitized.trim().replaceAll(RegExp(r'^\.+|\.+$'), '');

    if (sanitized.isEmpty) {
      throw ArgumentError(
        'File name becomes empty after sanitization: "$input"',
      );
    }

    return sanitized;
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
