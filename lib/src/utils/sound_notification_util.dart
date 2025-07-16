import 'dart:io';

class SoundNotificationUtil {
  static void playNotificationSound() {
    try {
      _playAsciiBell();
      _playSystemBeep();
    } catch (e) {
      // Silently fail if sound cannot be played
    }
  }

  static void _playAsciiBell() {
    stdout.write('\x07');
  }

  static void _playSystemBeep() {
    if (Platform.isWindows) {
      _playWindowsBeep();
    } else if (Platform.isLinux) {
      _playLinuxBeep();
    } else if (Platform.isMacOS) {
      _playMacBeep();
    }
  }

  static void _playWindowsBeep() {
    try {
      // Short, high-pitched cheerful beep (frequency: 1000Hz, duration: 150ms)
      Process.runSync('powershell', ['-c', '[console]::beep(1000,150)']);
    } catch (e) {
      // Fallback to system message beep (shorter)
      try {
        Process.runSync('rundll32', ['user32.dll,MessageBeep', '0']);
      } catch (e) {
        // Silent fail
      }
    }
  }

  static void _playLinuxBeep() {
    try {
      // Try playing a pleasant notification sound first
      Process.runSync('pactl', ['play-sample', 'complete']);
    } catch (e) {
      try {
        // Short beep with higher frequency (1200Hz, 100ms)
        Process.runSync('beep', ['-f', '1200', '-l', '100']);
      } catch (e) {
        try {
          // Very short speaker test
          Process.runSync('speaker-test', ['-t', 'sine', '-f', '1200', '-l', '1', '-s', '1']);
        } catch (e) {
          // Try simple bell sound
          try {
            Process.runSync('tput', ['bel']);
          } catch (e) {
            // Silent fail
          }
        }
      }
    }
  }

  static void _playMacBeep() {
    try {
      // Use a pleasant macOS system sound
      Process.runSync('afplay', ['/System/Library/Sounds/Glass.aiff']);
    } catch (e) {
      try {
        // Fallback to Ping sound (shorter than default beep)
        Process.runSync('afplay', ['/System/Library/Sounds/Ping.aiff']);
      } catch (e) {
        try {
          // Use system beep but make it brief
          Process.runSync('osascript', ['-e', 'beep 1']);
        } catch (e) {
          // Silent fail
        }
      }
    }
  }
}