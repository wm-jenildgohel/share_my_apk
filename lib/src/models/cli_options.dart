/// Configuration model for command-line interface options.
///
/// This class encapsulates all the configurable options that can be passed
/// to the share_my_apk command-line tool or used programmatically when
/// building and uploading APK files.
///
/// ## Example Usage
///
/// ```dart
/// final options = CliOptions(
///   token: 'your_diawi_token',
///   path: '/path/to/flutter/project',
///   isRelease: true,
///   provider: 'diawi',
///   customName: 'MyApp_Beta',
///   environment: 'staging',
///   outputDir: '/custom/output/directory',
/// );
/// ```
class CliOptions {
  /// API token for upload providers.
  ///
  /// Required for Diawi uploads, optional for Gofile.io.
  /// Get your Diawi token from: https://dashboard.diawi.com/profile/api
  final String? token;

  /// API token for Diawi.
  final String? diawiToken;

  /// API token for Gofile.io.
  final String? gofileToken;

  /// Firebase App ID for Firebase App Distribution.
  ///
  /// Format: 1:123456789:android:abc123def456
  /// Get this from Firebase Console → Project Settings → Your apps
  final String? firebaseAppId;

  /// Path to Firebase service account JSON file.
  ///
  /// Required for Firebase App Distribution uploads.
  /// Get from Google Cloud Console → IAM & Admin → Service Accounts
  final String? firebaseServiceAccountPath;

  /// List of Firebase tester groups to distribute to.
  ///
  /// Example: ['qa-team', 'beta-testers', 'internal']
  final List<String>? firebaseTesterGroups;

  /// Release notes for Firebase App Distribution.
  ///
  /// Displayed to testers when they receive the build notification.
  final String? firebaseReleaseNotes;

  /// Path to the Flutter project directory.
  ///
  /// If not specified, the current working directory will be used.
  /// The path should contain a valid Flutter project with pubspec.yaml.
  final String? path;

  /// Whether to build in release mode.
  ///
  /// When `true`, builds the APK in release mode (optimized for production).
  /// When `false`, builds in debug mode (includes debugging information).
  /// Defaults to `true`.
  final bool isRelease;

  /// Upload provider to use for APK distribution.
  ///
  /// Supported providers:
  /// - `'diawi'`: Upload to Diawi service (requires token)
  /// - `'gofile'`: Upload to Gofile.io service (no token required)
  /// - `'firebase'`: Upload to Firebase App Distribution (requires app ID)
  ///
  /// The tool automatically switches from Diawi to Gofile.io if the APK
  /// size exceeds 70MB and Diawi is selected.
  final String provider;

  /// Custom name for the generated APK file.
  ///
  /// If provided, the APK will be named using the format:
  /// `{customName}_{version}_{timestamp}.apk`
  ///
  /// If not provided, uses the app name from pubspec.yaml:
  /// `{appName}_{version}_{timestamp}.apk`
  final String? customName;

  /// Environment folder for organizing builds.
  ///
  /// When specified, creates a subdirectory with this name in the output
  /// directory. Commonly used values: 'dev', 'staging', 'prod', 'test'.
  ///
  /// Example structure: `/output/staging/MyApp_1.0.0_timestamp.apk`
  final String? environment;

  /// Custom output directory for the built APK.
  ///
  /// If not specified, defaults to `{projectPath}/build/apk/`.
  /// The directory will be created if it doesn't exist.
  final String? outputDir;

  /// Whether to run `flutter clean` before building.
  ///
  /// When `true`, cleans the project before building to ensure a fresh build.
  /// This removes build artifacts and can help resolve build issues.
  /// Defaults to `true`.
  final bool clean;

  /// Whether to run `flutter pub get` before building.
  ///
  /// When `true`, fetches dependencies before building to ensure all
  /// packages are up to date. Defaults to `true`.
  final bool getPubDeps;

  /// Whether to generate localizations before building.
  ///
  /// When `true`, runs `flutter gen-l10n` if a `lib/l10n` directory exists.
  /// This ensures localization files are generated before building.
  /// Defaults to `true`.
  final bool generateL10n;
  final bool verbose;

  /// Creates a new [CliOptions] instance.
  ///
  /// All parameters are optional and have sensible defaults.
  /// The [isRelease] parameter defaults to `true` and [provider] defaults to `'diawi'`.
  /// Build pipeline options default to `true` for comprehensive builds.
  ///
  /// Throws [ArgumentError] if:
  /// - [provider] is not one of: 'diawi', 'gofile', 'firebase'
  /// - [provider] is 'diawi' but neither [diawiToken] nor [token] is provided
  /// - [provider] is 'firebase' but [firebaseAppId] is not provided
  /// - [firebaseAppId] is provided but has invalid format
  CliOptions({
    this.token,
    this.diawiToken,
    this.gofileToken,
    this.firebaseAppId,
    this.firebaseServiceAccountPath,
    this.firebaseTesterGroups,
    this.firebaseReleaseNotes,
    this.path,
    this.isRelease = true,
    String? provider,
    this.customName,
    this.environment,
    this.outputDir,
    this.clean = true,
    this.getPubDeps = true,
    this.generateL10n = true,
    this.verbose = false,
  }) : provider = _validateProvider(provider ?? 'diawi') {
    // H2 fix: Add input validation
    _validateConfiguration();
  }

  /// Valid provider names.
  static const validProviders = ['diawi', 'gofile', 'firebase'];

  /// Validates that the provider is supported.
  static String _validateProvider(String provider) {
    final normalizedProvider = provider.trim().toLowerCase();

    if (!validProviders.contains(normalizedProvider)) {
      throw ArgumentError(
        'Invalid provider: "$provider". '
        'Must be one of: ${validProviders.join(", ")}',
      );
    }

    return normalizedProvider;
  }

  /// Validates the configuration based on the selected provider.
  void _validateConfiguration() {
    // Validate provider-specific requirements
    switch (provider) {
      case 'diawi':
        if (diawiToken == null && token == null) {
          throw ArgumentError(
            'Diawi provider requires a token. '
            'Provide --diawi-token or set diawi_token in config file.\n'
            'Get your token at: https://dashboard.diawi.com/profile/api',
          );
        }
        break;

      case 'firebase':
        if (firebaseAppId == null || firebaseAppId!.isEmpty) {
          throw ArgumentError(
            'Firebase provider requires an App ID.\n'
            'Get your Firebase App ID from:\n'
            'Firebase Console → Project Settings → Your apps\n'
            'Format: 1:123456789:android:abc123def456',
          );
        }

        // Validate Firebase App ID format
        _validateFirebaseAppId(firebaseAppId!);
        break;

      case 'gofile':
        // Gofile doesn't require a token, so no validation needed
        break;
    }
  }

  /// Validates Firebase App ID format.
  void _validateFirebaseAppId(String appId) {
    // Firebase App ID format: 1:123456789:android:abc123def456
    // Pattern: {mobilesdk_app_id}:{platform}:{bundle_id}
    final pattern = RegExp(r'^\d+:\d+:(android|ios):[a-zA-Z0-9]+$');

    if (!pattern.hasMatch(appId)) {
      throw ArgumentError(
        'Invalid Firebase App ID format: "$appId"\n'
        'Expected format: 1:123456789:android:abc123def456\n'
        'Get your App ID from Firebase Console → Project Settings',
      );
    }
  }

  /// Creates a copy of this [CliOptions] with the given fields replaced.
  ///
  /// This method is useful for creating variations of the configuration
  /// without modifying the original instance.
  CliOptions copyWith({
    String? token,
    String? diawiToken,
    String? gofileToken,
    String? firebaseAppId,
    String? firebaseServiceAccountPath,
    List<String>? firebaseTesterGroups,
    String? firebaseReleaseNotes,
    String? path,
    bool? isRelease,
    String? provider,
    String? customName,
    String? environment,
    String? outputDir,
    bool? clean,
    bool? getPubDeps,
    bool? generateL10n,
    bool? verbose,
  }) {
    return CliOptions(
      token: token ?? this.token,
      diawiToken: diawiToken ?? this.diawiToken,
      gofileToken: gofileToken ?? this.gofileToken,
      firebaseAppId: firebaseAppId ?? this.firebaseAppId,
      firebaseServiceAccountPath: firebaseServiceAccountPath ?? this.firebaseServiceAccountPath,
      firebaseTesterGroups: firebaseTesterGroups ?? this.firebaseTesterGroups,
      firebaseReleaseNotes: firebaseReleaseNotes ?? this.firebaseReleaseNotes,
      path: path ?? this.path,
      isRelease: isRelease ?? this.isRelease,
      provider: provider ?? this.provider,
      customName: customName ?? this.customName,
      environment: environment ?? this.environment,
      outputDir: outputDir ?? this.outputDir,
      clean: clean ?? this.clean,
      getPubDeps: getPubDeps ?? this.getPubDeps,
      generateL10n: generateL10n ?? this.generateL10n,
      verbose: verbose ?? this.verbose,
    );
  }

  @override
  String toString() {
    return 'CliOptions('
        'token: ${token != null ? '***' : 'null'}, '
        'diawiToken: ${diawiToken != null ? '***' : 'null'}, '
        'gofileToken: ${gofileToken != null ? '***' : 'null'}, '
        'firebaseAppId: $firebaseAppId, '
        'firebaseServiceAccountPath: $firebaseServiceAccountPath, '
        'firebaseTesterGroups: $firebaseTesterGroups, '
        'firebaseReleaseNotes: $firebaseReleaseNotes, '
        'path: $path, '
        'isRelease: $isRelease, '
        'provider: $provider, '
        'customName: $customName, '
        'environment: $environment, '
        'outputDir: $outputDir, '
        'clean: $clean, '
        'getPubDeps: $getPubDeps, '
        'generateL10n: $generateL10n, '
        'verbose: $verbose'
        ')';
  }
}
