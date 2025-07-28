// Using print here is acceptable for CLI message output
// ignore_for_file: avoid_print

class MessageUtil {
  static void printSuccessBox(String provider, String downloadLink) {
    print('\n=== APK UPLOAD SUCCESSFUL ===');
    print('Provider: $provider');
    print('Download URL: $downloadLink');
    print('Share this link to install the APK');

    if (provider == 'diawi') {
      print('Note: Diawi links expire after 30 days');
    } else {
      print('Note: Gofile links are permanent but public');
    }
    print('==============================\n');
  }

  static void printHelpfulSuggestions() {
    print('\n--- TROUBLESHOOTING HELP ---');
    print('• Run "share_my_apk --init" to create a config file');
    print('• For Diawi: Get token at https://dashboard.diawi.com/profile/api');
    print('• Use "share_my_apk --help" for all available options');
    print('• For Gofile: Get token at https://gofile.io/api');
    print('-----------------------------\n');
  }

  static void printBuildErrorSuggestions() {
    print('\n--- BUILD ERROR HELP ---');
    print('• Run "flutter doctor" to check Flutter installation');
    print('• Try "flutter clean && flutter pub get" in your project');
    print('• Ensure you\'re in a valid Flutter project directory');
    print('• Check if Android toolchain is properly configured');
    print('• Try building manually: "flutter build apk --release"');
    print('-------------------------\n');
  }

  static void printNetworkErrorSuggestions() {
    print('\n--- NETWORK ERROR HELP ---');
    print('• Check your internet connection');
    print('• Try again in a few minutes (server might be busy)');
    print('• Check if you\'re behind a firewall or proxy');
    print('• Try switching providers (--provider gofile or diawi)');
    print('---------------------------\n');
  }

  static void printUploadErrorSuggestions() {
    print('\n--- UPLOAD ERROR HELP ---');
    print('• Verify your API token is correct and active');
    print('• Check if file size exceeds provider limits (Diawi: 70MB)');
    print('• Try using Gofile.io: "share_my_apk --provider gofile"');
    print('• Ensure APK file exists and is not corrupted');
    print('--------------------------\n');
  }

  static void printGeneralErrorSuggestions() {
    print('\n--- GENERAL ERROR HELP ---');
    print('• Try running with --help for usage information');
    print('• Ensure all dependencies are up to date');
    print('• Check GitHub issues: github.com/wm-jenildgohel/share_my_apk');
    print('• Try running the command again');
    print('---------------------------\n');
  }
}
