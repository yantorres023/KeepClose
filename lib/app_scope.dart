import 'package:flutter/widgets.dart';

import 'data/repository.dart';
import 'domain/local_date.dart';
import 'services/contact_picker.dart';
import 'services/launcher.dart';
import 'services/notification_service.dart';
import 'services/reminder_scheduler.dart';

/// Dependencies shared across the widget tree.
class AppDependencies {
  AppDependencies({
    required this.repository,
    required this.notifications,
    required this.scheduler,
    required this.contactPicker,
    required this.launcher,
  });

  final KeepCloseRepository repository;
  final NotificationService notifications;
  final ReminderScheduler scheduler;
  final ContactPicker contactPicker;
  final Launcher launcher;

  LocalDate get today => repository.today;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.deps, required super.child});

  final AppDependencies deps;

  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.deps;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => deps != oldWidget.deps;
}
