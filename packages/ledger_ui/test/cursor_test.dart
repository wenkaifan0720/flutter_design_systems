// The pointer's cursor over what takes a tap or a drag: the click cursor over
// a live slider (its track and its knob), a select's label and a tab of the
// phone's tab bar, the caret cursor over a text field's label; an off slider
// or field defers to what it stands on.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) =>
      LedgerHost(brightness: Brightness.light, child: page!),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Align(alignment: Alignment.topCenter, child: child),
    ),
  ),
);

Future<TestGesture> _pump(WidgetTester t, Widget child) async {
  t.view.physicalSize = const Size(1440, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(_host(child));
  await t.pump();
  final mouse = await t.createGesture(
    kind: PointerDeviceKind.mouse,
    pointer: 1,
  );
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  await t.pump();
  return mouse;
}

/// The cursor the mouse shows resting at [at].
Future<MouseCursor?> _over(WidgetTester t, TestGesture mouse, Offset at) async {
  await mouse.moveTo(at);
  await t.pump();
  return RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);
}

/// The slider's track: the strip under its label line.
Finder get _track => find
    .descendant(
      of: find.byType(LedgerSlider),
      matching: find.byType(CustomPaint),
    )
    .last;

Rect _strip(WidgetTester t) => t.getRect(_track);

/// The mouse region nearest over the slider's track.
MouseRegion _region(WidgetTester t) => t.widget<MouseRegion>(
  find.ancestor(of: _track, matching: find.byType(MouseRegion)).first,
);

void main() {
  group('slider', () {
    Widget slider(ValueChanged<double>? set) => LedgerSlider(
      label: 'Paper weight',
      value: 120,
      min: 80,
      max: 200,
      onChanged: set,
    );

    testWidgets('a live one shows the click cursor over its track and knob', (
      t,
    ) async {
      final mouse = await _pump(t, SizedBox(width: 400, child: slider((_) {})));
      final strip = _strip(t);
      // The knob stands at a third of the way (120 of 80 to 200), the track
      // runs on to its ends.
      for (final at in [
        strip.centerLeft + const Offset(4, 0),
        Offset(strip.left + 11 + (strip.width - 22) / 3, strip.center.dy),
        strip.centerRight - const Offset(4, 0),
      ]) {
        expect(
          await _over(t, mouse, at),
          SystemMouseCursors.click,
          reason: '$at',
        );
      }
      final region = _region(t);
      expect(region.cursor, SystemMouseCursors.click);
    });

    testWidgets('an off one defers its cursor to what it stands on', (t) async {
      final mouse = await _pump(t, SizedBox(width: 400, child: slider(null)));
      final region = _region(t);
      expect(region.cursor, MouseCursor.defer);
      expect(await _over(t, mouse, _strip(t).center), SystemMouseCursors.basic);
    });
  });

  testWidgets('a field\'s label shows the cursor of what a tap on it focuses', (
    t,
  ) async {
    final mouse = await _pump(
      t,
      SizedBox(
        width: 400,
        child: Column(
          children: [
            const LedgerTextField(label: 'Payee'),
            LedgerSelect<String>(
              label: 'Account',
              value: 'everyday',
              items: const [
                LedgerSelectItem(value: 'everyday', label: 'Everyday'),
                LedgerSelectItem(value: 'savings', label: 'Savings'),
              ],
              onChanged: (_) {},
            ),
            const LedgerTextField(label: 'Memo', enabled: false),
          ],
        ),
      ),
    );
    expect(
      await _over(t, mouse, t.getCenter(find.text('PAYEE'))),
      SystemMouseCursors.text,
    );
    expect(
      await _over(t, mouse, t.getCenter(find.text('ACCOUNT'))),
      SystemMouseCursors.click,
    );
    expect(
      await _over(t, mouse, t.getCenter(find.text('MEMO'))),
      SystemMouseCursors.basic,
    );
  });

  testWidgets('a tab of the phone tab bar shows the click cursor', (t) async {
    final mouse = await _pump(
      t,
      SizedBox(
        width: 390,
        child: LedgerNavBar(
          items: const [
            LedgerNavItem(Icons.home_outlined, 'Home'),
            LedgerNavItem(Icons.receipt_long_outlined, 'Register'),
            LedgerNavItem(Icons.settings_outlined, 'Settings'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      ),
    );
    for (final name in ['Home', 'Register', 'Settings']) {
      expect(
        await _over(t, mouse, t.getCenter(find.text(name))),
        SystemMouseCursors.click,
        reason: name,
      );
    }
  });
}
