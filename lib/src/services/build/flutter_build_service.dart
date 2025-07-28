import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';
import 'package:share_my_apk/src/utils/console_logger.dart';

class FlutterBuildService {
  final ConsoleLogger? _logger;

  FlutterBuildService({
    ConsoleLogger? logger,
  }) : _logger = logger;

  /// Builds a Flutter Android APK with comprehensive build pipeline.
  ///
  /// - [release]: Whether to build in release mode. Defaults to `true`.
  /// - [projectPath]: The path to the Flutter project. Defaults to the current directory.
  /// - [customName]: A custom name for the APK file.
  /// - [environment]: The build environment (e.g., 'dev', 'prod').
  /// - [outputDir]: The directory to save the final APK file.
  /// - [clean]: Whether to run flutter clean before build. Defaults to `true`.
  /// - [getPubDeps]: Whether to run pub get before build. Defaults to `true`.
  /// - [generateL10n]: Whether to generate localizations. Defaults to `true`.
  ///
  /// Returns the path to the built and organized APK file.
  Future<String> build({
    bool release = true,
    String? projectPath,
    String? customName,
    String? environment,
    String? outputDir,
    bool clean = true,
    bool getPubDeps = true,
    bool generateL10n = true,
    bool verbose = false,
  }) async {
    final workingDir = projectPath ?? Directory.current.path;
    final shell = Shell(workingDirectory: workingDir);
    final buildType = release ? 'release' : 'debug';

    _logger?.info('Starting comprehensive APK build (mode: $buildType)...');

    final flutterCommand = _detectFlutterCommand(workingDir);
    _logger?.fine('Using Flutter command: $flutterCommand');

    await _runBuildPipeline(
      shell,
      flutterCommand,
      workingDir,
      buildType,
      clean,
      getPubDeps,
      generateL10n,
      verbose,
    );

    final result = await _runCommand(
      shell,
      '$flutterCommand build apk --$buildType',
      'Building APK ($buildType mode)...',
      verbose,
    );

    if (result.first.exitCode == 0) {
      final buildOutput = result.outText;
      _logger?.fine('Build output:\n$buildOutput');

      final originalApkPath = _parseApkPath(buildOutput, projectPath);
      if (originalApkPath != null) {
        _logger?.info('APK built successfully: $originalApkPath');

        final finalApkPath = await _organizeApk(
          originalApkPath,
          projectPath,
          customName,
          environment,
          outputDir,
        );

        return finalApkPath;
      } else {
        _logger?.severe('Could not find APK path in build output.');
        throw Exception('APK build failed: Could not find APK path.');
      }
    } else {
      _logger?.severe(
        'APK build failed with exit code ${result.first.exitCode}:',
      );
      _logger?.severe(result.errText);
      throw Exception('APK build failed.');
    }
  }

  Future<List<ProcessResult>> _runCommand(
    Shell shell,
    String command,
    String message,
    bool verbose,
  ) async {
    _logger?.startProgress(message);
    try {
      final result = await shell.run(command);
      _logger?.stopProgress();
      if (verbose) {
        _logger?.fine(result.map((line) => line.outText).join('\n'));
      }
      return result;
    } catch (e) {
      _logger?.stopProgress(success: false);
      rethrow;
    }
  }

  Future<void> _runBuildPipeline(
    Shell shell,
    String flutterCommand,
    String workingDir,
    String buildType,
    bool clean,
    bool getPubDeps,
    bool generateL10n,
    bool verbose,
  ) async {
    // 1. Clean project
    if (clean) {
      await _runCommand(
        shell,
        '$flutterCommand clean',
        'Cleaning project...',
        verbose,
      );
    }

    // 2. Get dependencies
    if (getPubDeps) {
      await _runCommand(
        shell,
        '$flutterCommand pub get',
        'Getting dependencies...',
        verbose,
      );
    }

    // 3. Generate localizations if needed
    final l10nFile = File(p.join(workingDir, 'l10n.yaml'));
    if (generateL10n && l10nFile.existsSync()) {
      _logger?.fine('Found localizations directory, will generate l10n');
      await _runCommand(
        shell,
        '$flutterCommand gen-l10n',
        'Generating localizations...',
        verbose,
      );
    }
  }

  String _detectFlutterCommand(String workingDir) {
    final fvmConfig = File(p.join(workingDir, '.fvm', 'fvm_config.json'));
    if (fvmConfig.existsSync()) {
      _logger?.fine('FVM config found, using fvm flutter command.');
      return 'fvm flutter';
    } else {
      _logger?.fine('No FVM config found, using global flutter command.');
      return 'flutter';
    }
  }

  /// Parses the build output to extract APK path
  String? _parseApkPath(String buildOutput, String? projectPath) {
    final regex = RegExp(r'Built\s+(.+\.apk)');
    final match = regex.firstMatch(buildOutput);

    if (match != null) {
      final capturedPath = match.group(1);
      if (capturedPath != null) {
        final fullPath = p.join(projectPath ?? '.', capturedPath);
        _logger?.info('Found APK at: $fullPath');
        return fullPath;
      }
    }
    _logger?.warning('Could not extract APK path from build output.');
    return null;
  }

  /// Organizes the APK by moving and renaming it based on provided options
  Future<String> _organizeApk(
    String originalApkPath,
    String? projectPath,
    String? customName,
    String? environment,
    String? outputDir,
  ) async {
    final originalFile = File(originalApkPath);
    if (!await originalFile.exists()) {
      _logger?.severe('Original APK file not found at: $originalApkPath');
      throw Exception('Built APK file not found.');
    }

    if (customName == null && environment == null && outputDir == null) {
      _logger?.info('No organization options provided. Using original APK path.');
      return originalApkPath;
    }

    final appInfo = _getAppInfo(projectPath);
    final fileName = _generateFileName(customName, appInfo);
    final destDir = _createDestinationDirectory(outputDir, environment, projectPath);
    final finalApkPath = p.join(destDir, '$fileName.apk');

    _logger?.info('Organizing APK to: $finalApkPath');

    try {
      await originalFile.copy(finalApkPath);
      _logger?.info('Successfully copied APK to final destination.');
    } catch (e) {
      _logger?.severe('Failed to copy APK to destination: $e');
      throw Exception('Failed to organize APK.');
    }

    return finalApkPath;
  }

  Map<String, String> _getAppInfo(String? projectPath) {
    final pubspecPath = p.join(projectPath ?? '.', 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);

    if (!pubspecFile.existsSync()) {
      _logger?.warning('pubspec.yaml not found at $pubspecPath');
      return {'name': 'app', 'version': '1.0.0'};
    }

    try {
      final content = pubspecFile.readAsStringSync();
      final lines = content.split('\n');
      
      String name = 'app';
      String version = '1.0.0';
      
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('name:')) {
          name = trimmed.substring(5).trim().replaceAll(RegExp(r'["\x27]'), '');
        } else if (trimmed.startsWith('version:')) {
          version = trimmed.substring(8).trim().replaceAll(RegExp(r'["\x27]'), '');
        }
      }

      return {'name': name, 'version': version};
    } catch (e) {
      _logger?.warning('Error reading pubspec.yaml: $e');
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
      _logger?.info('Creating directory: $finalDir');
      directory.createSync(recursive: true);
    }

    return finalDir;
  }
}
