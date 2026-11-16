// A field's popover (a select's list, a date picker's calendar: Fluent2FieldPopover) closes when a route is pushed
// over its field's: an alert on the field's own navigator, and one on the root navigator over a page in a nested
// navigator, which leaves the field's route current in its own. Focus is the new route's, never sent back to the
// field under it, and the popover is still closed once the route is gone. Focus parked on the root scope (the app in
// the background) leaves it open.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

const _options = [
  Fluent2Option('equipment', 'Equipment'),
  Fluent2Option('access', 'Access'),
  Fluent2Option('room', 'Room booking'),
];

Future<void> _app(
  WidgetTester t, {
  required bool nested,
  FocusNode? other,
}) async {
  t.view.physicalSize = const Size(1440, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final page = Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 320,
          child: Fluent2Select<String>(
            label: 'Type',
            value: 'equipment',
            options: _options,
            onChanged: (_) {},
          ),
        ),
        Focus(focusNode: other, child: const SizedBox(width: 10, height: 10)),
      ],
    ),
  );
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) =>
          Fluent2Host(brightness: Brightness.light, child: navigator!),
      home: nested
          ? Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute<void>(
                settings: settings,
                builder: (context) => page,
              ),
            )
          : page,
    ),
  );
  await t.pumpAndSettle();
}

/// Opens the select's list: its other options show.
Future<void> _open(WidgetTester t) async {
  await t.tap(find.text('Equipment'));
  await t.pumpAndSettle();
  expect(find.text('Access'), findsOneWidget);
}

/// Pushes an alert on the root navigator, as showDialog does, holding [focus].
void _alert(WidgetTester t, FocusNode focus) {
  showDialog<void>(
    context: t.element(find.text('Equipment').first),
    builder: (context) => Center(
      child: Focus(
        focusNode: focus,
        autofocus: true,
        child: const SizedBox(width: 200, height: 80, child: Text('Delete?')),
      ),
    ),
  );
}

void main() {
  for (final nested in [false, true]) {
    final where = nested
        ? 'on the root navigator over a nested one'
        : 'on its own navigator';
    testWidgets('an alert $where closes the list and keeps the focus', (
      t,
    ) async {
      await _app(t, nested: nested);
      await _open(t);
      final focus = FocusNode(debugLabel: 'alert');
      addTearDown(focus.dispose);
      _alert(t, focus);
      // Gone within the alert's first frames: the alert's own navigator takes
      // the focus as its first frame ends, the list closes as the next ends.
      for (var frame = 0; frame < 3; frame++) {
        await t.pump();
      }
      expect(find.text('Access'), findsNothing);
      await t.pumpAndSettle();
      expect(find.text('Access'), findsNothing);
      expect(focus.hasPrimaryFocus, isTrue);

      Navigator.of(t.element(find.text('Delete?'))).pop();
      await t.pumpAndSettle();
      expect(find.text('Delete?'), findsNothing);
      expect(find.text('Access'), findsNothing);
    });
  }

  testWidgets(
    'the app in the background, and focus moving on its page, leave the '
    'list open',
    (t) async {
      final other = FocusNode(debugLabel: 'other');
      addTearDown(other.dispose);
      await _app(t, nested: true, other: other);
      await _open(t);
      // On a desktop, focus is parked on the root scope meanwhile.
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus,
        same(FocusManager.instance.rootScope),
      );
      expect(find.text('Access'), findsOneWidget, reason: 'background');
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pumpAndSettle();
      other.requestFocus();
      await t.pumpAndSettle();
      expect(find.text('Access'), findsOneWidget, reason: 'its page');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}
