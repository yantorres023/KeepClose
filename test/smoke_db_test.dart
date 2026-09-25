import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepclose/data/database.dart';
void main() {
  test('db opens', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(await db.select(db.people).get(), isEmpty);
    await db.close();
  });
}
