// Admit's Settings at a phone's and a desktop's width: every row goes where it says. Name and email and Payment
// open their pages, the density select opens its list and takes a choice, and Sign out asks first.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/admit/admit.dart';

Future<void> _open(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const AdmitApp(initialPlace: AdmitPlace.settings));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester, Finder onPage) async {
  Navigator.of(tester.element(onPage)).pop();
  await tester.pumpAndSettle();
}

void main() {
  for (final width in const [390.0, 1440.0]) {
    testWidgets('Name and email opens its page at ${width.toInt()}', (
      tester,
    ) async {
      await _open(tester, width);
      await _tap(tester, find.text('Name and email'));
      final page = find.text('Tickets and receipts go here.');
      expect(page, findsOneWidget);
      await _back(tester, page);
      expect(page, findsNothing);
      expect(find.text('Payment'), findsOneWidget);
    });

    testWidgets('Payment opens its page at ${width.toInt()}', (tester) async {
      await _open(tester, width);
      await _tap(tester, find.text('Payment'));
      final page = find.text('Save card');
      expect(page, findsOneWidget);
      await _back(tester, page);
      expect(page, findsNothing);
    });

    testWidgets('the density select opens and takes a choice at '
        '${width.toInt()}', (tester) async {
      await _open(tester, width);
      expect(find.text('Compact'), findsNothing);
      await _tap(tester, find.text('Standard'));
      expect(find.text('Compact'), findsOneWidget);
      await tester.tap(find.text('Compact'));
      await tester.pumpAndSettle();
      expect(find.text('Comfortable'), findsNothing);
      expect(find.text('Compact'), findsOneWidget);
    });

    testWidgets('Sign out asks first at ${width.toInt()}', (tester) async {
      await _open(tester, width);
      await _tap(tester, find.text('Sign out'));
      expect(find.text('Sign out?'), findsOneWidget);
      await tester.tap(find.text('Stay signed in'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsNothing);
      await _tap(tester, find.text('Sign out'));
      await tester.tap(find.text('Sign out').last);
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsNothing);
      expect(find.text('Signed out on this device.'), findsOneWidget);
      // The toast's own time runs out.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
    });
  }
}
