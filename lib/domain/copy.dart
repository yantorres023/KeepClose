import '../data/repository.dart';
import 'local_date.dart';
import 'reminder_engine.dart';

/// All reminder wording lives here so tone stays consistent.
///
/// Rules: never mention how long it has been, never "overdue", never scores.
class Copy {
  static String firstName(String name) {
    final trimmed = name.trim();
    final space = trimmed.indexOf(' ');
    return space <= 0 ? trimmed : trimmed.substring(0, space);
  }

  /// Main line for a reminder card.
  static String title(ReminderItem item, LocalDate today) {
    final who = firstName(item.person.name);
    switch (item.kind) {
      case ReminderKind.followUp:
        return item.isLateOn(today)
            ? 'Still want to ask $who about ${_trimTerminal(item.text!)}?'
            : 'Ask $who: ${item.text}';
      case ReminderKind.checkIn:
        return 'Thinking of $who?';
      case ReminderKind.birthday:
        final possessive = _possessive(who);
        if (item.date == today) {
          return item.turning != null
              ? '$possessive birthday today — turning ${item.turning}'
              : '$possessive birthday is today';
        }
        return '$possessive birthday ${relativeDay(item.date, today)}';
      case ReminderKind.event:
        if (item.date == today) return '$who: ${item.text} is today';
        return '$who: ${item.text} ${relativeDay(item.date, today)}';
    }
  }

  static String kindLabel(ReminderKind kind) => switch (kind) {
    ReminderKind.followUp => 'Remember to ask',
    ReminderKind.checkIn => 'Check in',
    ReminderKind.birthday => 'Birthday',
    ReminderKind.event => 'Date',
  };

  /// "today", "tomorrow", "on Friday", "on 3 Oct".
  static String relativeDay(LocalDate date, LocalDate today) {
    final diff = today.daysUntil(date);
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    if (diff > 1 && diff < 7) return 'on ${weekdayName(date)}';
    return 'on ${shortDate(date)}';
  }

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String weekdayName(LocalDate d) => _weekdays[d.weekday - 1];

  static String shortDate(LocalDate d) =>
      '${_weekdays[d.weekday - 1].substring(0, 3)} ${d.day} ${_months[d.month - 1]}';

  static String longDate(LocalDate d) =>
      '${_weekdays[d.weekday - 1]}, ${d.day} ${monthNames[d.month - 1]}';

  static String monthDay(int month, int day) => '$day ${monthNames[month - 1]}';

  /// Digest notification text for one day, honouring the privacy level.
  static ({String title, String body}) digest(
    List<ReminderItem> items,
    LocalDate day,
    NotificationDetail detail,
  ) {
    const title = 'KeepClose';
    final n = items.length;
    switch (detail) {
      case NotificationDetail.private:
        return (
          title: title,
          body: n == 1
              ? 'You have a gentle reminder today.'
              : 'You have $n gentle reminders today.',
        );
      case NotificationDetail.names:
        final names = <String>[];
        for (final i in items) {
          final f = firstName(i.person.name);
          if (!names.contains(f)) names.add(f);
        }
        final shown = names.take(3).join(', ');
        final more = names.length > 3 ? ' and ${names.length - 3} more' : '';
        return (title: title, body: 'Thinking of $shown$more today.');
      case NotificationDetail.full:
        final first = Copy.title(items.first, day);
        final more = n > 1 ? ' (+${n - 1} more)' : '';
        return (title: title, body: '$first$more');
    }
  }

  static String _possessive(String name) =>
      name.endsWith('s') ? "$name'" : "$name's";

  static String _trimTerminal(String s) =>
      s.trim().replaceAll(RegExp(r'[.?!]+$'), '');

  static String rhythmLabel(int? days) => switch (days) {
    null => 'Off',
    14 => 'About every 2 weeks',
    30 => 'About every month',
    60 => 'About every 2 months',
    90 => 'About every 3 months',
    182 => 'About every 6 months',
    _ => 'About every $days days',
  };

  static const rhythmOptions = <int?>[null, 14, 30, 60, 90, 182];

  static String headsUpLabel(int days) => switch (days) {
    0 => 'On the day',
    1 => '1 day before',
    7 => '1 week before',
    _ => '$days days before',
  };

  static const headsUpOptions = [0, 1, 3, 7];
}
