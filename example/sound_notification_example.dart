import 'dart:io';
import 'package:share_my_apk/src/utils/sound_notification_util.dart';

void main() {
  stdout.writeln('Testing cross-platform sound notification...');
  
  stdout.writeln('Playing ASCII bell...');
  SoundNotificationUtil.playNotificationSound();
  
  stdout.writeln('Sound notification test completed!');
  stdout.writeln('You should have heard a beep/notification sound if your system supports it.');
}