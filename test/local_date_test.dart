import 'package:flutter_test/flutter_test.dart';
import 'package:keepclose/domain/local_date.dart';

void main() {
  group('LocalDate', () {
    test('round-trips through its storage key', () {
      final d = LocalDate(2026, 3, 9);
      expect(d.key, 20260309);
      expect(LocalDate.fromKey(20260309), d);
    });

    test('normalizes overflowing days across months and years', () {
      expect(LocalDate(2026, 12, 31).addDays(1), LocalDate(2027, 1, 1));
      expect(LocalDate(2026, 3, 1).addDays(-1), LocalDate(2026, 2, 28));
      expect(LocalDate(2028, 3, 1).addDays(-1), LocalDate(2028, 2, 29));
    });

    test('daysUntil is unaffected by DST transitions', () {
      // US DST starts 8 Mar 2026, EU 29 Mar 2026; civil-day math must not care.
      expect(LocalDate(2026, 3, 7).daysUntil(LocalDate(2026, 3, 9)), 2);
      expect(LocalDate(2026, 3, 28).daysUntil(LocalDate(2026, 3, 30)), 2);
      expect(LocalDate(2026, 10, 24).daysUntil(LocalDate(2026, 10, 26)), 2);
    });

    test('annual Feb 29 falls back to Feb 28 in non-leap years', () {
      expect(LocalDate.annual(2027, 2, 29), LocalDate(2027, 2, 28));
      expect(LocalDate.annual(2028, 2, 29), LocalDate(2028, 2, 29));
      expect(LocalDate.annual(2100, 2, 29), LocalDate(2100, 2, 28));
      expect(LocalDate.annual(2000, 2, 29), LocalDate(2000, 2, 29));
    });

    test('ordering and equality', () {
      final a = LocalDate(2026, 1, 1);
      final b = LocalDate(2026, 1, 2);
      expect(a.isBefore(b), isTrue);
      expect(b.isAfter(a), isTrue);
      expect(a.compareTo(b), lessThan(0));
      expect(LocalDate(2026, 1, 1), a);
      expect({a, LocalDate(2026, 1, 1)}.length, 1);
    });

    test('today() uses the local calendar day', () {
      expect(
        LocalDate.today(DateTime(2026, 9, 25, 23, 59)),
        LocalDate(2026, 9, 25),
      );
    });

    test('weekday', () {
      expect(LocalDate(2026, 9, 25).weekday, DateTime.friday);
    });
  });
}
