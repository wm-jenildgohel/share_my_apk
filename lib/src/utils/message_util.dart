import 'dart:io';

// ANSI color codes
const String reset = '\x1B[0m';
const String red = '\x1B[31m';
const String green = '\x1B[32m';
const String yellow = '\x1B[33m';
const String blue = '\x1B[34m';
const String cyan = '\x1B[36m';

class MessageUtil {
  static void printSuccessBox(String provider, String downloadLink) {
    // Provider-specific messages
    String emoji, title, linkLabel, shareMessage, tip;
    
    switch (provider.toLowerCase()) {
      case 'firebase':
        emoji = '🔥';
        title = 'APK successfully uploaded to Firebase App Distribution!';
        linkLabel = '🔗 Tester Link:';
        shareMessage = '📱 Share this link with your testers';
        tip = '💡 Testers need Firebase App Tester app or will get email invite';
        break;
      case 'diawi':
        emoji = '📦';
        title = 'APK successfully uploaded to Diawi!';
        linkLabel = '🔗 Download Link:';
        shareMessage = '📱 Share this link to install the APK';
        tip = '💡 Diawi links expire after 30 days';
        break;
      case 'gofile':
      default:
        emoji = '☁️';
        title = 'APK successfully uploaded to Gofile!';
        linkLabel = '🔗 Download Link:';
        shareMessage = '📱 Share this link to install the APK';
        tip = '💡 Gofile links are permanent but publicly accessible';
        break;
    }

    final message = '$emoji $title';
    final link = '$linkLabel $downloadLink';
    
    // Calculate box width based on longest line
    final maxLength = [
      message,
      link,
      shareMessage,
      tip,
    ].map((s) => _stripEmojis(s).length).reduce((a, b) => a > b ? a : b);
    final boxWidth = maxLength + 4;

    // Print beautiful success box
    stdout.writeln('\n\n');
    stdout.writeln(green);
    stdout.writeln('╔${'═' * (boxWidth - 2)}╗');
    stdout.writeln('║ ${_padLine(message, boxWidth - 3)}║');
    stdout.writeln('║${' ' * (boxWidth - 2)}║');
    stdout.writeln('║ ${_padLine(link, boxWidth - 3)}║');
    stdout.writeln('║ ${_padLine(shareMessage, boxWidth - 3)}║');
    stdout.writeln('║${' ' * (boxWidth - 2)}║');
    stdout.writeln('║ ${_padLine(tip, boxWidth - 3)}║');
    stdout.writeln('╚${'═' * (boxWidth - 2)}╝');
    stdout.writeln(reset);
  }

  /// Strips emojis for accurate length calculation
  static String _stripEmojis(String text) {
    // Remove common emojis used in our messages
    return text
        .replaceAll(RegExp(r'[🎉🔗📱💡🔥📦☁️]'), '')
        .trim();
  }

  /// Pads a line accounting for emoji width issues
  static String _padLine(String text, int width) {
    final strippedLength = _stripEmojis(text).length;
    final padding = width - strippedLength;
    return text + (' ' * (padding > 0 ? padding : 0));
  }

  static void printHelpfulSuggestions() {
    stdout.writeln(
      '$yellow╔═══════════════════════════════════════════════════════════════╗$reset',
    );
    stdout.writeln(
      '$yellow║                     💡 TROUBLESHOOTING HELP                   ║$reset',
    );
    stdout.writeln(
      '$yellow╠═══════════════════════════════════════════════════════════════╣$reset',
    );
    stdout.writeln(
      '$yellow║  • Run "share_my_apk --init" to create a config file          ║$reset',
    );
    stdout.writeln(
      '$yellow║  • For Diawi: Get token at https://dashboard.diawi.com/...    ║$reset',
    );
    stdout.writeln(
      '$yellow║  • Use "share_my_apk --help" for all available options        ║$reset',
    );
    stdout.writeln(
      '$yellow║  • Try "share_my_apk --provider gofile" (no token required)   ║$reset',
    );
    stdout.writeln(
      '$yellow╚═══════════════════════════════════════════════════════════════╝$reset',
    );
  }

  static void printBuildErrorSuggestions() {
    stdout.writeln(
      '$red╔═══════════════════════════════════════════════════════════════╗$reset',
    );
    stdout.writeln(
      '$red║                     🔧 BUILD ERROR HELP                       ║$reset',
    );
    stdout.writeln(
      '$red╠═══════════════════════════════════════════════════════════════╣$reset',
    );
    stdout.writeln(
      '$red║  • Run "flutter doctor" to check Flutter installation         ║$reset',
    );
    stdout.writeln(
      '$red║  • Try "flutter clean && flutter pub get" in your project     ║$reset',
    );
    stdout.writeln(
      '$red║  • Ensure you\'re in a valid Flutter project directory         ║$reset',
    );
    stdout.writeln(
      '$red║  • Check if Android toolchain is properly configured          ║$reset',
    );
    stdout.writeln(
      '$red║  • Try building manually: "flutter build apk --release"       ║$reset',
    );
    stdout.writeln(
      '$red╚═══════════════════════════════════════════════════════════════╝$reset',
    );
  }

  static void printNetworkErrorSuggestions() {
    stdout.writeln(
      '$red╔═══════════════════════════════════════════════════════════════╗$reset',
    );
    stdout.writeln(
      '$red║                     🌐 NETWORK ERROR HELP                     ║$reset',
    );
    stdout.writeln(
      '$red╠═══════════════════════════════════════════════════════════════╣$reset',
    );
    stdout.writeln(
      '$red║  • Check your internet connection                             ║$reset',
    );
    stdout.writeln(
      '$red║  • Try again in a few minutes (server might be busy)          ║$reset',
    );
    stdout.writeln(
      '$red║  • Check if you\'re behind a firewall or proxy                 ║$reset',
    );
    stdout.writeln(
      '$red║  • Try switching providers (--provider gofile or diawi)       ║$reset',
    );
    stdout.writeln(
      '$red╚═══════════════════════════════════════════════════════════════╝$reset',
    );
  }

  static void printUploadErrorSuggestions() {
    stdout.writeln(
      '$red╔═══════════════════════════════════════════════════════════════╗$reset',
    );
    stdout.writeln(
      '$red║                     📤 UPLOAD ERROR HELP                      ║$reset',
    );
    stdout.writeln(
      '$red╠═══════════════════════════════════════════════════════════════╣$reset',
    );
    stdout.writeln(
      '$red║  • Verify your API token is correct and active                ║$reset',
    );
    stdout.writeln(
      '$red║  • Check if file size exceeds provider limits (Diawi: 70MB)   ║$reset',
    );
    stdout.writeln(
      '$red║  • Try using Gofile.io: "share_my_apk --provider gofile"       ║$reset',
    );
    stdout.writeln(
      '$red║  • Ensure APK file exists and is not corrupted                ║$reset',
    );
    stdout.writeln(
      '$red╚═══════════════════════════════════════════════════════════════╝$reset',
    );
  }

  static void printGeneralErrorSuggestions() {
    stdout.writeln(
      '$red╔═══════════════════════════════════════════════════════════════╗$reset',
    );
    stdout.writeln(
      '$red║                     ⚠️  GENERAL ERROR HELP                     ║$reset',
    );
    stdout.writeln(
      '$red╠═══════════════════════════════════════════════════════════════╣$reset',
    );
    stdout.writeln(
      '$red║  • Try running with --help for usage information              ║$reset',
    );
    stdout.writeln(
      '$red║  • Ensure all dependencies are up to date                     ║$reset',
    );
    stdout.writeln(
      '$red║  • Check GitHub issues: github.com/wm-jenildgohel/share_my_apk║$reset',
    );
    stdout.writeln(
      '$red║  • Try running the command again                              ║$reset',
    );
    stdout.writeln(
      '$red╚═══════════════════════════════════════════════════════════════╝$reset',
    );
  }
}
