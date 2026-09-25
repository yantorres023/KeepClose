import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepclose/app.dart';

import '../helpers.dart';

Future<void> seedBusyDay(TestEnv e) async {
  final ana = await e.repo.addPerson(
    name: 'Anastasia Konstantinopoulou-Vasquez de la Cruz',
    note: 'Met at the climbing gym. Two kids: Leo and Mia.',
    phone: '+1 555 0100',
  );
  final lucas = await e.repo.addPerson(name: 'Lucas');
  await e.repo.addFollowUp(
    personId: ana,
    body:
        'how the job interview at the hospital went and whether they called back',
    due: testToday,
  );
  await e.repo.addBirthday(personId: lucas, month: 9, day: 25, year: 1990);
  await e.repo.setCheckIn(lucas, 14);
  await e.repo.addFollowUp(
    personId: lucas,
    body: 'the new flat',
    due: testToday.addDays(2),
  );
}

void main() {
  testWidgets('Today meets tap-target and labeling guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    final env = await pumpApp(tester, seed: seedBusyDay);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
    await tearDownApp(tester, env);
  });

  testWidgets('reminder cards expose a merged, descriptive semantics label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final env = await pumpApp(tester, seed: seedBusyDay);
    expect(
      find.bySemanticsLabel(RegExp(r'^Ask Anastasia: how the job interview')),
      findsOneWidget,
    );
    handle.dispose();
    await tearDownApp(tester, env);
  });

  for (final scale in [1.5, 2.0]) {
    testWidgets(
      'Today, People, Person and Settings render at text scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2160);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final env = TestEnv.create();
        await tester.runAsync(() async {
          await env.repo.setOnboardingDone();
          await seedBusyDay(env);
        });
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 720),
              textScaler: TextScaler.linear(scale),
            ),
            child: KeepCloseApp(deps: env.deps),
          ),
        );
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Ask Anastasia'), findsWidgets);

        await tester.tap(find.text('People'));
        await settle(tester);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Lucas'));
        await settle(tester);
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await settle(tester);

        await tester.tap(find.text('Settings'));
        await settle(tester);
        expect(tester.takeException(), isNull);
        await tearDownApp(tester, env);
      },
    );
  }

  testWidgets('onboarding renders at text scale 2.0 on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final env = TestEnv.create();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(2),
        ),
        child: KeepCloseApp(deps: env.deps),
      ),
    );
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Remember to ask.'), findsOneWidget);
    await tearDownApp(tester, env);
  });
}
