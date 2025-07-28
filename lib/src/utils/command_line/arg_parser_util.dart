import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:share_my_apk/src/models/cli_options.dart';
import 'package:share_my_apk/src/services/config_service.dart';

/// A utility class for parsing command-line arguments.
/// A utility class for parsing command-line arguments.
class ArgParserUtil {
  late final ArgParser _parser;
  static const _help = 'help';
  static const _init = 'init';
  static const _diawiToken = 'diawi-token';
  static const _gofileToken = 'gofile-token';
  static const _path = 'path';
  static const _release = 'release';
  static const _provider = 'provider';
  static const _customName = 'name';
  static const _environment = 'environment';
  static const _outputDir = 'output-dir';
  static const _clean = 'clean';
  static const _getPubDeps = 'pub-get';
  static const _generateL10n = 'gen-l10n';
  static const _verbose = 'verbose';
  static const _sound = 'sound';

  /// Creates an instance of [ArgParserUtil] and initializes the argument parser.
  ArgParserUtil() {
    _parser = ArgParser();
    _parser.addFlag(
      _help,
      abbr: 'h',
      help: 'Show this help message.',
      negatable: false,
    );
    _parser.addFlag(
      _init,
      help: 'Generate a `share_my_apk.yaml` configuration file.',
      negatable: false,
    );
    _parser.addOption(
      _provider,
      help:
          'The upload provider to use.\n[diawi, gofile] (reads from config file)',
      allowed: ['diawi', 'gofile'],
    );
    _parser.addOption(_diawiToken, help: 'Your Diawi API token.');
    _parser.addOption(_gofileToken, help: 'Your Gofile API token.');
    _parser.addOption(
      _path,
      abbr: 'p',
      help: 'The path to your Flutter project.',
      defaultsTo: '.',
    );
    _parser.addFlag(
      _release,
      help: 'Build the APK in release mode.',
      defaultsTo: true,
    );
    _parser.addOption(
      _customName,
      abbr: 'n',
      help: 'Custom name for the APK file.',
    );
    _parser.addOption(
      _environment,
      abbr: 'e',
      help: 'Environment folder for organizing builds.',
    );
    _parser.addOption(
      _outputDir,
      abbr: 'o',
      help: 'Output directory for the built APK.',
    );
    _parser.addFlag(
      _clean,
      help: 'Run `flutter clean` before building.',
      defaultsTo: true,
    );
    _parser.addFlag(
      _getPubDeps,
      help: 'Run `flutter pub get` before building.',
      defaultsTo: true,
    );
    _parser.addFlag(
      _generateL10n,
      help: 'Run `flutter gen-l10n` before building.',
      defaultsTo: true,
    );
    _parser.addFlag(
      _verbose,
      abbr: 'v',
      help: 'Show verbose output.',
      defaultsTo: false,
    );
    _parser.addFlag(
      _sound,
      abbr: 's',
      help: 'Play sound notification after successful upload.',
      defaultsTo: true,
    );
  }

  /// Parses the command-line arguments and returns a [CliOptions] object.
  ///
  /// Throws an [ArgumentError] if the token is not provided when required.
  CliOptions parse(List<String> args) {
    final argResults = _parser.parse(args);

    if (argResults[_help] as bool) {
      _printHelp(_parser.usage);
      exit(0);
    }

    if (argResults[_init] as bool) {
      _generateConfigFile();
      exit(0);
    }

    final config = ConfigService.getConfig();

    final provider =
        argResults[_provider] as String? ??
        (config['provider']?.toString() ?? 'diawi');

    final diawiToken =
        argResults[_diawiToken] as String? ?? config['diawi_token']?.toString();
    final gofileToken =
        argResults[_gofileToken] as String? ??
        config['gofile_token']?.toString();

    String? token;
    if (provider == 'diawi') {
      token = diawiToken;
    } else if (provider == 'gofile') {
      token = gofileToken;
    }

    final path = argResults[_path] as String? ?? config['path']?.toString();
    final isRelease =
        argResults[_release] as bool? ?? (config['release'] as bool? ?? true);
    final customName =
        argResults[_customName] as String? ?? config['name']?.toString();
    final environment =
        argResults[_environment] as String? ??
        config['environment']?.toString();
    final outputDir =
        argResults[_outputDir] as String? ?? config['output-dir']?.toString();
    final clean =
        argResults[_clean] as bool? ?? (config['clean'] as bool? ?? true);
    final getPubDeps =
        argResults[_getPubDeps] as bool? ??
        (config['pub-get'] as bool? ?? true);
    final generateL10n =
        argResults[_generateL10n] as bool? ??
        (config['gen-l10n'] as bool? ?? true);
    final verbose =
        argResults[_verbose] as bool? ?? (config['verbose'] as bool? ?? false);
    final sound =
        argResults[_sound] as bool? ?? (config['sound'] as bool? ?? true);

    // Enhanced validation with helpful messaging
    if (provider == 'diawi' && token == null) {
      throw ArgumentError(
        'Diawi requires an API token!\n\n'
        'Quick Setup:\n'
        '1. Get your token at: https://dashboard.diawi.com/profile/api\n'
        '2. Use: share_my_apk --provider diawi --diawi-token YOUR_TOKEN\n'
        '3. Or add "diawi_token: YOUR_TOKEN" to share_my_apk.yaml\n\n'
        'Alternative: Use Gofile.io (no token required):\n'
        '   share_my_apk --provider gofile\n\n'
        'Available options:\n${_parser.usage}',
      );
    }

    // Validate paths if provided
    if (path != null && !Directory(path).existsSync()) {
      throw ArgumentError(
        'Project path does not exist: $path\n\n'
        'Make sure the path points to a valid Flutter project directory.',
      );
    }

    // Validate output directory if provided
    if (outputDir != null) {
      final outputDirectory = Directory(outputDir);
      if (!outputDirectory.existsSync()) {
        try {
          outputDirectory.createSync(recursive: true);
        } catch (e) {
          throw ArgumentError(
            'Cannot create output directory: $outputDir\n'
            'Error: $e\n\n'
            'Make sure you have write permissions to the parent directory.',
          );
        }
      }
    }

    return CliOptions(
      token: token,
      path: path,
      isRelease: isRelease,
      provider: provider,
      customName: customName,
      environment: environment,
      outputDir: outputDir,
      diawiToken: diawiToken,
      gofileToken: gofileToken,
      clean: clean,
      getPubDeps: getPubDeps,
      generateL10n: generateL10n,
      verbose: verbose,
      sound: sound,
    );
  }

  static void _printHelp(String usage) {
    final logger = Logger('HelpUtil');
    logger.info('''
NAME
      share_my_apk - Your friendly neighborhood APK sharer.

SYNOPSIS
      share_my_apk [options]

DESCRIPTION
      Why bother with the drag-and-drop dance when you can just use this tool?
      It builds and shares your Flutter APKs, giving you more time to ponder the important questions in life, like "why is it called a build when it's already built?".

OPTIONS
$usage

CONFIGURATION
      Set it and forget it! Use a share_my_apk.yaml file in your project's root.
      To get started, just run:
            share_my_apk --init

JOKE OF THE DAY
      Why do programmers prefer dark mode? 
      Because light attracts bugs!
''');
  }

  static void _generateConfigFile() {
    final logger = Logger('InitUtil');
    logger.info('Initializing Share My APK configuration...');

    final configFile = File('share_my_apk.yaml');
    if (configFile.existsSync()) {
      logger.warning('Configuration file already exists: share_my_apk.yaml');
      logger.info('Edit the existing file or delete it to regenerate');
      return;
    }

    configFile.writeAsStringSync('''
# Share My APK Configuration File
# This file contains default values for the command-line options.
# Uncomment and modify values as needed.

# PROVIDER SETTINGS
# Choose your upload provider (diawi or gofile)
# • Diawi: Great for team sharing, requires token, 70MB limit, links expire in 30 days
# • Gofile: No size limits, no token required, permanent public links
provider: gofile

# API TOKENS
# Diawi token (required for diawi provider): https://dashboard.diawi.com/profile/api
# diawi_token: your_diawi_token_here

# Gofile token (optional, enables private uploads): https://gofile.io/api
# gofile_token: your_gofile_token_here

# BUILD SETTINGS
# Path to your Flutter project (default: current directory)
path: .

# Build mode (release = optimized APK, debug = development APK)
release: true

# FILE ORGANIZATION
# Custom name for the APK file (without .apk extension)
# Example: "MyApp_v1.0" -> "MyApp_v1.0_2025_01_15_14_30_45.apk"
# name: MyApp_Production

# Environment folder for organizing builds (dev, staging, prod, etc.)
# Creates: output-dir/environment/your-apk.apk
# environment: prod

# Output directory for the built APK (default: Flutter's build/app/outputs/apk)
# output-dir: builds/releases

# BUILD PIPELINE
# Run flutter clean before building (recommended: true)
clean: true

# Run flutter pub get before building (recommended: true)
pub-get: true

# Generate localizations if lib/l10n exists (recommended: true)
gen-l10n: true
''');

    logger.info('Configuration file created: share_my_apk.yaml');
    logger.info('');
    logger.info('Next Steps:');
    logger.info('   1. Edit share_my_apk.yaml to customize your settings');
    logger.info(
      '   2. For Diawi: Add your token from https://dashboard.diawi.com/profile/api',
    );
    logger.info('   3. Run "share_my_apk" to build and upload your APK');
    logger.info('');
    logger.info('Quick Start:');
    logger.info('   • Gofile (no setup): share_my_apk');
    logger.info('   • Diawi: share_my_apk --diawi-token YOUR_TOKEN');
  }
}
