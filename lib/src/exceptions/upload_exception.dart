/// Exception thrown when an APK upload fails.
///
/// This exception includes detailed context about the failure to help
/// with debugging and error reporting.
class UploadException implements Exception {
  /// A human-readable error message.
  final String message;

  /// The upload provider that failed (e.g., 'diawi', 'gofile', 'firebase').
  final String provider;

  /// The path to the file that failed to upload, if available.
  final String? filePath;

  /// The HTTP status code from the upload response, if applicable.
  final int? statusCode;

  /// The response body from the upload service, if available.
  final String? responseBody;

  /// The original error that caused this exception, if any.
  final dynamic originalError;

  /// Creates a new upload exception with detailed context.
  UploadException(
    this.message, {
    required this.provider,
    this.filePath,
    this.statusCode,
    this.responseBody,
    this.originalError,
  });

  @override
  String toString() {
    final buffer = StringBuffer('UploadException: $message\n');
    buffer.writeln('Provider: $provider');
    if (filePath != null) buffer.writeln('File: $filePath');
    if (statusCode != null) buffer.writeln('HTTP Status: $statusCode');
    if (responseBody != null && responseBody!.isNotEmpty) {
      buffer.writeln('Response: ${responseBody!.length > 200 ? '${responseBody!.substring(0, 200)}...' : responseBody}');
    }
    if (originalError != null) buffer.writeln('Original Error: $originalError');
    return buffer.toString();
  }
}
