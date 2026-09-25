import 'package:flutter_test/flutter_test.dart';
import 'package:keepclose/domain/copy.dart';
import 'package:keepclose/domain/local_date.dart';
import 'package:keepclose/domain/reminder_engine.dart';

import 'builders.dart';

void main() {
  final today = LocalDate(2026, 9, 25); // Friday
  final mariana = person(1, 'Mariana Silva');
  final james = person(2, 'James');

  ReminderItem item(
    ReminderKind kind, {
    LocalDate? date,
    String? text,
    int? turning,
    bool isJames = false,
  }) => ReminderItem(
    kind: kind,
    person: isJames ? james : mariana,
    sourceId: 1,
    date: date ?? today,
    activeFrom: date ?? today,
    text: text,
    turning: turning,
  );

  test('follow-up wording uses the user\'s own words and first name', () {
    expect(
      Copy.title(
        item(ReminderKind.followUp, text: 'how the interview went'),
        today,
      ),
      'Ask Mariana: how the interview went',
    );
  });

  test('late follow-ups are phrased gently, never as overdue', () {
    final t = Copy.title(
      item(ReminderKind.followUp, text: 'the exam?', date: today.addDays(-3)),
      today,
    );
    expect(t, 'Still want to ask Mariana about the exam?');
    expect(t.toLowerCase(), isNot(contains('overdue')));
    expect(t, isNot(contains('3')));
  });

  test('check-in never mentions elapsed time', () {
    expect(
      Copy.title(item(ReminderKind.checkIn), today),
      'Thinking of Mariana?',
    );
  });

  test('birthdays and possessives', () {
    expect(
      Copy.title(item(ReminderKind.birthday, turning: 30), today),
      'Mariana\'s birthday today — turning 30',
    );
    expect(
      Copy.title(item(ReminderKind.birthday, isJames: true), today),
      'James\' birthday is today',
    );
    expect(
      Copy.title(item(ReminderKind.birthday, date: today.addDays(3)), today),
      'Mariana\'s birthday on Monday',
    );
  });

  test('relative days', () {
    expect(Copy.relativeDay(today, today), 'today');
    expect(Copy.relativeDay(today.addDays(1), today), 'tomorrow');
    expect(Copy.relativeDay(today.addDays(3), today), 'on Monday');
    expect(Copy.relativeDay(today.addDays(8), today), 'on Sat 3 Oct');
  });

  test('first name handles single names and extra spaces', () {
    expect(Copy.firstName('  Ana  '), 'Ana');
    expect(Copy.firstName('Ana Maria Souza'), 'Ana');
    expect(Copy.firstName('李雷'), '李雷');
  });

  test('rhythm labels', () {
    expect(Copy.rhythmLabel(null), 'Off');
    expect(Copy.rhythmLabel(30), 'About every month');
    expect(Copy.rhythmLabel(10), 'About every 10 days');
  });
}
