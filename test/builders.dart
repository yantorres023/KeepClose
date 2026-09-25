import 'package:keepclose/data/database.dart';
import 'package:keepclose/domain/local_date.dart';

final created = DateTime(2026, 1, 1, 12);

Person person(
  int id,
  String name, {
  int? checkInDays,
  LocalDate? anchor,
  LocalDate? snoozed,
}) => Person(
  id: id,
  name: name,
  checkInDays: checkInDays,
  checkInAnchor: anchor,
  checkInSnoozedUntil: snoozed,
  createdAt: created,
  updatedAt: created,
);

FollowUp followUp(
  int id,
  int personId,
  String body,
  LocalDate due, {
  FollowUpStatus status = FollowUpStatus.open,
}) => FollowUp(
  id: id,
  personId: personId,
  body: body,
  dueDate: due,
  status: status,
  createdAt: created,
);

ImportantDate birthday(
  int id,
  int personId,
  int month,
  int day, {
  int? year,
  int lead = 0,
  LocalDate? ack,
}) => ImportantDate(
  id: id,
  personId: personId,
  kind: DateKind.birthday,
  month: month,
  day: day,
  year: year,
  notifyDaysBefore: lead,
  acknowledgedFor: ack,
  createdAt: created,
);

ImportantDate event(
  int id,
  int personId,
  String label,
  LocalDate date, {
  int lead = 0,
}) => ImportantDate(
  id: id,
  personId: personId,
  kind: DateKind.event,
  label: label,
  month: date.month,
  day: date.day,
  year: date.year,
  notifyDaysBefore: lead,
  createdAt: created,
);
