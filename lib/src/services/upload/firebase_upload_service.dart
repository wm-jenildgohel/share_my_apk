import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:share_my_apk/src/services/upload/upload_service.dart';

/// A service for uploading APK files to Firebase App Distribution.
///
/// This service handles the upload process to Firebase App Distribution,
/// including authentication via service account credentials and app management.
///
/// ## Authentication Methods
///
/// 1. **Service Account JSON File**: Specify path to service account JSON file
/// 2. **Application Default Credentials (ADC)**: Use gcloud CLI authentication
/// 3. **Environment Variables**: Set GOOGLE_APPLICATION_CREDENTIALS
///
/// ## Usage Example
///
/// ```dart
/// // Using service account file
/// final service = FirebaseUploadService(
///   projectId: 'my-firebase-project',
///   appId: '1:123456789:android:abcdef',
///   serviceAccountPath: '/path/to/service-account.json',
/// );
///
/// // Using Application Default Credentials
/// final service = FirebaseUploadService(
///   projectId: 'my-firebase-project',
///   appId: '1:123456789:android:abcdef',
/// );
///
/// final shareableLink = await service.upload('/path/to/app.apk');
/// ```
class FirebaseUploadService implements UploadService {
  static final Logger _logger = Logger('FirebaseUploadService');

  /// Firebase project ID
  final String projectId;

  /// Firebase app ID (format: 1:123456789:android:abcdef)
  final String appId;

  /// Path to service account JSON file (optional)
  final String? serviceAccountPath;

  /// Release notes for the uploaded APK
  final String? releaseNotes;

  /// Testers to notify (email addresses)
  final List<String>? testers;

  /// Groups to notify
  final List<String>? groups;

  /// HTTP client for making API requests
  final http.Client _httpClient;

  /// Creates a new Firebase App Distribution upload service.
  FirebaseUploadService({
    required this.projectId,
    required this.appId,
    this.serviceAccountPath,
    this.releaseNotes,
    this.testers,
    this.groups,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  @override
  Future<String> upload(String filePath) async {
    _logger.info('Starting Firebase App Distribution upload...');

    try {
      // Validate file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('APK file not found', filePath);
      }

      final fileSize = await file.length();
      _logger.info('Uploading APK: ${path.basename(filePath)} (${_formatBytes(fileSize)})');

      // Get access token
      final accessToken = await _getAccessToken();

      // Upload the APK file
      final operation = await _uploadApk(filePath, accessToken);

      // Wait for upload completion
      final release = await _waitForUploadCompletion(operation, accessToken);

      // Distribute to testers/groups if specified
      if (testers?.isNotEmpty == true || groups?.isNotEmpty == true) {
        await _distributeRelease(release['name'] as String, accessToken);
      }

      final downloadUrl = (release['binaryDownloadUri'] as String?) ??
          (release['displayVersion'] as String?) ??
          'Firebase App Distribution';

      _logger.info('Firebase App Distribution upload completed successfully!');
      return downloadUrl;
    } catch (e) {
      _logger.severe('Firebase upload failed: $e');
      rethrow;
    }
  }

  /// Get OAuth2 access token for Firebase API
  Future<String> _getAccessToken() async {
    try {
      if (serviceAccountPath != null) {
        return await _getAccessTokenFromServiceAccount();
      } else {
        return await _getAccessTokenFromADC();
      }
    } catch (e) {
      throw Exception('Failed to get access token: $e');
    }
  }

  /// Get access token using service account JSON file
  Future<String> _getAccessTokenFromServiceAccount() async {
    if (serviceAccountPath == null || serviceAccountPath!.isEmpty) {
      throw ArgumentError('Service account path is null or empty');
    }

    final serviceAccountFile = File(serviceAccountPath!);
    if (!await serviceAccountFile.exists()) {
      throw FileSystemException('Service account file not found', serviceAccountPath);
    }

    final serviceAccountJson = await serviceAccountFile.readAsString();
    final serviceAccount = jsonDecode(serviceAccountJson) as Map<String, dynamic>;

    final privateKey = serviceAccount['private_key'] as String?;
    final clientEmail = serviceAccount['client_email'] as String?;

    if (privateKey == null || privateKey.isEmpty) {
      throw ArgumentError('Service account JSON missing or empty private_key field');
    }
    if (clientEmail == null || clientEmail.isEmpty) {
      throw ArgumentError('Service account JSON missing or empty client_email field');
    }

    // Create JWT for service account authentication
    final jwt = _createJwt(clientEmail, privateKey);

    // Exchange JWT for access token
    final response = await _httpClient.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': jwt,
      },
    );

    if (response.statusCode != 200) {
      throw HttpException('Failed to get access token: ${response.body}');
    }

    final tokenData = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = tokenData['access_token'] as String?;
    
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Received null or empty access token from OAuth2 response');
    }
    
    return accessToken;
  }

  /// Get access token using Application Default Credentials
  Future<String> _getAccessTokenFromADC() async {
    // Try to use gcloud CLI to get access token
    try {
      final result = await Process.run('gcloud', [
        'auth',
        'application-default',
        'print-access-token',
      ]);

      if (result.exitCode == 0) {
        final token = result.stdout.toString().trim();
        if (token.isNotEmpty) {
          return token;
        }
      }
      _logger.warning('gcloud CLI returned empty token or failed with exit code: ${result.exitCode}');
    } catch (e) {
      _logger.warning('Failed to get token from gcloud CLI: $e');
    }

    // Fallback to environment variable
    final credentialsPath = Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];
    if (credentialsPath != null && credentialsPath.isNotEmpty) {
      try {
        final tempService = FirebaseUploadService(
          projectId: projectId,
          appId: appId,
          serviceAccountPath: credentialsPath,
        );
        return await tempService._getAccessTokenFromServiceAccount();
      } catch (e) {
        _logger.warning('Failed to get token from service account file: $e');
      }
    }

    throw Exception(
      'No authentication method available. Please either:\n'
      '1. Set serviceAccountPath parameter\n'
      '2. Run "gcloud auth application-default login"\n'
      '3. Set GOOGLE_APPLICATION_CREDENTIALS environment variable\n'
      '\nCurrent state:\n'
      '- Service account path: ${serviceAccountPath ?? "not provided"}\n'
      '- GOOGLE_APPLICATION_CREDENTIALS: ${credentialsPath ?? "not set"}\n'
      '- gcloud CLI: not authenticated or not available',
    );
  }

  /// Create JWT for service account authentication
  String _createJwt(String clientEmail, String privateKey) {
    // Note: In a production implementation, you would use proper RSA signing
    // For now, this is a simplified version that assumes external JWT creation
    throw UnimplementedError(
      'JWT creation requires RSA signing. Please use a service account JSON file '
      'with gcloud CLI or set GOOGLE_APPLICATION_CREDENTIALS environment variable.',
    );
  }

  /// Upload APK file to Firebase App Distribution
  Future<Map<String, dynamic>> _uploadApk(String filePath, String accessToken) async {
    final fileName = path.basename(filePath);

    final uri = Uri.parse(
      'https://firebaseappdistribution.googleapis.com/v1/projects/$projectId/apps/$appId/releases:upload',
    );

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.headers['X-Goog-Upload-File-Name'] = fileName;
    request.headers['X-Goog-Upload-Protocol'] = 'multipart';

    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    _logger.info('Uploading to Firebase App Distribution...');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw HttpException('Upload failed: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    _logger.info('Upload initiated successfully');
    return responseData;
  }

  /// Wait for upload operation to complete
  Future<Map<String, dynamic>> _waitForUploadCompletion(
    Map<String, dynamic> operation,
    String accessToken,
  ) async {
    final operationName = operation['name'] as String;
    _logger.info('Waiting for upload to complete...');

    for (int attempt = 0; attempt < 30; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 2));

      final response = await _httpClient.get(
        Uri.parse('https://firebaseappdistribution.googleapis.com/v1/$operationName'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode != 200) {
        throw HttpException('Failed to check operation status: ${response.body}');
      }

      final operationData = jsonDecode(response.body) as Map<String, dynamic>;

      if (operationData['done'] == true) {
        if (operationData.containsKey('error')) {
          throw Exception('Upload failed: ${operationData['error']}');
        }
        _logger.info('Upload completed successfully');
        return operationData['response'] as Map<String, dynamic>;
      }

      _logger.info('Upload in progress... (attempt ${attempt + 1}/30)');
    }

    throw TimeoutException('Upload timed out after 60 seconds');
  }

  /// Distribute release to testers and groups
  Future<void> _distributeRelease(String releaseName, String accessToken) async {
    if (testers?.isEmpty == true && groups?.isEmpty == true) {
      return;
    }

    _logger.info('Distributing release to testers and groups...');

    final distributionRequest = <String, dynamic>{};

    if (testers?.isNotEmpty == true) {
      distributionRequest['testerEmails'] = testers;
    }

    if (groups?.isNotEmpty == true) {
      distributionRequest['groupAliases'] = groups;
    }

    if (releaseNotes?.isNotEmpty == true) {
      distributionRequest['releaseNotes'] = {'text': releaseNotes};
    }

    final response = await _httpClient.patch(
      Uri.parse('https://firebaseappdistribution.googleapis.com/v1/$releaseName'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(distributionRequest),
    );

    if (response.statusCode != 200) {
      _logger.warning('Failed to distribute release: ${response.body}');
    } else {
      _logger.info('Release distributed successfully');
    }
  }

  /// Format bytes to human readable string
  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Dispose of resources
  void dispose() {
    _httpClient.close();
  }
}

/// Exception thrown when upload times out
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}