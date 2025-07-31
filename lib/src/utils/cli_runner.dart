import 'dart:io';

import 'package:share_my_apk/share_my_apk.dart';
import 'package:share_my_apk/src/utils/console_logger.dart';
import 'package:share_my_apk/src/utils/message_util.dart' as message_util;
import 'package:share_my_apk/src/utils/sound_notification_util.dart';
import 'package:share_my_apk/src/version.dart';

class CliRunner {
  final ConsoleLogger _logger;

  CliRunner() : _logger = ConsoleLogger('main');

  Future<void> run(List<String> arguments) async {
    try {
      _printWelcomeMessage(packageVersion);

      final argParserUtil = ArgParserUtil();
      final options = argParserUtil.parse(arguments);

      _showConfigurationInfo(options);

      final apkBuilder = FlutterBuildService(logger: _logger);

      final apkPath = await apkBuilder.build(
        release: options.isRelease,
        projectPath: options.path ?? '.',
        customName: options.customName,
        environment: options.environment,
        outputDir: options.outputDir,
        clean: options.clean,
        getPubDeps: options.getPubDeps,
        generateL10n: options.generateL10n,
        verbose: options.verbose,
      );

      final apkFile = File(apkPath);
      final fileSize = await apkFile.length();
      final fileSizeMB = (fileSize / 1024 / 1024);
      var provider = options.provider;
      String? token;

      _logger.info('APK Information:');
      _logger.info('   • File: ${apkFile.path.split('/').last}');
      _logger.info(
        '   • Size: ${fileSizeMB.toStringAsFixed(2)} MB ($fileSize bytes)',
      );
      _logger.info('   • Location: $apkPath');

      if (provider == 'diawi' && fileSize > 70 * 1024 * 1024) {
        _logger.warning(
          'Smart Provider Switch: APK size (${fileSizeMB.toStringAsFixed(1)} MB) exceeds Diawi\'s 70MB limit.',
        );
        _logger.info(
          'Automatically switching to Gofile.io for better compatibility...',
        );
        provider = 'gofile';
        token = options.gofileToken;
      } else if (provider == 'diawi') {
        token = options.diawiToken;
        _logger.info('Using Diawi (great for team sharing, 70MB limit)');
        if (token == null) {
          _logger.warning(
            'No Diawi token found. Get one at: https://dashboard.diawi.com/profile/api',
          );
        }
      } else if (provider == 'gofile') {
        token = options.gofileToken;
        _logger.info('Using Gofile.io (no size limits, requires token)');
        if (token == null) {
          _logger.warning(
            'No Gofile token found. Get one at: https://gofile.io/api',
          );
        }
      } else if (provider == 'firebase') {
        _logger.info('Using Firebase App Distribution (enterprise-grade distribution)');
        if (options.firebaseProjectId == null) {
          _logger.warning('No Firebase project ID provided');
        }
        if (options.firebaseAppId == null) {
          _logger.warning('No Firebase app ID provided');
        }
      }

      final uploader = UploadServiceFactory.create(
        provider,
        token: token,
        projectId: options.firebaseProjectId,
        appId: options.firebaseAppId,
        serviceAccountPath: options.firebaseServiceAccountPath,
        releaseNotes: options.firebaseReleaseNotes,
        testers: options.firebaseTesters,
        groups: options.firebaseGroups,
      );

      _logger.info('Starting Upload Process...');
      _logger.info('   • Provider: $provider');
      _logger.info('   • File size: ${fileSizeMB.toStringAsFixed(2)} MB');
      if (token != null) {
        _logger.info('   • Authentication: Token provided');
      } else {
        _logger.info('   • Authentication: Missing token (will fail)');
      }

      final downloadLink = await uploader.upload(apkPath);

      if (options.sound) {
        SoundNotificationUtil.playNotificationSound();
      }

      stdout.writeln('\n' * 3);
      message_util.MessageUtil.printSuccessBox(provider, downloadLink);
    } on ArgumentError catch (e) {
      _logger.severe('Configuration Error: ${e.message}');
      message_util.MessageUtil.printHelpfulSuggestions();
      exit(1);
    } on ProcessException catch (e) {
      _logger.severe('Build Error: ${e.message}');
      message_util.MessageUtil.printBuildErrorSuggestions();
      exit(1);
    } on SocketException catch (e) {
      _logger.severe('Network Error: ${e.message}');
      message_util.MessageUtil.printNetworkErrorSuggestions();
      exit(1);
    } on HttpException catch (e) {
      _logger.severe('Upload Error: ${e.message}');
      message_util.MessageUtil.printUploadErrorSuggestions();
      exit(1);
    } catch (e) {
      _logger.severe('Unexpected Error: $e');
      message_util.MessageUtil.printGeneralErrorSuggestions();
      exit(1);
    }
  }

  void _printWelcomeMessage(String version) {
    _logger.info('Share My APK v$version');
    _logger.info('Flutter APK Build & Upload Tool');
    _logger.info('');
  }


  void _showConfigurationInfo(CliOptions options) {
    _logger.info('Configuration loaded:');

    final envConfigFile = File('.shareMyApk');
    final homeConfigFile = File('${Platform.environment['HOME'] ?? '.'}/.shareMyApk');
    final hasEnvVars = Platform.environment.containsKey('DIAWI_TOKEN') || 
                       Platform.environment.containsKey('GOFILE_TOKEN') ||
                       Platform.environment.containsKey('FIREBASE_PROJECT_ID');

    if (hasEnvVars) {
      _logger.info('   • Source: Environment variables');
    } else if (envConfigFile.existsSync()) {
      _logger.info('   • Source: .shareMyApk (project)');
    } else if (homeConfigFile.existsSync()) {
      _logger.info('   • Source: ~/.shareMyApk (global)');
    } else {
      _logger.info('   • Source: CLI arguments + defaults');
      _logger.info('   Run --init to create simple config file');
    }

    _logger.info('   • Project: ${options.path ?? "."}');
    _logger.info('   • Build mode: ${options.isRelease ? "release" : "debug"}');
    _logger.info('   • Provider: ${options.provider}');

    if (options.customName != null) {
      _logger.info('   • Custom name: ${options.customName}');
    }
    if (options.environment != null) {
      _logger.info('   • Environment: ${options.environment}');
    }
    if (options.outputDir != null) {
      _logger.info('   • Output dir: ${options.outputDir}');
    }
    if (options.provider == 'firebase') {
      if (options.firebaseProjectId != null) {
        _logger.info('   • Firebase project: ${options.firebaseProjectId}');
      }
      if (options.firebaseAppId != null) {
        _logger.info('   • Firebase app: ${options.firebaseAppId}');
      }
      if (options.firebaseTesters?.isNotEmpty == true) {
        _logger.info('   • Firebase testers: ${options.firebaseTesters!.length} emails');
      }
      if (options.firebaseGroups?.isNotEmpty == true) {
        _logger.info('   • Firebase groups: ${options.firebaseGroups!.join(", ")}');
      }
    }

    stdout.writeln('');
  }
}
