// Under a mouse, a part that takes a press or a drag shows its cursor (the user, 11-13, on the published gallery: "the
// slider doesnt change cursor style"). A live slider shows the click cursor over its whole track and over its knob,
// its MouseRegion's cursor is click; an inert one defers to what is under it. The 0.1.1 sweep's other finds: the
// navigation bar's tabs and act, the range slider's track and the colour sliders' tracks show click (their thumbs
// keep ui_core's resize cursor); the reorder grip, a swipe row and a phone sheet's grabber show the open hand.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

void _drop(Object? _) {}

void _none() {}

Future<void> _pump(
  WidgetTester t,
  List<Widget> children, {
  double width = 1440,
}) async {
  t.view.physicalSize = Size(width, 1400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) =>
          FrostedHost(brightness: Brightness.dark, child: page!),
      home: Center(
        child: SizedBox(
          width: width < 600 ? width - 32 : 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 32,
            children: children,
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<TestGesture> _mouse(WidgetTester t) async {
  final mouse = await t.createGesture(
    kind: PointerDeviceKind.mouse,
    pointer: 1,
  );
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  return mouse;
}

/// The cursor the mouse shows at [at].
Future<MouseCursor?> _cursorAt(
  TestGesture mouse,
  WidgetTester t,
  Offset at,
) async {
  await mouse.moveTo(at);
  await t.pump();
  await t.pump();
  return RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);
}

Finder _named(String type) =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == type);

void main() {
  testWidgets('a live slider shows the click cursor over its track and its '
      'knob; an inert one defers', (t) async {
    await _pump(t, const [
      FrostedSlider(label: 'Volume', value: .4, onChanged: _drop),
      FrostedSlider(label: 'Locked', value: .4, onChanged: null),
    ]);
    final live = find.byType(FrostedSlider).first;
    final off = find.byType(FrostedSlider).last;
    // The slider's own region, inside its focus ring: the region round the
    // ring only watches for a resting pointer and defers its cursor.
    MouseRegion region(Finder slider) => t.widget<MouseRegion>(
      find
          .descendant(
            of: find.descendant(
              of: slider,
              matching: find.byType(FrostedFocusRing),
            ),
            matching: find.byType(MouseRegion),
          )
          .first,
    );
    expect(region(live).cursor, SystemMouseCursors.click);
    expect(region(off).cursor, MouseCursor.defer);

    final mouse = await _mouse(t);
    final box = t.getRect(live);
    // The knob stands 40% of the way along the room its 22 leaves.
    final knob = Offset(box.left + 11 + (box.width - 22) * .4, box.center.dy);
    for (final (name, at) in [
      ('the track near its start', Offset(box.left + 4, box.center.dy)),
      ('the knob', knob),
      ('the track past the knob', Offset(box.right - 30, box.center.dy)),
      ('the track near its end', Offset(box.right - 4, box.center.dy)),
    ]) {
      expect(
        await _cursorAt(mouse, t, at),
        SystemMouseCursors.click,
        reason: 'over $name',
      );
    }
    expect(
      await _cursorAt(mouse, t, t.getCenter(off)),
      SystemMouseCursors.basic,
      reason: 'an inert slider takes the cursor of what is under it',
    );
  });

  testWidgets('the range slider, the colour sliders, the nav act, the reorder '
      'grip and a swipe row show their cursors', (t) async {
    await _pump(t, [
      const FrostedRangeSlider(
        values: DesignRangeValues(.2, .7),
        onChanged: _drop,
      ),
      const FrostedColorPicker(value: Color(0xFF3366FF), onChanged: _drop),
      const FrostedNavAction(
        icon: FrostedGlyphs.arrowRightLeft,
        label: 'Move',
        onPressed: _none,
      ),
      SizedBox(
        height: 140,
        child: FrostedReorderableListView<String>(
          items: const ['Rent', 'Food'],
          labelOf: (s) => s,
          onReorder: (_, _) {},
          itemBuilder: (context, s) => Text(s),
        ),
      ),
      const FrostedSwipeActions(
        trailing: [
          FrostedSwipeAction(
            label: 'Delete',
            icon: FrostedGlyphs.delete,
            onPressed: _none,
          ),
        ],
        child: SizedBox(height: 48, child: Text('A row')),
      ),
      const FrostedSwipeActions(
        key: ValueKey('open'),
        initiallyOpen: true,
        trailing: [
          FrostedSwipeAction(
            label: 'Archive',
            icon: FrostedGlyphs.delete,
            onPressed: _none,
          ),
        ],
        child: SizedBox(height: 48, child: Text('An open row')),
      ),
    ]);
    final mouse = await _mouse(t);
    final range = t.getRect(find.byType(FrostedRangeSlider));
    expect(
      await _cursorAt(mouse, t, range.center),
      SystemMouseCursors.click,
      reason: 'the range slider\'s track between its thumbs',
    );
    final hue = t.getRect(_named('DesignColorSlider').first);
    expect(
      await _cursorAt(
        mouse,
        t,
        Offset(hue.left + hue.width * .2, hue.center.dy),
      ),
      SystemMouseCursors.click,
      reason: 'the hue slider\'s track',
    );
    expect(
      await _cursorAt(mouse, t, t.getCenter(find.byType(FrostedNavAction))),
      SystemMouseCursors.click,
      reason: 'the nav act',
    );
    expect(
      await _cursorAt(
        mouse,
        t,
        t.getCenter(find.byIcon(FrostedGlyphs.grip).first),
      ),
      SystemMouseCursors.grab,
      reason: 'the reorder grip',
    );
    expect(
      await _cursorAt(mouse, t, t.getCenter(find.text('A row'))),
      SystemMouseCursors.grab,
      reason: 'a row with acts to show',
    );
    // Open, a click on the row's strip closes it, so it shows click (ui_core's
    // close layer), as its act does.
    final open = t.getRect(find.byKey(const ValueKey('open')));
    expect(
      await _cursorAt(
        mouse,
        t,
        Offset(open.left + open.width * .3, open.center.dy),
      ),
      SystemMouseCursors.click,
      reason: 'an open row\'s strip',
    );
    expect(
      await _cursorAt(mouse, t, Offset(open.right - 12, open.center.dy)),
      SystemMouseCursors.click,
      reason: 'the act an open row shows',
    );
  });

  testWidgets('on a phone the tab bar\'s tabs show click, a sheet\'s grabber '
      'the open hand', (t) async {
    await _pump(width: 390, t, [
      const FrostedNavigationBar(
        items: [
          FrostedNavItem(FrostedGlyphs.house, 'Home'),
          FrostedNavItem(FrostedGlyphs.person, 'You'),
        ],
        onDestinationSelected: _drop,
      ),
      const FrostedSheetShell(title: 'Add money', children: [Text('Amount')]),
    ]);
    final mouse = await _mouse(t);
    expect(
      await _cursorAt(mouse, t, t.getCenter(find.text('You'))),
      SystemMouseCursors.click,
      reason: 'a tab',
    );
    expect(
      await _cursorAt(mouse, t, t.getCenter(_named('FrostedGrabber'))),
      SystemMouseCursors.grab,
      reason: 'the grabber',
    );
  });
}
