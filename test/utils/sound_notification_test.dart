import 'package:test/test.dart';
import 'package:share_my_apk/src/utils/sound_notification_util.dart';

void main() {
  group('SoundNotificationUtil', () {
    test('playNotificationSound does not throw', () {
      expect(
        () => SoundNotificationUtil.playNotificationSound(),
        returnsNormally,
      );
    });
  });
}
