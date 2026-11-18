// The example's values page: each value behaviour, painted plainly, takes
// its input.
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Offset, Scrollable;
import 'package:flutter_test/flutter_test.dart';

// The example is its own app beside the package, not the package's lib.
// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';
import 'behaviour_harness.dart';

// A screen reader's [action] on the node labelled [label].
Future<void> _act(
  WidgetTester tester,
  String label,
  SemanticsAction action, [
  Object? arguments,
]) async {
  final node = tester.getSemantics(find.bySemanticsLabel(label));
  semanticsOwner().performAction(node.id, action, arguments);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the values page opens from the report and takes input', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    // The report scrolls: the pages' entries are at its foot.
    await tester.ensureVisible(find.text('Values'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Values'));
    await tester.pumpAndSettle();
    expect(find.text('Date'), findsWidgets);

    // The date wheel: Tab to the month, Down a month.
    expect(find.bySemanticsLabel('Month'), findsNWidgets(2));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Month').first).value,
      'December',
    );

    // The date field: a tap on its month, then digits.
    await tester.tap(find.text('mm'));
    await tester.pump();
    for (final c in '12252026'.split('')) {
      await tester.sendKeyEvent(
        LogicalKeyboardKey(LogicalKeyboardKey.digit0.keyId + int.parse(c)),
        character: c,
      );
      await tester.pump();
    }
    expect(
      tester.getSemantics(find.bySemanticsLabel('Due date')).value,
      'Friday, 25 December 2026',
    );

    // The time field: Up an hour.
    await tester.tap(find.text('9'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Start time')).value,
      '10:30\u202FAM',
    );

    // The number field: its plus, then Up.
    await tester.tap(find.text('+'));
    await tester.pump();
    expect(tester.getSemantics(find.bySemanticsLabel('Guests')).value, '3');
    await tester.tap(find.bySemanticsLabel('Guests'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(tester.getSemantics(find.bySemanticsLabel('Guests')).value, '4');

    // The rating: End fills it.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(tester.getSemantics(find.bySemanticsLabel('Stars')).value, '5 of 5');

    // The visits: a screen reader steps onto January's web visits, then
    // asks for the table; a tap on "Show chart" brings the chart back.
    await tester.scrollUntilVisible(
      find.text('Spending'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await _act(tester, 'Visits by month', SemanticsAction.increase);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Visits by month')).value,
      'January 2026, Web: 820',
    );
    await _act(
      tester,
      'Visits by month',
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(
        const CustomSemanticsAction(label: 'Show data table'),
      ),
    );
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('January 2026'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Show chart'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Show chart'));
    await tester.pumpAndSettle();
    expect(find.text('Month'), findsNothing);

    // The orders: a mouse over Q2's bar reads it out.
    await tester.scrollUntilVisible(
      find.text('Spending'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final orders = tester.getRect(find.bySemanticsLabel('Orders by quarter'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(
      Offset(orders.left + 36 + (orders.width - 48) * 0.375, orders.center.dy),
    );
    await tester.pumpAndSettle();
    expect(find.text('Orders 58'), findsOneWidget);
    await mouse.removePointer();

    // The donut: a screen reader steps onto its first slice.
    await _act(tester, 'Spending', SemanticsAction.increase);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Spending')).value,
      '50%, Rent: 1,200',
    );
    expect(find.text('Rent\n50%'), findsOneWidget);
    semantics.dispose();
  });
}
