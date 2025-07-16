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
      Process.runSync('rundll32', ['user32.dll,MessageBeep']);
    } catch (e) {
      // Fallback to PowerShell beep
      try {
        Process.runSync('powershell', ['-c', '[console]::beep(800,200)']);
      } catch (e) {
        // Silent fail
      }
    }
  }

  static void _playLinuxBeep() {
    try {
      Process.runSync('pactl', ['play-sample', 'bell']);
    } catch (e) {
      try {
        Process.runSync('beep', []);
      } catch (e) {
        try {
          Process.runSync('speaker-test', ['-t', 'sine', '-f', '1000', '-l', '1']);
        } catch (e) {
          // Silent fail
        }
      }
    }
  }

  static void _playMacBeep() {
    try {
      Process.runSync('afplay', ['/System/Library/Sounds/Ping.aiff']);
    } catch (e) {
      try {
        Process.runSync('osascript', ['-e', 'beep']);
      } catch (e) {
        // Silent fail
      }
    }
  }
}