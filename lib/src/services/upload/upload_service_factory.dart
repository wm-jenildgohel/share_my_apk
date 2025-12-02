import 'package:share_my_apk/src/services/upload/diawi_upload_service.dart';
import 'package:share_my_apk/src/services/upload/firebase_cli_upload_service.dart';
import 'package:share_my_apk/src/services/upload/gofile_upload_service.dart';
import 'package:share_my_apk/src/services/upload/upload_service.dart';

/// A factory for creating [UploadService] instances.
class UploadServiceFactory {
  /// Creates a new [UploadService] instance based on the given [provider].
  ///
  /// Supported providers:
  /// - `'diawi'`: Diawi file sharing service (requires [token])
  /// - `'gofile'`: Gofile.io file sharing service (optional [token])
  /// - `'firebase'`: Firebase App Distribution (requires [firebaseAppId])
  ///
  /// For Firebase provider:
  /// - [firebaseAppId]: Required. Format: 1:123456789:android:abc123def456
  /// - [firebaseServiceAccountPath]: Optional. Path to service account JSON file
  /// - [firebaseTesterGroups]: Optional. List of tester groups to distribute to
  /// - [firebaseReleaseNotes]: Optional. Release notes for testers
  static UploadService create(
    String provider, {
    String? token,
    String? firebaseAppId,
    String? firebaseServiceAccountPath,
    List<String>? firebaseTesterGroups,
    String? firebaseReleaseNotes,
  }) {
    final normalizedProvider = provider.trim().toLowerCase();

    if (normalizedProvider.isEmpty) {
      throw ArgumentError('Provider cannot be empty.');
    }

    switch (normalizedProvider) {
      case 'firebase':
        if (firebaseAppId == null || firebaseAppId.isEmpty) {
          throw ArgumentError(
            'Firebase provider requires an App ID.\n\n'
            'Get your Firebase App ID from:\n'
            'Firebase Console → Project Settings → Your apps\n'
            'Format: 1:123456789:android:abc123def456\n\n'
            'Provide via:\n'
            '  --firebase-app-id "YOUR_APP_ID"\n'
            'OR in share_my_apk.yaml:\n'
            '  firebase:\n'
            '    app_id: "YOUR_APP_ID"',
          );
        }
        return FirebaseCliUploadService(
          appId: firebaseAppId,
          serviceAccountPath: firebaseServiceAccountPath,
          testerGroups: firebaseTesterGroups,
          releaseNotes: firebaseReleaseNotes,
        );

      case 'gofile':
        return GofileUploadService(apiToken: token);

      case 'diawi':
        if (token == null || token.isEmpty) {
          throw ArgumentError('Diawi provider requires a token.');
        }
        return DiawiUploadService(token);

      default:
        throw ArgumentError(
          'Unknown provider: $provider\n\n'
          'Supported providers:\n'
          '  - diawi    (file sharing with 70MB limit)\n'
          '  - gofile   (file sharing, unlimited size)\n'
          '  - firebase (Firebase App Distribution for beta testing)',
        );
    }
  }
}
