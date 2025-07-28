import 'dart:io';

class SoundNotificationUtil {
  /// Plays a cross-platform notification sound with intelligent fallbacks.
  /// Maintains the same API but uses lightweight system sounds instead of embedded WAV.
  static void playNotificationSound() {
    _playSystemSound();
  }

  static void _playSystemSound() {
    try {
      if (Platform.isWindows) {
        _playWindowsSound();
      } else if (Platform.isLinux) {
        _playLinuxSound();
      } else if (Platform.isMacOS) {
        _playMacSound();
      }
    } catch (e) {
      // Silent fail - same behavior as before
    }
  }

  static void _playWindowsSound() {
    // Try pleasant notification sound first, then fallback
    Process.run('rundll32', ['user32.dll,MessageBeep', '0x30']).catchError((_) {
      // Fallback to default system sound
      return Process.run('rundll32', ['user32.dll,MessageBeep', '0']);
    });
  }

  static void _playLinuxSound() {
    // Try modern notification system first
    Process.run('pactl', ['play-sample', 'complete']).catchError((_) {
      // Fallback to alternative notification
      return Process.run('canberra-gtk-play', ['-i', 'complete']).catchError((_) {
        // Last resort - try system bell
        return Process.run('pactl', ['play-sample', 'bell']);
      });
    });
  }

  static void _playMacSound() {
    // Use built-in pleasant system sound
    Process.run('afplay', ['/System/Library/Sounds/Glass.aiff']).catchError((_) {
      // Fallback to alternative system sound
      return Process.run('afplay', ['/System/Library/Sounds/Ping.aiff']);
    });
  }
}
