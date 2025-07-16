import 'dart:io';

class SoundNotificationUtil {
  static void playNotificationSound() {
    try {
      // Skip ASCII bell as it can be harsh
      _playPleasantSound();
    } catch (e) {
      // Silently fail if sound cannot be played
    }
  }

  static void _playPleasantSound() {
    if (Platform.isWindows) {
      _playWindowsSound();
    } else if (Platform.isLinux) {
      _playLinuxSound();
    } else if (Platform.isMacOS) {
      _playMacSound();
    }
  }

  static void _playWindowsSound() {
    try {
      // Play Windows notification sound (pleasant ding)
      Process.runSync('rundll32', ['user32.dll,MessageBeep', '64']);
    } catch (e) {
      try {
        // Play system notification sound
        Process.runSync('powershell', ['-c', '(New-Object Media.SoundPlayer "C:\\Windows\\Media\\notify.wav").PlaySync()']);
      } catch (e) {
        try {
          // Gentle, higher-pitched beep as last resort
          Process.runSync('powershell', ['-c', '[console]::beep(800,100)']);
        } catch (e) {
          // Silent fail
        }
      }
    }
  }

  static void _playLinuxSound() {
    try {
      // Try playing notification sound from freedesktop sound theme
      Process.runSync('pactl', ['play-sample', 'message-new-instant']);
    } catch (e) {
      try {
        // Try playing bell sound
        Process.runSync('pactl', ['play-sample', 'bell-terminal']);
      } catch (e) {
        try {
          // Try system notification sound
          Process.runSync('canberra-gtk-play', ['-i', 'message-new-instant']);
        } catch (e) {
          try {
            // Use aplay with a notification sound if available
            Process.runSync('aplay', ['/usr/share/sounds/alsa/Front_Left.wav']);
          } catch (e) {
            try {
              // Very gentle beep as last resort
              Process.runSync('beep', ['-f', '600', '-l', '80']);
            } catch (e) {
              // Silent fail
            }
          }
        }
      }
    }
  }

  static void _playMacSound() {
    try {
      // Use pleasant macOS notification sounds
      Process.runSync('afplay', ['/System/Library/Sounds/Blow.aiff']);
    } catch (e) {
      try {
        // Fallback to Bottle sound (very pleasant)
        Process.runSync('afplay', ['/System/Library/Sounds/Bottle.aiff']);
      } catch (e) {
        try {
          // Fallback to Glass sound
          Process.runSync('afplay', ['/System/Library/Sounds/Glass.aiff']);
        } catch (e) {
          try {
            // Fallback to Pop sound
            Process.runSync('afplay', ['/System/Library/Sounds/Pop.aiff']);
          } catch (e) {
            // Silent fail - no harsh beeps as fallback
          }
        }
      }
    }
  }
}