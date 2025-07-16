import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  generateNotificationSound();
}

void generateNotificationSound() {
  const sampleRate = 44100;
  const duration = 0.3; // 300ms
  const frequency1 = 800.0; // First tone
  const frequency2 = 1000.0; // Second tone (harmony)
  final samples = (sampleRate * duration).round();

  final data = Uint8List(44 + samples * 2); // WAV header (44 bytes) + data

  // WAV header
  _writeString(data, 0, 'RIFF');
  _writeInt32(data, 4, 36 + samples * 2);
  _writeString(data, 8, 'WAVE');
  _writeString(data, 12, 'fmt ');
  _writeInt32(data, 16, 16); // PCM format chunk size
  _writeInt16(data, 20, 1); // PCM format
  _writeInt16(data, 22, 1); // Mono
  _writeInt32(data, 24, sampleRate);
  _writeInt32(data, 28, sampleRate * 2); // Byte rate
  _writeInt16(data, 32, 2); // Block align
  _writeInt16(data, 34, 16); // Bits per sample
  _writeString(data, 36, 'data');
  _writeInt32(data, 40, samples * 2);

  // Generate pleasant dual-tone sound with fade in/out
  for (int i = 0; i < samples; i++) {
    final t = i / sampleRate;
    final fadeIn = min(1.0, t * 10); // Quick fade in
    final fadeOut = min(1.0, (duration - t) * 10); // Quick fade out
    final envelope = fadeIn * fadeOut;

    // Mix two frequencies for a pleasant harmonic sound
    final sample1 = sin(2 * pi * frequency1 * t);
    final sample2 = sin(2 * pi * frequency2 * t) * 0.5; // Quieter harmony
    final sample = (sample1 + sample2) * envelope * 0.3; // Lower volume

    final sampleInt = (sample * 32767).round().clamp(-32768, 32767);
    _writeInt16(data, 44 + i * 2, sampleInt);
  }

  // Write to package assets location
  final file = File('lib/assets/sounds/notification.wav');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(data);

  stdout.writeln('Generated pleasant notification sound: ${file.path}');
  stdout.writeln('Duration: ${duration}s, Sample rate: ${sampleRate}Hz');

  // Generate Dart file with Base64 encoded sound
  final base64String = base64Encode(data);
  final dartFile = File('lib/src/utils/notification_sound_data.dart');
  dartFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: prefer_single_quotes

class NotificationSoundData {
  static const String base64Encoded = '$base64String';
}
''');

  stdout.writeln('Generated Dart file with sound data: ${dartFile.path}');
}

void _writeString(Uint8List data, int offset, String value) {
  for (int i = 0; i < value.length; i++) {
    data[offset + i] = value.codeUnitAt(i);
  }
}

void _writeInt32(Uint8List data, int offset, int value) {
  data[offset] = value & 0xFF;
  data[offset + 1] = (value >> 8) & 0xFF;
  data[offset + 2] = (value >> 16) & 0xFF;
  data[offset + 3] = (value >> 24) & 0xFF;
}

void _writeInt16(Uint8List data, int offset, int value) {
  data[offset] = value & 0xFF;
  data[offset + 1] = (value >> 8) & 0xFF;
}
