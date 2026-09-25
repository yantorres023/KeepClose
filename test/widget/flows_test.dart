import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepclose/data/database.dart';
import 'package:keepclose/services/contact_picker.dart';
import 'package:keepclose/services/notification_service.dart';

import '../helpers.dart';

void main() {
  testWidgets(
    'onboarding: three pages, no permission prompts, lands on Today',
    (tester) async {
      final env = await pumpApp(tester, onboarded: false);
      expect(find.text('Remember to ask.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();
      expect(find.text('Private by design.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();
      expect(find.text('When should we nudge you?'), findsOneWidget);
      await tester.tap(find.text('Get started'));
      await settle(tester);
      expect(find.text('Who matters to you?'), findsOneWidget);
      expect(env.notifications.requestCount, 0);
      await tearDownApp(tester, env);
    },
  );

  testWidgets('add a person manually from People', (tester) async {
    final env = await pumpApp(tester);
    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fab-add-person')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('person-name')),
      '  Mariana Silva ',
    );
    await tester.enterText(
      find.byKey(const Key('person-note')),
      'Old flatmate',
    );
    await tester.tap(find.byKey(const Key('person-save')));
    await settle(tester);
    // Person page opens.
    expect(find.text('Mariana Silva'), findsWidgets);
    expect(find.text('Old flatmate'), findsOneWidget);
    expect(find.text('Remember to ask'), findsWidgets);
    await tearDownApp(tester, env);
  });

  testWidgets('empty name shows a gentle validation message', (tester) async {
    final env = await pumpApp(tester);
    await tester.tap(find.text('Add someone'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('person-save')));
    await settle(tester);
    expect(find.text('Add a name.'), findsOneWidget);
    await tearDownApp(tester, env);
  });

  testWidgets('core loop: remember to ask → reminder → Asked → Undo', (
    tester,
  ) async {
    final env = await pumpApp(
      tester,
      seed: (e) => e.repo.addPerson(name: 'Mariana Silva'),
    );
    await tester.tap(find.byKey(const Key('fab-remember')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mariana Silva'));
    await tester.pumpAndSettle();
    expect(find.text('Remember to ask Mariana…'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('follow-up-text')),
      'how the interview went',
    );
    expect(find.text('Remind me tomorrow'), findsOneWidget);
    await tester.tap(find.byKey(const Key('follow-up-save')));
    await settle(tester);

    // Permission asked just-in-time, exactly once.
    expect(env.notifications.requestCount, 1);
    // Due tomorrow → listed under Coming up.
    expect(find.text('Coming up'), findsOneWidget);
    expect(find.text('Ask Mariana: how the interview went'), findsOneWidget);

    // A second follow-up due today via the person-less flow doesn't re-ask.
    await tester.runAsync(() async {
      final p = (await env.repo.allPeople()).single;
      await env.repo.addFollowUp(
        personId: p.id,
        body: 'the exam',
        due: testToday,
      );
    });
    await settle(tester);
    expect(find.text('Ask Mariana: the exam'), findsOneWidget);

    await tester.tap(find.text('Asked'));
    await settle(tester);
    expect(find.text('Ask Mariana: the exam'), findsNothing);
    expect(find.textContaining('Saved to Mariana'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.text('Ask Mariana: the exam'), findsOneWidget);
    expect(env.notifications.requestCount, 1);
    await tearDownApp(tester, env);
  });

  testWidgets('Later moves a reminder out of Today', (tester) async {
    final env = await pumpApp(
      tester,
      seed: (e) async {
        final id = await e.repo.addPerson(name: 'Lucas');
        await e.repo.addFollowUp(
          personId: id,
          body: 'the move',
          due: testToday,
        );
      },
    );
    expect(find.text('Ask Lucas: the move'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next week'));
    await settle(tester);
    expect(find.text('We\'ll remind you on Fri 2 Oct.'), findsOneWidget);
    expect(find.text('Ask Lucas: the move'), findsOneWidget); // in Coming up
    expect(
      find.text(
        'Nothing to remember today. When someone mentions something coming up, tap Remember to ask.',
      ),
      findsOneWidget,
    );
    await tearDownApp(tester, env);
  });

  testWidgets('Let go dismisses, Undo restores', (tester) async {
    final env = await pumpApp(
      tester,
      seed: (e) async {
        final id = await e.repo.addPerson(name: 'Lucas');
        final f = await e.repo.addFollowUp(
          personId: id,
          body: 'the move',
          due: testToday,
        );
        // Simulate a reminder whose day has passed.
        await e.db.customStatement(
          'UPDATE follow_ups SET due_date = ${testToday.addDays(-3).key} WHERE id = $f',
        );
      },
    );
    expect(
      find.text('Still want to ask Lucas about the move?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Let go'));
    await settle(tester);
    expect(find.text('Still want to ask Lucas about the move?'), findsNothing);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(
      find.text('Still want to ask Lucas about the move?'),
      findsOneWidget,
    );
    await tearDownApp(tester, env);
  });

  testWidgets('denied notification permission is respected', (tester) async {
    final env = TestEnv.create(permission: PermissionState.denied);
    await pumpApp(
      tester,
      env: env,
      seed: (e) => e.repo.addPerson(name: 'Ana'),
    );
    await tester.tap(find.byKey(const Key('fab-remember')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('follow-up-text')), 'x');
    await tester.tap(find.byKey(const Key('follow-up-save')));
    await settle(tester);
    expect(
      find.textContaining('your reminders will still be in Today'),
      findsOneWidget,
    );
    expect(find.text('Coming up'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await settle(tester);
    expect(find.text('Notifications are off for KeepClose'), findsOneWidget);
    await tearDownApp(tester, env);
  });

  group('contact picker', () {
    Future<TestEnv> openAddSheet(WidgetTester tester, [TestEnv? env]) async {
      final e = await pumpApp(
        tester,
        env: env,
        seed: (e) =>
            e.repo.addPerson(name: 'Ana Souza', phone: '+55 11 99999-0000'),
      );
      await tester.tap(find.text('People'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fab-add-person')));
      await tester.pumpAndSettle();
      return e;
    }

    testWidgets('cancelled pick changes nothing', (tester) async {
      final env = await openAddSheet(tester);
      env.picker.next = null;
      await tester.tap(find.text('Pick from contacts'));
      await settle(tester);
      expect(env.picker.calls, 1);
      final field = tester.widget<TextField>(
        find.byKey(const Key('person-name')),
      );
      expect(field.controller!.text, isEmpty);
      await tearDownApp(tester, env);
    });

    testWidgets('picker failure falls back to manual entry', (tester) async {
      final env = await openAddSheet(tester);
      env.picker.fail = true;
      await tester.tap(find.text('Pick from contacts'));
      await settle(tester);
      expect(find.textContaining('add them by name'), findsOneWidget);
      await tearDownApp(tester, env);
    });

    testWidgets('picked contact fills the form', (tester) async {
      final env = await openAddSheet(tester);
      env.picker.next = const PickedContact(
        name: 'Bruno Lima',
        phone: '+1 555 0100',
      );
      await tester.tap(find.text('Pick from contacts'));
      await settle(tester);
      expect(find.text('Bruno Lima'), findsOneWidget);
      expect(find.text('+1 555 0100'), findsOneWidget);
      await tearDownApp(tester, env);
    });

    testWidgets('duplicate contact offers to open the existing person', (
      tester,
    ) async {
      final env = await openAddSheet(tester);
      env.picker.next = const PickedContact(
        name: 'ana souza',
        phone: '+5511999990000',
      );
      await tester.tap(find.text('Pick from contacts'));
      await settle(tester);
      expect(find.text('Ana Souza is already here'), findsOneWidget);
      await tester.tap(find.text('Open'));
      await settle(tester);
      expect(await tester.runAsync(env.repo.allPeople), hasLength(1));
      await tearDownApp(tester, env);
    });
  });

  testWidgets('person page: message opens the OS app, never sends', (
    tester,
  ) async {
    final env = await pumpApp(
      tester,
      seed: (e) => e.repo.addPerson(name: 'Ana', phone: '+1 (555) 0100'),
    );
    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana'));
    await settle(tester);
    await tester.tap(find.text('Message'));
    await tester.pump();
    expect(env.launcher.launched, ['sms:+1 (555) 0100']);
    await tearDownApp(tester, env);
  });

  testWidgets('delete a person requires confirmation', (tester) async {
    final env = await pumpApp(
      tester,
      seed: (e) => e.repo.addPerson(name: 'Ana'),
    );
    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana'));
    await settle(tester);
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Ana?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(await tester.runAsync(env.repo.allPeople), hasLength(1));

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);
    expect(await tester.runAsync(env.repo.allPeople), isEmpty);
    await tearDownApp(tester, env);
  });

  testWidgets('delete all data needs the typed confirmation', (tester) async {
    final env = await pumpApp(
      tester,
      seed: (e) => e.repo.addPerson(name: 'Ana'),
    );
    await tester.tap(find.text('Settings'));
    await settle(tester);
    await tester.dragUntilVisible(
      find.byKey(const Key('delete-all')),
      find.byType(ListView).last,
      const Offset(0, -200),
    );
    await tester.tap(find.byKey(const Key('delete-all')));
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, 'Delete everything');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('delete-confirm')), 'DELETE');
    await tester.pumpAndSettle();
    await tester.tap(button);
    await settle(tester);
    expect(await tester.runAsync(env.repo.allPeople), isEmpty);
    expect(find.text('Remember to ask.'), findsOneWidget); // back to onboarding
    await tearDownApp(tester, env);
  });

  testWidgets('birthday today shows with Done, which hides it', (tester) async {
    final env = await pumpApp(
      tester,
      seed: (e) async {
        final id = await e.repo.addPerson(name: 'Ana');
        await e.repo.addBirthday(personId: id, month: 9, day: 25, year: 1996);
      },
    );
    expect(find.text('Ana\'s birthday today — turning 30'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.text('Ana\'s birthday today — turning 30'), findsNothing);
    await tearDownApp(tester, env);
  });

  testWidgets('check-in rhythm and moment logging on the person page', (
    tester,
  ) async {
    final env = await pumpApp(
      tester,
      seed: (e) => e.repo.addPerson(name: 'Ana'),
    );
    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana'));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Off'), 100);
    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About every month'));
    await settle(tester);
    expect(find.text('About every month'), findsOneWidget);
    expect(find.textContaining('Next suggestion'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('We talked'), 100);
    await tester.tap(find.text('We talked'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('moment-note')),
      'Got the job!',
    );
    await tester.tap(find.byKey(const Key('moment-save')));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Got the job!'), 100);
    expect(find.text('Got the job!'), findsOneWidget);
    final moments = await tester.runAsync(
      () => env.db.select(env.db.moments).get(),
    );
    expect(moments!.single.kind, MomentKind.talked);
    await tearDownApp(tester, env);
  });
}
