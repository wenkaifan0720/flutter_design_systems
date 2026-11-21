// The pointer's mark is an ink change and nothing more: under it a
// control's brackets, a slider's block or a tab's words take the accent, the
// cells' ground as it was, so it stays lighter than the keyboard's cursor (a
// block of the accent). It shows the hand on what presses and the arrow on
// what doesn't. What hover is information for may do more: a tooltip and a
// hover card open, and an open menu or list marks the row under the pointer
// (an action sheet's and the command palette's, open in their specimens).
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

/// Rows whose part opens on hover (that is what it is for), and an open
/// menu or list, whose row under the pointer is marked: an action sheet's,
/// the command palette's.
const _opensOnHover = {'Tooltip', 'HoverCard', 'ActionSheet', 'Command'};

/// Rows whose controls mark the pointer: each must change some ink under it.
const _marksThePointer = {
  'Button',
  'IconButton',
  'Chip',
  'Checkbox',
  'RadioGroup',
  'Switch',
  'Slider',
  'RangeSlider',
  'TabBar',
};

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
List<(RawButton, Offset)> _pressables(WidgetTester tester) => [
  for (final e in find.byType(RawButton).hitTestable().evaluate())
    (e.widget as RawButton, tester.getCenter(find.byWidget(e.widget))),
];

/// The radios of the part on screen (Flutter's RawRadio under each), whether
/// each can be chosen, by their centre.
List<(bool, Offset)> _radios(WidgetTester tester) => [
  for (final e
      in find.byWidgetPredicate((w) => w is RawRadio).hitTestable().evaluate())
    ((e.widget as RawRadio).enabled, tester.getCenter(find.byWidget(e.widget))),
];

/// Where the pointer goes in the part on screen: its pressables', its
/// radios' and its value handles' (a slider's) centres.
List<(String, Offset)> _targets(WidgetTester tester) => [
  for (final (p, centre) in _pressables(tester))
    (p.semanticLabel ?? '$centre', centre),
  for (final (_, centre) in _radios(tester)) ('radio at $centre', centre),
  for (final e in find.byType(DesignValueHandle).hitTestable().evaluate())
    (
      (e.widget as DesignValueHandle).semanticLabel ?? 'handle',
      tester.getCenter(find.byWidget(e.widget)),
    ),
];

/// The colour most of [pixels] are: the ground the part stands on.
int _ground(List<int> pixels) {
  final counts = <int, int>{};
  for (var i = 0; i < pixels.length; i += 4) {
    final c =
        pixels[i] << 24 |
        pixels[i + 1] << 16 |
        pixels[i + 2] << 8 |
        pixels[i + 3];
    counts[c] = (counts[c] ?? 0) + 1;
  }
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

bool _presses(RawButton p) =>
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
      }
      for (final (enabled, centre) in _radios(tester)) {
        await mouse.moveTo(centre);
        await tester.pump();
        final cursor = RendererBinding.instance.mouseTracker
            .debugDeviceActiveCursor(1);
        expect(
          cursor == SystemMouseCursors.click,
          enabled,
          reason: '${entry.row}: the radio at $centre shows $cursor',
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
    "the pointer changes a control's ink, never the ground",
    (tester) async {
      _size(tester);
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        pointer: 1,
      );
      const away = Offset(1279, 2399);
      await mouse.addPointer(location: away);
      final grounds = <String>[];
      final unmarked = <String>{..._marksThePointer};
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
        final ground = _ground(idle);
        for (final (name, centre) in _targets(tester).take(8)) {
          await mouse.moveTo(centre);
          await _settle(tester);
          final over = await _pixels(tester);
          for (var i = 0; i < idle.length; i += 4) {
            if (idle[i] == over[i] &&
                idle[i + 1] == over[i + 1] &&
                idle[i + 2] == over[i + 2] &&
                idle[i + 3] == over[i + 3]) {
              continue;
            }
            unmarked.remove(entry.row);
            final was =
                idle[i] << 24 |
                idle[i + 1] << 16 |
                idle[i + 2] << 8 |
                idle[i + 3];
            if (was == ground) {
              grounds.add('${entry.row}: $name');
              break;
            }
          }
          seen++;
          await mouse.moveTo(away);
          await _settle(tester);
        }
      }
      expect(grounds, isEmpty, reason: 'the pointer filled the ground');
      expect(unmarked, isEmpty, reason: 'no mark under the pointer');
      expect(seen, greaterThan(50));
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: _desk,
    tags: 'goldens',
  );
}
