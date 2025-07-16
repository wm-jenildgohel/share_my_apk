import 'dart:io';
import 'package:share_my_apk/src/utils/sound_notification_util.dart';

void main() {
  stdout.writeln('Testing cross-platform sound notification...');
  
  stdout.writeln('Playing pleasant notification sound...');
  SoundNotificationUtil.playNotificationSound();
  
  stdout.writeln('Sound notification test completed!');
  stdout.writeln('You should have heard a pleasant dual-tone notification sound (800Hz + 1000Hz, 300ms).');
  stdout.writeln('The sound file is located at lib/assets/sounds/notification.wav');
}