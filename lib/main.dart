import 'package:flutter/material.dart';

import 'app.dart';
import 'app_scope.dart';
import 'data/database.dart';
import 'data/repository.dart';
import 'services/contact_picker.dart';
import 'services/launcher.dart';
import 'services/notification_service.dart';
import 'services/reminder_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Bootstrap());
}

/// Opens the database and services, showing a recoverable error if that fails.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late Future<AppDependencies> _deps = _open();

  Future<AppDependencies> _open() async {
    final db = AppDatabase.open();
    final repository = KeepCloseRepository(db);
    // Touch the database so open/migration errors surface here.
    await repository.loadSettings();
    final notifications = LocalNotificationService();
    try {
      await notifications.init(onTap: _openToday);
    } catch (e) {
      debugPrint('KeepClose: notifications unavailable (${e.runtimeType})');
    }
    final scheduler = ReminderScheduler(
      repository: repository,
      notifications: notifications,
    )..start();
    return AppDependencies(
      repository: repository,
      notifications: notifications,
      scheduler: scheduler,
      contactPicker: NativeContactPicker(),
      launcher: UrlLauncher(),
    );
  }

  void _openToday() {
    _navigatorKey.currentState?.popUntil((r) => r.isFirst);
    homeTabRequest.value = HomeTab.today;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppDependencies>(
      future: _deps,
      builder: (context, snap) {
        if (snap.hasData) {
          return KeepCloseApp(deps: snap.data!, navigatorKey: _navigatorKey);
        }
        if (snap.hasError) {
          return StartupErrorApp(
            onRetry: () => setState(() => _deps = _open()),
          );
        }
        return const StartupLoadingApp();
      },
    );
  }
}
