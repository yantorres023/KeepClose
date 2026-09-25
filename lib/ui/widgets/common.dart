import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/repository.dart';
import '../../domain/copy.dart';
import '../../domain/local_date.dart';
import '../../services/notification_service.dart';

/// Subscribes to a stream once (per widget lifetime) and rebuilds on events.
class Watch<T> extends StatefulWidget {
  const Watch({
    super.key,
    required this.stream,
    required this.builder,
    this.loading,
  });

  final Stream<T> Function(AppDependencies deps) stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loading;

  @override
  State<Watch<T>> createState() => _WatchState<T>();
}

class _WatchState<T> extends State<Watch<T>> {
  Stream<T>? _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stream ??= widget.stream(AppScope.of(context));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return const EmptyState(
            icon: Icons.error_outline,
            title: 'Something went wrong',
            message: 'Please close and reopen KeepClose.',
          );
        }
        if (!snap.hasData) {
          return widget.loading ?? const SizedBox.shrink();
        }
        return widget.builder(context, snap.data as T);
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 48, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                text,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.name, this.radius = 20});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : String.fromCharCodes(trimmed.runes.take(1)).toUpperCase();
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: radius,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        child: Text(initial),
      ),
    );
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showUndo(
  BuildContext context,
  String message,
  Future<void> Function() undo, {
  SnackBarAction? extra,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
        action: extra ?? SnackBarAction(label: 'Undo', onPressed: () => undo()),
      ),
    );
}

/// Runs a repository write and reports validation problems gently.
Future<bool> guardedWrite(
  BuildContext context,
  Future<void> Function() write,
) async {
  try {
    await write();
    return true;
  } on ValidationException catch (e) {
    if (context.mounted) showMessage(context, e.message);
  } catch (e) {
    debugPrint('KeepClose: write failed (${e.runtimeType})');
    if (context.mounted) {
      showMessage(context, 'Couldn\'t save that. Please try again.');
    }
  }
  return false;
}

/// Asks for notification permission once, right after the user creates their
/// first reminder — never at launch.
Future<void> maybeAskForNotifications(BuildContext context) async {
  final deps = AppScope.of(context);
  final settings = await deps.repository.loadSettings();
  if (settings.notificationPermissionAsked || !settings.notificationsEnabled) {
    return;
  }
  await deps.repository.setNotificationPermissionAsked();
  PermissionState result;
  try {
    result = await deps.notifications.requestPermission();
  } catch (_) {
    result = PermissionState.unknown;
  }
  if (result == PermissionState.denied && context.mounted) {
    showMessage(context, 'No problem — your reminders will still be in Today.');
  }
  unawaited(deps.scheduler.sync());
}

/// Lets the user pick a later day. Returns null if cancelled.
Future<LocalDate?> pickLater(BuildContext context) {
  final today = AppScope.of(context).today;
  final options = <(String, LocalDate)>[
    ('Tomorrow', today.addDays(1)),
    ('In 3 days', today.addDays(3)),
    ('Next week', today.addDays(7)),
  ];
  return showModalBottomSheet<LocalDate>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, date) in options)
            ListTile(
              title: Text(label),
              subtitle: Text(Copy.shortDate(date)),
              onTap: () => Navigator.pop(context, date),
            ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Pick a day'),
            onTap: () async {
              final picked = await pickDate(context, initial: today.addDays(1));
              if (picked != null && context.mounted) {
                Navigator.pop(context, picked);
              }
            },
          ),
        ],
      ),
    ),
  );
}

Future<LocalDate?> pickDate(
  BuildContext context, {
  required LocalDate initial,
  LocalDate? first,
  LocalDate? last,
}) async {
  final today = AppScope.of(context).today;
  final firstDate = first ?? today;
  final lastDate = last ?? today.addDays(365 * 3);
  final picked = await showDatePicker(
    context: context,
    initialDate: initial.toDateTime(),
    firstDate: firstDate.toDateTime(),
    lastDate: lastDate.toDateTime(),
  );
  return picked == null ? null : LocalDate.fromDateTime(picked);
}
