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
  static const _diawiToken = 'diawi-token';
  static const _gofileToken = 'gofile-token';
  static const _firebaseProjectId = 'firebase-project-id';
  static const _firebaseAppId = 'firebase-app-id';
  static const _firebaseServiceAccountPath = 'firebase-service-account';
  static const _firebaseReleaseNotes = 'firebase-notes';
  static const _firebaseTesters = 'firebase-testers';
  static const _firebaseGroups = 'firebase-groups';
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
    _parser.addOption(
      _provider,
      help:
          'The upload provider to use.\n[diawi, gofile, firebase] (reads from config file)',
      allowed: ['diawi', 'gofile', 'firebase'],
    );
    _parser.addOption(_diawiToken, help: 'Your Diawi API token.');
    _parser.addOption(_gofileToken, help: 'Your Gofile API token.');
    _parser.addOption(_firebaseProjectId, help: 'Firebase project ID.');
    _parser.addOption(_firebaseAppId, help: 'Firebase app ID (format: 1:123456789:android:abcdef).');
    _parser.addOption(_firebaseServiceAccountPath, help: 'Path to Firebase service account JSON file.');
    _parser.addOption(_firebaseReleaseNotes, help: 'Release notes for Firebase App Distribution.');
    _parser.addOption(_firebaseTesters, help: 'Comma-separated list of tester emails for Firebase.');
    _parser.addOption(_firebaseGroups, help: 'Comma-separated list of tester groups for Firebase.');
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
    // Handle 'init' command first (before parsing flags)
    if (args.isNotEmpty && args[0] == 'init') {
      _generateConfigFile();
      exit(0);
    }

    final argResults = _parser.parse(args);

    if (argResults[_help] as bool) {
      _printHelp(_parser.usage);
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

    // Firebase configuration
    final firebaseProjectId =
        argResults[_firebaseProjectId] as String? ?? config['firebase_project_id']?.toString();
    final firebaseAppId =
        argResults[_firebaseAppId] as String? ?? config['firebase_app_id']?.toString();
    final firebaseServiceAccountPath =
        argResults[_firebaseServiceAccountPath] as String? ?? config['firebase_service_account_path']?.toString();
    final firebaseReleaseNotes =
        argResults[_firebaseReleaseNotes] as String? ?? config['firebase_release_notes']?.toString();
    
    // Parse comma-separated lists
    List<String>? firebaseTesters;
    final testersString = argResults[_firebaseTesters] as String? ?? config['firebase_testers']?.toString();
    if (testersString != null && testersString.isNotEmpty) {
      firebaseTesters = testersString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    
    List<String>? firebaseGroups;
    final groupsString = argResults[_firebaseGroups] as String? ?? config['firebase_groups']?.toString();
    if (groupsString != null && groupsString.isNotEmpty) {
      firebaseGroups = groupsString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

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

    if (provider == 'firebase') {
      if (firebaseProjectId == null || firebaseProjectId.isEmpty) {
        throw ArgumentError(
          'Firebase App Distribution requires a project ID!\n\n'
          'Quick Setup:\n'
          '1. Get your project ID from Firebase Console\n'
          '2. Use: share_my_apk --provider firebase --firebase-project-id YOUR_PROJECT_ID --firebase-app-id YOUR_APP_ID\n'
          '3. Or add to share_my_apk.yaml:\n'
          '   firebase_project_id: YOUR_PROJECT_ID\n'
          '   firebase_app_id: YOUR_APP_ID\n\n'
          'Available options:\n${_parser.usage}',
        );
      }
      if (firebaseAppId == null || firebaseAppId.isEmpty) {
        throw ArgumentError(
          'Firebase App Distribution requires an app ID!\n\n'
          'Format: 1:123456789:android:abcdef\n'
          'Find it in Firebase Console > Project Settings > General\n\n'
          'Usage: share_my_apk --provider firebase --firebase-app-id YOUR_APP_ID\n\n'
          'Available options:\n${_parser.usage}',
        );
      }
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
      firebaseProjectId: firebaseProjectId,
      firebaseAppId: firebaseAppId,
      firebaseServiceAccountPath: firebaseServiceAccountPath,
      firebaseReleaseNotes: firebaseReleaseNotes,
      firebaseTesters: firebaseTesters,
      firebaseGroups: firebaseGroups,
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
      2. Config file: Run 'share_my_apk init' to create .shareMyApk
      3. Command line: share_my_apk --diawi-token YOUR_TOKEN

COMMANDS
      init                   Create comprehensive .shareMyApk config file

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

    configFile.writeAsStringSync('''# ================================================
# Share My APK Configuration File
# ================================================
# Edit values below or use environment variables (higher priority)
# Remove '#' to uncomment and activate settings

# ================================================
# UPLOAD PROVIDER (Required)
# ================================================
# Choose your upload provider: diawi, gofile, or firebase
# • Diawi: Great for team sharing, 70MB limit, links expire in 30 days
# • Gofile: No size limits, permanent public links
# • Firebase: Enterprise-grade distribution with tester management
PROVIDER=gofile

# ================================================  
# API TOKENS (Required for uploads)
# ================================================
# Different providers have different requirements

# Diawi API Token
# Get yours at: https://dashboard.diawi.com/profile/api
# DIAWI_TOKEN=your_diawi_token_here

# Gofile API Token  
# Get yours at: https://gofile.io/api
# GOFILE_TOKEN=your_gofile_token_here

# Firebase App Distribution Configuration
# Get project info from Firebase Console > Project Settings
# FIREBASE_PROJECT_ID=your-firebase-project
# FIREBASE_APP_ID=1:123456789:android:abcdef
# FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/service-account.json
# FIREBASE_RELEASE_NOTES=New beta release with bug fixes
# FIREBASE_TESTERS=tester1@example.com,tester2@example.com
# FIREBASE_GROUPS=internal-team,beta-testers

# ================================================
# BUILD CONFIGURATION
# ================================================
# Build mode: true for release (optimized), false for debug
RELEASE=true

# Flutter project path (default: current directory)
# PATH=.

# ================================================
# FILE ORGANIZATION
# ================================================
# Custom APK name (without .apk extension)
# Example: "MyApp_v2.0" becomes "MyApp_v2.0_2025_01_28_12_30_45.apk"
# NAME=MyApp_Production

# Environment folder for organizing builds
# Creates: output-dir/environment/your-apk.apk
# Examples: dev, staging, prod, beta
# ENVIRONMENT=prod

# Custom output directory for APKs
# Default: Flutter's build/app/outputs/apk/release
# OUTPUT_DIR=builds/releases

# ================================================
# BUILD PIPELINE OPTIONS
# ================================================
# Run flutter clean before building (recommended)
# CLEAN=true

# Run flutter pub get before building (recommended)  
# PUB_GET=true

# Generate localizations if l10n.yaml exists (recommended)
# GEN_L10N=true

# Show verbose build output
# VERBOSE=false

# Play sound notification after successful upload
# SOUND=true

# ================================================
# USAGE EXAMPLES
# ================================================
# Environment variables (highest priority):
#   export DIAWI_TOKEN="your_token"
#   export GOFILE_TOKEN="your_token"
#   export FIREBASE_PROJECT_ID="your-project"
#   share_my_apk
#
# Command line (overrides this file):
#   share_my_apk --diawi-token YOUR_TOKEN
#   share_my_apk --gofile-token YOUR_TOKEN --name MyApp_Beta
#   share_my_apk --provider firebase --firebase-project-id PROJECT --firebase-app-id APP_ID
#
# This config file (edit values above):
#   share_my_apk
# ================================================
''');

    logger.info('Simple configuration created: .shareMyApk');
    logger.info('');
    logger.info('📝 Comprehensive configuration created with all options!');
    logger.info('');
    logger.info('🎯 Next steps:');
    logger.info('   1. Edit .shareMyApk and uncomment/set your tokens');
    logger.info('   2. Or use environment variables for security:');
    logger.info('      export GOFILE_TOKEN="your_token"');
    logger.info('   3. Then run: share_my_apk');
    logger.info('');
    logger.info('💡 All configuration options are documented in the file!');
  }
}
