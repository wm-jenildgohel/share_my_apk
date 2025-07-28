import 'dart:io';
import 'package:path/path.dart' as p;

/// Simple configuration service using environment variables and .env files.
///
/// Priority order (highest to lowest):
/// 1. Environment variables (DIAWI_TOKEN, GOFILE_TOKEN, etc.)
/// 2. .shareMyApk file in project root
/// 3. .shareMyApk file in user home directory
/// 4. Default values
class ConfigService {
  static const _envConfigFile = '.shareMyApk';

  /// Gets configuration from environment variables and .env files.
  ///
  /// Priority order:
  /// 1. Environment variables (DIAWI_TOKEN, GOFILE_TOKEN, etc.)
  /// 2. .shareMyApk file in project root
  /// 3. .shareMyApk file in user home directory
  /// 4. Default values
  ///
  /// ## Environment Variables:
  /// ```bash
  /// export DIAWI_TOKEN="your_token"
  /// export GOFILE_TOKEN="your_token"
  /// export SHARE_MY_APK_PROVIDER="gofile"
  /// ```
  ///
  /// ## Simple Config File (.shareMyApk):
  /// ```
  /// DIAWI_TOKEN=your_token
  /// GOFILE_TOKEN=your_token
  /// PROVIDER=gofile
  /// ```
  static Map<String, dynamic> getConfig() {
    final config = <String, dynamic>{};
    
    // Load from config files first (lowest priority)
    config.addAll(_loadFromConfigFiles());
    
    // Override with environment variables (highest priority)
    config.addAll(_loadFromEnvironment());
    
    return config;
  }

  static Map<String, dynamic> _loadFromEnvironment() {
    final config = <String, dynamic>{};
    
    // Load common environment variables
    final env = Platform.environment;
    
    if (env.containsKey('DIAWI_TOKEN')) {
      config['diawi_token'] = env['DIAWI_TOKEN'];
    }
    if (env.containsKey('GOFILE_TOKEN')) {
      config['gofile_token'] = env['GOFILE_TOKEN'];
    }
    if (env.containsKey('SHARE_MY_APK_PROVIDER')) {
      config['provider'] = env['SHARE_MY_APK_PROVIDER'];
    }
    if (env.containsKey('SHARE_MY_APK_RELEASE')) {
      config['release'] = env['SHARE_MY_APK_RELEASE'] == 'true';
    }
    
    return config;
  }

  static Map<String, dynamic> _loadFromConfigFiles() {
    // Try project root first, then user home
    final projectConfig = File(_envConfigFile);
    final homeConfig = File(p.join(_getUserHome(), _envConfigFile));
    
    if (projectConfig.existsSync()) {
      return _parseEnvFile(projectConfig);
    } else if (homeConfig.existsSync()) {
      return _parseEnvFile(homeConfig);
    }
    
    return <String, dynamic>{};
  }

  static Map<String, dynamic> _parseEnvFile(File file) {
    final config = <String, dynamic>{};
    
    try {
      final lines = file.readAsLinesSync();
      
      for (final line in lines) {
        final trimmed = line.trim();
        
        // Skip empty lines and comments
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        
        // Parse KEY=value format
        final parts = trimmed.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim().toLowerCase();
          final value = parts.sublist(1).join('=').trim();
          
          // Remove quotes if present
          final cleanValue = value.replaceAll(RegExp(r'^["\x27]|["\x27]$'), '');
          
          // Convert known boolean values
          if (cleanValue == 'true' || cleanValue == 'false') {
            config[key] = cleanValue == 'true';
          } else {
            config[key] = cleanValue;
          }
        }
      }
    } catch (e) {
      // Ignore parsing errors, return empty config
    }
    
    return config;
  }

  static String _getUserHome() {
    final env = Platform.environment;
    if (Platform.isWindows) {
      return env['USERPROFILE'] ?? env['HOME'] ?? '.';
    } else {
      return env['HOME'] ?? '.';
    }
  }
}
