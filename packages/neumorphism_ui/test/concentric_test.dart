// Nested and lifted outlines are concentric, measured on what is painted (polish round 3, §2). Each part is focused by
// the keyboard (or chosen), every painter under it is replayed into a recorder that keeps its transforms, and every
// pair of box-like outlines where one sits inside the other is measured: where two adjacent sides keep the same gap d
// (a ring, a rim, a pressed-in cell inside its bank, a thumb inside its track), the corner between them must be the
// outer corner moved by d around the same centre. Along the corner's diagonal that is exactly d further in, or d√2
// when the corners are square (a square corner stays square in its ring), within 0.5 px, under every corner family
// and every stroke setting.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void _hit() {}

/// One outline as painted: its path in the screen's coordinates, and the painter that drew it.
typedef _Outline = ({Path path, Rect box, String by});

/// Replays a painter, keeping its transforms, and records the outlines it fills, strokes or clips to. Blurred shadows
/// are left out: they are the relief's light, not an outline.
class _Recorder implements Canvas {
  _Recorder(this.by, Offset origin) {
    _stack.add(Matrix4.translationValues(origin.dx, origin.dy, 0));
  }
  final String by;
  final _stack = <Matrix4>[];
  final outlines = <_Outline>[];
  Matrix4 get _m => _stack.last;

  void _add(Path path, [Paint? paint]) {
    if (paint?.maskFilter != null) return;
    final p = path.transform(_m.storage);
    outlines.add((path: p, box: p.getBounds(), by: by));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final a = invocation.positionalArguments;
    switch (invocation.memberName) {
      case #save:
      case #saveLayer:
        _stack.add(_m.clone());
        return null;
      case #restore:
        if (_stack.length > 1) _stack.removeLast();
        return null;
      case #restoreToCount:
        while (_stack.length > math.max(1, a.first as int)) {
          _stack.removeLast();
        }
        return null;
      case #getSaveCount:
        return _stack.length;
      case #translate:
        _stack.last = _m.clone()
          ..translateByDouble(a[0] as double, a[1] as double, 0, 1);
        return null;
      case #scale:
        final sx = a[0] as double;
        final sy = a.length > 1 ? (a[1] as double? ?? sx) : sx;
        _stack.last = _m.clone()..scaleByDouble(sx, sy, 1, 1);
        return null;
      case #rotate:
        _stack.last = _m.clone()..rotateZ(a[0] as double);
        return null;
      case #transform:
        _stack.last = _m.clone()
          ..multiply(Matrix4.fromFloat64List(a[0] as Float64List));
        return null;
      case #getTransform:
        return _m.storage;
      case #getLocalClipBounds:
      case #getDestinationClipBounds:
        return Rect.largest;
      case #drawPath:
        _add(a[0] as Path, a[1] as Paint);
      case #clipPath:
        final clip = a[0] as Path;
        if (_lifts.contains(by) && clip.fillType == PathFillType.evenOdd) {
          // A lift is painted outside its part, clipped to a box with the part's outline cut out: that hole is the
          // outline the lift follows.
          final contours = [
            for (final m in clip.computeMetrics()) m.extractPath(0, m.length),
          ];
          contours.sort(
            (x, y) => x.getBounds().width.compareTo(y.getBounds().width),
          );
          for (final hole in contours.take(contours.length - 1)) {
            _add(hole);
          }
        } else {
          _add(clip);
        }
      case #drawRRect:
        _add(Path()..addRRect(a[0] as RRect), a[1] as Paint);
      case #clipRRect:
        _add(Path()..addRRect(a[0] as RRect));
      case #drawDRRect:
        _add(Path()..addRRect(a[0] as RRect), a[2] as Paint);
        _add(Path()..addRRect(a[1] as RRect), a[2] as Paint);
      case #drawRect:
        _add(Path()..addRect(a[0] as Rect), a[1] as Paint);
      case #drawCircle:
        _add(
          Path()..addOval(
            Rect.fromCircle(center: a[0] as Offset, radius: a[1] as double),
          ),
          a[2] as Paint,
        );
      case #drawOval:
        _add(Path()..addOval(a[0] as Rect), a[1] as Paint);
    }
    return null;
  }
}

/// Whether focus shows under [root]: a lift painted round a part, or a groove or well deepened.
bool _focusShows(Finder root) =>
    _outlines(root).any((o) => _lifts.contains(o.by)) ||
    find
        .descendant(of: root, matching: find.byType(CustomPaint))
        .evaluate()
        .any((e) {
          final p = (e.widget as CustomPaint).painter;
          return p.runtimeType.toString() == '_CastPainter' &&
              ((p as dynamic).focus as double) > 0;
        });

/// Every outline the painters under [root] draw, in the screen's coordinates.
List<_Outline> _outlines(Finder root) {
  final found = <_Outline>[];
  for (final element
      in find
          .descendant(of: root, matching: find.byType(CustomPaint))
          .evaluate()) {
    final w = element.widget as CustomPaint;
    final box = element.renderObject! as RenderBox;
    if (!box.hasSize) continue;
    final origin = box.localToGlobal(Offset.zero);
    for (final painter in [w.painter, w.foregroundPainter]) {
      if (painter == null) continue;
      final recorder = _Recorder(painter.runtimeType.toString(), origin);
      painter.paint(recorder, box.size);
      found.addAll(recorder.outlines);
    }
  }
  return found;
}

/// A closed outline shaped like a box: it holds the points just inside the middles of its bounds' four sides. A tick or
/// a line does not.
bool _boxLike(_Outline o) {
  final b = o.box;
  if (b.shortestSide < 14) return false;
  final c = b.center;
  return [
    Offset(c.dx, b.top + 1),
    Offset(c.dx, b.bottom - 1),
    Offset(b.left + 1, c.dy),
    Offset(b.right - 1, c.dy),
    c,
  ].every(o.path.contains);
}

/// How far along the corner's 45° diagonal from [corner] (into the box, on [toward]'s side) the outline first holds a
/// point. The diagonal, not the line to the centre: on a wide box that line is shallow and misses the corner's arc.
double _entry(Path path, Offset corner, Offset toward, double reach) {
  final dir =
      Offset(toward.dx > corner.dx ? 1 : -1, toward.dy > corner.dy ? 1 : -1) /
      math.sqrt2;
  if (path.contains(corner + dir * .05)) return 0;
  var lo = 0.0, hi = reach;
  if (!path.contains(corner + dir * hi)) return double.infinity;
  for (var i = 0; i < 40; i++) {
    final mid = (lo + hi) / 2;
    if (path.contains(corner + dir * mid)) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  return hi;
}

/// The painters that lift a part on keyboard focus: a part's own, a region's, a slider's thumb's.
const _lifts = {'_FocusLift', '_Lift', '_ThumbLift'};

/// Measures every nested pair under [root], [far] apart at most; returns the faults, and how many corners it measured
/// with a focus lift in them.
(List<String>, int, int) _measure(Finder root, {double far = 8}) {
  final outlines = _outlines(root).where(_boxLike).toList();
  final faults = <String>[];
  var corners = 0, ringed = 0;
  const sqrt2 = math.sqrt2;
  for (final outer in outlines) {
    for (final inner in outlines) {
      if (identical(inner, outer)) continue;
      final o = outer.box, n = inner.box;
      final insets = [
        n.left - o.left,
        n.top - o.top,
        n.right < o.right ? o.right - n.right : -1.0,
        n.bottom < o.bottom ? o.bottom - n.bottom : -1.0,
      ];
      bool keeps(double v) => v >= .3 && v <= far;
      // Corners by their two sides: top-left, top-right, bottom-right, bottom-left.
      for (final (i, j, corner) in [
        (0, 1, o.topLeft),
        (2, 1, o.topRight),
        (2, 3, o.bottomRight),
        (0, 3, o.bottomLeft),
      ]) {
        final d = insets[i], e = insets[j];
        if (!keeps(d) || !keeps(e) || (d - e).abs() > .5) continue;
        final gap = (d + e) / 2;
        // Along the diagonal, no further than the middle of the shorter side.
        final reach = math.min(o.shortestSide, n.shortestSide + 2 * gap) * .7;
        final sOuter = _entry(outer.path, corner, o.center, reach);
        final sInner = _entry(inner.path, corner, o.center, reach);
        if (!sOuter.isFinite || !sInner.isFinite) continue;
        // The outer corner's radius from where its diagonal enters it; the inner corner is max(0, r - d) about the
        // same centre, which along the diagonal is d√2 + max(0, r - d)(√2 - 1) from the outer box's corner.
        final r = sOuter / (sqrt2 - 1);
        final expected = gap * sqrt2 + math.max(0, r - gap) * (sqrt2 - 1);
        corners++;
        if (_lifts.contains(inner.by) || _lifts.contains(outer.by)) ringed++;
        if ((sInner - expected).abs() > .5) {
          faults.add(
            '${inner.by} in ${outer.by}: gap ${gap.toStringAsFixed(2)} at the sides, '
            'corner ${(sInner - sOuter).toStringAsFixed(2)} in along the diagonal '
            '(outer radius ${r.toStringAsFixed(1)}; expected ${(expected - sOuter).toStringAsFixed(2)})',
          );
        }
      }
    }
  }
  return (faults, corners, ringed);
}

/// Parts with no line that follows another unless their stroke draws one: a radio lifts its whole row, the words with
/// the disc (that lift follows the row's own outline, checked by highlight_shape_test), and a badge sits on an
/// avatar with no line round either. At a stroke their rims nest and are measured.
const _rowRinged = {'radio', 'badge on an avatar'};

/// A grouped list's row is a band of its card, which prints no line of its own at any stroke, and the row's lift follows
/// the card's rim: nothing nests inside the band to measure, in relief or in high contrast.
const _bands = {'list row, first in a group', 'list row, last in a group'};

const _families = <String>['look'];

/// The relief alone, and the fine outline high contrast prints.
const _strokes = <String, bool>{'relief': false, 'high contrast': true};

List<NeumorphicButtonSegment<int>> _segments() => const [
  NeumorphicButtonSegment(0, 'Day'),
  NeumorphicButtonSegment(1, 'Week'),
  NeumorphicButtonSegment(2, 'Month'),
];

/// The parts polish round 3 names, each with how many Tab presses reach the mark measured (0: none, it is chosen).
final _parts = <String, (Widget Function(), int)>{
  'text field': (() => const NeumorphicTextField(label: 'Name'), 1),
  'search field': (() => const NeumorphicSearchField(hint: 'Search'), 1),
  'text area': (() => const NeumorphicTextArea(label: 'Notes'), 1),
  'select': (
    () => NeumorphicSelect<int>(
      label: 'Country',
      value: 0,
      options: const [NeumorphicMenuItem(0, 'Canada')],
      onChanged: (_) {},
    ),
    1,
  ),
  'button': (() => NeumorphicButton('Save', onPressed: _hit), 1),
  'act button': (() => NeumorphicButton.filled('Save', onPressed: _hit), 1),
  'icon button': (
    () => NeumorphicIconButton(
      NeumorphicGlyphs.plus,
      label: 'Add',
      onPressed: _hit,
    ),
    1,
  ),
  'chip': (() => NeumorphicChip('Quiet', onPressed: _hit), 1),
  'chip, chosen': (
    () => NeumorphicChip('Quiet', selected: true, onPressed: _hit),
    1,
  ),
  'checkbox': (
    () => NeumorphicCheckbox(value: true, label: 'Agree', onChanged: (_) {}),
    1,
  ),
  'radio': (
    () => NeumorphicRadioGroup<int>(
      label: 'Delivery',
      value: 0,
      options: const [
        NeumorphicRadio(0, 'Standard'),
        NeumorphicRadio(1, 'Express'),
      ],
      onChanged: (_) {},
    ),
    1,
  ),
  'switch': (
    () => NeumorphicSwitch(value: true, label: 'Alerts', onChanged: (_) {}),
    1,
  ),
  'slider': (
    () => NeumorphicSlider(label: 'Volume', value: .4, onChanged: (_) {}),
    1,
  ),
  for (final (i, place) in ['first', 'middle', 'last'].indexed) ...{
    'segmented, $place chosen': (
      () => NeumorphicSegmentedButton<int>(
        label: 'Period',
        value: i,
        segments: _segments(),
        onChanged: (_) {},
      ),
      i + 1,
    ),
    'tab bar, $place chosen': (
      () => NeumorphicTabBar(
        tabs: const ['Overview', 'Activity', 'Files'],
        selectedIndex: i,
        onChanged: (_) {},
      ),
      1,
    ),
    'latches, $place chosen': (
      () => NeumorphicLatchGroup(
        options: const [
          NeumorphicLatch('Auto'),
          NeumorphicLatch('On'),
          NeumorphicLatch('Off'),
        ],
        value: ['Auto', 'On', 'Off'][i],
        onChanged: (_) {},
      ),
      i + 1,
    ),
  },
  'stepper': (
    () => NeumorphicNumberField(value: '2', onDecrease: _hit, onIncrease: _hit),
    1,
  ),
  'pagination': (
    () => NeumorphicPagination(count: 9, page: 4, onChanged: (_) {}),
    1,
  ),
  'menu item': (
    () => NeumorphicMenu<int>(
      autofocus: true,
      items: const [
        NeumorphicMenuItem(0, 'Rename'),
        NeumorphicMenuItem(1, 'Move'),
        NeumorphicMenuItem(2, 'Delete'),
      ],
      onSelected: (_) {},
    ),
    0,
  ),
  'list row, first in a group': (
    () => NeumorphicListSection(
      children: [
        NeumorphicListTile(title: 'Profile', isFirst: true, onPressed: _hit),
        NeumorphicListTile(title: 'Security', onPressed: _hit),
      ],
    ),
    1,
  ),
  'list row, last in a group': (
    () => NeumorphicListSection(
      label: 'Account',
      children: [
        NeumorphicListTile(title: 'Profile', isFirst: true, onPressed: _hit),
        NeumorphicListTile(title: 'Security', onPressed: _hit),
      ],
    ),
    2,
  ),
  'date picker cell': (
    () => NeumorphicDatePicker(
      value: DateTime(2026, 11, 6),
      first: DateTime(2026, 11, 1),
      last: DateTime(2026, 11, 30),
      onChanged: (_) {},
    ),
    3,
  ),
  'time picker cell': (
    () => NeumorphicTimePicker(
      value: const NeumorphicTime(9, 0),
      minuteStep: 30,
      onChanged: (_) {},
    ),
    1,
  ),
  'dialog': (
    () => NeumorphicDialog(
      title: 'Save changes?',
      actions: [NeumorphicButton.filled('Save', onPressed: _hit)],
    ),
    1,
  ),
  'sheet': (
    () => SizedBox(
      height: 320,
      child: NeumorphicBottomSheet(
        title: 'Options',
        inPlace: true,
        onClose: _hit,
        actions: [NeumorphicButton.filled('Apply', onPressed: _hit)],
        child: const Text('Choose'),
      ),
    ),
    1,
  ),
  'badge on an avatar': (
    () => const NeumorphicBadge(4, child: NeumorphicAvatar('AM')),
    0,
  ),
};

/// Where a corner fails to be [outer]'s corner moved in by [d] around the same centre; null when it is.
String? _cornerFault(_Outline outer, _Outline inner, Offset corner, double d) {
  final reach =
      math.min(outer.box.shortestSide, inner.box.shortestSide + 2 * d) * .7;
  final sOuter = _entry(outer.path, corner, outer.box.center, reach);
  final sInner = _entry(inner.path, corner, outer.box.center, reach);
  if (!sOuter.isFinite || !sInner.isFinite) return 'no corner found';
  final r = sOuter / (math.sqrt2 - 1);
  final expected = d * math.sqrt2 + math.max(0, r - d) * (math.sqrt2 - 1);
  if ((sInner - expected).abs() <= .5) return null;
  return 'corner ${(sInner - sOuter).toStringAsFixed(2)} in along the diagonal, '
      'expected ${(expected - sOuter).toStringAsFixed(2)} (outer radius ${r.toStringAsFixed(1)}, d ${d.toStringAsFixed(2)})';
}

/// Checks that [inner] is [outer] moved in by one d on every side in [sides] (left, top, right, bottom), round the
/// whole part (d at most [most]), with the corners between two such sides concentric. Returns the faults.
List<String> _movedIn(
  _Outline outer,
  _Outline inner,
  List<bool> sides, {
  double most = 8,
}) {
  final o = outer.box, n = inner.box;
  final insets = [
    n.left - o.left,
    n.top - o.top,
    o.right - n.right,
    o.bottom - n.bottom,
  ];
  final shared = [
    for (var i = 0; i < 4; i++)
      if (sides[i]) insets[i],
  ];
  final faults = <String>[];
  if (shared.isEmpty) return faults;
  final d = shared.reduce((a, b) => a + b) / shared.length;
  final named = ['left', 'top', 'right', 'bottom'];
  for (var i = 0; i < 4; i++) {
    if (!sides[i]) continue;
    if ((insets[i] - d).abs() > .5 || insets[i] < -.5 || insets[i] > most) {
      faults.add(
        '${inner.by} in ${outer.by}: ${named[i]} ${insets[i].toStringAsFixed(2)} in, '
        'not one d (${[for (final v in insets) v.toStringAsFixed(2)].join(', ')}) of at most $most',
      );
    }
  }
  for (final (i, j, corner) in [
    (0, 1, o.topLeft),
    (2, 1, o.topRight),
    (2, 3, o.bottomRight),
    (0, 3, o.bottomLeft),
  ]) {
    if (!sides[i] || !sides[j]) continue;
    final fault = _cornerFault(outer, inner, corner, d);
    if (fault != null) faults.add('${inner.by} in ${outer.by}: $fault');
  }
  return faults;
}

/// A row of a list or a cell of a bank, the Tab presses that focus it, and which sides of its holder it shares (left,
/// top, right, bottom). No holder: a plain row, whose ring is its own pressed face moved out.
typedef _Whole = ({Widget Function() build, int tabs, List<bool>? sides});

final _wholes = <String, _Whole>{
  'list row, plain': (
    build: () => NeumorphicList(
      children: [
        NeumorphicListTile(title: 'Profile', isFirst: true, onPressed: _hit),
        NeumorphicListTile(title: 'Security', onPressed: _hit),
      ],
    ),
    tabs: 1,
    sides: null,
  ),
  'list row, alone in a group': (
    build: () => NeumorphicListSection(
      children: [
        NeumorphicListTile(title: 'Profile', isFirst: true, onPressed: _hit),
      ],
    ),
    tabs: 1,
    sides: [true, true, true, true],
  ),
  'list row, first in a group': (
    build: () => NeumorphicListSection(
      children: [
        NeumorphicListTile(title: 'Profile', isFirst: true, onPressed: _hit),
        NeumorphicListTile(title: 'Security', onPressed: _hit),
      ],
    ),
    tabs: 1,
    sides: [true, true, true, false],
  ),
  'list row, middle of a group under its label': (
    build: () => NeumorphicListSection(
      label: 'Account',
      children: [
        NeumorphicListTile(title: 'Profile', isFirst: true, onPressed: _hit),
        NeumorphicListTile(title: 'Security', onPressed: _hit),
        NeumorphicListTile(title: 'Devices', onPressed: _hit),
      ],
    ),
    tabs: 2,
    sides: [true, false, true, false],
  ),
  'list row, last in a group': (
    build: () => NeumorphicListSection(
      children: [
        NeumorphicListTile(title: 'Profile', isFirst: true, onPressed: _hit),
        NeumorphicListTile(title: 'Security', onPressed: _hit),
      ],
    ),
    tabs: 2,
    sides: [true, false, true, true],
  ),
  for (final (i, place) in ['first', 'middle', 'last'].indexed)
    'segmented, the $place cell focused': (
      build: () => NeumorphicSegmentedButton<int>(
        label: 'Period',
        value: i,
        segments: _segments(),
        onChanged: (_) {},
      ),
      tabs: i + 1,
      sides: [i == 0, true, i == 2, true],
    ),
};

/// The painters a part's tap draws in its face: they are not its holder.
const _tapPainters = {'_FocusLift', '_Lift', '_PressRelief', '_Overlay'};

void main() {
  setUpAll(loadNeumorphicFonts);

  // polish round 3, back (§1–4): a focus lift and a press are the part's own outline moved by one d, round the whole
  // row or cell, never a box round its words. A grouped list's row is a band of its card; a bank's cell is its bank's.
  for (final MapEntry(key: name, value: whole) in _wholes.entries) {
    for (final family in _families) {
      testWidgets(
        '$name, $family: its lift and its press are its own outline moved by one d',
        (tester) async {
          tester.view.physicalSize = const Size(520, 760);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.alwaysTraditional;
          addTearDown(
            () => FocusManager.instance.highlightStrategy =
                FocusHighlightStrategy.automatic,
          );
          final faults = <String>[];
          for (final stroke in ['none', 'fine', 'bold']) {
            final theme = NeumorphicThemeData.porcelain().copyWith(
              highContrast: _strokes[stroke],
            );
            await tester.pumpWidget(
              MaterialApp(
                key: ValueKey(stroke),
                home: NeumorphicTheme(
                  data: theme,
                  child: MediaQuery(
                    data: const MediaQueryData(
                      size: Size(520, 760),
                      disableAnimations: true,
                    ),
                    child: ColoredBox(
                      color: theme.colors.ground,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: SizedBox(
                            key: const Key('part'),
                            width: 420,
                            child: whole.build(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            for (var i = 0; i < whole.tabs; i++) {
              await tester.sendKeyEvent(LogicalKeyboardKey.tab);
              await tester.pumpAndSettle();
            }
            final root = find.byKey(const Key('part'));
            final bounds = tester.getRect(root).inflate(1);
            final rings = _outlines(root)
                .where((o) => _lifts.contains(o.by) && _boxLike(o))
                .toList();
            if (rings.length != 1) {
              faults.add('$stroke: ${rings.length} focus lifts');
              continue;
            }
            final ring = rings.single;
            // Press where the ring is, and hold.
            final finger = await tester.startGesture(ring.box.center);
            await tester.pump(const Duration(milliseconds: 400));
            final everything = _outlines(root).where(_boxLike).toList();
            final presses = everything
                .where((o) => o.by == '_PressRelief')
                .toList();
            final pressedRing = everything
                .where((o) => _lifts.contains(o.by))
                .toList();
            await finger.up();
            await tester.pumpAndSettle();
            final sides = whole.sides;
            if (sides == null) {
              // A plain row: the lift follows its pressed face, the same d on every side.
              if (presses.isEmpty || pressedRing.length != 1) {
                faults.add('$stroke: no press or no lift while pressed');
                continue;
              }
              faults.addAll(
                _movedIn(pressedRing.single, presses.first, const [
                  true,
                  true,
                  true,
                  true,
                ]).map((f) => '$stroke: $f'),
              );
              continue;
            }
            // The holder: the widest outline round the lift that its tap did not draw (the card, the bank).
            final holders =
                everything
                    .where(
                      (o) =>
                          !_tapPainters.contains(o.by) &&
                          bounds.contains(o.box.topLeft) &&
                          bounds.contains(o.box.bottomRight) &&
                          o.box.contains(ring.box.center) &&
                          o.box.width >= ring.box.width,
                    )
                    .toList()
                  ..sort(
                    (a, b) => (b.box.width * b.box.height).compareTo(
                      a.box.width * a.box.height,
                    ),
                  );
            if (holders.isEmpty) {
              faults.add('$stroke: no holder round the lift');
              continue;
            }
            final holder = holders.first;
            faults.addAll(
              _movedIn(holder, ring, sides).map((f) => '$stroke: $f'),
            );
            // A row presses its whole band, inside the card's rim; a bank's chosen cell takes no press.
            if (name.startsWith('list row')) {
              if (presses.isEmpty) {
                faults.add('$stroke: the row showed no press');
              } else {
                faults.addAll(
                  _movedIn(
                    holder,
                    presses.first,
                    sides,
                  ).map((f) => '$stroke: $f'),
                );
              }
            }
          }
          expect(faults, isEmpty, reason: faults.join('\n'));
        },
      );
    }
  }

  for (final MapEntry(key: name, value: (build, tabs)) in _parts.entries) {
    for (final family in _families) {
      testWidgets(
        '$name, $family: lifts and rims are concentric at every stroke',
        (tester) async {
          tester.view.physicalSize = const Size(520, 760);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.alwaysTraditional;
          addTearDown(
            () => FocusManager.instance.highlightStrategy =
                FocusHighlightStrategy.automatic,
          );
          final faults = <String>[];
          for (final MapEntry(key: stroke, value: strokes)
              in _strokes.entries) {
            final theme = NeumorphicThemeData.porcelain().copyWith(
              highContrast: strokes,
            );
            await tester.pumpWidget(
              MaterialApp(
                key: ValueKey(stroke),
                home: NeumorphicTheme(
                  data: theme,
                  child: MediaQuery(
                    data: const MediaQueryData(
                      size: Size(520, 760),
                      disableAnimations: true,
                    ),
                    child: ColoredBox(
                      color: theme.colors.ground,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: SizedBox(
                            key: const Key('part'),
                            width: 420,
                            child: build(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            for (var i = 0; i < tabs; i++) {
              await tester.sendKeyEvent(LogicalKeyboardKey.tab);
              await tester.pumpAndSettle();
            }
            final (found, corners, ringed) = _measure(
              find.byKey(const Key('part')),
            );
            faults.addAll(found.map((f) => '$stroke: $f'));
            final ringsRow = _rowRinged.contains(name);
            // In relief alone a part prints no rim (the settings cut took the resting rim away), so there may be
            // nothing nested to measure; high contrast draws the fine outline, which must be concentric and present.
            if (corners == 0 &&
                stroke == 'high contrast' &&
                !ringsRow &&
                !_bands.contains(name)) {
              faults.add('$stroke: no nested outline measured');
            }
            // Focus shows in the material: a lift round the part, or a field's well deepened. Never a line.
            if (tabs > 0 &&
                !ringsRow &&
                !_focusShows(find.byKey(const Key('part')))) {
              faults.add('$stroke: focus shows nothing');
            }
          }
          expect(faults, isEmpty, reason: faults.join('\n'));
        },
      );
    }
  }
}
