import 'dart:io';

import 'package:args/args.dart';
import 'package:share_my_apk/src/models/cli_options.dart';
import 'package:share_my_apk/src/services/config_service.dart';
import 'package:share_my_apk/src/utils/command_line/help_util.dart';
import 'package:share_my_apk/src/utils/command_line/init_util.dart';

/// A utility class for parsing command-line arguments.
class ArgParserUtil {
  late final ArgParser _parser;
  static const _help = 'help';
  static const _init = 'init';
  static const _diawiToken = 'diawi-token';
  static const _gofileToken = 'gofile-token';
  static const _firebaseAppId = 'firebase-app-id';
  static const _firebaseServiceAccount = 'firebase-service-account';
  static const _firebaseTesterGroups = 'firebase-tester-groups';
  static const _firebaseReleaseNotes = 'firebase-release-notes';
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
      help: 'The upload provider to use.',
      allowed: ['diawi', 'gofile', 'firebase'],
      defaultsTo: 'diawi',
    );
    _parser.addOption(_diawiToken, help: 'Your Diawi API token.');
    _parser.addOption(_gofileToken, help: 'Your Gofile API token.');
    _parser.addOption(
      _firebaseAppId,
      help: 'Firebase App ID (format: 1:123:android:abc).',
    );
    _parser.addOption(
      _firebaseServiceAccount,
      help: 'Path to Firebase service account JSON file (optional).',
    );
    _parser.addOption(
      _firebaseTesterGroups,
      help: 'Comma-separated list of Firebase tester groups.',
    );
    _parser.addOption(
      _firebaseReleaseNotes,
      help: 'Release notes for Firebase App Distribution.',
    );
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
  }

  /// Parses the command-line arguments and returns a [CliOptions] object.
  ///
  /// Throws an [ArgumentError] if the token is not provided when required.
  CliOptions parse(List<String> args) {
    final argResults = _parser.parse(args);

    if (argResults[_help] as bool) {
      HelpUtil.printHelp(_parser.usage);
      exit(0);
    }

    if (argResults[_init] as bool) {
      InitUtil.generateConfigFile();
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

    // Parse Firebase configuration
    final firebaseConfig = config['firebase'] as Map<String, dynamic>?;

    final firebaseAppId =
        argResults[_firebaseAppId] as String? ??
        firebaseConfig?['app_id']?.toString();

    final firebaseServiceAccountPath =
        argResults[_firebaseServiceAccount] as String? ??
        firebaseConfig?['service_account_path']?.toString();

    final firebaseTesterGroupsStr =
        argResults[_firebaseTesterGroups] as String?;

    List<String>? firebaseTesterGroups;
    if (firebaseTesterGroupsStr != null && firebaseTesterGroupsStr.isNotEmpty) {
      firebaseTesterGroups = firebaseTesterGroupsStr
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (firebaseConfig?['tester_groups'] is List) {
      firebaseTesterGroups = (firebaseConfig!['tester_groups'] as List)
          .map((e) => e.toString())
          .toList();
    }

    final firebaseReleaseNotes =
        argResults[_firebaseReleaseNotes] as String? ??
        firebaseConfig?['release_notes']?.toString();

    // Enhanced validation with helpful messaging
    if (provider == 'diawi' && token == null) {
      throw ArgumentError(
        '🔑 Diawi requires an API token!\n\n'
        '📋 Quick Setup:\n'
        '1. Get your token at: https://dashboard.diawi.com/profile/api\n'
        '2. Use: share_my_apk --provider diawi --diawi-token YOUR_TOKEN\n'
        '3. Or add "diawi_token: YOUR_TOKEN" to share_my_apk.yaml\n\n'
        '💡 Alternative: Use Gofile.io (no token required):\n'
        '   share_my_apk --provider gofile\n\n'
        'Available options:\n${_parser.usage}',
      );
    }

    if (provider == 'firebase' && firebaseAppId == null) {
      throw ArgumentError(
        '🔥 Firebase provider requires an App ID!\n\n'
        '📋 Quick Setup:\n'
        '1. Get your Firebase App ID from Firebase Console:\n'
        '   https://console.firebase.google.com\n'
        '   → Project Settings → Your apps\n'
        '   Format: 1:123456789:android:abc123def456\n\n'
        '2. Use one of these methods:\n'
        '   a) CLI: share_my_apk --provider firebase --firebase-app-id "YOUR_APP_ID"\n'
        '   b) Config file (share_my_apk.yaml):\n'
        '      firebase:\n'
        '        app_id: "YOUR_APP_ID"\n\n'
        '3. Authentication (choose ONE):\n'
        '   a) Local: Run "firebase login" (recommended for development)\n'
        '   b) CI/CD: Provide service account JSON file:\n'
        '      --firebase-service-account /path/to/service-account.json\n\n'
        '💡 Note: Service account is optional for local development!\n\n'
        'Available options:\n${_parser.usage}',
      );
    }

    // Validate paths if provided
    if (path != null && !Directory(path).existsSync()) {
      throw ArgumentError(
        '📁 Project path does not exist: $path\n\n'
        '💡 Make sure the path points to a valid Flutter project directory.',
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
            '📁 Cannot create output directory: $outputDir\n'
            'Error: $e\n\n'
            '💡 Make sure you have write permissions to the parent directory.',
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
      firebaseAppId: firebaseAppId,
      firebaseServiceAccountPath: firebaseServiceAccountPath,
      firebaseTesterGroups: firebaseTesterGroups,
      firebaseReleaseNotes: firebaseReleaseNotes,
      clean: clean,
      getPubDeps: getPubDeps,
      generateL10n: generateL10n,
      verbose: verbose,
    );
  }
}
