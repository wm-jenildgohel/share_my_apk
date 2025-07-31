/// **Share My APK** - The Ultimate Flutter APK Build & Upload Automation Tool
///
/// This library provides comprehensive tools for automating Flutter Android APK
/// builds and uploads to cloud services like Diawi, Gofile.io, and Firebase App Distribution.
///
/// ## Features
///
/// - **One-Command Automation**: Build and upload APKs with a single command
/// - **Multi-Provider Support**: Upload to Diawi, Gofile.io, and Firebase App Distribution
/// - **Comprehensive Build Pipeline**: Automatic clean, dependencies, and localization
/// - **Smart Organization**: Custom naming, versioning, and directory structure
/// - **Production Ready**: Enterprise-grade reliability with 100+ tests
/// - **Flexible Configuration**: YAML-based setup with CLI overrides
///
/// ## Quick Start
///
/// ### CLI Usage
/// ```bash
/// # Install globally
/// dart pub global activate share_my_apk
///
/// # Initialize configuration
/// share_my_apk --init
///
/// # Build and upload
/// share_my_apk
/// ```
///
/// ### Library Usage
/// ```dart
/// import 'package:share_my_apk/share_my_apk.dart';
///
/// void main() async {
///   // Build APK with comprehensive pipeline
///   final buildService = FlutterBuildService();
///   final apkPath = await buildService.build(
///     release: true,
///     customName: 'MyApp_Beta',
///     environment: 'staging',
///   );
///
///   // Upload to cloud
///   final uploader = UploadServiceFactory.create('gofile');
///   final downloadLink = await uploader.upload(apkPath);
///
///   print('Download link: $downloadLink');
/// }
/// ```
///
/// ## Core Services
///
/// - **[FlutterBuildService]**: Comprehensive APK building with pipeline automation
/// - **[UploadServiceFactory]**: Creates upload service instances for different providers
/// - **[DiawiUploadService]**: Upload to Diawi with polling and timeout handling
/// - **[GofileUploadService]**: Upload to Gofile.io with retry logic
/// - **[FirebaseUploadService]**: Upload to Firebase App Distribution with enterprise features
/// - **[ConfigService]**: YAML configuration management
/// - **[ArgParserUtil]**: Command-line argument parsing
///
/// ## Configuration
///
/// Create a `share_my_apk.yaml` file in your project root:
///
/// ```yaml
/// # Provider settings
/// provider: diawi
///
/// # API tokens
/// diawi_token: your_diawi_token_here
/// gofile_token: your_gofile_token_here
///
/// # Build configuration
/// release: true
/// clean: true
/// pub-get: true
/// gen-l10n: true
///
/// # File organization
/// name: MyApp_Production
/// environment: prod
/// output-dir: build/releases
/// ```
///
/// ## Examples
///
/// See the [example](https://github.com/wm-jenildgohel/share_my_apk/tree/main/example)
/// directory for comprehensive usage examples.
///
/// ## Documentation
///
/// For complete documentation, visit:
/// - [API Reference](https://pub.dev/documentation/share_my_apk/latest/)
/// - [GitHub Repository](https://github.com/wm-jenildgohel/share_my_apk)
/// - [Usage Guide](https://github.com/wm-jenildgohel/share_my_apk#readme)
library;

// Build Services
export 'package:share_my_apk/src/services/build/flutter_build_service.dart';

// Upload Services
export 'package:share_my_apk/src/services/upload/diawi_upload_service.dart';
export 'package:share_my_apk/src/services/upload/firebase_upload_service.dart';
export 'package:share_my_apk/src/services/upload/gofile_upload_service.dart';
export 'package:share_my_apk/src/services/upload/upload_service.dart';
export 'package:share_my_apk/src/services/upload/upload_service_factory.dart';

// Command-Line Utilities
export 'package:share_my_apk/src/utils/command_line/arg_parser_util.dart';

// Utility Classes
export 'package:share_my_apk/src/utils/retry_util.dart';

// Configuration and Models
export 'package:share_my_apk/src/models/cli_options.dart';
export 'package:share_my_apk/src/services/config_service.dart';
