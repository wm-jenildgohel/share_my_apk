import 'dart:io';
import 'package:path/path.dart' as p;

/// Simple configuration service using environment variables and .env files.
///
/// Priority order (highest to lowest):
/// 1. Environment variables (DIAWI_TOKEN, GOFILE_TOKEN, etc.)
/// 2. .shareMyApk file in project root
/// 3. .shareMyApk file in user home directory
/// 4. Default values
class ConfigService {
  static const _envConfigFile = '.shareMyApk';

  /// Private constructor to prevent instantiation
  ConfigService._();

  /// Gets configuration from environment variables and .env files.
  ///
  /// Priority order:
  /// 1. Environment variables (DIAWI_TOKEN, GOFILE_TOKEN, etc.)
  /// 2. .shareMyApk file in project root
  /// 3. .shareMyApk file in user home directory
  /// 4. Default values
  ///
  /// ## Environment Variables:
  /// ```bash
  /// export DIAWI_TOKEN="your_token"
  /// export GOFILE_TOKEN="your_token"
  /// export SHARE_MY_APK_PROVIDER="gofile"
  /// ```
  ///
  /// ## Simple Config File (.shareMyApk):
  /// ```
  /// DIAWI_TOKEN=your_token
  /// GOFILE_TOKEN=your_token
  /// PROVIDER=gofile
  /// ```
  static Map<String, dynamic> getConfig() {
    final config = <String, dynamic>{};

    // Load from config files first (lowest priority)
    config.addAll(_loadFromConfigFiles());

    // Override with environment variables (highest priority)
    config.addAll(_loadFromEnvironment());

    return config;
  }

  static Map<String, dynamic> _loadFromEnvironment() {
    final config = <String, dynamic>{};

    // Load environment variables
    final env = Platform.environment;

    // API Tokens
    if (env.containsKey('DIAWI_TOKEN')) {
      config['diawi_token'] = env['DIAWI_TOKEN'];
    }
    if (env.containsKey('GOFILE_TOKEN')) {
      config['gofile_token'] = env['GOFILE_TOKEN'];
    }

    // Provider and build settings
    if (env.containsKey('PROVIDER')) {
      config['provider'] = env['PROVIDER'];
    }
    if (env.containsKey('SHARE_MY_APK_PROVIDER')) {
      config['provider'] = env['SHARE_MY_APK_PROVIDER'];
    }
    if (env.containsKey('RELEASE')) {
      config['release'] = env['RELEASE'] == 'true';
    }
    if (env.containsKey('SHARE_MY_APK_RELEASE')) {
      config['release'] = env['SHARE_MY_APK_RELEASE'] == 'true';
    }

    // File organization
    if (env.containsKey('NAME')) {
      config['name'] = env['NAME'];
    }
    if (env.containsKey('ENVIRONMENT')) {
      config['environment'] = env['ENVIRONMENT'];
    }
    if (env.containsKey('OUTPUT_DIR')) {
      config['output-dir'] = env['OUTPUT_DIR'];
    }
    if (env.containsKey('PATH')) {
      config['path'] = env['PATH'];
    }

    // Build pipeline options
    if (env.containsKey('CLEAN')) {
      config['clean'] = env['CLEAN'] == 'true';
    }
    if (env.containsKey('PUB_GET')) {
      config['pub-get'] = env['PUB_GET'] == 'true';
    }
    if (env.containsKey('GEN_L10N')) {
      config['gen-l10n'] = env['GEN_L10N'] == 'true';
    }
    if (env.containsKey('VERBOSE')) {
      config['verbose'] = env['VERBOSE'] == 'true';
    }
    if (env.containsKey('SOUND')) {
      config['sound'] = env['SOUND'] == 'true';
    }

    return config;
  }

  static Map<String, dynamic> _loadFromConfigFiles() {
    // Try project root first, then user home
    final projectConfig = File(_envConfigFile);
    final homeConfig = File(p.join(_getUserHome(), _envConfigFile));

    if (projectConfig.existsSync()) {
      return _parseEnvFile(projectConfig);
    } else if (homeConfig.existsSync()) {
      return _parseEnvFile(homeConfig);
    }

    return <String, dynamic>{};
  }

  static Map<String, dynamic> _parseEnvFile(File file) {
    final config = <String, dynamic>{};

    try {
      final lines = file.readAsLinesSync();

      for (final line in lines) {
        final trimmed = line.trim();

        // Skip empty lines and comments
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

        // Parse KEY=value format
        final parts = trimmed.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim().toLowerCase();
          final value = parts.sublist(1).join('=').trim();

          // Remove quotes if present
          final cleanValue = value.replaceAll(RegExp(r'^["\x27]|["\x27]$'), '');

          // Convert known boolean values
          if (cleanValue == 'true' || cleanValue == 'false') {
            config[key] = cleanValue == 'true';
          } else {
            config[key] = cleanValue;
          }
        }
      }
    } catch (e) {
      // Ignore parsing errors, return empty config
    }

    return config;
  }

  static String _getUserHome() {
    final env = Platform.environment;
    if (Platform.isWindows) {
      return env['USERPROFILE'] ?? env['HOME'] ?? '.';
    } else {
      return env['HOME'] ?? '.';
    }
  }

  /// Saves Firebase configuration to .shareMyApk file
  /// Supports multiple testers and groups (comma-separated)
  static void saveFirebaseConfig(Map<String, dynamic> firebaseConfig) {
    final configFile = File('.shareMyApk');
    final Map<String, String> existingConfig = {};

    // Read existing config if file exists
    if (configFile.existsSync()) {
      final content = configFile.readAsStringSync();
      final lines = content.split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty || line.trim().startsWith('#')) continue;
        final parts = line.split('=');
        if (parts.length >= 2) {
          existingConfig[parts[0].trim()] = parts.sublist(1).join('=').trim();
        }
      }
    }

    // Update with Firebase config
    existingConfig['PROVIDER'] = 'firebase';
    existingConfig['FIREBASE_PROJECT_ID'] =
        firebaseConfig['projectId'] as String;
    existingConfig['FIREBASE_APP_ID'] = firebaseConfig['appId'] as String;

    if (firebaseConfig['serviceAccountPath'] != null &&
        (firebaseConfig['serviceAccountPath'] as String).isNotEmpty) {
      existingConfig['FIREBASE_SERVICE_ACCOUNT_PATH'] =
          firebaseConfig['serviceAccountPath'] as String;
    }

    if (firebaseConfig['releaseNotes'] != null &&
        (firebaseConfig['releaseNotes'] as String).isNotEmpty) {
      existingConfig['FIREBASE_RELEASE_NOTES'] =
          firebaseConfig['releaseNotes'] as String;
    }

    // Handle multiple testers (comma-separated)
    if (firebaseConfig['testers'] != null) {
      final testers = firebaseConfig['testers'] as List<String>;
      if (testers.isNotEmpty) {
        existingConfig['FIREBASE_TESTERS'] = testers.join(',');
      }
    }

    // Handle multiple groups (comma-separated)
    if (firebaseConfig['groups'] != null) {
      final groups = firebaseConfig['groups'] as List<String>;
      if (groups.isNotEmpty) {
        existingConfig['FIREBASE_GROUPS'] = groups.join(',');
      }
    }

    // Write config file
    final buffer = StringBuffer();
    buffer.writeln('# ================================================');
    buffer.writeln('# Share My APK Configuration');
    buffer.writeln('# Auto-generated Firebase configuration');
    buffer.writeln('# ================================================');
    buffer.writeln();

    // Write Firebase config
    buffer.writeln('# Firebase App Distribution');
    buffer.writeln('PROVIDER=${existingConfig['PROVIDER']}');
    buffer.writeln(
      'FIREBASE_PROJECT_ID=${existingConfig['FIREBASE_PROJECT_ID']}',
    );
    buffer.writeln('FIREBASE_APP_ID=${existingConfig['FIREBASE_APP_ID']}');

    if (existingConfig.containsKey('FIREBASE_SERVICE_ACCOUNT_PATH')) {
      buffer.writeln(
        'FIREBASE_SERVICE_ACCOUNT_PATH=${existingConfig['FIREBASE_SERVICE_ACCOUNT_PATH']}',
      );
    }

    if (existingConfig.containsKey('FIREBASE_RELEASE_NOTES')) {
      buffer.writeln(
        'FIREBASE_RELEASE_NOTES=${existingConfig['FIREBASE_RELEASE_NOTES']}',
      );
    }

    // Multiple testers, comma-separated
    if (existingConfig.containsKey('FIREBASE_TESTERS')) {
      buffer.writeln('FIREBASE_TESTERS=${existingConfig['FIREBASE_TESTERS']}');
    }

    // Multiple groups, comma-separated
    if (existingConfig.containsKey('FIREBASE_GROUPS')) {
      buffer.writeln('FIREBASE_GROUPS=${existingConfig['FIREBASE_GROUPS']}');
    }

    buffer.writeln();
    buffer.writeln('# Build settings');
    buffer.writeln('RELEASE=${existingConfig['RELEASE'] ?? 'true'}');
    buffer.writeln();

    configFile.writeAsStringSync(buffer.toString());
  }
}
