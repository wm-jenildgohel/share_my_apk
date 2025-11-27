import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:share_my_apk/src/services/upload/upload_service.dart';

/// A service for uploading APK files to Firebase App Distribution.
///
/// This service uses the Firebase CLI as an intermediary for reliable uploads,
/// as recommended by Google for Firebase App Distribution integration.
///
/// ## Prerequisites
///
/// 1. **Firebase CLI installed**: `npm install -g firebase-tools`
/// 2. **Android App ID**: Must be in format `1:PROJECT_NUMBER:android:APP_ID`
/// 3. **Authentication**: Service account JSON or `firebase login`
///
/// ## Authentication Methods
///
/// 1. **Service Account**: Set `GOOGLE_APPLICATION_CREDENTIALS`
/// 2. **Firebase Login**: Run `firebase login` (for local development)
///
/// ## Usage Example
///
/// ```dart
/// final service = FirebaseUploadService(
///   projectId: 'my-firebase-project',
///   appId: '1:123456789:android:abcdef123456',
///   serviceAccountPath: '/path/to/service-account.json',
///   releaseNotes: 'Beta release',
///   testers: ['tester@example.com'],
///   groups: ['beta-testers'],
/// );
///
/// final result = await service.upload('/path/to/app.apk');
/// ```
class FirebaseUploadService implements UploadService {
  static final Logger _logger = Logger('FirebaseUploadService');

  /// Firebase project ID
  final String projectId;

  /// Firebase Android app ID (format: 1:123456789:android:abcdef)
  final String appId;

  /// Path to service account JSON file (optional)
  final String? serviceAccountPath;

  /// Release notes for the uploaded APK
  final String? releaseNotes;

  /// Testers to notify (email addresses)
  final List<String>? testers;

  /// Groups to notify
  final List<String>? groups;

  /// Creates a new Firebase App Distribution upload service.
  FirebaseUploadService({
    required this.projectId,
    required this.appId,
    this.serviceAccountPath,
    this.releaseNotes,
    this.testers,
    this.groups,
  }) {
    _validateConfiguration();
  }

  @override
  Future<String> upload(String filePath) async {
    _logger.info('Starting Firebase App Distribution upload...');

    try {
      // Validate prerequisites
      await _validatePrerequisites();

      // Validate file exists and is APK
      await _validateApkFile(filePath);

      // Set up authentication
      final environment = await _setupAuthentication();

      // Upload using Firebase CLI
      final downloadUrl = await _uploadWithFirebaseCli(filePath, environment);

      _logger.info('Firebase App Distribution upload completed successfully!');
      return downloadUrl;
    } catch (e) {
      _logger.severe('Firebase upload failed: $e');
      rethrow;
    }
  }

  /// Validate Firebase configuration
  void _validateConfiguration() {
    if (projectId.isEmpty) {
      throw ArgumentError('Firebase project ID cannot be empty');
    }

    // Validate Android app ID format
    final androidAppIdPattern = RegExp(r'^1:\d+:android:[a-f0-9]+$');
    if (!androidAppIdPattern.hasMatch(appId)) {
      throw ArgumentError(
        'Invalid Firebase App ID format. Expected: 1:PROJECT_NUMBER:android:APP_ID\n'
        'Got: $appId\n'
        'Note: Firebase App Distribution only supports Android apps, not web apps.\n'
        'Please use your Android app ID from Firebase Console > Project Settings > General > Your apps',
      );
    }
  }

  /// Validate prerequisites are installed
  Future<void> _validatePrerequisites() async {
    // Check if Firebase CLI is installed
    try {
      final result = await Process.run('firebase', ['--version']);
      if (result.exitCode != 0) {
        throw Exception('Firebase CLI not working properly');
      }
      final version = result.stdout.toString().trim();
      _logger.info('Found Firebase CLI: $version');
    } catch (e) {
      throw Exception(
        'Firebase CLI is required but not found. Please install it:\n'
        '1. Install Node.js from https://nodejs.org/\n'
        '2. Run: npm install -g firebase-tools\n'
        '3. Verify: firebase --version\n\n'
        'Error: $e',
      );
    }
  }

  /// Validate APK file
  Future<void> _validateApkFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('APK file not found', filePath);
    }

    // Check if it's an APK file
    if (!filePath.toLowerCase().endsWith('.apk')) {
      throw ArgumentError('File must be an APK file: $filePath');
    }

    final fileSize = await file.length();
    final fileSizeMB = (fileSize / 1024 / 1024);
    _logger.info(
      'Uploading APK: ${path.basename(filePath)} (${fileSizeMB.toStringAsFixed(1)} MB)',
    );
  }

  /// Set up Firebase authentication and return environment variables
  Future<Map<String, String>> _setupAuthentication() async {
    final environment = Map<String, String>.from(Platform.environment);

    if (serviceAccountPath != null && serviceAccountPath!.isNotEmpty) {
      // Use service account authentication
      final serviceAccountFile = File(serviceAccountPath!);
      if (!await serviceAccountFile.exists()) {
        throw FileSystemException(
          'Service account file not found',
          serviceAccountPath,
        );
      }

      // Set environment variable for Firebase CLI
      environment['GOOGLE_APPLICATION_CREDENTIALS'] = serviceAccountPath!;
      _logger.info('Using service account authentication');
    } else {
      // Check if user is logged in to Firebase or has GOOGLE_APPLICATION_CREDENTIALS
      final hasCredentials =
          Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'] != null;

      try {
        final result = await Process.run('firebase', [
          'projects:list',
        ], environment: environment);
        if (result.exitCode != 0 && !hasCredentials) {
          throw Exception('Not authenticated with Firebase');
        }

        if (hasCredentials) {
          _logger.info(
            'Using GOOGLE_APPLICATION_CREDENTIALS environment variable',
          );
        } else {
          _logger.info('Using Firebase login authentication');
        }
      } catch (e) {
        throw Exception(
          'Firebase authentication required. Please either:\n'
          '1. Set serviceAccountPath parameter\n'
          '2. Run "firebase login" for interactive authentication\n'
          '3. Set GOOGLE_APPLICATION_CREDENTIALS environment variable\n\n'
          'Error: $e',
        );
      }
    }

    return environment;
  }

  /// Upload APK using Firebase CLI
  Future<String> _uploadWithFirebaseCli(
    String filePath,
    Map<String, String> environment,
  ) async {
    final arguments = <String>[
      'appdistribution:distribute',
      filePath,
      '--app',
      appId,
    ];

    // Add optional parameters
    if (releaseNotes != null && releaseNotes!.isNotEmpty) {
      arguments.addAll(['--release-notes', releaseNotes!]);
    }

    if (testers?.isNotEmpty == true) {
      arguments.addAll(['--testers', testers!.join(',')]);
    }

    if (groups?.isNotEmpty == true) {
      arguments.addAll(['--groups', groups!.join(',')]);
    }

    _logger.info('Executing Firebase CLI upload...');
    _logger.info('Command: firebase ${arguments.join(' ')}');

    final result = await Process.run(
      'firebase',
      arguments,
      environment: environment,
    );

    if (result.exitCode != 0) {
      final error = result.stderr.toString();
      final output = result.stdout.toString();

      _logger.severe('Firebase CLI error output: $error');
      _logger.severe('Firebase CLI stdout: $output');

      // Provide helpful error messages for common issues
      if (error.contains('not found') || error.contains('does not exist')) {
        throw Exception(
          'Firebase app not found. Please verify:\n'
          '1. App ID is correct: $appId\n'
          '2. App exists in Firebase Console\n'
          '3. App is an Android app (not web or iOS)\n'
          '4. You have permission to access this app\n\n'
          'Firebase CLI Error: $error',
        );
      } else if (error.contains('permission') ||
          error.contains('unauthorized')) {
        throw Exception(
          'Permission denied. Please ensure:\n'
          '1. You have Firebase App Distribution Admin role\n'
          '2. Service account has proper permissions\n'
          '3. Authentication is set up correctly\n\n'
          'Firebase CLI Error: $error',
        );
      } else {
        throw Exception('Firebase CLI upload failed: $error');
      }
    }

    final output = result.stdout.toString();
    _logger.info('Firebase CLI output: $output');

    // Parse download URL from output
    final downloadUrl = _parseDownloadUrl(output);
    return downloadUrl;
  }

  /// Parse download URL from Firebase CLI output
  String _parseDownloadUrl(String output) {
    // Firebase CLI typically outputs something like:
    // "View this release in the Firebase Console: https://console.firebase.google.com/..."
    // or includes the download URL directly

    final lines = output.split('\n');
    for (final line in lines) {
      if (line.contains('console.firebase.google.com')) {
        final match = RegExp(
          r'https://console\.firebase\.google\.com[^\s]*',
        ).firstMatch(line);
        if (match != null) {
          return match.group(0)!;
        }
      }
      if (line.contains('https://') && line.contains('firebase')) {
        final match = RegExp(r'https://[^\s]+').firstMatch(line);
        if (match != null) {
          return match.group(0)!;
        }
      }
    }

    // If no URL found, return Firebase Console link
    return 'https://console.firebase.google.com/project/$projectId/appdistribution';
  }
}

/// Exception thrown when Firebase CLI operation fails
class FirebaseCliException implements Exception {
  /// The error message
  final String message;

  /// Standard error output from the CLI
  final String? stderr;

  /// Standard output from the CLI
  final String? stdout;

  /// Creates a new Firebase CLI exception
  FirebaseCliException(this.message, {this.stderr, this.stdout});

  @override
  String toString() => 'FirebaseCliException: $message';
}
