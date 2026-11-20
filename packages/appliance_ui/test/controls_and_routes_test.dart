// Keyboard, pointer and overlay behavior of the public controls.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appliance_ui/appliance_ui.dart';

Widget _app(Widget home, {Brightness brightness = Brightness.light}) =>
    WidgetsApp(
      color: const Color(0xFFEE6A26),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
      builder: (context, app) =>
          ApplianceHost(brightness: brightness, child: app!),
      home: home,
    );

/// A key that opens what [open] shows.
Widget _opener(void Function(BuildContext context) open) => Builder(
  builder: (context) =>
      Center(child: ApplianceButton('Open', onPressed: () => open(context))),
);

/// Sizes the test's window to [width] by 900 logical pixels.
void _window(WidgetTester tester, double width) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('$brightness: a dialog rises, and Escape or its key closes '
        'it', (tester) async {
      String? answer;
      await tester.pumpWidget(
        _app(
          brightness: brightness,
          _opener(
            (context) => showApplianceDialog<void>(
              context: context,
              builder: (context) => ApplianceDialog(
                title: 'Remove from the basket?',
                content: const Text('It goes back on the shelf.'),
                actions: [
                  ApplianceButton(
                    'Keep it',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ApplianceButton.filled(
                    'Remove',
                    isDestructiveAction: true,
                    onPressed: () {
                      answer = 'removed';
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Remove from the basket?'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Remove from the basket?'), findsNothing);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(answer, 'removed');
      expect(find.text('Remove from the basket?'), findsNothing);
    });
  }

  testWidgets('an alert stays when the page beside it is pressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _opener(
          (context) => showApplianceDialog<void>(
            context: context,
            isAlert: true,
            builder: (context) => ApplianceDialog(
              title: 'Leave without paying?',
              actions: [
                ApplianceButton(
                  'Stay',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('Leave without paying?'), findsOneWidget);
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(find.text('Leave without paying?'), findsNothing);
  });

  testWidgets('a sheet closes on a press beside it, and stays on a press '
      'inside it', (tester) async {
    await tester.pumpWidget(
      _app(
        _opener(
          (context) => showApplianceBottomSheet<void>(
            context: context,
            title: 'Filter',
            builder: (context) => const Text('In stock only'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('In stock only'), findsOneWidget);
    await tester.tap(find.text('In stock only'));
    await tester.pumpAndSettle();
    expect(find.text('In stock only'), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('In stock only'), findsNothing);
  });

  testWidgets('a tab is chosen once, by a press or (from one Tab) the arrows', (
    tester,
  ) async {
    final chosen = <String>[];
    await tester.pumpWidget(
      _app(
        Center(
          child: SizedBox(
            width: 360,
            child: StatefulBuilder(
              builder: (context, setState) => ApplianceTabBar<String>(
                semanticLabel: 'Orders',
                tabs: const [
                  ApplianceSegment(value: 'open', label: 'Open'),
                  ApplianceSegment(value: 'past', label: 'Past'),
                  ApplianceSegment(value: 'returns', label: 'Returns'),
                ],
                value: chosen.isEmpty ? 'open' : chosen.last,
                onChanged: (v) => setState(() => chosen.add(v)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();
    expect(chosen, ['past']);
    // A press does not take the keyboard's focus; one Tab reaches the bar
    // (one stop), the arrows choose.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(chosen, ['past', 'returns']);
  });

  testWidgets('a rating takes a press on a star', (tester) async {
    var value = 3;
    await tester.pumpWidget(
      _app(
        Center(
          child: StatefulBuilder(
            builder: (context, setState) => ApplianceRating(
              value: value.toDouble(),
              semanticLabel: 'Your rating',
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );
    Offset star(int n) {
      final rect = tester.getRect(find.byType(ApplianceRating));
      return Offset(rect.left + rect.width / 5 * (n - 0.5), rect.center.dy);
    }

    await tester.tapAt(star(5));
    await tester.pumpAndSettle();
    expect(value, 5);
    await tester.tapAt(star(2));
    await tester.pumpAndSettle();
    expect(value, 2);
  });

  testWidgets('a search that fails says so, with a row to try again', (
    tester,
  ) async {
    var asked = 0;
    await tester.pumpWidget(
      _app(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 320,
            child: ApplianceCombobox<String>(
              label: 'Stockist',
              search: (words) {
                asked++;
                return Future<Iterable<String>>.error(
                  StateError('No connection'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'Le');
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load results"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    final before = asked;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(asked, greaterThan(before));
  });

  for (final (width, kind) in [
    (390.0, ApplianceNavigationBar),
    (800.0, ApplianceNavigationRail),
    (1440.0, ApplianceSideNavigation),
  ]) {
    testWidgets('at $width the scaffold lays its places in an $kind', (
      tester,
    ) async {
      _window(tester, width);
      var place = 0;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => ApplianceScaffold(
              destinations: const [
                ApplianceDestination(icon: IconData(0x41), label: 'Home'),
                ApplianceDestination(icon: IconData(0x42), label: 'Shop'),
                ApplianceDestination(icon: IconData(0x43), label: 'Orders'),
              ],
              selectedIndex: place,
              onSelected: (i) => setState(() => place = i),
              body: Center(child: Text('Place $place')),
            ),
          ),
        ),
      );
      expect(find.byType(kind), findsOneWidget);
      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();
      expect(place, 1);
      expect(find.text('Place 1'), findsOneWidget);
    });
  }

  testWidgets('a sheet dragged and let go keeps the keys: Escape closes it', (
    tester,
  ) async {
    _window(tester, 390);
    await tester.pumpWidget(
      _app(
        _opener(
          (context) => showApplianceBottomSheet<void>(
            context: context,
            title: 'Filter',
            builder: (context) => const Text('In stock only'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final drag = await tester.startGesture(
      tester.getCenter(find.text('Filter')),
    );
    for (var i = 0; i < 8; i++) {
      await drag.moveBy(const Offset(0, 6));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await drag.up();
    await tester.pumpAndSettle();
    expect(find.text('In stock only'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('In stock only'), findsNothing);
  });

  testWidgets('a sheet closes on Escape', (tester) async {
    await tester.pumpWidget(
      _app(
        _opener(
          (context) => unawaited(
            showApplianceSheet<void>(
              context: context,
              builder: (context) => const Text('Delivery'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Delivery'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Delivery'), findsNothing);
  });
}
