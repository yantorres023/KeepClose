import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/repository.dart';
import '../../services/notification_service.dart';
import '../widgets/common.dart';
import 'privacy_screen.dart';

String formatMinutes(BuildContext context, int minutes) {
  final t = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  return MaterialLocalizations.of(context).formatTimeOfDay(
    t,
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

Future<int?> pickReminderTime(BuildContext context, int current) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    helpText: 'Daily reminder time',
  );
  return picked == null ? null : picked.hour * 60 + picked.minute;
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PermissionState? _permission;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    PermissionState state;
    try {
      state = await AppScope.of(context).notifications.permissionState();
    } catch (_) {
      state = PermissionState.unknown;
    }
    if (mounted) setState(() => _permission = state);
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAllDialog(),
    );
    if (!(confirmed ?? false) || !mounted) return;
    final deps = AppScope.of(context);
    await guardedWrite(context, () async {
      await deps.repository.deleteAllData();
      await deps.notifications.cancelAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    final repo = deps.repository;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Watch<AppSettings>(
        stream: (deps) => deps.repository.watchSettings(),
        builder: (context, s) => ListView(
          children: [
            const SectionHeader('Reminders'),
            SwitchListTile(
              key: const Key('notifications-switch'),
              title: const Text('Daily reminder'),
              subtitle: const Text(
                'At most one a day, only when there\'s something to remember.',
              ),
              value: s.notificationsEnabled,
              onChanged: (v) async {
                await repo.setNotificationsEnabled(v);
                if (v) {
                  final state = await deps.notifications.requestPermission();
                  if (mounted) setState(() => _permission = state);
                }
              },
            ),
            if (s.notificationsEnabled && _permission == PermissionState.denied)
              const ListTile(
                leading: Icon(Icons.notifications_off_outlined),
                title: Text('Notifications are off for KeepClose'),
                subtitle: Text(
                  'Turn them on in your phone\'s Settings if you\'d like a '
                  'daily nudge. Everything still shows in Today.',
                ),
              ),
            ListTile(
              enabled: s.notificationsEnabled,
              title: const Text('Time'),
              subtitle: Text(formatMinutes(context, s.reminderMinutes)),
              trailing: const Icon(Icons.schedule),
              onTap: () async {
                final m = await pickReminderTime(context, s.reminderMinutes);
                if (m != null) await repo.setReminderMinutes(m);
              },
            ),
            const SectionHeader('On the lock screen'),
            RadioGroup<NotificationDetail>(
              groupValue: s.notificationDetail,
              onChanged: (v) {
                if (v != null) repo.setNotificationDetail(v);
              },
              child: const Column(
                children: [
                  RadioListTile(
                    value: NotificationDetail.private,
                    title: Text('Private (recommended)'),
                    subtitle: Text('"You have 2 gentle reminders today."'),
                  ),
                  RadioListTile(
                    value: NotificationDetail.names,
                    title: Text('Names only'),
                    subtitle: Text('"Thinking of Ana, Lucas today."'),
                  ),
                  RadioListTile(
                    value: NotificationDetail.full,
                    title: Text('Full details'),
                    subtitle: Text('"Ask Ana: how the interview went"'),
                  ),
                ],
              ),
            ),
            const SectionHeader('Privacy & data'),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('How your data is handled'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
              ),
            ),
            ListTile(
              key: const Key('delete-all'),
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Delete all data'),
              onTap: _deleteAll,
            ),
            const SectionHeader('About'),
            ListTile(
              title: const Text('KeepClose'),
              subtitle: const Text('Version 0.1.0 · Remember to ask.'),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'KeepClose',
                applicationVersion: '0.1.0',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Requires typing DELETE before wiping everything.
class _DeleteAllDialog extends StatefulWidget {
  const _DeleteAllDialog();

  @override
  State<_DeleteAllDialog> createState() => _DeleteAllDialogState();
}

class _DeleteAllDialogState extends State<_DeleteAllDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Delete all data?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently removes everyone, all reminders, dates, '
              'moments and settings from this phone. Type DELETE to confirm.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('delete-confirm'),
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: _controller.text.trim() == 'DELETE'
              ? () => Navigator.pop(context, true)
              : null,
          child: const Text('Delete everything'),
        ),
      ],
    );
  }
}
