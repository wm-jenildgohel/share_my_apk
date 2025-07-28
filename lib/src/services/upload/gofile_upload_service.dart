import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:share_my_apk/src/services/upload/upload_service.dart';
import 'package:share_my_apk/src/utils/retry_util.dart';
import 'package:logging/logging.dart';

/// An [UploadService] for uploading APKs to Gofile.io.
class GofileUploadService implements UploadService {
  /// The API token for authenticating with the Gofile.io API.
  final String? apiToken;
  static final Logger _logger = Logger('GofileUploadService');

  /// Creates a new [GofileUploadService].
  GofileUploadService({this.apiToken});

  Future<String> getServer() async {
    final response = await http.get(Uri.parse('https://api.gofile.io/servers'));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'ok') {
        final servers = jsonResponse['data']['servers'] as List;
        if (servers.isNotEmpty) {
          return servers[0]['name']?.toString() ?? '';
        }
      }
    }
    throw Exception('Failed to get gofile.io server.');
  }

  @override
  Future<String> upload(String filePath) async {
    _logger.info('Initializing Gofile.io upload...');

    final file = File(filePath);
    if (!await file.exists()) {
      _logger.severe('File not found: $filePath');
      throw Exception('File not found: $filePath');
    }

    final fileSize = await file.length();
    final fileSizeMB = (fileSize / 1024 / 1024).toStringAsFixed(2);
    _logger.info('File size: $fileSizeMB MB');

    _logger.info('Finding optimal Gofile server...');
    final server = await getServer();
    _logger.info('Using server: $server.gofile.io');

    final uploadUrl = Uri.parse(
      'https://$server.gofile.io/contents/uploadfile',
    );

    final request = http.MultipartRequest('POST', uploadUrl);
    if (apiToken != null) {
      request.fields['token'] = apiToken!;
      _logger.info('Using authenticated upload');
    } else {
      _logger.info('Using anonymous upload');
    }

    _logger.info('Preparing file for upload...');
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      _logger.info('Starting upload to Gofile.io...');
      _logger.info(
        'This may take a while depending on file size and connection...',
      );

      // Use retry logic for upload with network error handling
      final response = await RetryUtil.withRetry(
        () => request.send(),
        maxRetries: 3,
        retryIf: RetryUtil.conditions.or([
          RetryUtil.conditions.network,
          RetryUtil.conditions.timeout,
          RetryUtil.conditions.serverError,
        ]),
      );

      if (response.statusCode == 200) {
        _logger.info('Upload completed successfully!');
        _logger.info('Processing response...');

        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);

        if (jsonResponse['status'] == 'ok') {
          final downloadPage =
              jsonResponse['data']['downloadPage']?.toString() ?? '';
          final directLink = jsonResponse['data']['directLink']?.toString();

          _logger.info('Upload successful!');
          _logger.info('Download page: $downloadPage');
          if (directLink != null) {
            _logger.info('Direct link: $directLink');
          }

          return downloadPage;
        } else {
          final reason = jsonResponse['status'];
          final message = jsonResponse['message'] ?? 'Unknown error';
          _logger.severe('Gofile.io upload failed: $reason - $message');
          throw Exception('Gofile.io upload failed: $message');
        }
      } else {
        _logger.severe(
          'Upload failed with HTTP status: ${response.statusCode}',
        );
        _logger.info('Try again or check your internet connection');
        throw Exception(
          'Gofile.io upload failed with status: ${response.statusCode}',
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
      throw Exception('Error uploading to Gofile.io: $e');
    }
  }
}
