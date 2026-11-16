// A terminal has no hover. The pointer over a part changes nothing it
// paints; it shows the hand on what presses and the arrow on what doesn't.
// Only what hover is information for may change: a tooltip and a hover card
// open, and an open menu or list marks the row under the pointer (an
// action sheet's and the command palette's, open in their specimens).
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

/// Rows whose part opens on hover (that is what it is for), and an open
/// menu or list, whose row under the pointer is marked (relay F): an action
/// sheet's, the command palette's.
const _opensOnHover = {'Tooltip', 'HoverCard', 'ActionSheet', 'Command'};

final _shot = GlobalKey();

Widget _host(WidgetBuilder build, String row) => MaterialApp(
  home: MediaQuery(
    // Loops stand still, and a state's change shows at once.
    data: const MediaQueryData(size: Size(1280, 2400), disableAnimations: true),
    child: TermTheme(
      data: TermThemeData.dark(),
      child: TermToaster(
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: RepaintBoundary(
              key: _shot,
              child: Builder(key: ValueKey(row), builder: build),
            ),
          ),
        ),
      ),
    ),
  ),
);

/// The pressables of the part on screen, by their centre.
List<(DesignPressable, Offset)> _pressables(WidgetTester tester) => [
  for (final e in find.byType(DesignPressable).hitTestable().evaluate())
    (e.widget as DesignPressable, tester.getCenter(find.byWidget(e.widget))),
];

bool _presses(DesignPressable p) =>
    (p.enabled ?? true) && (p.onPressed != null || p.onLongPress != null);

Future<List<int>> _pixels(WidgetTester tester) async {
  final boundary =
      _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List().toList();
  }))!;
}

void _size(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 2400);
  addTearDown(tester.view.reset);
}

/// Frames for 320 ms: a spring's first frame has no time in it, so one long
/// pump would show where it started, not where it went.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

// The pointer is a desk's: a phone's touch has no hover, and there the
// look leaves out the parts a keyboard alone reads (its keys).
final _desk = TargetPlatformVariant.only(TargetPlatform.macOS);

void main() {
  setUpAll(loadFaces);

  testWidgets('the hand on what presses, the arrow elsewhere', (tester) async {
    _size(tester);
    final mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    await mouse.addPointer(location: const Offset(1279, 2399));
    var seen = 0;
    for (final entry in termInventory.entries) {
      final build = entry.builder;
      if (build == null) continue;
      await tester.pumpWidget(_host(build, entry.row));
      await tester.pump();
      for (final (pressable, centre) in _pressables(tester)) {
        await mouse.moveTo(centre);
        await tester.pump();
        final cursor = RendererBinding.instance.mouseTracker
            .debugDeviceActiveCursor(1);
        if (pressable.mouseCursor != null) continue;
        expect(
          cursor == SystemMouseCursors.click,
          _presses(pressable),
          reason:
              '${entry.row}: ${pressable.semanticLabel ?? centre} '
              'shows $cursor',
        );
        seen++;
        await mouse.moveTo(const Offset(1279, 2399));
        await tester.pump();
      }
    }
    expect(seen, greaterThan(50));
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: _desk);

  testWidgets(
    'the pointer over a part paints nothing new',
    (tester) async {
      _size(tester);
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        pointer: 1,
      );
      const away = Offset(1279, 2399);
      await mouse.addPointer(location: away);
      final changed = <String>[];
      var seen = 0;
      for (final entry in termInventory.entries) {
        final build = entry.builder;
        if (build == null || _opensOnHover.contains(entry.row)) continue;
        await tester.pumpWidget(_host(build, entry.row));
        await _settle(tester);
        if (_shot.currentContext!.size!.isEmpty) continue;
        final idle = await _pixels(tester);
        await _settle(tester);
        if (!listEquals(idle, await _pixels(tester))) continue; // it moves
        for (final (pressable, centre) in _pressables(tester).take(8)) {
          await mouse.moveTo(centre);
          await _settle(tester);
          if (!listEquals(idle, await _pixels(tester))) {
            changed.add('${entry.row}: ${pressable.semanticLabel ?? centre}');
          }
          seen++;
          await mouse.moveTo(away);
          await _settle(tester);
        }
      }
      expect(changed, isEmpty);
      expect(seen, greaterThan(50));
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: _desk,
    tags: 'goldens',
  );
}
