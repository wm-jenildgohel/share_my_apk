import 'package:share_my_apk/src/services/upload/diawi_upload_service.dart';
import 'package:share_my_apk/src/services/upload/gofile_upload_service.dart';
import 'package:share_my_apk/src/services/upload/upload_service.dart';

/// A factory for creating [UploadService] instances.
class UploadServiceFactory {
  /// Creates a new [UploadService] instance based on the given [provider].
  static UploadService create(String provider, {String? token}) {
    final normalizedProvider = provider.trim().toLowerCase();

    if (normalizedProvider.isEmpty) {
      throw ArgumentError('Provider cannot be empty.');
    }

    switch (normalizedProvider) {
      case 'gofile':
        if (token == null || token.isEmpty) {
          throw ArgumentError('Gofile provider requires an API token.');
        }
        return GofileUploadService(apiToken: token);
      case 'diawi':
        if (token == null || token.isEmpty) {
          throw ArgumentError('Diawi provider requires a token.');
        }
        return DiawiUploadService(token);
      default:
        throw ArgumentError('Unknown provider: $provider');
    }
  }
}
