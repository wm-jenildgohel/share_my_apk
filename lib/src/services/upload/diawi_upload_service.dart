import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random, min, pow;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:share_my_apk/src/constants/upload_limits.dart';
import 'package:share_my_apk/src/exceptions/upload_exception.dart';
import 'package:share_my_apk/src/services/upload/upload_service.dart';

/// An [UploadService] for uploading APKs to Diawi.
class DiawiUploadService implements UploadService {
  /// The API token for authenticating with the Diawi API.
  final String apiToken;

  /// The HTTP client used for network requests.
  final http.Client _client;

  static final Logger _logger = Logger('DiawiUploadService');

  /// Creates a new [DiawiUploadService].
  DiawiUploadService(this.apiToken, {http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<String> upload(String filePath) async {
    _logger.info('🔶 Initializing Diawi upload...');

    // Validate file
    await _validateFile(filePath);

    // Redact token in logs (H1 fix)
    _logger.fine('Token: ${_redactToken(apiToken)}');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://upload.diawi.com/'),
    );

    request.fields['token'] = apiToken;
    _logger.info('📤 Preparing file for upload...');
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      _logger.info('🚀 Starting upload to Diawi...');
      _logger.info(
        '⏳ This may take a while depending on file size and connection...',
      );

      // C3 fix: Add timeout to upload
      final streamedResponse = await _client.send(request).timeout(
            Duration(minutes: UploadLimits.defaultUploadTimeoutMinutes),
            onTimeout: () => throw TimeoutException(
              'Upload timed out after ${UploadLimits.defaultUploadTimeoutMinutes} minutes. '
              'Please check your network connection.',
            ),
          );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        _logger.info('✅ Upload request successful!');
        _logger.info('📋 Processing response...');

        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

        if (jsonResponse['job'] != null) {
          final job = jsonResponse['job'] as String;
          _logger.info('🎯 Upload started, job ID: $job');
          _logger.info('⏳ Waiting for Diawi to process the APK...');

          // H3 fix: Poll for job completion with exponential backoff
          return await _pollJobStatus(job);
        } else {
          final errorMessage =
              jsonResponse['message']?.toString() ?? 'Unknown error';
          _logger.severe('❌ Diawi upload failed: $errorMessage');
          if (errorMessage.contains('token')) {
            _logger.info(
              '💡 Check your Diawi token at: https://dashboard.diawi.com/profile/api',
            );
          }
          // H4 fix: Use UploadException with context
          throw UploadException(
            'Diawi upload failed: $errorMessage',
            provider: 'diawi',
            filePath: filePath,
            responseBody: response.body,
          );
        }
      } else {
        _logger.severe(
          '❌ Upload failed with HTTP status: ${response.statusCode}',
        );
        if (response.statusCode == 401) {
          _logger.info(
            '💡 Invalid token. Get a valid token at: https://dashboard.diawi.com/profile/api',
          );
        } else if (response.statusCode == 413) {
          _logger.info(
            '💡 File too large. Diawi has a 70MB limit. Try using Gofile.io instead.',
          );
        }
        // H4 fix: Use UploadException with context
        throw UploadException(
          'Diawi upload failed',
          provider: 'diawi',
          filePath: filePath,
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } on TimeoutException catch (e) {
      throw UploadException(
        'Upload timed out: ${e.message}',
        provider: 'diawi',
        filePath: filePath,
        originalError: e,
      );
    } on SocketException catch (e) {
      _logger.severe('❌ Network error during upload: Connection failed');
      _logger.info('💡 Check your internet connection and try again');
      throw UploadException(
        'Network error: ${e.message}',
        provider: 'diawi',
        filePath: filePath,
        originalError: e,
      );
    } catch (e) {
      if (e is UploadException) rethrow;
      _logger.severe('❌ Upload error: $e');
      throw UploadException(
        'Unexpected error during upload',
        provider: 'diawi',
        filePath: filePath,
        originalError: e,
      );
    }
  }

  /// Validates that the file exists and is within Diawi's size limit.
  Future<void> _validateFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      _logger.severe('❌ File not found: $filePath');
      throw UploadException(
        'File not found',
        provider: 'diawi',
        filePath: filePath,
      );
    }

    final fileSize = await file.length();
    final fileSizeMB = UploadLimits.bytesToMB(fileSize).toStringAsFixed(2);
    _logger.info('📁 File size: $fileSizeMB MB');

    if (fileSize > UploadLimits.diawiMaxSizeBytes) {
      final limitMB = UploadLimits.bytesToMB(UploadLimits.diawiMaxSizeBytes).toStringAsFixed(0);
      _logger.warning('⚠️  File size exceeds Diawi\'s ${limitMB}MB limit!');
      _logger.info('💡 Consider using Gofile.io for larger files');
      throw UploadException(
        'File size ($fileSizeMB MB) exceeds Diawi limit ($limitMB MB)',
        provider: 'diawi',
        filePath: filePath,
      );
    }
  }

  /// Redacts API token for safe logging (shows only first 4 characters).
  String _redactToken(String token) {
    if (token.length <= 4) return '****';
    return '${token.substring(0, 4)}${'*' * (token.length - 4)}';
  }

  Future<String> _pollJobStatus(String job) async {
    _logger.info('🔄 Monitoring processing status for job: $job');

    var attempts = 0;

    while (attempts < UploadLimits.maxPollingAttempts) {
      // H3 fix: Calculate exponential backoff with jitter
      final backoff = _calculateBackoff(attempts);
      _logger.fine(
        'Polling attempt ${attempts + 1}/${UploadLimits.maxPollingAttempts} (waiting ${backoff.inSeconds}s)',
      );

      await Future<void>.delayed(backoff);
      attempts++;

      try {
        final statusUrl = Uri.parse(
            'https://upload.diawi.com/status?token=$apiToken&job=$job');

        // C3 fix: Add timeout to status check
        final response = await _client.get(statusUrl).timeout(
              Duration(seconds: UploadLimits.defaultStatusCheckTimeoutSeconds),
              onTimeout: () =>
                  throw TimeoutException('Status check timed out after ${UploadLimits.defaultStatusCheckTimeoutSeconds}s'),
            );

        if (response.statusCode == 200) {
          final jsonResponse =
              json.decode(response.body) as Map<String, dynamic>;

          if (jsonResponse['status'] == 2000) {
            // Upload completed successfully
            final hash = jsonResponse['hash'];
            final downloadLink = 'https://i.diawi.com/$hash';
            final message = jsonResponse['message']?.toString() ?? '';

            _logger.info('🎉 Processing completed successfully!');
            _logger.info('📄 Download link: $downloadLink');
            if (message.isNotEmpty) {
              _logger.info('📝 Message: $message');
            }
            _logger.info('⏰ Link expires in 30 days');

            return downloadLink;
          } else if (jsonResponse['status'] == 4000) {
            // Upload failed
            final errorMessage =
                jsonResponse['message'] ?? 'Upload processing failed';
            _logger.severe('❌ Diawi processing failed: $errorMessage');
            throw UploadException(
              'Diawi processing failed: $errorMessage',
              provider: 'diawi',
              statusCode: jsonResponse['status'] as int?,
              responseBody: response.body,
            );
          } else {
            // Still processing, continue polling
            _logger.info(
              '⏳ Still processing... (attempt $attempts/${UploadLimits.maxPollingAttempts})',
            );

            if (attempts == 10) {
              _logger.info(
                '🐌 Taking longer than usual - large files may need more time',
              );
            } else if (attempts == 30) {
              _logger.info(
                '⚠️  Processing is taking unusually long - but still trying...',
              );
            }
          }
        } else {
          _logger.warning(
            '⚠️  Status check failed with HTTP ${response.statusCode} (attempt $attempts)',
          );
        }
      } on TimeoutException {
        _logger.warning('⚠️  Status check timed out (attempt $attempts)');
        continue;
      } on SocketException catch (e) {
        _logger.warning(
            '⚠️  Network error checking status: ${e.message} (attempt $attempts)');
        if (attempts > 5) {
          _logger.info(
            '💡 Persistent connection issues - check your internet connection',
          );
        }
        continue;
      } catch (e) {
        _logger.warning('⚠️  Error checking job status: $e (attempt $attempts)');
        continue;
      }
    }

    _logger.severe(
        '❌ Processing timed out after ${UploadLimits.maxPollingAttempts} attempts');
    _logger.info(
      '💡 The job might still be processing. Check Diawi dashboard or try again later.',
    );
    throw UploadException(
      'Job processing timed out after ${UploadLimits.maxPollingAttempts} attempts',
      provider: 'diawi',
    );
  }

  /// Calculates exponential backoff duration with jitter.
  ///
  /// Starts at 5 seconds and increases exponentially:
  /// 5s, 10s, 20s, 40s, 60s (capped at 60s)
  /// Adds random jitter (±20%) to prevent thundering herd.
  Duration _calculateBackoff(int attempt) {
    // Exponential backoff: 5 * 2^attempt, capped at maxPollingBackoffSeconds
    final baseDelay = min(
      UploadLimits.initialPollingIntervalSeconds * pow(2, attempt).toInt(),
      UploadLimits.maxPollingBackoffSeconds,
    );

    // Add jitter ±20%
    final jitterRange = (baseDelay * 0.4).toInt();
    final jitter = Random().nextInt(jitterRange) - (jitterRange ~/ 2);

    return Duration(seconds: baseDelay + jitter);
  }

  /// Disposes of the HTTP client. Call this when done with the service.
  void dispose() {
    _client.close();
  }
}
