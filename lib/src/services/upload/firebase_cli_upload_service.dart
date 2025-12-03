import 'dart:io';

import 'package:share_my_apk/src/exceptions/upload_exception.dart';
import 'package:share_my_apk/src/services/upload/upload_service.dart';
import 'package:share_my_apk/src/utils/console_logger.dart';

/// Upload service for Firebase App Distribution using Firebase CLI.
///
/// This service wraps the Firebase CLI `appdistribution:distribute` command
/// to upload APK files to Firebase App Distribution for beta testing.
///
/// ## Authentication
///
/// Firebase CLI supports multiple authentication methods (checked in priority order):
/// 1. Service account via GOOGLE_APPLICATION_CREDENTIALS environment variable
/// 2. User authentication via `firebase login`
/// 3. Application Default Credentials (ADC)
///
/// For local development, simply run `firebase login` once.
/// For CI/CD, provide a service account JSON file path.
///
/// ## Example Usage
///
/// ```dart
/// final service = FirebaseCliUploadService(
///   appId: '1:123456789:android:abc123def456',
///   serviceAccountPath: '/path/to/service-account.json', // Optional
///   testerGroups: ['qa-team', 'beta-testers'],
///   releaseNotes: 'Bug fixes and improvements',
/// );
///
/// final downloadLink = await service.upload('/path/to/app-release.apk');
/// print('Download link: $downloadLink');
/// ```
class FirebaseCliUploadService implements UploadService {
  /// Firebase App ID in format: 1:PROJECT_NUMBER:android:APP_ID_HASH
  ///
  /// Get this from Firebase Console → Project Settings → Your apps
  final String appId;

  /// Optional path to Firebase service account JSON file.
  ///
  /// If not provided, Firebase CLI will use existing authentication
  /// (e.g., from `firebase login` or Application Default Credentials).
  final String? serviceAccountPath;

  /// Optional list of Firebase tester groups to distribute to.
  ///
  /// Example: ['qa-team', 'beta-testers', 'internal']
  final List<String>? testerGroups;

  /// Optional release notes displayed to testers.
  ///
  /// Maximum 16,384 characters.
  final String? releaseNotes;

  final ConsoleLogger _logger = ConsoleLogger('FirebaseAppDistribution');

  FirebaseCliUploadService({
    required this.appId,
    this.serviceAccountPath,
    this.testerGroups,
    this.releaseNotes,
  });

  @override
  Future<String> upload(String filePath) async {
    // Step 1: Validate Firebase CLI is installed
    await _validateFirebaseCli();

    // Step 2: Validate APK file exists
    await _validateFile(filePath);

    // Step 3: Check authentication (only if service account not provided)
    if (serviceAccountPath == null) {
      await _checkAuthentication();
    } else {
      // Validate service account file exists
      final serviceAccountFile = File(serviceAccountPath!);
      if (!await serviceAccountFile.exists()) {
        throw UploadException(
          'Service account file not found: $serviceAccountPath',
          provider: 'firebase',
          filePath: filePath,
        );
      }
    }

    // Step 4: Build and execute Firebase CLI command
    return await _executeUpload(filePath);
  }

  /// Validates that Firebase CLI is installed and accessible.
  Future<void> _validateFirebaseCli() async {
    try {
      // Check if Firebase CLI is installed
      final result = await Process.run('which', ['firebase']);
      if (result.exitCode != 0) {
        _logger.severe('Firebase CLI not found in PATH');
        throw UploadException(
          _getFirebaseCliNotFoundMessage(),
          provider: 'firebase',
        );
      }

      // Verify Firebase CLI version
      final versionResult = await Process.run('firebase', ['--version']);
      if (versionResult.exitCode == 0) {
        final version = versionResult.stdout.toString().trim();
        _logger.info('Firebase CLI version: $version');
      } else {
        throw UploadException(
          'Firebase CLI found but unable to determine version',
          provider: 'firebase',
        );
      }
    } catch (e) {
      if (e is UploadException) rethrow;
      _logger.severe('Error verifying Firebase CLI: $e');
      throw UploadException(
        _getFirebaseCliNotFoundMessage(),
        provider: 'firebase',
        originalError: e,
      );
    }
  }

  /// Checks if Firebase CLI has valid authentication.
  ///
  /// This is only called if no service account path is provided.
  Future<void> _checkAuthentication() async {
    try {
      // Try to list projects to verify authentication
      final result = await Process.run(
        'firebase',
        ['projects:list', '--json'],
        runInShell: true,
      );

      if (result.exitCode != 0) {
        final stderr = result.stderr.toString();
        if (stderr.contains('not logged in') ||
            stderr.contains('authentication') ||
            stderr.contains('credentials')) {
          throw UploadException(
            _getAuthenticationErrorMessage(),
            provider: 'firebase',
          );
        }
      }

      _logger.info('Using existing Firebase authentication (user login or ADC)');
    } catch (e) {
      if (e is UploadException) rethrow;
      if (e.toString().contains('not logged in') ||
          e.toString().contains('authentication')) {
        throw UploadException(
          _getAuthenticationErrorMessage(),
          provider: 'firebase',
          originalError: e,
        );
      }
      // If it's a different error, log it but continue
      // (Firebase CLI might still work)
      _logger.warning('Could not verify Firebase authentication: $e');
    }
  }

  /// Executes the Firebase App Distribution upload command.
  Future<String> _executeUpload(String filePath) async {
    final commands = <String>[];

    // Set service account environment variable if provided
    if (serviceAccountPath != null) {
      commands.add(
        'export GOOGLE_APPLICATION_CREDENTIALS="$serviceAccountPath"',
      );
      _logger.info('Using service account: $serviceAccountPath');
    }

    // Build Firebase CLI command
    final distributeArgs = [
      'firebase appdistribution:distribute "$filePath"',
      '--app "$appId"',
    ];

    if (releaseNotes != null && releaseNotes!.isNotEmpty) {
      // Escape quotes in release notes
      final escapedNotes = releaseNotes!.replaceAll('"', '\\"');
      distributeArgs.add('--release-notes "$escapedNotes"');
    }

    if (testerGroups != null && testerGroups!.isNotEmpty) {
      distributeArgs.add('--groups "${testerGroups!.join(',')}"');
    }

    commands.add(distributeArgs.join(' '));

    // Execute command
    _logger.info('Uploading to Firebase App Distribution...');
    _logger.info('App ID: $appId');
    if (testerGroups != null && testerGroups!.isNotEmpty) {
      _logger.info('Tester groups: ${testerGroups!.join(", ")}');
    }

    final result = await Process.run(
      'bash',
      ['-c', commands.join(' && ')],
    );

    if (result.exitCode != 0) {
      final errorMessage = result.stderr.toString();
      _logger.severe('Firebase upload failed: $errorMessage');
      throw UploadException(
        'Firebase App Distribution upload failed',
        provider: 'firebase',
        filePath: filePath,
        responseBody: errorMessage,
      );
    }

    // Parse output
    final output = result.stdout.toString();
    _logger.info(output);

    // Extract download link from Firebase CLI output
    return _parseDownloadLink(output);
  }

  /// Parses the Firebase Console link from CLI output.
  String _parseDownloadLink(String output) {
    // Firebase CLI outputs links in various formats:
    // 1. "View this release in the Firebase console: https://..."
    // 2. Direct links: https://appdistribution.firebase.google.com/...
    // 3. Console links: https://console.firebase.google.com/...

    final linkPatterns = [
      RegExp(r'https://appdistribution\.firebase\.google\.com[^\s]+'),
      RegExp(r'https://console\.firebase\.google\.com[^\s]+'),
    ];

    for (final pattern in linkPatterns) {
      final match = pattern.firstMatch(output);
      if (match != null) {
        return match.group(0)!;
      }
    }

    // If no link found, return success message
    return 'Upload successful! Check Firebase Console for details.';
  }

  String _getFirebaseCliNotFoundMessage() {
    return '''
🚨 Firebase CLI not found!

📦 Install Firebase CLI:
   npm install -g firebase-tools

🔍 Verify installation:
   firebase --version

📖 Documentation:
   https://firebase.google.com/docs/cli

After installation, authenticate with:
   firebase login
''';
  }

  String _getAuthenticationErrorMessage() {
    return '''
🔐 Firebase CLI is not authenticated!

Choose ONE of these authentication methods:

Option 1 - Local Development (Recommended):
  Run: firebase login
  This will open a browser for Google sign-in.

Option 2 - Service Account (CI/CD):
  1. Create a service account in Firebase Console
  2. Download the JSON key file
  3. Provide path via configuration:

     In share_my_apk.yaml:
     firebase:
       service_account_path: /path/to/service-account.json

     OR via CLI:
     --firebase-service-account /path/to/service-account.json

     OR via environment variable:
     export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json

Option 3 - Application Default Credentials:
  Run: gcloud auth application-default login

📖 For more information:
   https://firebase.google.com/docs/app-distribution/authenticate-service-account
''';
  }

  /// Validates that the file exists.
  Future<void> _validateFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      _logger.severe('❌ File not found: $filePath');
      throw UploadException(
        'APK file not found',
        provider: 'firebase',
        filePath: filePath,
      );
    }

    final fileSize = await file.length();
    final fileSizeMB = (fileSize / 1024 / 1024).toStringAsFixed(2);
    _logger.info('📁 File size: $fileSizeMB MB');
  }
}
