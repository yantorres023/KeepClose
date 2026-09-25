@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepclose/app.dart';
import 'package:keepclose/app_scope.dart';
import 'package:keepclose/ui/sheets/follow_up_sheet.dart';
import 'package:keepclose/ui/theme.dart';

import '../helpers.dart';
import '../widget/accessibility_test.dart' show seedBusyDay;

/// Loads Roboto and Material Icons from the Flutter SDK so goldens show real
/// text instead of the test font's boxes.
Future<void> loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('$dir/$f');
      if (!file.existsSync()) return;
      loader.addFont(
        Future.value(ByteData.sublistView(file.readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await load('Roboto', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

void main() {
  setUpAll(loadFonts);

  Future<TestEnv> pumpPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    return pumpApp(tester, seed: seedBusyDay);
  }

  testWidgets('Today', (tester) async {
    final env = await pumpPhone(tester);
    await expectLater(
      find.byType(KeepCloseApp),
      matchesGoldenFile('goldens/today.png'),
    );
    await tearDownApp(tester, env);
  });

  testWidgets('People', (tester) async {
    final env = await pumpPhone(tester);
    await tester.tap(find.text('People'));
    await settle(tester);
    await expectLater(
      find.byType(KeepCloseApp),
      matchesGoldenFile('goldens/people.png'),
    );
    await tearDownApp(tester, env);
  });

  testWidgets('Person detail', (tester) async {
    final env = await pumpPhone(tester);
    await tester.tap(find.text('People'));
    await settle(tester);
    await tester.tap(find.text('Lucas'));
    await settle(tester);
    await expectLater(
      find.byType(KeepCloseApp),
      matchesGoldenFile('goldens/person_detail.png'),
    );
    await tearDownApp(tester, env);
  });

  testWidgets('Add follow-up', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final env = TestEnv.create();
    final id = await tester.runAsync(
      () => env.repo.addPerson(name: 'Mariana Silva'),
    );
    final person = await tester.runAsync(() => env.repo.personById(id!));
    await tester.pumpWidget(
      AppScope(
        deps: env.deps,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => showFollowUpSheet(context, person!),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('follow-up-text')),
      'how the interview went',
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/add_follow_up.png'),
    );
    await tearDownApp(tester, env);
  });
}
