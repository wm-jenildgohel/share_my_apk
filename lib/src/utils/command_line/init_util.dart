import 'dart:io';
import 'package:logging/logging.dart';

class InitUtil {
  static final Logger _logger = Logger('InitUtil');

  static void generateConfigFile() {
    _logger.info('🚀 Initializing Share My APK configuration...');

    final configFile = File('share_my_apk.yaml');
    if (configFile.existsSync()) {
      _logger.warning(
        '⚠️  Configuration file already exists: share_my_apk.yaml',
      );
      _logger.info('💡 Edit the existing file or delete it to regenerate');
      return;
    }

    configFile.writeAsStringSync('''
# 🚀 Share My APK Configuration File
# This file contains default values for the command-line options.
# Uncomment and modify values as needed.

# 📋 PROVIDER SETTINGS
# Choose your upload provider: diawi, gofile, or firebase
# • Diawi: Great for team sharing, requires token, 70MB limit, links expire in 30 days
# • Gofile: No size limits, no token required, permanent public links
# • Firebase: Enterprise beta testing platform, 2GB limit, tester management, free
provider: gofile

# 🔑 API TOKENS
# Diawi token (required for diawi provider): https://dashboard.diawi.com/profile/api
# diawi_token: your_diawi_token_here

# Gofile token (optional, enables private uploads): https://gofile.io/api
# gofile_token: your_gofile_token_here

# 🔥 FIREBASE APP DISTRIBUTION (for beta testing)
# Uncomment and configure to use Firebase App Distribution
# firebase:
#   # Firebase App ID (REQUIRED): Get from Firebase Console → Project Settings → Your apps
#   # Format: 1:123456789:android:abc123def456
#   app_id: "1:123456789:android:abc123def456"
#
#   # Service account JSON path (OPTIONAL for local dev)
#   # Required for CI/CD, optional if you've run "firebase login"
#   # Get from: Google Cloud Console → IAM & Admin → Service Accounts
#   # service_account_path: ~/.firebase/service-account.json
#
#   # Tester groups to distribute to (OPTIONAL)
#   # Create groups in Firebase Console → App Distribution → Testers & Groups
#   # tester_groups:
#   #   - qa-team
#   #   - beta-testers
#   #   - internal
#
#   # Release notes shown to testers (OPTIONAL, max 16,384 characters)
#   # release_notes: "Bug fixes and performance improvements"

# 📁 BUILD SETTINGS
# Path to your Flutter project (default: current directory)
path: .

# Build mode (release = optimized APK, debug = development APK)
release: true

# 🏷️  FILE ORGANIZATION
# Custom name for the APK file (without .apk extension)
# Example: "MyApp_v1.0" -> "MyApp_v1.0_2025_01_15_14_30_45.apk"
# name: MyApp_Production

# Environment folder for organizing builds (dev, staging, prod, etc.)
# Creates: output-dir/environment/your-apk.apk
# environment: prod

# Output directory for the built APK (default: Flutter's build/app/outputs/apk)
# output-dir: builds/releases

# 🔧 BUILD PIPELINE
# Run flutter clean before building (recommended: true)
clean: true

# Run flutter pub get before building (recommended: true)
pub-get: true

# Generate localizations if lib/l10n exists (recommended: true)
gen-l10n: true
''');

    _logger.info('✅ Configuration file created: share_my_apk.yaml');
    _logger.info('');
    _logger.info('🎯 Next Steps:');
    _logger.info('   1. Edit share_my_apk.yaml to customize your settings');
    _logger.info('   2. Choose your provider:');
    _logger.info(
      '      • Diawi: Add token from https://dashboard.diawi.com/profile/api',
    );
    _logger.info('      • Gofile: No setup needed (default)');
    _logger.info(
      '      • Firebase: Uncomment firebase section and add App ID',
    );
    _logger.info('   3. Run "share_my_apk" to build and upload your APK');
    _logger.info('');
    _logger.info('💡 Quick Start:');
    _logger.info('   • Gofile (no setup): share_my_apk');
    _logger.info('   • Diawi: share_my_apk --provider diawi --diawi-token YOUR_TOKEN');
    _logger.info('   • Firebase: share_my_apk --provider firebase --firebase-app-id "YOUR_APP_ID"');
  }
}
