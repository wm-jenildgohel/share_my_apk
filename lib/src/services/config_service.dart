import 'dart:io';
import 'package:yaml/yaml.dart';

/// Service for reading configuration from `share_my_apk.yaml`.
///
/// This service extracts configuration options for the share_my_apk package
/// from a dedicated `share_my_apk.yaml` file, allowing users to set default
/// values for various options without specifying them on the command line.
/// Service for reading configuration from `share_my_apk.yaml`.
///
/// This service extracts configuration options for the share_my_apk package
/// from a dedicated `share_my_apk.yaml` file, allowing users to set default
/// values for various options without specifying them on the command line.
class ConfigService {
  static const _configFileName = 'share_my_apk.yaml';

  /// Creates an instance of [ConfigService].
  ///
  /// This class is not meant to be instantiated, as it provides static methods only.
  const ConfigService();

  /// Reads share_my_apk configuration from `share_my_apk.yaml`.
  ///
  /// Looks for a `share_my_apk.yaml` file in the project root and returns
  /// the configuration as a Map. Returns an empty Map if the file doesn't
  /// exist or if it's empty.
  ///
  /// ## Example `share_my_apk.yaml` configuration:
  ///
  /// ```yaml
  /// # Default provider to use for uploads.
  /// provider: diawi
  ///
  /// # API tokens for different providers.
  /// diawi_token: your_diawi_token
  /// gofile_token: your_gofile_token
  ///
  /// # Default build environment.
  /// environment: staging
  ///
  /// # Default output directory for APKs.
  /// output-dir: /custom/output
  /// ```
  static Map<String, dynamic> getConfig() {
    final file = File(_configFileName);
    if (!file.existsSync()) {
      // Also check for config in pubspec.yaml for backward compatibility.
      return _getConfigFromPubspec();
    }

    final content = file.readAsStringSync();
    final yaml = loadYaml(content);

    if (yaml is Map) {
      return Map<String, dynamic>.from(yaml);
    }

    return <String, dynamic>{};
  }

  static Map<String, dynamic> _getConfigFromPubspec() {
    final file = File('pubspec.yaml');
    if (!file.existsSync()) {
      return <String, dynamic>{};
    }

    final content = file.readAsStringSync();
    final yaml = loadYaml(content);

    final config = yaml['share_my_apk'];
    if (config is Map) {
      return Map<String, dynamic>.from(config);
    }

    return <String, dynamic>{};
  }
}
