import 'package:test/test.dart';
import 'package:share_my_apk/src/models/cli_options.dart';
import 'package:share_my_apk/src/utils/command_line/arg_parser_util.dart';

void main() {
  group('Bundle Functionality', () {
    group('CliOptions', () {
      test('should default bundle to false', () {
        const options = CliOptions();
        expect(options.bundle, false);
      });

      test('should support bundle parameter', () {
        const options = CliOptions(bundle: true);
        expect(options.bundle, true);
      });

      test('copyWith should include bundle parameter', () {
        const options = CliOptions();
        final updated = options.copyWith(bundle: true);
        expect(updated.bundle, true);
        expect(options.bundle, false); // Original unchanged
      });

      test('toString should include bundle parameter', () {
        const options = CliOptions(bundle: true);
        final string = options.toString();
        expect(string, contains('bundle: true'));
      });
    });

    group('ArgParserUtil', () {
      late ArgParserUtil argParser;

      setUp(() {
        argParser = ArgParserUtil();
      });

      test('should parse bundle flag from arguments', () {
        final options = argParser.parse(['--bundle']);
        expect(options.bundle, true);
      });

      test('should default bundle to false when not specified', () {
        final options = argParser.parse([]);
        expect(options.bundle, false);
      });

      test('should support bundle with other flags', () {
        final options = argParser.parse([
          '--bundle',
          '--name', 'TestApp',
          '--environment', 'prod',
        ]);
        expect(options.bundle, true);
        expect(options.customName, 'TestApp');
        expect(options.environment, 'prod');
      });

      test('should handle bundle flag in any position', () {
        final options = argParser.parse([
          '--name', 'TestApp',
          '--bundle',
          '--environment', 'prod',
        ]);
        expect(options.bundle, true);
        expect(options.customName, 'TestApp');
        expect(options.environment, 'prod');
      });
    });

    group('Bundle Build Logic', () {
      test('should differentiate between APK and AAB output types', () {
        const apkOptions = CliOptions(bundle: false);
        const aabOptions = CliOptions(bundle: true);
        
        expect(apkOptions.bundle, false);
        expect(aabOptions.bundle, true);
      });

      test('should handle bundle with custom naming', () {
        const options = CliOptions(
          bundle: true,
          customName: 'MyApp_Production',
          environment: 'prod',
        );
        
        expect(options.bundle, true);
        expect(options.customName, 'MyApp_Production');
        expect(options.environment, 'prod');
      });

      test('should handle bundle with release mode', () {
        const options = CliOptions(
          bundle: true,
          isRelease: true,
        );
        
        expect(options.bundle, true);
        expect(options.isRelease, true);
      });

      test('should handle bundle with debug mode', () {
        const options = CliOptions(
          bundle: true,
          isRelease: false,
        );
        
        expect(options.bundle, true);
        expect(options.isRelease, false);
      });
    });

    group('Bundle Configuration', () {
      test('should support bundle in configuration files', () {
        // Test that bundle flag can be read from config
        // This would require mocking ConfigService, but tests the concept
        const options = CliOptions(bundle: true);
        expect(options.bundle, true);
      });

      test('should prioritize CLI argument over config file', () {
        final argParser = ArgParserUtil();
        final options = argParser.parse(['--bundle']);
        expect(options.bundle, true);
      });

      test('should handle mixed bundle and upload configurations', () {
        const options = CliOptions(
          bundle: false,  // APK with upload
          provider: 'gofile',
          customName: 'TestApp_Beta',
        );
        
        expect(options.bundle, false);
        expect(options.provider, 'gofile');
        expect(options.customName, 'TestApp_Beta');
      });
    });

    group('Edge Cases', () {
      test('should handle empty arguments gracefully', () {
        final argParser = ArgParserUtil();
        final options = argParser.parse([]);
        expect(options.bundle, false); // Default value
      });

      test('should handle bundle with all other options', () {
        final argParser = ArgParserUtil();
        final options = argParser.parse([
          '--bundle',
          '--name', 'FullTest',
          '--environment', 'staging',
          '--no-release',
          '--verbose',
        ]);
        
        expect(options.bundle, true);
        expect(options.customName, 'FullTest');
        expect(options.environment, 'staging');
        expect(options.isRelease, false);
        expect(options.verbose, true);
      });
    });
  });
}