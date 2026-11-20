// Keyboard focus lights the light each Studio part already has, inside its
// own housing: a key's legend or lamp, a fader's index slit, a tab's light,
// a field's or a display's inner lip. The lit pixels stay within the part, by
// day and by night. A part whose lamp is already lit lights its edge all the
// way round when focused (by day a latched key's lit rim glows at full
// strength), and so does a key whose legend is already lit red. A chip lights
// its rim, selected or not, and leaves its lamp to mean selected. A text field
// lights its edge however it took the focus, and a menu command sinks only
// while a press is held.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:studio_ui/studio_ui.dart';

final _frame = GlobalKey();

Future<void> _show(
  WidgetTester tester,
  Widget child,
  Brightness brightness,
) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 1688);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          StudioHost(brightness: brightness, child: app!),
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: RepaintBoundary(
            key: _frame,
            child: Builder(
              builder: (context) => ColoredBox(
                color: StudioTheme.of(context).colors.panel,
                child: Padding(padding: const EdgeInsets.all(16), child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<(Uint8List, int)> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_frame),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return (data!.buffer.asUint8List(), image.width);
    } finally {
      image.dispose();
    }
  }))!;
}

void _none() {}

// The rim of a focused part whose lamp is lit, at full strength.
Color _rim(WidgetTester tester) =>
    StudioTheme.of(tester.element(find.byKey(_frame))).colors.focusRing;

// [key]'s bounds with room for its travel: a latched key stands sunk and
// its light moves with it.
Rect _sunk(Rect key) => Rect.fromLTRB(
  key.left,
  key.top,
  key.right,
  key.bottom + StudioMetrics.pressTravel,
);

// Every surface in the frame, and its face.
Map<Element, StudioFace> _faces() => {
  for (final element
      in find
          .descendant(
            of: find.byKey(_frame),
            matching: find.byWidgetPredicate(
              (w) => w is AnimatedStudioSurface || w is StudioSurface,
            ),
          )
          .evaluate())
    element: switch (element.widget) {
      AnimatedStudioSurface(:final face) => face,
      StudioSurface(:final face) => face,
      _ => throw StateError('not a surface'),
    },
};

// How many of 24 sectors round [edge]'s centre hold a pixel of its rim (the
// band 4 points inside its edge) that reads at 1.5:1 or more between [before]
// and [after]: 24 when the light runs all the way round.
int _litSectors(
  Uint8List before,
  Uint8List after,
  int width,
  Rect edge, {
  double radius = 0,
}) {
  // The band along the part's own outline, its corners rounded as the part's
  // are: a round key's edge is a circle.
  final outer = RRect.fromRectAndRadius(
    edge.inflate(1),
    Radius.circular(radius + 1),
  );
  final inner = RRect.fromRectAndRadius(
    edge.deflate(4),
    Radius.circular(math.max(0, radius - 4)),
  );
  final sectors = <int>{};
  for (var i = 0; i + 3 < before.length; i += 4) {
    final at = Offset(
      ((i ~/ 4) % width + 0.5) / 2,
      ((i ~/ 4) ~/ width + 0.5) / 2,
    );
    if (!outer.contains(at) || inner.contains(at)) continue;
    if (_contrast(before, after, i) < 1.5) continue;
    final turn = ((at - edge.center).direction + math.pi) / (2 * math.pi);
    sectors.add((turn * 24).floor() % 24);
  }
  return sectors.length;
}

// The contrast between pixel [i] of [a] and of [b], as WCAG reads two colours.
double _contrast(Uint8List a, Uint8List b, int i) {
  double luminance(Uint8List p) {
    double channel(int v) {
      final c = v / 255;
      return c <= 0.04045
          ? c / 12.92
          : math.pow((c + 0.055) / 1.055, 2.4) * 1.0;
    }

    return 0.2126 * channel(p[i]) +
        0.7152 * channel(p[i + 1]) +
        0.0722 * channel(p[i + 2]);
  }

  final x = luminance(a), y = luminance(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

List<Rect> _focusBounds(WidgetTester tester, Widget part, String name) {
  Rect box(Finder finder) => tester.getRect(finder);
  final frame = find.byKey(_frame);
  final bounds = box(find.byWidget(part));
  switch (name) {
    case 'key':
      return [box(find.text('Save'))];
    case 'lit key':
    case 'chip':
    case 'radio':
      // Its lamp is lit already, so its rim lights as well, on the key sunk
      // by its travel.
      return [
        box(find.byType(StudioLamp).first),
        for (final MapEntry(key: element, value: face) in _faces().entries)
          if (face.rim == _rim(tester))
            _sunk(box(find.byWidget(element.widget))),
      ];
    case 'fader':
      return [Rect.fromCenter(center: bounds.center, width: 6, height: 30)];
    case 'tab':
      final words = box(find.text('Episodes'));
      return [
        Rect.fromLTRB(
          words.left - StudioSpacing.tight,
          bounds.bottom - 4,
          words.right + StudioSpacing.tight,
          bounds.bottom,
        ),
      ];
    case 'switch':
      final painter = find
          .descendant(
            of: find.byType(StudioSwitch),
            matching: find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter != null,
            ),
          )
          .last;
      return [box(painter).deflate(StudioSwitch.lip - 1)];
    case 'selector':
    case 'icon key':
    case 'floating key':
    case 'transport key':
      final lit = find.descendant(
        of: frame,
        matching: find.byWidgetPredicate(
          (w) =>
              (w is AnimatedStudioSurface && w.face.focus.a > 0) ||
              (w is StudioSurface && w.face.focus.a > 0),
        ),
      );
      return [lit.evaluate().isEmpty ? bounds : box(lit.first)];
    default:
      return [bounds];
  }
}

void _expectLight(
  (Uint8List, int) idle,
  Uint8List focused,
  List<Rect> bounds,
  Offset origin, {
  Rect? exclude,
}) {
  final (before, width) = idle;
  var lit = 0, outside = 0;
  for (var i = 0; i < before.length; i += 4) {
    if ((before[i] - focused[i]).abs() < 4 &&
        (before[i + 1] - focused[i + 1]).abs() < 4 &&
        (before[i + 2] - focused[i + 2]).abs() < 4) {
      continue;
    }
    final point =
        origin +
        Offset(((i ~/ 4) % width + 0.5) / 2, ((i ~/ 4) ~/ width + 0.5) / 2);
    if (exclude?.contains(point) ?? false) continue;
    if (bounds.any((rect) => rect.inflate(0.5).contains(point))) {
      lit++;
    } else {
      outside++;
    }
  }
  expect(lit, greaterThan(0), reason: 'The fitted light remained dark');
  expect(outside, 0, reason: 'The light escaped its housing');
}

void main() {
  setUpAll(studioLoadFonts);

  final parts = <String, Widget>{
    'key': const StudioButton('Save', onPressed: _none),
    'lit key': const StudioButton.lit('Publish', onPressed: _none),
    'icon key': const StudioIconButton(
      icon: Icon(LucideIcons.heart),
      tooltip: 'Save',
      onPressed: _none,
    ),
    'transport key': const StudioTransportKey(
      icon: Icon(LucideIcons.play),
      tooltip: 'Play',
      onPressed: _none,
    ),
    'floating key': const StudioFloatingKey(
      icon: Icon(LucideIcons.mic),
      tooltip: 'Record',
      onPressed: _none,
    ),
    'switch': StudioSwitch(
      value: true,
      semanticLabel: 'Auto',
      onChanged: (_) {},
    ),
    'chip': StudioChip(label: 'Interviews', selected: true, onSelected: (_) {}),
    'selector': StudioSegmentedButton<int>(
      semanticLabel: 'Speed',
      segments: const [
        StudioSegment(value: 0, label: '1×'),
        StudioSegment(value: 1, label: '1.5×'),
        StudioSegment(value: 2, label: '2×'),
      ],
      value: 0,
      onChanged: (_) {},
    ),
    'text field': SizedBox(
      width: 300,
      child: StudioTextField(label: 'Title', onChanged: (_) {}),
    ),
    'search field': SizedBox(
      width: 300,
      child: StudioSearchField(onChanged: (_) {}),
    ),
    'input group': SizedBox(
      width: 300,
      child: StudioInputGroup(
        label: 'Feed address',
        leading: const Text('https://'),
        onChanged: (_) {},
      ),
    ),
    'tag input': SizedBox(
      width: 300,
      child: StudioTagInput<String>(
        label: 'Guests',
        values: const [],
        onChanged: (_) {},
        labelOf: (v) => v,
      ),
    ),
    'select': SizedBox(
      width: 300,
      child: StudioSelect<String>(
        label: 'Quality',
        value: 'High',
        items: const [
          StudioSelectItem(value: 'High', label: 'High'),
          StudioSelectItem(value: 'Low', label: 'Low'),
        ],
        onChanged: (_) {},
      ),
    ),
    'tab': StudioTabBar(
      tabs: const ['Episodes', 'About'],
      selectedIndex: 0,
      onChanged: (_) {},
    ),
    'knob': StudioKnob(value: 0.5, semanticLabel: 'Monitor', onChanged: (_) {}),
    'radio': StudioRadio<int>(value: 1, groupValue: 1, onChanged: (_) {}),
    'checkbox': StudioCheckbox(value: false, onChanged: (_) {}),
    'fader': SizedBox(
      width: 250,
      child: StudioFader(value: 0.5, onChanged: (_) {}),
    ),
  };
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: part) in parts.entries) {
      testWidgets(
        'a focused $name lights its fitted control by ${brightness.name}',
        (tester) async {
          FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.alwaysTraditional;
          addTearDown(
            () => FocusManager.instance.highlightStrategy =
                FocusHighlightStrategy.automatic,
          );
          await _show(tester, part, brightness);
          final before = await _pixels(tester);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          final (after, _) = await _pixels(tester);
          _expectLight(
            before,
            after,
            _focusBounds(tester, part, name),
            tester.getTopLeft(find.byKey(_frame)),
          );
        },
      );
    }
  }

  // A part whose lamp is already lit cannot show focus by brightening it.
  // By day a latched key or chosen place is backlit, its rim glowing amber
  // where its focus light would fall, so a focused one's rim glows at full
  // strength; a chosen radio or chip, and an on switch's cap, light their
  // rim the same way, by day and by night. All the way round, some of the
  // edge's pixels read at 1.5:1 or more against the same pixels at rest, and
  // nothing changes outside the part.
  final lit = <String, Widget>{
    'latched key in a bank': StudioSegmentedButton<int>(
      segments: const [
        StudioSegment(value: 0, label: '1×'),
        StudioSegment(value: 1, label: '1.5×'),
        StudioSegment(value: 2, label: '2×'),
      ],
      value: 0,
      onChanged: (_) {},
    ),
    'latched toggle key': StudioToggleBank<String>(
      options: const ['Mute', 'Solo'],
      selected: const {'Mute'},
      labelOf: (s) => s,
      onSelectionChanged: (_) {},
    ),
    'latched icon key': const StudioIconButton(
      icon: Icon(LucideIcons.repeat),
      tooltip: 'Repeat',
      selected: true,
      onPressed: _none,
    ),
    'lit key': const StudioButton.lit('Publish', onPressed: _none),
    'lit split key': const StudioSplitKey(
      label: 'Export',
      lit: true,
      onPressed: _none,
      actions: [StudioMenuItem(label: 'Export WAV', onPressed: _none)],
    ),
    'playing transport key': const StudioTransportKey(
      icon: Icon(LucideIcons.pause),
      tooltip: 'Pause',
      lit: true,
      onPressed: _none,
    ),
    'destructive key': const StudioButton(
      'Discard',
      isDestructiveAction: true,
      onPressed: _none,
    ),
    'destructive capless key': const StudioButton.text(
      'Discard',
      isDestructiveAction: true,
      onPressed: _none,
    ),
    'checked checkbox': StudioCheckbox(value: true, onChanged: (_) {}),
    'chosen radio': StudioRadio<int>(
      value: 1,
      groupValue: 1,
      onChanged: (_) {},
    ),
    'selected chip': StudioChip(
      label: 'Interviews',
      selected: true,
      onSelected: (_) {},
    ),
    'chip, not selected': StudioChip(label: 'Music', onSelected: (_) {}),
    'switch, on': StudioSwitch(
      value: true,
      semanticLabel: 'Auto',
      onChanged: (_) {},
    ),
    'chosen place in a bar': SizedBox(
      width: 320,
      child: StudioNavigationBar(
        destinations: const [
          StudioDestination(
            icon: SizedBox.square(dimension: 18),
            label: 'Home',
          ),
          StudioDestination(
            icon: SizedBox.square(dimension: 18),
            label: 'Library',
          ),
        ],
        selectedIndex: 0,
        onDestinationSelected: (_) {},
      ),
    ),
    'chosen place in a rail': SizedBox(
      height: 240,
      child: StudioNavigationRail(
        destinations: const [
          StudioDestination(
            icon: SizedBox.square(dimension: 18),
            label: 'Home',
          ),
          StudioDestination(
            icon: SizedBox.square(dimension: 18),
            label: 'Library',
          ),
        ],
        selectedIndex: 0,
        onDestinationSelected: (_) {},
      ),
    ),
  };
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: part) in lit.entries) {
      testWidgets('a focused $name lights its edge by ${brightness.name}', (
        tester,
      ) async {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        addTearDown(
          () => FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.automatic,
        );
        await _show(tester, part, brightness);
        final (before, width) = await _pixels(tester);
        final rest = _faces();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final (after, _) = await _pixels(tester);
        final origin = tester.getTopLeft(find.byKey(_frame));
        // The rim that lights, and the part it must stay within.
        final Rect edge, whole;
        var radius = 0.0;
        if (name == 'switch, on') {
          // The cap, thrown to the end of the slot.
          final slot = tester.getRect(
            find
                .descendant(
                  of: find.byType(StudioSwitch),
                  matching: find.byWidgetPredicate(
                    (w) => w is CustomPaint && w.painter != null,
                  ),
                )
                .last,
          );
          // Its window glows faintly on focus as well.
          whole = slot;
          const cap = StudioSwitch.capSize;
          edge = Rect.fromLTWH(
            slot.right - StudioSwitch.lip - cap.width,
            slot.top + StudioSwitch.lip,
            cap.width,
            cap.height,
          );
        } else {
          // The surface whose face the focus changed.
          final changed = [
            for (final MapEntry(key: element, value: face) in _faces().entries)
              if (rest[element] != face) element,
          ];
          expect(changed, isNotEmpty, reason: 'no face took the focus');
          final box = changed.first.renderObject! as RenderBox;
          edge = box.localToGlobal(Offset.zero) & box.size;
          whole = edge;
          radius = _faces()[changed.first]!.radius;
        }
        final outline = _sunk(edge).shift(-origin);
        final within = _sunk(whole).shift(-origin);
        expect(
          _litSectors(before, after, width, outline, radius: radius),
          24,
          reason: 'The edge did not light all the way round',
        );
        var outside = 0;
        for (var i = 0; i + 3 < before.length; i += 4) {
          final at = Offset(
            ((i ~/ 4) % width + 0.5) / 2,
            ((i ~/ 4) ~/ width + 0.5) / 2,
          );
          final moved =
              (before[i] - after[i]).abs() >= 4 ||
              (before[i + 1] - after[i + 1]).abs() >= 4 ||
              (before[i + 2] - after[i + 2]).abs() >= 4;
          if (moved && !within.inflate(1).contains(at)) outside++;
        }
        expect(outside, 0, reason: 'The light escaped the part');
      });
    }
  }

  // On a row of chips with one selected, each chip in turn takes the focus:
  // its rim lights all the way round, and no lamp in the row changes, so
  // focus is never read as a selection.
  for (final brightness in Brightness.values) {
    testWidgets('a focused chip leaves its lamp to mean selected by '
        '${brightness.name}', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await _show(
        tester,
        Wrap(
          spacing: StudioSpacing.small,
          children: [
            StudioChip(label: 'Music', onSelected: (_) {}),
            StudioChip(label: 'Interviews', selected: true, onSelected: (_) {}),
            StudioChip(label: 'News', onSelected: (_) {}),
          ],
        ),
        brightness,
      );
      final (rest, width) = await _pixels(tester);
      final faces = _faces();
      final origin = tester.getTopLeft(find.byKey(_frame));
      final lamps = [
        for (final lamp in find.byType(StudioLamp).evaluate())
          (lamp.renderObject! as RenderBox).localToGlobal(Offset.zero) &
              (lamp.renderObject! as RenderBox).size,
      ];
      expect(lamps, hasLength(3));
      for (var chip = 0; chip < 3; chip++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final (focused, _) = await _pixels(tester);
        for (var i = 0; i + 3 < rest.length; i += 4) {
          final at =
              origin +
              Offset(
                ((i ~/ 4) % width + 0.5) / 2,
                ((i ~/ 4) ~/ width + 0.5) / 2,
              );
          if (!lamps.any((lamp) => lamp.inflate(1).contains(at))) continue;
          expect(
            (rest[i] - focused[i]).abs() +
                (rest[i + 1] - focused[i + 1]).abs() +
                (rest[i + 2] - focused[i + 2]).abs(),
            lessThan(4),
            reason: 'Focus on chip $chip changed a lamp',
          );
        }
        // One chip's surface takes the focus (its animated face and the face
        // it draws).
        final changed = {
          for (final MapEntry(key: element, value: face) in _faces().entries)
            if (faces[element] != face)
              (element.renderObject! as RenderBox).localToGlobal(Offset.zero): (
                element,
                face,
              ),
        };
        expect(changed, hasLength(1), reason: 'one chip takes the focus');
        final (element, face) = changed.values.first;
        final box = element.renderObject! as RenderBox;
        final edge = box.localToGlobal(Offset.zero) & box.size;
        expect(
          _litSectors(
            rest,
            focused,
            width,
            _sunk(edge).shift(-origin),
            radius: face.radius,
          ),
          24,
          reason: 'Chip $chip did not light its rim all the way round',
        );
      }
    });
  }

  // A window lights its edge however it got the focus: a press or a touch
  // gives it the typing, as Tab does.
  for (final brightness in Brightness.values) {
    testWidgets('a pressed text field lights its edge by ${brightness.name}', (
      tester,
    ) async {
      await _show(
        tester,
        SizedBox(
          width: 300,
          child: StudioTextField(label: 'Title', onChanged: (_) {}),
        ),
        brightness,
      );
      final before = await _pixels(tester);
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      final (after, _) = await _pixels(tester);
      final field = find
          .descendant(
            of: find.byType(StudioTextField),
            matching: find.byType(AnimatedStudioSurface),
          )
          .first;
      final rect = tester.getRect(field);
      _expectLight(
        before,
        after,
        [rect],
        tester.getTopLeft(find.byKey(_frame)),
        exclude: rect.deflate(StudioMetrics.focusWidth + 2),
      );
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'a menu command depresses only during a held press in ${brightness.name}',
      (tester) async {
        Future<void> show(Set<WidgetState> states) => _show(
          tester,
          SizedBox(
            width: 210,
            child: StudioMenuRow(label: 'Download', states: states),
          ),
          brightness,
        );
        double depth() => tester
            .widget<AnimatedStudioSurface>(find.byType(AnimatedStudioSurface))
            .face
            .presence;
        await show({});
        final (idle, _) = await _pixels(tester);
        for (final state in [WidgetState.hovered, WidgetState.focused]) {
          await show({state});
          final (lit, _) = await _pixels(tester);
          expect(lit, isNot(orderedEquals(idle)), reason: state.name);
          expect(depth(), 0);
        }
        await show({WidgetState.pressed});
        expect(depth(), greaterThan(0));
      },
    );
  }
}
