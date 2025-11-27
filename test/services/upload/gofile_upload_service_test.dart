import 'package:share_my_apk/src/services/upload/gofile_upload_service.dart';
import 'package:test/test.dart';

void main() {
  group('GofileUploadService', () {
    late GofileUploadService service;
    late GofileUploadService serviceWithToken;

    setUp(() {
      service = GofileUploadService();
      serviceWithToken = GofileUploadService(apiToken: 'test-token');
    });

    group('constructor', () {
      test('creates service without token', () {
        expect(service.apiToken, isNull);
      });

      test('creates service with token', () {
        expect(serviceWithToken.apiToken, equals('test-token'));
      });
    });

    group('upload', () {
      test('throws exception when file does not exist', () async {
        // Act & Assert
        expect(
          () => service.upload('/non/existent/file.apk'),
          throwsA(
            isA<Exception>().having(
              (Exception e) => e.toString(),
              'message',
              contains('File not found'),
            ),
          ),
        );
      });

      test('handles empty file path', () async {
        // Act & Assert
        expect(() => service.upload(''), throwsA(isA<Exception>()));
      });

      test('validates file path format', () async {
        // Act & Assert
        expect(
          () => service.upload('invalid_path_without_extension'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('token handling', () {
      test('service without token is created correctly', () {
        final noTokenService = GofileUploadService();
        expect(noTokenService.apiToken, isNull);
      });

      test('service with empty token is handled correctly', () {
        final emptyTokenService = GofileUploadService(apiToken: '');
        expect(emptyTokenService.apiToken, equals(''));
      });

      test('service with valid token is created correctly', () {
        final validTokenService = GofileUploadService(
          apiToken: 'valid-token-123',
        );
        expect(validTokenService.apiToken, equals('valid-token-123'));
      });
    });
  });
}
