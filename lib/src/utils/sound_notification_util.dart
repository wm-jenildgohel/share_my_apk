import 'dart:io';
import 'package:path/path.dart' as path;

class SoundNotificationUtil {
  static void playNotificationSound() {
    try {
      _playNotificationFile();
    } catch (e) {
      // Silently fail if sound cannot be played
    }
  }

  static void _playNotificationFile() {
    final audioFile = _getNotificationSoundPath();
    
    if (!File(audioFile).existsSync()) {
      return; // Silent fail if file doesn't exist
    }

    if (Platform.isWindows) {
      _playWindowsAudio(audioFile);
    } else if (Platform.isLinux) {
      _playLinuxAudio(audioFile);
    } else if (Platform.isMacOS) {
      _playMacAudio(audioFile);
    }
  }

  static String _getNotificationSoundPath() {
    // Get the directory where the executable is running
    final executableDir = path.dirname(Platform.resolvedExecutable);
    
    // Try different possible locations for the sound file
    final possiblePaths = [
      path.join(executableDir, 'assets', 'sounds', 'notification.wav'),
      path.join(Directory.current.path, 'assets', 'sounds', 'notification.wav'),
      path.join(executableDir, '..', 'assets', 'sounds', 'notification.wav'),
    ];
    
    for (final soundPath in possiblePaths) {
      if (File(soundPath).existsSync()) {
        return soundPath;
      }
    }
    
    // Default path (may not exist)
    return possiblePaths.first;
  }

  static void _playWindowsAudio(String audioFile) {
    try {
      // Use PowerShell SoundPlayer for WAV files
      Process.runSync('powershell', [
        '-c',
        '(New-Object Media.SoundPlayer "$audioFile").PlaySync()'
      ]);
    } catch (e) {
      try {
        // Fallback to Windows Media Player
        Process.runSync('wmplayer', [audioFile, '/close']);
      } catch (e) {
        try {
          // Last resort: pleasant Windows notification
          Process.runSync('rundll32', ['user32.dll,MessageBeep', '64']);
        } catch (e) {
          // Silent fail
        }
      }
    }
  }

  static void _playLinuxAudio(String audioFile) {
    try {
      // Try aplay (ALSA audio player)
      Process.runSync('aplay', [audioFile]);
    } catch (e) {
      try {
        // Try paplay (PulseAudio player)
        Process.runSync('paplay', [audioFile]);
      } catch (e) {
        try {
          // Try ffplay (if available)
          Process.runSync('ffplay', ['-nodisp', '-autoexit', audioFile]);
        } catch (e) {
          try {
            // Try mpg123 or similar
            Process.runSync('mpg123', ['-q', audioFile]);
          } catch (e) {
            // Silent fail
          }
        }
      }
    }
  }

  static void _playMacAudio(String audioFile) {
    try {
      // Use afplay (built-in macOS audio player)
      Process.runSync('afplay', [audioFile]);
    } catch (e) {
      try {
        // Fallback to QuickTime Player
        Process.runSync('open', ['-a', 'QuickTime Player', audioFile]);
      } catch (e) {
        try {
          // Fallback to pleasant system sound
          Process.runSync('afplay', ['/System/Library/Sounds/Glass.aiff']);
        } catch (e) {
          // Silent fail
        }
      }
    }
  }
}