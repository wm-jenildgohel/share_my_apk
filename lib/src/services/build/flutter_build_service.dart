import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:share_my_apk/src/constants/upload_limits.dart';
import 'package:share_my_apk/src/exceptions/build_exception.dart';
import 'package:share_my_apk/src/services/build/apk_organizer_service.dart';
import 'package:share_my_apk/src/services/build/apk_parser_service.dart';
import 'package:share_my_apk/src/utils/console_logger.dart';
import 'package:share_my_apk/src/utils/flutter_version_checker.dart';

class FlutterBuildService {
  final ApkParserService _apkParserService;
  final ApkOrganizerService _apkOrganizerService;
  final ConsoleLogger? _logger;

  FlutterBuildService({
    ApkParserService? apkParserService,
    ApkOrganizerService? apkOrganizerService,
    ConsoleLogger? logger,
  }) : _apkParserService = apkParserService ?? ApkParserService(),
       _apkOrganizerService = apkOrganizerService ?? ApkOrganizerService(),
       _logger = logger;

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
  /// Throws [BuildException] if the build fails.
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

    // Validate working directory
    if (!Directory(workingDir).existsSync()) {
      throw BuildException(
        'Project path does not exist',
        workingDirectory: workingDir,
      );
    }

    final buildType = release ? 'release' : 'debug';

    _logger?.info('🚀 Starting comprehensive APK build (mode: $buildType)...');

    // Check Flutter version compatibility
    await FlutterVersionChecker.checkFlutterVersion();

    final flutterCommand = _detectFlutterCommand(workingDir);
    _logger?.fine('Using Flutter command: $flutterCommand');

    try {
      await _runBuildPipeline(
        flutterCommand,
        workingDir,
        buildType,
        clean,
        getPubDeps,
        generateL10n,
        verbose,
      );

      final result = await _runSecureCommand(
        flutterCommand,
        ['build', 'apk', '--$buildType'],
        workingDir,
        'Building APK ($buildType mode)...',
        verbose,
      );

      if (result.exitCode == 0) {
        final buildOutput = result.stdout as String;
        _logger?.fine('Build output:\n$buildOutput');

        final originalApkPath = _apkParserService.getApkPath(
          buildOutput,
          projectPath,
        );
        if (originalApkPath != null) {
          _logger?.info('✅ APK built successfully: $originalApkPath');

          final finalApkPath = await _apkOrganizerService.organize(
            originalApkPath,
            projectPath,
            customName,
            environment,
            outputDir,
          );

          return finalApkPath;
        } else {
          _logger?.severe('🔥 Could not find APK path in build output.');
          throw BuildException(
            'Could not find APK path in build output',
            exitCode: result.exitCode,
            stdout: result.stdout as String?,
            workingDirectory: workingDir,
          );
        }
      } else {
        _logger?.severe(
          '🔥 APK build failed with exit code ${result.exitCode}:',
        );
        _logger?.severe(result.stderr.toString());
        throw BuildException(
          'Flutter build failed',
          exitCode: result.exitCode,
          stdout: result.stdout as String?,
          stderr: result.stderr as String?,
          workingDirectory: workingDir,
        );
      }
    } on TimeoutException catch (e) {
      throw BuildException(
        'Build timeout: ${e.message}',
        workingDirectory: workingDir,
      );
    } on ProcessException catch (e) {
      throw BuildException(
        'Failed to execute Flutter command: ${e.message}',
        workingDirectory: workingDir,
      );
    } catch (e) {
      if (e is BuildException) rethrow;
      throw BuildException(
        'Unexpected build error: $e',
        workingDirectory: workingDir,
      );
    }
  }

  /// Executes a Flutter command securely using Process.run to prevent command injection.
  Future<ProcessResult> _runSecureCommand(
    String flutterCommand,
    List<String> args,
    String workingDir,
    String message,
    bool verbose,
  ) async {
    _logger?.startSpinner(message);

    // Split flutter command (handles 'fvm flutter' or 'flutter')
    final commandParts = flutterCommand.split(' ');
    final executable = commandParts.first;
    final baseArgs = commandParts.length > 1 ? commandParts.sublist(1) : <String>[];
    final allArgs = [...baseArgs, ...args];

    _logger?.fine('Executing: $executable ${allArgs.join(' ')}');

    try {
      final result = await Process.run(
        executable,
        allArgs,
        workingDirectory: workingDir,
        runInShell: false, // Prevent shell interpretation for security
      ).timeout(
        Duration(minutes: UploadLimits.buildTimeoutMinutes),
        onTimeout: () => throw TimeoutException(
          'Command timed out after ${UploadLimits.buildTimeoutMinutes} minutes',
        ),
      );

      _logger?.stopSpinner();

      if (verbose && result.stdout != null) {
        _logger?.fine(result.stdout as String);
      }

      return result;
    } catch (e) {
      _logger?.stopSpinner(success: false);
      rethrow;
    }
  }

  Future<void> _runBuildPipeline(
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
      await _runSecureCommand(
        flutterCommand,
        ['clean'],
        workingDir,
        '🧹 [1/4] Cleaning project...',
        verbose,
      );
    }

    // 2. Get dependencies
    if (getPubDeps) {
      await _runSecureCommand(
        flutterCommand,
        ['pub', 'get'],
        workingDir,
        '📦 [2/4] Getting dependencies...',
        verbose,
      );
    }

    // 3. Generate localizations if needed
    final l10nFile = File(p.join(workingDir, 'l10n.yaml'));
    if (generateL10n && l10nFile.existsSync()) {
      _logger?.fine('Found localizations directory, will generate l10n');
      await _runSecureCommand(
        flutterCommand,
        ['gen-l10n'],
        workingDir,
        '🌍 [3/4] Generating localizations...',
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
}
