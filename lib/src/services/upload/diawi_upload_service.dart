import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:share_my_apk/src/services/upload/upload_service.dart';

/// An [UploadService] for uploading APKs to Diawi.
class DiawiUploadService implements UploadService {
  /// The API token for authenticating with the Diawi API.
  final String apiToken;
  static final Logger _logger = Logger('DiawiUploadService');

  /// Diawi's maximum file size limit in bytes (70 MB)
  static const int maxFileSizeBytes = 70 * 1024 * 1024;

  /// Creates a new [DiawiUploadService].
  DiawiUploadService(this.apiToken);

  @override
  Future<String> upload(String filePath) async {
    _logger.info('Initializing Diawi upload...');

    final file = File(filePath);
    if (!await file.exists()) {
      _logger.severe('File not found: $filePath');
      throw Exception('File not found: $filePath');
    }

    final fileSize = await file.length();
    final fileSizeMB = fileSize / (1024 * 1024);
    _logger.info('File size: ${fileSizeMB.toStringAsFixed(2)} MB');

    if (fileSize > maxFileSizeBytes) {
      _logger.warning('File size exceeds Diawi\'s 70MB limit!');
      _logger.info('Consider using Gofile.io for larger files');
    }

    _logger.info('Authenticating with Diawi API...');
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://upload.diawi.com/'),
    );

    request.fields['token'] = apiToken;
    _logger.info('Preparing file for upload...');
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      _logger.info('Starting upload to Diawi...');
      _logger.info(
        'This may take a while depending on file size and connection...',
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        _logger.info('Upload request successful!');
        _logger.info('Processing response...');

        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);

        if (jsonResponse['job'] != null) {
          final job = jsonResponse['job'];
          _logger.info('Upload started, job ID: $job');
          _logger.info('Waiting for Diawi to process the APK...');

          // Poll for job completion
          return await _pollJobStatus(job as String);
        } else {
          final errorMessage =
              jsonResponse['message']?.toString() ?? 'Unknown error';
          _logger.severe('Diawi upload failed: $errorMessage');
          if (errorMessage.contains('token')) {
            _logger.info(
              'Check your Diawi token at: https://dashboard.diawi.com/profile/api',
            );
          }
          throw Exception('Diawi upload failed: $errorMessage');
        }
      } else {
        _logger.severe(
          'Upload failed with HTTP status: ${response.statusCode}',
        );
        if (response.statusCode == 401) {
          _logger.info(
            'Invalid token. Get a valid token at: https://dashboard.diawi.com/profile/api',
          );
        } else if (response.statusCode == 413) {
          _logger.info(
            'File too large. Diawi has a 70MB limit. Try using Gofile.io instead.',
          );
        }
        throw Exception(
          'Diawi upload failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        _logger.severe('Network error during upload: Connection failed');
        _logger.info('Check your internet connection and try again');
      } else {
        _logger.severe('Upload error: $e');
      }
      throw Exception('Error uploading to Diawi: $e');
    }
  }

  /// Maximum number of polling attempts
  static const int _maxPollingAttempts = 30;

  /// Poll interval between status checks
  static const Duration _pollInterval = Duration(seconds: 5);

  Future<String> _pollJobStatus(String job) async {
    _logger.info('Monitoring processing status for job: $job');

    final totalTimeoutMinutes =
        (_maxPollingAttempts * _pollInterval.inSeconds / 60).toStringAsFixed(1);

    _logger.info('Maximum wait time: $totalTimeoutMinutes minutes');

    for (int attempt = 0; attempt < _maxPollingAttempts; attempt++) {
      try {
        final response = await http.get(
          Uri.parse('https://upload.diawi.com/status?token=$apiToken&job=$job'),
        );

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);

          if (jsonResponse['status'] == 2000) {
            // Upload completed successfully
            final hash = jsonResponse['hash'];
            final downloadLink = 'https://i.diawi.com/$hash';
            final message = jsonResponse['message']?.toString() ?? '';

            _logger.info('Processing completed successfully!');
            _logger.info('Download link: $downloadLink');
            if (message.isNotEmpty) {
              _logger.info('Message: $message');
            }
            _logger.info('Link expires in 30 days');

            return downloadLink;
          } else if (jsonResponse['status'] == 4000) {
            // Upload failed
            final errorMessage =
                jsonResponse['message'] ?? 'Upload processing failed';
            _logger.severe('Diawi processing failed: $errorMessage');
            throw Exception('Diawi processing failed: $errorMessage');
          } else {
            // Still processing, continue polling
            final elapsedMinutes =
                ((attempt + 1) * _pollInterval.inSeconds / 60).toStringAsFixed(
                  1,
                );
            _logger.info(
              'Still processing... ($elapsedMinutes min elapsed, attempt ${attempt + 1}/$_maxPollingAttempts)',
            );

            if (attempt == 10) {
              _logger.info(
                'Taking longer than usual - large files may need more time',
              );
            } else if (attempt == 20) {
              _logger.info(
                'Processing is taking unusually long - but still trying...',
              );
            }

            await Future<void>.delayed(_pollInterval);
          }
        } else {
          _logger.warning(
            'Status check failed with HTTP ${response.statusCode} (attempt ${attempt + 1})',
          );
          await Future<void>.delayed(_pollInterval);
        }
      } catch (e) {
        _logger.warning(
          'Error checking job status: $e (attempt ${attempt + 1})',
        );
        if (attempt > 5) {
          _logger.info(
            'Persistent connection issues - check your internet connection',
          );
        }
        await Future<void>.delayed(_pollInterval);
      }
    }

    _logger.severe('Processing timed out after $totalTimeoutMinutes minutes');
    _logger.info(
      'The job might still be processing. Check Diawi dashboard or try again later.',
    );
    throw Exception(
      'Job processing timed out after $totalTimeoutMinutes minutes',
    );
  }
}
