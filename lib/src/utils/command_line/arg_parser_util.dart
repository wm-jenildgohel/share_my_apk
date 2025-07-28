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
      help: 'Generate a simple .shareMyApk configuration file.',
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
      Super simple! Three ways to configure:
      1. Environment variables: export DIAWI_TOKEN="your_token"
      2. Config file: Run 'share_my_apk --init' to create .shareMyApk
      3. Command line: share_my_apk --diawi-token YOUR_TOKEN

JOKE OF THE DAY
      Why do programmers prefer dark mode? 
      Because light attracts bugs!
''');
  }

  static void _generateConfigFile() {
    final logger = Logger('InitUtil');
    logger.info('Setting up Share My APK configuration...');

    final configFile = File('.shareMyApk');
    if (configFile.existsSync()) {
      logger.warning('Configuration file already exists: .shareMyApk');
      logger.info('Edit the existing file or delete it to regenerate');
      return;
    }

    configFile.writeAsStringSync('''# Share My APK Simple Configuration
# Edit values below or use environment variables (higher priority)

# Upload Provider (diawi or gofile)
PROVIDER=gofile

# API Tokens
# Get Diawi token: https://dashboard.diawi.com/profile/api
# DIAWI_TOKEN=your_diawi_token_here

# Get Gofile token (optional): https://gofile.io/api  
# GOFILE_TOKEN=your_gofile_token_here

# Build Settings
RELEASE=true
''');

    logger.info('Simple configuration created: .shareMyApk');
    logger.info('');
    logger.info('🚀 Three ways to configure:');
    logger.info('');
    logger.info('1. Edit .shareMyApk file (just created)');
    logger.info('2. Use environment variables:');
    logger.info('   export DIAWI_TOKEN="your_token"');
    logger.info('   export GOFILE_TOKEN="your_token"');
    logger.info('');
    logger.info('3. Pass tokens via command line:');
    logger.info('   share_my_apk --diawi-token YOUR_TOKEN');
    logger.info('');
    logger.info('Quick start (no setup needed):');
    logger.info('   share_my_apk  # Uses Gofile, no token required!');
  }
}
