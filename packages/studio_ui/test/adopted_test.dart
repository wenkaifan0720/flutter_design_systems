// The parts Studio runs on ui_core, held to how they behave in an app (the
// module's own package, as the design-systems gate composes it). The full
// suite (every part's states, motion, goldens and Roomtone's screens) runs
// on the exported package, studio_ui.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

Widget _app(Widget home, {Brightness brightness = Brightness.light}) =>
    WidgetsApp(
      color: const Color(0xFF1B1D21),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
      home: StudioTheme(
        data: brightness == Brightness.dark
            ? StudioThemeData.dark()
            : StudioThemeData.light(),
        child: home,
      ),
    );

/// A key that opens what [open] shows.
Widget _opener(void Function(BuildContext context) open) => Builder(
  builder: (context) =>
      Center(child: StudioButton('Open', onPressed: () => open(context))),
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
            (context) => showStudioDialog<void>(
              context: context,
              builder: (context) => StudioDialog(
                title: 'Export this take?',
                content: const Text('An MP3 at 128 kbps.'),
                actions: [
                  StudioButton(
                    'Not now',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  StudioButton.lit(
                    'Export',
                    onPressed: () {
                      answer = 'exported';
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
      expect(find.text('Export this take?'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Export this take?'), findsNothing);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      expect(answer, 'exported');
      expect(find.text('Export this take?'), findsNothing);
    });
  }

  testWidgets('an alert stays when the scrim is pressed', (tester) async {
    await tester.pumpWidget(
      _app(
        _opener(
          (context) => showStudioDialog<void>(
            context: context,
            isAlert: true,
            builder: (context) => StudioDialog(
              title: 'Discard this take?',
              actions: [
                StudioButton(
                  'Keep',
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
    expect(find.text('Discard this take?'), findsOneWidget);
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(find.text('Discard this take?'), findsNothing);
  });

  testWidgets('a sheet closes on a press beside it, and stays on a press '
      'inside it', (tester) async {
    await tester.pumpWidget(
      _app(
        _opener(
          (context) => showStudioBottomSheet<void>(
            context: context,
            title: 'Export',
            builder: (context) => const Text('MP3, 128 kbps'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('MP3, 128 kbps'), findsOneWidget);
    await tester.tap(find.text('MP3, 128 kbps'));
    await tester.pumpAndSettle();
    expect(find.text('MP3, 128 kbps'), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('MP3, 128 kbps'), findsNothing);
  });

  testWidgets('a tab is chosen once, by a press or (from one Tab) the arrows', (
    tester,
  ) async {
    final chosen = <int>[];
    await tester.pumpWidget(
      _app(
        Center(
          child: StatefulBuilder(
            builder: (context, setState) => StudioTabBar(
              tabs: const ['Notes', 'Chapters', 'Transcript'],
              selectedIndex: chosen.isEmpty ? 0 : chosen.last,
              onChanged: (i) => setState(() => chosen.add(i)),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Chapters'));
    await tester.pumpAndSettle();
    expect(chosen, [1]);
    // One Tab reaches the bar (one stop), the arrows choose.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(chosen, [1, 2]);
  });

  testWidgets('a rating takes a press, and a press on the lens given takes '
      'it back', (tester) async {
    var value = 3;
    await tester.pumpWidget(
      _app(
        Center(
          child: StatefulBuilder(
            builder: (context, setState) => StudioRating(
              value: value,
              semanticLabel: 'Your rating',
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );
    Offset lens(int n) {
      final rect = tester.getRect(find.byType(StudioRating));
      return Offset(rect.left + rect.width / 5 * (n - 0.5), rect.center.dy);
    }

    await tester.tapAt(lens(5));
    await tester.pumpAndSettle();
    expect(value, 5);
    await tester.tapAt(lens(5));
    await tester.pumpAndSettle();
    expect(value, 4);
  });

  testWidgets('a wheel turns a row on Down from one Tab', (tester) async {
    var takes = 1;
    await tester.pumpWidget(
      _app(
        Center(
          child: StatefulBuilder(
            builder: (context, setState) => StudioWheelPicker<int>(
              items: const [1, 2, 3, 4],
              value: takes,
              labelOf: (n) => '$n',
              semanticLabel: 'Takes',
              onChanged: (n) => setState(() => takes = n),
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(takes, 2);
  });

  for (final (width, kind) in [
    (390.0, StudioNavigationBar),
    (800.0, StudioNavigationRail),
    (1440.0, StudioSideNavigation),
  ]) {
    testWidgets('at $width the app shell lays its places in a $kind', (
      tester,
    ) async {
      _window(tester, width);
      var place = 0;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => StudioScaffold(
              destinations: const [
                StudioDestination(icon: Icon(IconData(0x41)), label: 'Home'),
                StudioDestination(icon: Icon(IconData(0x42)), label: 'Library'),
                StudioDestination(icon: Icon(IconData(0x43)), label: 'Record'),
              ],
              selectedIndex: place,
              onDestinationSelected: (i) => setState(() => place = i),
              body: Center(child: Text('Place $place')),
            ),
          ),
        ),
      );
      expect(find.byType(kind), findsOneWidget);
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(place, 1);
      expect(find.text('Place 1'), findsOneWidget);
    });
  }
}
