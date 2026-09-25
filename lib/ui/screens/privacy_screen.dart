import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _points = [
    (
      Icons.phone_iphone,
      'Everything stays on this phone',
      'People, notes, reminders and moments are stored in a private database '
          'on this device. There is no KeepClose account or server.',
    ),
    (
      Icons.contacts_outlined,
      'We don\'t read your contacts',
      'When you pick someone from contacts, your phone hands over only that '
          'one person\'s name and number. KeepClose never asks for access to '
          'your whole address book.',
    ),
    (
      Icons.chat_outlined,
      'We never read or send messages',
      'Message and Call open your own apps. You always write and send '
          'everything yourself.',
    ),
    (
      Icons.notifications_none,
      'Private notifications by default',
      'Lock-screen reminders don\'t show names or notes unless you choose to '
          'in Settings.',
    ),
    (
      Icons.insights_outlined,
      'No tracking',
      'No analytics, ads or third-party trackers. KeepClose doesn\'t use the '
          'internet.',
    ),
    (
      Icons.backup_outlined,
      'Backups are up to your phone',
      'If your phone\'s own backup (iCloud or Google) is on, it may include '
          'KeepClose\'s data, protected by your phone\'s backup encryption.',
    ),
    (
      Icons.delete_outline,
      'Delete any time',
      'Delete a person from their page, or everything from Settings. '
          'Uninstalling the app also removes its data from this phone.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your privacy')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final (icon, title, body) in _points)
            ListTile(
              leading: Icon(icon),
              title: Text(title),
              subtitle: Text(body),
              isThreeLine: true,
            ),
        ],
      ),
    );
  }
}
