// Sheets stand on the bars kept clear along the bottom: a bottom sheet or a
// side sheet pushed over an app's shell ends at the top of the shell's bar,
// and of a page's foot standing on it, so a floating card never leaves a
// strip of the bar showing under it. A key floating with edge: bottom, a
// part kept clear inside the sheet, the keyboard and an app with no toaster
// are read as before; a full-screen sheet and a dialog still cover the whole
// screen, the bar too.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const List<RawNavigationDestination> _places = [
  RawNavigationDestination(label: 'Books', icon: IconData(0xe318)),
  RawNavigationDestination(label: 'Add', icon: IconData(0xe145)),
];

const _card = ValueKey('card');
const _bar = ValueKey('bar');
const _foot = ValueKey('foot');

// The screen's bottom inset the sheet's content sees, as it last built.
double? _inset;

// A floating card: 16 from every edge of the sheet's panel.
Widget _floating(BuildContext context, [Widget? foot]) {
  _inset = MediaQuery.paddingOf(context).bottom;
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(key: _card, height: 200, child: Text('Due date')),
        ?foot,
      ],
    ),
  );
}

RawBottomSheetRoute<void> _sheet({Widget? foot}) => RawBottomSheetRoute<void>(
  builder: (context, details) => _floating(context, foot),
);

// The app: a shell whose bar takes the screen's bottom inset, its first
// place a page with [page]'s foot, under one toaster unless [toaster] is
// false. [open] pushes on the root navigator, or on the place's own.
Future<void> _pump(
  WidgetTester tester, {
  required Route<void> Function() open,
  Widget Function(Widget key)? page,
  bool toaster = true,
  bool onPlace = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(bottom: 20);
  addTearDown(tester.view.reset);
  final place = ValueNotifier(0);
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
          navigationBuilder: (context, details) => Padding(
            key: _bar,
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom,
            ),
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  for (final d in details.destinations) Expanded(child: d),
                ],
              ),
            ),
          ),
          branches: [
            (context) => Column(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) => GestureDetector(
                      onTap: () => Navigator.of(
                        context,
                        rootNavigator: !onPlace,
                      ).push(open()),
                      child: const Text('Open'),
                    ),
                  ),
                ),
                ?page?.call(const SizedBox(key: _foot, width: 390, height: 48)),
              ],
            ),
            (context) => const Text('Add page'),
          ],
        ),
      ),
      wrap: toaster
          ? (context, navigator) => RawToaster(
              toastBuilder: (context, details) => Text(details.toast.message),
              child: navigator!,
            )
          : null,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

double _barTop(WidgetTester tester) => tester.getRect(find.byKey(_bar)).top;

void main() {
  testWidgets('a floating sheet ends 16 above the bar, the bottom inset '
      "the bar's; the barrier still covers the bar", (tester) async {
    await _pump(tester, open: _sheet);
    final bar = _barTop(tester);
    expect(bar, 844 - 20 - 64);
    expect(tester.getRect(find.byKey(_card)).bottom, bar - 16);
    expect(_inset, 0, reason: 'the bar under the sheet takes the inset');
    // A tap on the bar reaches the barrier: the sheet closes, the place
    // stays.
    await tester.tapAt(Offset(300, bar + 20));
    await tester.pumpAndSettle();
    expect(find.byKey(_card), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets("it stands on a page's foot standing on the bar", (tester) async {
    await _pump(
      tester,
      open: _sheet,
      page: (key) => RawToasterKeepClear(child: key),
    );
    final foot = tester.getRect(find.byKey(_foot)).top;
    expect(foot, _barTop(tester) - 48);
    expect(tester.getRect(find.byKey(_card)).bottom, foot - 16);
  });

  testWidgets('a key floating with edge: bottom does not lift it', (
    tester,
  ) async {
    await _pump(
      tester,
      open: _sheet,
      page: (key) => Padding(
        padding: const EdgeInsets.all(16),
        child: RawToasterKeepClear(edge: RawKeepClearEdge.bottom, child: key),
      ),
    );
    expect(tester.getRect(find.byKey(_card)).bottom, _barTop(tester) - 16);
  });

  testWidgets('a part kept clear inside the sheet does not lift it', (
    tester,
  ) async {
    await _pump(
      tester,
      open: () =>
          _sheet(foot: const RawToasterKeepClear(child: SizedBox(height: 40))),
    );
    final bottom = tester.getRect(find.byKey(_card)).bottom;
    expect(bottom, _barTop(tester) - 16 - 40);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getRect(find.byKey(_card)).bottom, bottom);
  });

  testWidgets('a keyboard taller than the bar lifts it above the keyboard', (
    tester,
  ) async {
    await _pump(tester, open: _sheet);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_card)).bottom, 844 - 300 - 16);
  });

  testWidgets('a side sheet ends at the top of the bar', (tester) async {
    await _pump(
      tester,
      open: () => RawSideSheetRoute<void>(
        builder: (context, details) {
          _inset = MediaQuery.paddingOf(context).bottom;
          return const SizedBox.expand(key: _card);
        },
      ),
    );
    final panel = tester.getRect(find.byKey(_card));
    expect(panel.top, 0);
    expect(panel.bottom, _barTop(tester));
    expect(_inset, 0);
  });

  testWidgets("with no toaster a sheet stands on the screen's foot, the "
      'bottom inset its own', (tester) async {
    await _pump(tester, open: _sheet, toaster: false);
    expect(tester.getRect(find.byKey(_card)).bottom, 844 - 16);
    expect(_inset, 20);
  });

  testWidgets("a sheet on the place's own navigator ends above the bar, "
      'as before', (tester) async {
    await _pump(tester, open: _sheet, onPlace: true);
    expect(tester.getRect(find.byKey(_card)).bottom, _barTop(tester) - 16);
  });

  testWidgets('a full-screen sheet still covers the whole screen, the bar '
      'too', (tester) async {
    await _pump(
      tester,
      open: () => RawSheetRoute<void>(
        builder: (context) => const SizedBox.expand(key: _card),
      ),
    );
    expect(
      tester.getRect(find.byKey(_card)),
      Offset.zero & const Size(390, 844),
    );
  });

  testWidgets('a dialog still covers the whole screen, the bar too', (
    tester,
  ) async {
    await _pump(
      tester,
      open: () => RawModalDialogRoute<void>(
        builder: (context, details) => const SizedBox.expand(key: _card),
      ),
    );
    expect(
      tester.getRect(find.byKey(_card)),
      Offset.zero & const Size(390, 844),
    );
  });
}
