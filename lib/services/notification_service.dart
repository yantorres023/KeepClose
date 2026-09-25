import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A notification to deliver at a wall-clock time in the device timezone.
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
  });

  final int id;
  final tz.TZDateTime when;
  final String title;
  final String body;

  @override
  String toString() => 'PlannedNotification($id, $when, $title, $body)';
}

enum PermissionState { granted, denied, unknown }

/// Platform boundary for local notifications (faked in tests).
abstract class NotificationService {
  Future<void> init({void Function()? onTap});

  /// Refreshes `tz.local` from the device. Returns true if it changed.
  Future<bool> refreshTimezone();

  Future<PermissionState> permissionState();

  /// Asks the OS for permission. Returns the resulting state.
  Future<PermissionState> requestPermission();

  Future<void> cancelAll();

  Future<void> schedule(PlannedNotification n);

  /// Whether the app was launched by tapping a notification.
  Future<bool> launchedFromNotification();
}

class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _tzLoaded = false;

  static const _channel = AndroidNotificationDetails(
    'daily_digest',
    'Daily reminder',
    channelDescription: 'At most one gentle reminder a day.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    // Lock screen shows the public version (title only) unless the user
    // allows sensitive content in system settings.
    visibility: NotificationVisibility.private,
    category: AndroidNotificationCategory.reminder,
  );

  @override
  Future<void> init({void Function()? onTap}) async {
    await refreshTimezone();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => onTap?.call(),
    );
  }

  @override
  Future<bool> refreshTimezone() async {
    if (!_tzLoaded) {
      tzdata.initializeTimeZones();
      _tzLoaded = true;
    }
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final name = info.identifier;
      if (tz.local.name == name) return false;
      tz.setLocalLocation(tz.getLocation(name));
      return true;
    } catch (e) {
      debugPrint(
        'KeepClose: timezone lookup failed (${e.runtimeType}); using UTC',
      );
      return false;
    }
  }

  @override
  Future<PermissionState> permissionState() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final enabled = await android?.areNotificationsEnabled();
      if (enabled == null) return PermissionState.unknown;
      return enabled ? PermissionState.granted : PermissionState.denied;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final options = await ios?.checkPermissions();
      if (options == null) return PermissionState.unknown;
      return options.isEnabled
          ? PermissionState.granted
          : PermissionState.denied;
    }
    return PermissionState.unknown;
  }

  @override
  Future<PermissionState> requestPermission() async {
    bool? granted;
    if (defaultTargetPlatform == TargetPlatform.android) {
      granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: false, sound: true);
    }
    if (granted == null) return PermissionState.unknown;
    return granted ? PermissionState.granted : PermissionState.denied;
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> schedule(PlannedNotification n) => _plugin.zonedSchedule(
    id: n.id,
    title: n.title,
    body: n.body,
    scheduledDate: n.when,
    notificationDetails: const NotificationDetails(
      android: _channel,
      iOS: DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.passive,
      ),
    ),
    // A gentle daily nudge does not need exact alarms (and their extra
    // permission on Android 14+).
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );

  @override
  Future<bool> launchedFromNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp ?? false;
  }
}
