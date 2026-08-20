import 'package:onesignal_flutter/onesignal_flutter.dart';

const _oneSignalAppId = '518b5974-bbf8-4fbf-8c0c-4e434a2f49eb';

class OneSignalService {
  static void initialize() {
    OneSignal.initialize(_oneSignalAppId);
  }

  static Future<void> linkUser(String userId) => OneSignal.login(userId);

  static Future<void> unlinkUser() => OneSignal.logout();

  static Future<bool> requestPermission() =>
      OneSignal.Notifications.requestPermission(true);

  static bool get isPermissionGranted => OneSignal.Notifications.permission;

  // Fires when the user taps a push notification (cold start, background,
  // or foreground) — see send-push/index.ts, which attaches class_id/
  // class_name/is_teacher as the notification's `data` so the app can jump
  // straight to that class instead of just opening to Home.
  static void onNotificationClick(void Function(Map<String, dynamic> data) handler) {
    OneSignal.Notifications.addClickListener((event) {
      handler(event.notification.additionalData ?? {});
    });
  }
}
