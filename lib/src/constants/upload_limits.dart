/// Upload size limits and timeout constants for various providers.
class UploadLimits {
  /// Maximum file size for Diawi uploads (70 MB in bytes).
  static const int diawiMaxSizeBytes = 70 * 1024 * 1024;

  /// Maximum file size for Gofile uploads (500 MB in bytes).
  /// Note: Gofile supports larger files, but this is a reasonable limit.
  static const int gofileMaxSizeBytes = 500 * 1024 * 1024;

  /// Maximum file size for Firebase App Distribution (200 MB in bytes).
  static const int firebaseMaxSizeBytes = 200 * 1024 * 1024;

  /// Default upload timeout in minutes.
  static const int defaultUploadTimeoutMinutes = 10;

  /// Default status check timeout in seconds.
  static const int defaultStatusCheckTimeoutSeconds = 30;

  /// Maximum number of polling attempts for job status.
  static const int maxPollingAttempts = 60;

  /// Initial polling interval in seconds.
  static const int initialPollingIntervalSeconds = 5;

  /// Maximum polling backoff in seconds (capped value).
  static const int maxPollingBackoffSeconds = 60;

  /// Build command timeout in minutes.
  static const int buildTimeoutMinutes = 15;

  /// Converts bytes to megabytes.
  static double bytesToMB(int bytes) => bytes / (1024 * 1024);

  /// Converts megabytes to bytes.
  static int mbToBytes(double mb) => (mb * 1024 * 1024).toInt();

  /// Gets the size limit for a given provider.
  static int? getSizeLimit(String provider) {
    switch (provider.toLowerCase()) {
      case 'diawi':
        return diawiMaxSizeBytes;
      case 'gofile':
        return gofileMaxSizeBytes;
      case 'firebase':
        return firebaseMaxSizeBytes;
      default:
        return null;
    }
  }

  /// Gets a human-readable size limit for a provider.
  static String getSizeLimitDescription(String provider) {
    final limit = getSizeLimit(provider);
    if (limit == null) return 'unlimited';
    return '${bytesToMB(limit).toStringAsFixed(0)} MB';
  }
}
