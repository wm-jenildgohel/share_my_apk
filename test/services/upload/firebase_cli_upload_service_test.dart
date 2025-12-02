import 'package:test/test.dart';
import 'package:share_my_apk/src/services/upload/firebase_cli_upload_service.dart';
import 'package:share_my_apk/src/services/upload/upload_service_factory.dart';

void main() {
  group('FirebaseCliUploadService', () {
    test('creates service with required app ID', () {
      final service = FirebaseCliUploadService(
        appId: '1:123456789:android:abc123def456',
      );

      expect(service.appId, equals('1:123456789:android:abc123def456'));
      expect(service.serviceAccountPath, isNull);
      expect(service.testerGroups, isNull);
      expect(service.releaseNotes, isNull);
    });

    test('creates service with all parameters', () {
      final service = FirebaseCliUploadService(
        appId: '1:123456789:android:abc123def456',
        serviceAccountPath: '/path/to/service-account.json',
        testerGroups: ['qa-team', 'beta-testers'],
        releaseNotes: 'Bug fixes and improvements',
      );

      expect(service.appId, equals('1:123456789:android:abc123def456'));
      expect(
        service.serviceAccountPath,
        equals('/path/to/service-account.json'),
      );
      expect(service.testerGroups, equals(['qa-team', 'beta-testers']));
      expect(service.releaseNotes, equals('Bug fixes and improvements'));
    });

    test('service account path is optional', () {
      final service = FirebaseCliUploadService(
        appId: '1:123456789:android:abc123def456',
        testerGroups: ['qa-team'],
      );

      expect(service.serviceAccountPath, isNull);
      expect(service.testerGroups, isNotNull);
    });

    test('tester groups can be empty list', () {
      final service = FirebaseCliUploadService(
        appId: '1:123456789:android:abc123def456',
        testerGroups: [],
      );

      expect(service.testerGroups, isEmpty);
    });

    test('release notes can be empty string', () {
      final service = FirebaseCliUploadService(
        appId: '1:123456789:android:abc123def456',
        releaseNotes: '',
      );

      expect(service.releaseNotes, isEmpty);
    });
  });

  group('UploadServiceFactory - Firebase', () {
    test('creates FirebaseCliUploadService with app ID', () {
      final service = UploadServiceFactory.create(
        'firebase',
        firebaseAppId: '1:123456789:android:abc123def456',
      );

      expect(service, isA<FirebaseCliUploadService>());
    });

    test('creates Firebase service with all parameters', () {
      final service = UploadServiceFactory.create(
        'firebase',
        firebaseAppId: '1:123456789:android:abc123def456',
        firebaseServiceAccountPath: '/path/to/service-account.json',
        firebaseTesterGroups: ['qa-team', 'beta-testers'],
        firebaseReleaseNotes: 'Test release notes',
      );

      expect(service, isA<FirebaseCliUploadService>());
      final firebaseService = service as FirebaseCliUploadService;
      expect(
        firebaseService.serviceAccountPath,
        equals('/path/to/service-account.json'),
      );
      expect(
        firebaseService.testerGroups,
        equals(['qa-team', 'beta-testers']),
      );
      expect(
        firebaseService.releaseNotes,
        equals('Test release notes'),
      );
    });

    test('throws for Firebase without app ID', () {
      expect(
        () => UploadServiceFactory.create('firebase'),
        throwsArgumentError,
      );
    });

    test('throws for Firebase with empty app ID', () {
      expect(
        () => UploadServiceFactory.create('firebase', firebaseAppId: ''),
        throwsArgumentError,
      );
    });

    test('throws for Firebase with null app ID', () {
      expect(
        () => UploadServiceFactory.create('firebase', firebaseAppId: null),
        throwsArgumentError,
      );
    });

    test('accepts Firebase with case variations', () {
      final service1 = UploadServiceFactory.create(
        'FIREBASE',
        firebaseAppId: '1:123:android:abc',
      );
      final service2 = UploadServiceFactory.create(
        'Firebase',
        firebaseAppId: '1:123:android:abc',
      );
      final service3 = UploadServiceFactory.create(
        'firebase',
        firebaseAppId: '1:123:android:abc',
      );

      expect(service1, isA<FirebaseCliUploadService>());
      expect(service2, isA<FirebaseCliUploadService>());
      expect(service3, isA<FirebaseCliUploadService>());
    });
  });

  group('UploadServiceFactory - All Providers', () {
    test('creates correct service for each provider', () {
      final diawiService = UploadServiceFactory.create(
        'diawi',
        token: 'test-token',
      );
      final gofileService = UploadServiceFactory.create('gofile');
      final firebaseService = UploadServiceFactory.create(
        'firebase',
        firebaseAppId: '1:123:android:abc',
      );

      expect(diawiService.toString(), contains('DiawiUploadService'));
      expect(gofileService.toString(), contains('GofileUploadService'));
      expect(firebaseService, isA<FirebaseCliUploadService>());
    });

    test('throws for unknown provider', () {
      expect(
        () => UploadServiceFactory.create('unknown'),
        throwsArgumentError,
      );
    });

    test('throws for empty provider', () {
      expect(
        () => UploadServiceFactory.create(''),
        throwsArgumentError,
      );
    });

    test('throws for whitespace provider', () {
      expect(
        () => UploadServiceFactory.create('   '),
        throwsArgumentError,
      );
    });
  });
}
