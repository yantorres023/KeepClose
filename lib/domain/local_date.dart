/// A calendar date without time or timezone.
///
/// Reminders in KeepClose are day-level ("ask on Friday"), so all reminder math
/// is done on civil dates. This makes the engine immune to DST transitions and
/// timezone changes; wall-clock times are only applied when scheduling a
/// notification.
class LocalDate implements Comparable<LocalDate> {
  LocalDate(int year, int month, int day)
    : this._fromUtc(DateTime.utc(year, month, day));

  LocalDate._fromUtc(DateTime utc)
    : year = utc.year,
      month = utc.month,
      day = utc.day;

  /// Today according to the device's local clock.
  factory LocalDate.today([DateTime? now]) {
    final n = now ?? DateTime.now();
    return LocalDate(n.year, n.month, n.day);
  }

  factory LocalDate.fromDateTime(DateTime d) =>
      LocalDate(d.year, d.month, d.day);

  /// Decodes the `yyyymmdd` integer used for storage.
  factory LocalDate.fromKey(int key) =>
      LocalDate(key ~/ 10000, (key ~/ 100) % 100, key % 100);

  final int year;
  final int month;
  final int day;

  /// Storage encoding: `yyyymmdd`. Sorts chronologically as an integer.
  int get key => year * 10000 + month * 100 + day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// Midnight local time; use only for display/formatting.
  DateTime toDateTime() => DateTime(year, month, day);

  int get weekday => _utc.weekday;

  LocalDate addDays(int days) => LocalDate(year, month, day + days);

  /// Days from this date until [other] (negative if [other] is earlier).
  int daysUntil(LocalDate other) => other._utc.difference(_utc).inDays;

  bool isBefore(LocalDate other) => key < other.key;
  bool isAfter(LocalDate other) => key > other.key;

  static bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  /// The occurrence of an annual date (e.g. a birthday) in [year].
  /// February 29 falls back to February 28 in non-leap years.
  static LocalDate annual(int year, int month, int day) {
    if (month == 2 && day == 29 && !isLeapYear(year)) {
      return LocalDate(year, 2, 28);
    }
    return LocalDate(year, month, day);
  }

  @override
  int compareTo(LocalDate other) => key.compareTo(other.key);

  @override
  bool operator ==(Object other) => other is LocalDate && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
