import 'package:share_my_apk/src/services/build/flutter_build_service.dart';
import 'package:test/test.dart';

void main() {
  group('FlutterBuildService', () {
    late FlutterBuildService buildService;

    setUp(() {
      buildService = FlutterBuildService();
    });

    test('creates instance successfully', () {
      expect(buildService, isA<FlutterBuildService>());
    });

    test('creates instance with logger', () {
      final service = FlutterBuildService();
      expect(service, isA<FlutterBuildService>());
    });
  });
}
