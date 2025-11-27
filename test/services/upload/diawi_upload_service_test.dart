import 'package:share_my_apk/src/services/upload/diawi_upload_service.dart';
import 'package:test/test.dart';

void main() {
  group('DiawiUploadService', () {
    late DiawiUploadService service;
    const testToken = 'test-diawi-token';

    setUp(() {
      service = DiawiUploadService(testToken);
    });

    group('constructor', () {
      test('creates service with token', () {
        expect(service.apiToken, equals(testToken));
      });

      test('requires token in constructor', () {
        // This should compile and work
        final serviceWithToken = DiawiUploadService('required-token');
        expect(serviceWithToken.apiToken, equals('required-token'));
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

    group('token validation', () {
      test('service with empty token is handled correctly', () {
        final emptyTokenService = DiawiUploadService('');
        expect(emptyTokenService.apiToken, equals(''));
      });

      test('service with valid token is created correctly', () {
        final validTokenService = DiawiUploadService('valid-diawi-token-123');
        expect(validTokenService.apiToken, equals('valid-diawi-token-123'));
      });

      test('service with special characters in token', () {
        final specialTokenService = DiawiUploadService(
          'token-with-special-chars_123!',
        );
        expect(
          specialTokenService.apiToken,
          equals('token-with-special-chars_123!'),
        );
      });
    });

    group('file validation', () {
      test('rejects null file path', () async {
        // ignore: cast_from_null_always_fails
        expect(() => service.upload(null as String), throwsA(isA<TypeError>()));
      });

      test('handles very long file path', () async {
        final longPath = '/very/long/path' * 100 + '/file.apk';
        expect(() => service.upload(longPath), throwsA(isA<Exception>()));
      });

      test('handles path with special characters', () async {
        expect(
          () => service.upload('/path/with spaces/file.apk'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
