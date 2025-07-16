import 'dart:io';
import 'package:path/path.dart' as path;

class SoundNotificationUtil {
  static void playNotificationSound() {
    try {
      // Try audio file first, fallback to system sounds
      final audioFile = _getNotificationSoundPath();
      
      if (File(audioFile).existsSync()) {
        _playNotificationFile(audioFile);
      } else {
        // Use system notification sounds (more reliable for global installs)
        _playSystemFallback();
      }
    } catch (e) {
      // Silent fail
    }
  }

  static void _playNotificationFile(String audioFile) {
    if (Platform.isWindows) {
      _playWindowsAudio(audioFile);
    } else if (Platform.isLinux) {
      _playLinuxAudio(audioFile);
    } else if (Platform.isMacOS) {
      _playMacAudio(audioFile);
    }
  }

  static String _getNotificationSoundPath() {
    // Try different possible locations for the sound file
    final possiblePaths = [
      // Development environment
      path.join(Directory.current.path, 'lib', 'assets', 'sounds', 'notification.wav'),
      path.join(Directory.current.path, 'assets', 'sounds', 'notification.wav'),
      
      // Global package installation - the lib/assets should be accessible
      path.join(path.dirname(Platform.script.path), 'lib', 'assets', 'sounds', 'notification.wav'),
      path.join(path.dirname(Platform.script.path), '..', 'lib', 'assets', 'sounds', 'notification.wav'),
      path.join(path.dirname(Platform.script.path), '..', '..', 'lib', 'assets', 'sounds', 'notification.wav'),
      
      // Alternative paths for different package structures
      path.join(path.dirname(Platform.resolvedExecutable), 'lib', 'assets', 'sounds', 'notification.wav'),
      path.join(path.dirname(Platform.resolvedExecutable), '..', 'lib', 'assets', 'sounds', 'notification.wav'),
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

  static void _playSystemFallback() {
    try {
      if (Platform.isWindows) {
        // Pleasant Windows notification sound
        Process.runSync('rundll32', ['user32.dll,MessageBeep', '64']);
      } else if (Platform.isLinux) {
        // Try Linux notification sounds
        try {
          Process.runSync('pactl', ['play-sample', 'message-new-instant']);
        } catch (e) {
          try {
            Process.runSync('canberra-gtk-play', ['-i', 'complete']);
          } catch (e) {
            // Silent fail
          }
        }
      } else if (Platform.isMacOS) {
        // Pleasant macOS sound
        Process.runSync('afplay', ['/System/Library/Sounds/Glass.aiff']);
      }
    } catch (e) {
      // Silent fail
    }
  }
}