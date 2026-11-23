// ignore_for_file: avoid_relative_lib_imports
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/admit/admit.dart';

Future<void> _open(
  WidgetTester t,
  AdmitPlace place, {
  AdmitScene? scene,
  double width = 390,
  double scale = 1,
}) async {
  t.view.physicalSize = Size(width, width == 390 ? 844 : 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    AdmitApp(initialPlace: place, initialScene: scene, textScale: scale),
  );
  await t.pumpAndSettle();
}

Finder _input(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (w) => w is BrutalTextField && w.labelText == label,
  ),
  matching: find.byType(EditableText),
);

Future<void> _enter(WidgetTester t, String label, String value) async {
  final field = _input(label);
  await t.ensureVisible(field);
  await t.pumpAndSettle();
  await t.enterText(field, value);
  await t.pump();
}

Future<void> _tap(WidgetTester t, Finder target) async {
  await t.ensureVisible(target);
  await t.pumpAndSettle();
  await t.tap(target);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(brutalLoadFonts);

  testWidgets(
    'checkout rejects a missing card and a nonnumeric security code',
    (t) async {
      await _open(
        t,
        AdmitPlace.events,
        scene: AdmitScene.checkout,
        width: 1440,
      );
      await _enter(t, 'Card number', '');
      await _enter(t, 'Security code', 'abc');
      await _tap(t, find.text('Pay €67.00'));
      expect(find.text('Enter a valid card number.'), findsOneWidget);
      expect(
        find.text('Enter the 3 digits on the back of the card.'),
        findsOneWidget,
      );
      expect(
        t.widget<EditableText>(_input('Card number')).focusNode.hasFocus,
        isTrue,
      );
      expect(find.text('Paid €67.00'), findsNothing);
    },
  );

  testWidgets(
    'the first checkout error is visible above the Pay button at 200%',
    (t) async {
      await _open(t, AdmitPlace.events, scene: AdmitScene.checkout, scale: 2);
      final pay = find.text('Pay €67.00');
      await _tap(t, pay);
      final error = find.text('Enter the 3 digits on the back of the card.');
      expect(
        t.widget<EditableText>(_input('Security code')).focusNode.hasFocus,
        isTrue,
      );
      expect(t.getRect(error).top, greaterThan(0));
      expect(t.getRect(error).bottom, lessThan(t.getRect(pay).top));
    },
  );

  testWidgets(
    'the receipt and new ticket show all three purchased admissions',
    (t) async {
      await _open(t, AdmitPlace.events, scene: AdmitScene.checkout);
      await _tap(
        t,
        find.descendant(
          of: find.byType(BrutalStepper).first,
          matching: find.byIcon(LucideIcons.plus),
        ),
      );
      await _enter(t, 'Email for the tickets', 'guest@example.com');
      await _enter(t, 'Security code', '123');
      await _tap(t, find.text('Pay €100.50'));
      await t.pump(const Duration(seconds: 1));
      await t.pumpAndSettle();
      expect(find.text('Paid €100.50'), findsOneWidget);
      final newOrder = find.textContaining('3 × Standing');
      expect(newOrder, findsOneWidget);
      await _tap(t, newOrder);
      expect(find.text('Order A-2319'), findsOneWidget);
      expect(find.text('3 × STANDING'), findsOneWidget);
      expect(find.text('guest@example.com'), findsOneWidget);
      expect(find.text('Paid €100.50'), findsWidgets);
    },
  );

  testWidgets('cancelling removes the order and Undo restores its door code', (
    t,
  ) async {
    await _open(t, AdmitPlace.tickets, scene: AdmitScene.ticket);
    await _tap(t, find.text('Cancel tickets'));
    expect(find.textContaining('€64.00'), findsOneWidget);
    await _tap(t, find.text('Cancel tickets').last);
    expect(find.text('Tickets cancelled'), findsOneWidget);
    expect(find.textContaining('2 × Standing'), findsNothing);
    expect(find.text('Order A-2318'), findsNothing);
    await _tap(t, find.text('Undo'));
    await _tap(t, find.textContaining('2 × Standing'));
    expect(find.text('Order A-2318'), findsOneWidget);
  });

  testWidgets(
    'a mixed order keeps both prices and refunds the admission subtotal',
    (t) async {
      await _open(t, AdmitPlace.events, scene: AdmitScene.checkout);
      await _tap(
        t,
        find.descendant(
          of: find.byType(BrutalStepper).last,
          matching: find.byIcon(LucideIcons.plus),
        ),
      );
      await _enter(t, 'Card number', '4242 4242 4242 4242');
      await _enter(t, 'Security code', '123');
      await _tap(t, find.text('Pay €112.50'));
      await t.pump(const Duration(seconds: 1));
      await t.pumpAndSettle();
      await _tap(t, find.textContaining('2 × Standing, 1 × Balcony'));
      expect(find.text('Paid €112.50'), findsWidgets);
      expect(find.text('Card ending 4242'), findsOneWidget);
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();
      await _tap(t, find.text('Cancel tickets'));
      expect(
        find.textContaining('€108.00 comes back to your card ending 4242'),
        findsOneWidget,
      );
    },
  );

  testWidgets('saved account details reopen and reach the ticket recipient', (
    t,
  ) async {
    await _open(t, AdmitPlace.settings);
    await _tap(t, find.text('Name and email'));
    await _enter(t, 'Name', 'River Vale');
    await _enter(t, 'Email', 'river@example.com');
    await _tap(t, find.text('Save'));
    expect(find.text('River Vale'), findsOneWidget);
    await _tap(t, find.text('Name and email'));
    expect(
      t.widget<EditableText>(_input('Name')).controller.text,
      'River Vale',
    );
    expect(
      t.widget<EditableText>(_input('Email')).controller.text,
      'river@example.com',
    );
    await _tap(t, find.byIcon(LucideIcons.arrowLeft).first);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    await _tap(t, find.byIcon(LucideIcons.calendarDays).last);
    await _tap(t, find.text('Low Tide'));
    await _tap(t, find.text('Buy tickets'));
    expect(
      t.widget<EditableText>(_input('Email for the tickets')).controller.text,
      'river@example.com',
    );
  });

  testWidgets('signed-out navigation hides the account and private tickets', (
    t,
  ) async {
    await _open(t, AdmitPlace.settings, width: 1440);
    await _tap(t, find.text('Sign out'));
    await _tap(t, find.text('Sign out').last);
    expect(find.text('Ada Park'), findsNothing);
    await _tap(t, find.text('Tickets').first);
    expect(find.text('Low Tide'), findsNothing);
    expect(find.text('Ada Park'), findsNothing);
    expect(find.text('ada.park@example.com'), findsNothing);
    await _tap(t, find.text('Home').first);
    expect(find.text('Show ticket'), findsNothing);
    await _tap(t, find.text('Tickets').first);
    final signIn = find.descendant(
      of: find.byType(BrutalButton),
      matching: find.text('Sign in'),
    );
    await _tap(t, signIn);
    expect(find.text('Ada Park'), findsOneWidget);
    expect(find.textContaining('2 × Standing'), findsOneWidget);
  });
}
