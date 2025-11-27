import 'package:share_my_apk/src/services/upload/upload_service_factory.dart';
import 'package:share_my_apk/src/services/upload/diawi_upload_service.dart';
import 'package:share_my_apk/src/services/upload/gofile_upload_service.dart';
import 'package:test/test.dart';

void main() {
  group('UploadServiceFactory', () {
    group('create', () {
      group('diawi provider', () {
        test('creates DiawiUploadService with token', () {
          final service = UploadServiceFactory.create(
            'diawi',
            token: 'test-token',
          );
          expect(service, isA<DiawiUploadService>());
          expect(
            (service as DiawiUploadService).apiToken,
            equals('test-token'),
          );
        });

        test('throws ArgumentError when token is null', () {
          expect(
            () => UploadServiceFactory.create('diawi'),
            throwsA(
              isA<ArgumentError>().having(
                (ArgumentError e) => e.message,
                'message',
                contains('Diawi provider requires a token'),
              ),
            ),
          );
        });

        test('throws ArgumentError when token is empty', () {
          expect(
            () => UploadServiceFactory.create('diawi', token: ''),
            throwsA(
              isA<ArgumentError>().having(
                (ArgumentError e) => e.message,
                'message',
                contains('Diawi provider requires a token'),
              ),
            ),
          );
        });

        test('handles token with special characters', () {
          const tokenWithSpecialChars = 'token-123_!@#\$%';
          final service = UploadServiceFactory.create(
            'diawi',
            token: tokenWithSpecialChars,
          );
          expect(service, isA<DiawiUploadService>());
          expect(
            (service as DiawiUploadService).apiToken,
            equals(tokenWithSpecialChars),
          );
        });
      });

      group('gofile provider', () {
        test('creates GofileUploadService without token', () {
          final service = UploadServiceFactory.create('gofile');
          expect(service, isA<GofileUploadService>());
          expect((service as GofileUploadService).apiToken, isNull);
        });

        test('creates GofileUploadService with token', () {
          final service = UploadServiceFactory.create(
            'gofile',
            token: 'gofile-token',
          );
          expect(service, isA<GofileUploadService>());
          expect(
            (service as GofileUploadService).apiToken,
            equals('gofile-token'),
          );
        });

        test('creates GofileUploadService with empty token', () {
          final service = UploadServiceFactory.create('gofile', token: '');
          expect(service, isA<GofileUploadService>());
          expect((service as GofileUploadService).apiToken, equals(''));
        });

        test('handles token with special characters', () {
          const tokenWithSpecialChars = 'gofile-token-123_!@#\$%';
          final service = UploadServiceFactory.create(
            'gofile',
            token: tokenWithSpecialChars,
          );
          expect(service, isA<GofileUploadService>());
          expect(
            (service as GofileUploadService).apiToken,
            equals(tokenWithSpecialChars),
          );
        });
      });

      group('unknown provider', () {
        test('throws ArgumentError for unknown provider', () {
          expect(
            () => UploadServiceFactory.create('unknown'),
            throwsA(
              isA<ArgumentError>().having(
                (ArgumentError e) => e.message,
                'message',
                contains('Unknown provider'),
              ),
            ),
          );
        });

        test('throws TypeError for null provider', () {
          expect(
            // ignore: cast_from_null_always_fails
            () => UploadServiceFactory.create(null as String),
            throwsA(isA<TypeError>()),
          );
        });

        test('throws ArgumentError for empty provider', () {
          expect(
            () => UploadServiceFactory.create(''),
            throwsA(isA<ArgumentError>()),
          );
        });

        test('throws ArgumentError for provider with only whitespace', () {
          expect(
            () => UploadServiceFactory.create('   '),
            throwsA(isA<ArgumentError>()),
          );
        });

        test('throws ArgumentError for unsupported provider names', () {
          const unsupportedProviders = [
            'drive',
            'dropbox',
            'onedrive',
            'aws',
            'firebase',
          ];

          for (final provider in unsupportedProviders) {
            expect(
              () => UploadServiceFactory.create(provider),
              throwsA(isA<ArgumentError>()),
            );
          }
        });
      });

      group('case sensitivity', () {
        test('handles mixed case provider names', () {
          final service1 = UploadServiceFactory.create(
            'DIAWI',
            token: 'test-token',
          );
          expect(service1, isA<DiawiUploadService>());

          final service2 = UploadServiceFactory.create('Gofile');
          expect(service2, isA<GofileUploadService>());

          final service3 = UploadServiceFactory.create('GoFile');
          expect(service3, isA<GofileUploadService>());
        });
      });

      group('edge cases', () {
        test('handles provider with leading/trailing whitespace', () {
          final service1 = UploadServiceFactory.create(
            '  diawi  ',
            token: 'test-token',
          );
          expect(service1, isA<DiawiUploadService>());

          final service2 = UploadServiceFactory.create('  gofile  ');
          expect(service2, isA<GofileUploadService>());
        });

        test('handles very long tokens', () {
          final longToken = 'a' * 1000;
          final service = UploadServiceFactory.create(
            'diawi',
            token: longToken,
          );
          expect(service, isA<DiawiUploadService>());
          expect((service as DiawiUploadService).apiToken, equals(longToken));
        });
      });
    });
  });
}
