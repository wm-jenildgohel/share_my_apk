import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:share_my_apk/src/exceptions/upload_exception.dart';
import 'package:share_my_apk/src/services/upload/upload_service.dart';
import 'package:share_my_apk/src/utils/retry_util.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

/// An [UploadService] for uploading APKs to Gofile.io.
class GofileUploadService implements UploadService {
  /// The API token for authenticating with the Gofile.io API.
  final String? apiToken;

  /// The HTTP client used for network requests.
  final http.Client _client;

  static final Logger _logger = Logger('GofileUploadService');

  static const _uploadTimeoutMinutes = 10;

  /// Creates a new [GofileUploadService].
  GofileUploadService({this.apiToken, http.Client? client})
      : _client = client ?? http.Client();

  @visibleForTesting
  Future<String> getServer() async {
    try {
      final response = await _client
          .get(Uri.parse('https://api.gofile.io/servers'))
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw TimeoutException('Server lookup timed out after 30s'),
          );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'ok') {
          final servers = jsonResponse['data']['servers'] as List;
          if (servers.isNotEmpty) {
            return servers[0]['name']?.toString() ?? '';
          }
        }
      }

      throw UploadException(
        'Failed to get gofile.io server',
        provider: 'gofile',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    } on TimeoutException catch (e) {
      throw UploadException(
        'Server lookup timed out: ${e.message}',
        provider: 'gofile',
        originalError: e,
      );
    } on SocketException catch (e) {
      throw UploadException(
        'Network error during server lookup: ${e.message}',
        provider: 'gofile',
        originalError: e,
      );
    }
  }

  @override
  Future<String> upload(String filePath) async {
    _logger.info('☁️  Initializing Gofile.io upload...');

    // Validate file
    await _validateFile(filePath);

    // Redact token in logs
    if (apiToken != null) {
      _logger.fine('Token: ${_redactToken(apiToken!)}');
    }

    final file = File(filePath);
    final fileSize = await file.length();
    final fileSizeMB = (fileSize / 1024 / 1024).toStringAsFixed(2);
    _logger.info('📁 File size: $fileSizeMB MB');

    _logger.info('🔍 Finding optimal Gofile server...');
    final server = await getServer();
    _logger.info('🎯 Using server: $server.gofile.io');

    final uploadUrl = Uri.parse(
      'https://$server.gofile.io/contents/uploadfile',
    );

    final request = http.MultipartRequest('POST', uploadUrl);
    if (apiToken != null) {
      request.fields['token'] = apiToken!;
      _logger.info('🔐 Using authenticated upload');
    } else {
      _logger.info('📂 Using anonymous upload');
    }

    _logger.info('📤 Preparing file for upload...');
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      _logger.info('🚀 Starting upload to Gofile.io...');
      _logger.info(
        '⏳ This may take a while depending on file size and connection...',
      );

      // Use retry logic for upload with network error handling and timeout
      final response = await RetryUtil.withRetry(
        () => _client.send(request).timeout(
              Duration(minutes: _uploadTimeoutMinutes),
              onTimeout: () => throw TimeoutException(
                'Upload timed out after $_uploadTimeoutMinutes minutes. '
                'Please check your network connection.',
              ),
            ),
        maxRetries: 3,
        retryIf: RetryUtil.conditions.or([
          RetryUtil.conditions.network,
          RetryUtil.conditions.timeout,
          RetryUtil.conditions.serverError,
        ]),
      );

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        _logger.info('✅ Upload completed successfully!');
        _logger.info('📋 Processing response...');

        final jsonResponse = json.decode(responseBody);

        if (jsonResponse['status'] == 'ok') {
          final downloadPage =
              jsonResponse['data']['downloadPage']?.toString() ?? '';
          final directLink = jsonResponse['data']['directLink']?.toString();

          _logger.info('🎉 Upload successful!');
          _logger.info('📄 Download page: $downloadPage');
          if (directLink != null) {
            _logger.info('🔗 Direct link: $directLink');
          }

          return downloadPage;
        } else {
          final reason = jsonResponse['status'];
          final message = jsonResponse['message'] ?? 'Unknown error';
          _logger.severe('❌ Gofile.io upload failed: $reason - $message');
          throw UploadException(
            'Gofile.io upload failed: $message',
            provider: 'gofile',
            filePath: filePath,
            responseBody: responseBody,
          );
        }
      } else {
        _logger.severe(
          '❌ Upload failed with HTTP status: ${response.statusCode}',
        );
        _logger.info('💡 Try again or check your internet connection');
        throw UploadException(
          'Gofile.io upload failed',
          provider: 'gofile',
          filePath: filePath,
          statusCode: response.statusCode,
          responseBody: responseBody,
        );
      }
    } on TimeoutException catch (e) {
      throw UploadException(
        'Upload timed out: ${e.message}',
        provider: 'gofile',
        filePath: filePath,
        originalError: e,
      );
    } on SocketException catch (e) {
      _logger.severe('❌ Network error during upload: Connection failed');
      _logger.info('💡 Check your internet connection and try again');
      throw UploadException(
        'Network error: ${e.message}',
        provider: 'gofile',
        filePath: filePath,
        originalError: e,
      );
    } catch (e) {
      if (e is UploadException) rethrow;
      _logger.severe('❌ Upload error: $e');
      throw UploadException(
        'Unexpected error during upload',
        provider: 'gofile',
        filePath: filePath,
        originalError: e,
      );
    }
  }

  /// Validates that the file exists.
  Future<void> _validateFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      _logger.severe('❌ File not found: $filePath');
      throw UploadException(
        'File not found',
        provider: 'gofile',
        filePath: filePath,
      );
    }
  }

  /// Redacts API token for safe logging (shows only first 4 characters).
  String _redactToken(String token) {
    if (token.length <= 4) return '****';
    return '${token.substring(0, 4)}${'*' * (token.length - 4)}';
  }

  /// Disposes of the HTTP client. Call this when done with the service.
  void dispose() {
    _client.close();
  }
}
