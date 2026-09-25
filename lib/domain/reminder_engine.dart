import '../data/database.dart';
import 'local_date.dart';

enum ReminderKind { followUp, birthday, event, checkIn }

/// One thing to remember, derived deterministically from stored data.
class ReminderItem {
  const ReminderItem({
    required this.kind,
    required this.person,
    required this.sourceId,
    required this.date,
    required this.activeFrom,
    this.text,
    this.turning,
  });

  final ReminderKind kind;
  final Person person;

  /// Id of the follow-up / important date, or the person id for check-ins.
  final int sourceId;

  /// The day the reminder is about (due date, birthday, event, check-in).
  final LocalDate date;

  /// First day this item appears in Today (earlier than [date] for heads-ups).
  final LocalDate activeFrom;

  /// Follow-up text, or event label.
  final String? text;

  /// Age the person turns, for birthdays with a known year.
  final int? turning;

  /// True when an open item's day has already passed ("Still want to…?").
  bool isLateOn(LocalDate today) => date.isBefore(today);

  String get identity => '${kind.name}:$sourceId:${date.key}';

  @override
  bool operator ==(Object other) =>
      other is ReminderItem && other.identity == identity;

  @override
  int get hashCode => identity.hashCode;

  @override
  String toString() => 'ReminderItem($identity, ${person.name})';
}

/// Immutable input for the engine.
class ReminderSnapshot {
  const ReminderSnapshot({
    required this.people,
    required this.openFollowUps,
    required this.dates,
    required this.lastMomentByPerson,
  });

  final List<Person> people;
  final List<FollowUp> openFollowUps;
  final List<ImportantDate> dates;
  final Map<int, LocalDate> lastMomentByPerson;
}

/// Pure, deterministic reminder logic. No clocks, no I/O, no scoring.
class ReminderEngine {
  ReminderEngine(this.snapshot)
    : _people = {for (final p in snapshot.people) p.id: p};

  final ReminderSnapshot snapshot;
  final Map<int, Person> _people;

  /// Items that belong in Today: anything active on [today] and not resolved.
  /// Open follow-ups and check-ins whose day has passed stay here (gently).
  List<ReminderItem> today(LocalDate today) {
    final items = <ReminderItem>[
      for (final f in _followUps())
        if (!f.date.isAfter(today)) f,
      for (final c in _checkIns())
        if (!c.date.isAfter(today)) c,
      for (final d in _dateOccurrences(today.addDays(-7), today.addDays(400)))
        if (!today.isBefore(d.activeFrom) && !today.isAfter(d.date)) d,
    ];
    items.sort(_order);
    return items;
  }

  /// Items that become active after [today] and within [days] days.
  List<ReminderItem> upcoming(LocalDate today, {int days = 14}) {
    final end = today.addDays(days);
    bool inWindow(LocalDate d) => d.isAfter(today) && !d.isAfter(end);
    final items = <ReminderItem>[
      for (final f in _followUps())
        if (inWindow(f.date)) f,
      for (final c in _checkIns())
        if (inWindow(c.date)) c,
      for (final d in _dateOccurrences(today, end.addDays(400)))
        if (inWindow(d.activeFrom)) d,
    ];
    items.sort((a, b) {
      final c = a.activeFrom.compareTo(b.activeFrom);
      return c != 0 ? c : _order(a, b);
    });
    return items;
  }

  /// For each of the next [days] days starting at [from], the items that
  /// should be mentioned in that day's single digest notification.
  ///
  /// Items are announced once when they become active (and dates once more on
  /// the day itself). Items that were missed are never re-announced, to avoid
  /// nagging.
  Map<LocalDate, List<ReminderItem>> digestPlan(LocalDate from, int days) {
    final end = from.addDays(days - 1);
    final plan = <LocalDate, List<ReminderItem>>{};
    void add(LocalDate day, ReminderItem item) {
      if (day.isBefore(from) || day.isAfter(end)) return;
      (plan[day] ??= []).add(item);
    }

    for (final f in _followUps()) {
      add(f.date, f);
    }
    for (final c in _checkIns()) {
      add(c.date, c);
    }
    for (final d in _dateOccurrences(from, end.addDays(400))) {
      add(d.activeFrom, d);
      if (d.activeFrom != d.date) add(d.date, d);
    }
    for (final list in plan.values) {
      list.sort(_order);
    }
    return plan;
  }

  /// The next day a check-in is suggested for [person], or null if off.
  static LocalDate? nextCheckIn(Person person, LocalDate? lastMoment) {
    final interval = person.checkInDays;
    if (interval == null || interval <= 0) return null;
    var anchor =
        person.checkInAnchor ?? LocalDate.fromDateTime(person.createdAt);
    if (lastMoment != null && lastMoment.isAfter(anchor)) anchor = lastMoment;
    var due = anchor.addDays(interval);
    final snoozed = person.checkInSnoozedUntil;
    if (snoozed != null && snoozed.isAfter(due)) due = snoozed;
    return due;
  }

  Iterable<ReminderItem> _followUps() sync* {
    for (final f in snapshot.openFollowUps) {
      if (f.status != FollowUpStatus.open) continue;
      final person = _people[f.personId];
      if (person == null) continue;
      yield ReminderItem(
        kind: ReminderKind.followUp,
        person: person,
        sourceId: f.id,
        date: f.dueDate,
        activeFrom: f.dueDate,
        text: f.body,
      );
    }
  }

  Iterable<ReminderItem> _checkIns() sync* {
    for (final p in snapshot.people) {
      final due = nextCheckIn(p, snapshot.lastMomentByPerson[p.id]);
      if (due == null) continue;
      yield ReminderItem(
        kind: ReminderKind.checkIn,
        person: p,
        sourceId: p.id,
        date: due,
        activeFrom: due,
      );
    }
  }

  /// Occurrences of important dates whose day falls within [start, end].
  Iterable<ReminderItem> _dateOccurrences(
    LocalDate start,
    LocalDate end,
  ) sync* {
    for (final d in snapshot.dates) {
      final person = _people[d.personId];
      if (person == null) continue;
      final List<LocalDate> occurrences;
      if (d.kind == DateKind.event) {
        if (d.year == null) continue;
        occurrences = [LocalDate(d.year!, d.month, d.day)];
      } else {
        occurrences = [
          for (var y = start.year - 1; y <= end.year + 1; y++)
            LocalDate.annual(y, d.month, d.day),
        ];
      }
      for (final occ in occurrences) {
        if (occ.isBefore(start) || occ.isAfter(end)) continue;
        if (d.acknowledgedFor == occ) continue;
        final lead = d.notifyDaysBefore < 0 ? 0 : d.notifyDaysBefore;
        final isBirthday = d.kind == DateKind.birthday;
        final turning = isBirthday && d.year != null
            ? occ.year - d.year!
            : null;
        yield ReminderItem(
          kind: isBirthday ? ReminderKind.birthday : ReminderKind.event,
          person: person,
          sourceId: d.id,
          date: occ,
          activeFrom: occ.addDays(-lead),
          text: d.label,
          turning: turning != null && turning > 0 ? turning : null,
        );
      }
    }
  }

  static int _order(ReminderItem a, ReminderItem b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    final byKind = a.kind.index.compareTo(b.kind.index);
    if (byKind != 0) return byKind;
    final byName = a.person.name.toLowerCase().compareTo(
      b.person.name.toLowerCase(),
    );
    if (byName != 0) return byName;
    return a.sourceId.compareTo(b.sourceId);
  }
}
