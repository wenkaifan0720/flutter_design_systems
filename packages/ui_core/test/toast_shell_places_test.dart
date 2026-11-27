// The one way to raise a toast in an app with a shell: one RawToaster above
// the app's navigator (WidgetsApp.builder), RawToaster.of(context).show from
// anywhere under it. A toast raised on one place stays through a switch to
// another, and stands above the shell's bar and a page's footer key kept
// clear (RawToasterKeepClear round the footer with its padding, or with
// edge: bottom round a key floating on the page's padding).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const List<RawNavigationDestination> _places = [
  RawNavigationDestination(label: 'Books', icon: IconData(0xe318)),
  RawNavigationDestination(label: 'Add', icon: IconData(0xe145)),
];

// A page with a footer key, kept clear as [footer] says.
Widget _detail(Widget Function(Widget key) footer) => Column(
  children: [
    const Expanded(child: Text('Detail')),
    footer(const SizedBox(height: 48, child: Text('Delete'))),
  ],
);

Future<ValueNotifier<int>> _pump(
  WidgetTester tester,
  Widget Function(Widget key) footer,
) async {
  tester.view.physicalSize = const Size(390, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final place = ValueNotifier(1);
  addTearDown(place.dispose);
  await tester.pumpWidget(
    harness(
      ValueListenableBuilder<int>(
        valueListenable: place,
        builder: (context, selected, _) => RawAdaptiveShell.branches(
          mode: RawNavigationMode.bar,
          destinations: _places,
          selectedIndex: selected,
          onDestinationSelected: (i) => place.value = i,
          destinationBuilder: (context, d, details) =>
              SizedBox(height: 56, child: Center(child: Text(d.label))),
          navigationBuilder: (context, details) => SizedBox(
            key: const ValueKey('bar'),
            height: 64,
            child: Row(
              children: [
                for (final d in details.destinations) Expanded(child: d),
              ],
            ),
          ),
          branches: [
            (context) => _detail(footer),
            (context) => Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  RawToaster.of(context).show(const RawToast(message: 'Saved'));
                  place.value = 0;
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
      wrap: (context, navigator) => RawToaster(
        toastBuilder: (context, details) => SizedBox(
          width: 300,
          height: 40,
          child: Text(details.toast.message),
        ),
        child: navigator!,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return place;
}

void main() {
  for (final (how, footer) in [
    (
      'the footer with its padding',
      (Widget key) => RawToasterKeepClear(
        child: Padding(padding: const EdgeInsets.all(16), child: key),
      ),
    ),
    (
      'a key floating on the padding, edge: bottom',
      (Widget key) => Padding(
        padding: const EdgeInsets.all(16),
        child: RawToasterKeepClear(edge: RawKeepClearEdge.bottom, child: key),
      ),
    ),
  ]) {
    testWidgets('a toast raised on one place stays through the switch, '
        'above the bar and the footer key kept clear ($how)', (tester) async {
      await _pump(tester, footer);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsOneWidget, reason: 'switched places');
      expect(find.text('Saved'), findsOneWidget, reason: 'the toast stayed');
      final toast = tester.getRect(find.text('Saved'));
      final bar = tester.getRect(find.byKey(const ValueKey('bar')));
      final key = tester.getRect(find.text('Delete'));
      expect(toast.bottom, lessThanOrEqualTo(bar.top));
      expect(toast.bottom, lessThanOrEqualTo(key.top));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing, reason: 'its time ran');
    });
  }

  testWidgets('a key floating on the padding without an edge keeps nothing '
      'clear: the toast stands on the bar', (tester) async {
    await _pump(
      tester,
      (key) => Padding(
        padding: const EdgeInsets.all(16),
        child: RawToasterKeepClear(child: key),
      ),
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final toast = tester.getRect(find.text('Saved'));
    final key = tester.getRect(find.text('Delete'));
    expect(toast.bottom, greaterThan(key.top));
  });
}
