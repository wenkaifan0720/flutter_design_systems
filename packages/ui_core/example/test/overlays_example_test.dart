// The example's overlays as a reader meets them: the report's menu at the
// pointer, its rows doing what they say and showing their keys; the "i"'s
// tip; and "Send to", a search that takes time and can fail.
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// The example's own app, as its package's tests reach it once published.
// ignore: avoid_relative_lib_imports
import '../lib/main.dart';

void main() {
  testWidgets('a right click on the report opens its menu there; a row '
      'does what it says', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    final file = tester.getCenter(find.text('Q3 report.pdf'));
    await tester.tapAt(file, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Open')).dy, greaterThan(file.dy));
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsNothing);
    expect(find.text('Made Q3 report copy.pdf'), findsOneWidget);
  });

  testWidgets('Shift+F10 opens it at the focused report, on its first row', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    Focus.of(tester.element(find.text('Q3 report.pdf'))).requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsNothing);
  });

  testWidgets('the "i" shows its tip above it, the tail at its centre, '
      'when the keys reach it', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    // A key first: the focus that follows is the keyboard's.
    await tester.sendKeyEvent(LogicalKeyboardKey.shift);
    Focus.of(tester.element(find.text('i'))).requestFocus();
    await tester.pumpAndSettle();
    final tip = find.text('About this report');
    expect(tip, findsOneWidget);
    expect(
      tester.getBottomLeft(tip).dy,
      lessThan(tester.getTopLeft(find.text('i')).dy),
    );
    RawTooltip.dismissAllToolTips();
    await tester.pumpAndSettle();
  });

  testWidgets('each row shows its keys as the platform spells them, and '
      'they work while the report has the focus', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    final file = tester.getCenter(find.text('Q3 report.pdf'));
    await tester.tapAt(file, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('Ctrl+O'), findsOneWidget);
    expect(find.text('Ctrl+D'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.text('Q3 report.pdf'))).requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pump();
    expect(find.text('Made Q3 report copy.pdf'), findsOneWidget);
  });

  testWidgets('on macOS the keys are Apple\'s symbols', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.tapAt(
      tester.getCenter(find.text('Q3 report.pdf')),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();
    expect(find.text('⌘ O'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('Send to says it is looking, then lists; offline it says it '
      'could not load, and Try again finds them once back', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    final field = find.byType(EditableText).last;
    await tester.tap(field);
    await tester.enterText(field, 'fin');
    await tester.pump();
    expect(find.text('Loading'), findsOneWidget);
    // The debounce, then the server's 400 ms.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Finance'), findsOneWidget);
    await tester.tap(find.text('Offline'));
    await tester.enterText(field, 'leg');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load results"), findsOneWidget);
    await tester.tap(find.text('Offline'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Loading'), findsOneWidget);
    // Again at once, no debounce: the server's 400 ms.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Legal'), findsOneWidget);
  });
}
