// A part's own corners (cornerFreedom perCorner) and the theme's shapes (shapeScheme within Neumorphism's bands): every
// shaped part takes its style's corners over its own, mirrored right to left and held round (a square corner goes to the
// least, 6), a style's shape winning; a strip of cells takes them on its ends; a menu's first and last rows stand
// concentric with its corners; a change of corners, or of the theme's scale, eases with no snap.
import 'dart:typed_data';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

const _shotKey = ValueKey('shot');

// Only the top start corner large; the others as square as the look goes.
const _start = RawCorners.only(topStart: RawCorner.large);

// The top start and the bottom end square (held to the least); the other two the part's own.
const _diagonal = RawCorners(
  topStart: RawCorner.none,
  bottomEnd: RawCorner.none,
);

const _opaque = Color(0xFF203040);

NeumorphicStyle _cut(RawCorners corners) =>
    NeumorphicStyle(corners: WidgetStatePropertyAll(corners));

void _none() {}

void _ignore(Object? _) {}

Widget _app(
  Widget part,
  TextDirection direction, {
  NeumorphicThemeData? theme,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) => NeumorphicHost(
    theme: theme,
    brightness: Brightness.light,
    child: Directionality(textDirection: direction, child: app!),
  ),
  home: Material(
    type: MaterialType.transparency,
    child: Center(
      child: RepaintBoundary(
        key: _shotKey,
        child: Padding(padding: const EdgeInsets.all(32), child: part),
      ),
    ),
  ),
);

Future<void> _show(
  WidgetTester tester,
  Widget part,
  TextDirection direction, {
  NeumorphicThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(720, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // A fresh tree: nothing left open from the last part.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(_app(part, direction, theme: theme));
  await tester.pumpAndSettle();
}

Iterable<Element> _outlines() => find
    .descendant(
      of: find.byKey(_shotKey),
      matching: find.byType(AnimatedNeumorphicShape),
    )
    .evaluate();

OutlinedBorder? _shapeOf(Element e) =>
    (e.widget as AnimatedNeumorphicShape).shape;

// An outline drawn to an app's corners: a part's own, or a cell of a bank drawn to them.
BorderRadius? _cornersOf(OutlinedBorder? shape) => switch (shape) {
  NeumorphicRoundedBorder(:final borderRadius) => borderRadius,
  NeumorphicCellBorder(:final bank) => _cornersOf(bank),
  _ => null,
};

List<Element> _given() => [
  for (final e in _outlines())
    if (_cornersOf(_shapeOf(e)) != null) e,
];

Rect _rectOf(Element e) {
  final box = e.renderObject! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

// Which screen corners (top left, top right, bottom left, bottom right) are held to the least corner.
List<bool> _tight(BorderRadius r) => [
  r.topLeft,
  r.topRight,
  r.bottomLeft,
  r.bottomRight,
].map((x) => (x.x - NeumorphicRadii.least).abs() < .01).toList();

// The tight screen corners [cut] makes in [direction].
List<bool> _expected(RawCorners cut, TextDirection direction) {
  final ltr = direction == TextDirection.ltr;
  if (cut == _start) return [!ltr, ltr, true, true];
  return [ltr, !ltr, !ltr, ltr];
}

// Each shaped part, built with a style; whether its own corner is the least (so only [_start] tells).
final Map<String, (Widget Function(NeumorphicStyle s), bool)> _parts = {
  'button': (
    (s) => NeumorphicButton('Share', onPressed: _none, style: s),
    false,
  ),
  'act': (
    (s) => NeumorphicButton.filled('Save', onPressed: _none, style: s),
    false,
  ),
  'chip': (
    (s) => NeumorphicChip('Vegetarian', onPressed: _none, style: s),
    false,
  ),
  'card': (
    (s) => SizedBox(
      width: 260,
      child: NeumorphicCard(title: 'On pace', style: s),
    ),
    false,
  ),
  'well': (
    (s) => SizedBox(
      width: 260,
      child: NeumorphicWell(style: s, child: const Text('On pace')),
    ),
    false,
  ),
  'text field': (
    (s) => SizedBox(
      width: 260,
      child: NeumorphicTextField(
        labelText: 'Name',
        onChanged: _ignore,
        style: s,
      ),
    ),
    false,
  ),
  'select': (
    (s) => SizedBox(
      width: 260,
      child: NeumorphicSelect<String>(
        labelText: 'Space',
        options: const [NeumorphicMenuItem('quiet', 'Quiet room')],
        value: 'quiet',
        onChanged: _ignore,
        style: s,
      ),
    ),
    false,
  ),
  'badge': (
    (s) => NeumorphicBadge(
      3,
      semanticLabel: '3 unread',
      style: s,
      child: const Icon(NeumorphicGlyphs.bell),
    ),
    false,
  ),
  'checkbox': (
    (s) => NeumorphicCheckbox(
      value: true,
      semanticLabel: 'Walk',
      onChanged: _ignore,
      style: s,
    ),
    true,
  ),
  'snack bar': (
    (s) => SizedBox(
      width: 340,
      child: NeumorphicSnackBar('Saved to Drafts', style: s),
    ),
    false,
  ),
};

// The shot's paint, taken at four pixels a point: a point's red, green, blue and alpha (the wall round a part is left
// clear, so a cast shade is its alpha).
Future<List<int> Function(Offset)> _paintOf(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shotKey),
  );
  final origin = boundary.localToGlobal(Offset.zero);
  const scale = 4.0;
  final shot = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: scale);
    final bytes = (await image.toByteData())!;
    final width = image.width;
    image.dispose();
    return (bytes, width);
  });
  final (ByteData bytes, int width) = shot!;
  return (Offset p) {
    final x = ((p.dx - origin.dx) * scale).floor();
    final y = ((p.dy - origin.dy) * scale).floor();
    final i = 4 * (y * width + x);
    return [for (var k = 0; k < 4; k++) bytes.getUint8(i + k)];
  };
}

// Whether a point is drawn in [_opaque], [within] a summed channel distance.
Future<bool Function(Offset)> _inkOf(
  WidgetTester tester, {
  int within = 48,
}) async {
  final paint = await _paintOf(tester);
  return (Offset p) {
    final [r, g, b, _] = paint(p);
    return (r - 0x20).abs() + (g - 0x30).abs() + (b - 0x40).abs() < within;
  };
}

// How far in along the diagonal from [rect]'s top left the face's ink begins: about 0.29 of the corner's radius.
Future<double> _cornerDepth(WidgetTester tester, Rect rect) async {
  final ink = await _inkOf(tester);
  for (var i = 0.0; i < rect.shortestSide / 2; i += 0.25) {
    if (ink(rect.topLeft + Offset(i + .125, i + .125))) return i;
  }
  return rect.shortestSide / 2;
}

void main() {
  test(
    'every corner of a Neumorphism part may take its own step, held round',
    () {
      final limits = NeumorphicThemeData.shapeLimits;
      expect(limits.cornerFreedom, RawCornerFreedom.perCorner);
      expect(
        limits.clampCorners(
          const RawCorners(
            topStart: RawCorner.full,
            topEnd: RawCorner.none,
            bottomEnd: RawCorner.extraLarge,
          ),
          base: const RawCorners.all(RawCorner.medium),
          look: 'Neumorphism',
        ),
        const RawCorners(
          topStart: RawCorner.full,
          // A moulded surface has no point: square goes to the least corner.
          topEnd: RawCorner.extraSmall,
          bottomStart: RawCorner.medium,
          // Extra large is open, with large's band.
          bottomEnd: RawCorner.extraLarge,
        ),
      );
    },
  );

  for (final MapEntry(key: name, value: (build, least)) in _parts.entries) {
    testWidgets("a $name takes its style's corners, mirrored right to left", (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await _show(tester, build(const NeumorphicStyle()), direction);
        expect(_given(), isEmpty, reason: 'its own corners, ${direction.name}');
        for (final cut in [_start, if (!least) _diagonal]) {
          await _show(tester, build(_cut(cut)), direction);
          final given = _given();
          expect(given, isNotEmpty, reason: '$cut, ${direction.name}');
          for (final e in given) {
            expect(
              _tight(_cornersOf(_shapeOf(e))!),
              _expected(cut, direction),
              reason: '$cut, ${direction.name}',
            );
          }
          // Its press, its focus and its face are drawn to one outline.
          expect(
            given.map((e) => _shapeOf(e)).toSet(),
            hasLength(1),
            reason: '$cut, ${direction.name}',
          );
        }
      }
    });
  }

  for (final (name, part) in [
    (
      'switch',
      (NeumorphicStyle s) => NeumorphicSwitch(
        value: true,
        onChanged: _ignore,
        semanticLabel: 'Face ID',
        style: s,
      ),
    ),
    (
      'round key',
      (NeumorphicStyle s) => NeumorphicRoundButton(
        NeumorphicGlyphs.info,
        semanticLabel: 'Share',
        onPressed: _none,
        style: s,
      ),
    ),
  ]) {
    testWidgets("a $name keeps its own round: its geometry is the part", (
      tester,
    ) async {
      await _show(tester, part(_cut(_diagonal)), TextDirection.ltr);
      expect(_given(), isEmpty);
    });
  }

  testWidgets("a part's face is painted to its corners", (tester) async {
    for (final direction in TextDirection.values) {
      await _show(
        tester,
        const SizedBox(
          width: 260,
          child: NeumorphicCard(
            title: 'On pace',
            style: NeumorphicStyle(
              fill: WidgetStatePropertyAll(_opaque),
              corners: WidgetStatePropertyAll(_diagonal),
            ),
          ),
        ),
        direction,
      );
      final rect = _rectOf(_given().first);
      // The face's own ink, not the dark relief its fill casts beside it.
      final ink = await _inkOf(tester, within: 12);
      final ltr = direction == TextDirection.ltr;
      // 2.5 in from each screen corner: the face's ink where the corner is held to the least, the wall where it is
      // the card's own round.
      const d = 2.5;
      expect(
        [
          ink(rect.topLeft + const Offset(d, d)),
          ink(rect.topRight + const Offset(-d, d)),
          ink(rect.bottomLeft + const Offset(d, -d)),
          ink(rect.bottomRight + const Offset(-d, -d)),
        ],
        [ltr, !ltr, !ltr, ltr],
        reason: direction.name,
      );
    }
  });

  testWidgets("an app's corners redraw a part and never move its words", (
    tester,
  ) async {
    for (final name in ['button', 'act', 'chip', 'text field', 'select']) {
      final (build, _) = _parts[name]!;
      Rect words() => tester.getRect(
        find
            .descendant(
              of: find.byKey(_shotKey),
              matching: find.byType(RichText),
            )
            .first,
      );
      Size size() => tester.getSize(find.byKey(_shotKey));
      await _show(tester, build(const NeumorphicStyle()), TextDirection.ltr);
      final (ownWords, ownSize) = (words(), size());
      await _show(tester, build(_cut(_diagonal)), TextDirection.ltr);
      expect(words(), ownWords, reason: name);
      expect(size(), ownSize, reason: name);
    }
  });

  testWidgets("a style's shape wins over its corners", (tester) async {
    const shape = NeumorphicRoundedBorder(radius: 8);
    await _show(
      tester,
      const NeumorphicButton(
        'Save',
        onPressed: _none,
        style: NeumorphicStyle(
          shape: WidgetStatePropertyAll(shape),
          corners: WidgetStatePropertyAll(_diagonal),
        ),
      ),
      TextDirection.ltr,
    );
    expect(_given(), isEmpty);
    expect(_outlines().map(_shapeOf), contains(shape));
  });

  testWidgets("an app's corners are drawn in the theme's scale", (
    tester,
  ) async {
    final theme = NeumorphicThemeData.porcelain().copyWith(
      shapeScheme: NeumorphicThemeData.defaultShapeScheme.copyWith(
        corners: NeumorphicThemeData.defaultShapeScheme.corners.copyWith(
          large: 28,
        ),
      ),
    );
    await _show(
      tester,
      NeumorphicButton('Save', onPressed: _none, style: _cut(_start)),
      TextDirection.ltr,
      theme: theme,
    );
    final r = _cornersOf(_shapeOf(_given().first))!;
    expect(r.topLeft, const Radius.circular(28));
    expect(r.bottomRight, const Radius.circular(NeumorphicRadii.least));
  });

  testWidgets("a strip's ends take its corners; the seams stay", (
    tester,
  ) async {
    Widget strip({NeumorphicStyle? style}) => NeumorphicSegmentedButton<String>(
      semanticLabel: 'Range',
      segments: const [
        NeumorphicButtonSegment('a', 'Day'),
        NeumorphicButtonSegment('b', 'Week'),
        NeumorphicButtonSegment('c', 'Month'),
      ],
      value: 'b',
      onChanged: _ignore,
      style: style,
    );
    List<(Element, NeumorphicCellBorder)> cells() => [
      for (final e in _outlines())
        if (_shapeOf(e) case final NeumorphicCellBorder cell) (e, cell),
    ]..sort((a, b) => _rectOf(a.$1).left.compareTo(_rectOf(b.$1).left));
    // The middle cell's outline in its own box.
    Path middle(TextDirection direction) {
      final (e, cell) = cells()[1];
      return cell.getOuterPath(
        Offset.zero & _rectOf(e).size,
        textDirection: direction,
      );
    }

    for (final direction in TextDirection.values) {
      await _show(tester, strip(style: _cut(_diagonal)), direction);
      expect(cells(), hasLength(3), reason: direction.name);
      for (final (_, cell) in cells()) {
        // Every cell is cut from the bank, which takes the corners.
        expect(_tight(_cornersOf(cell)!), _expected(_diagonal, direction));
      }
      final size = _rectOf(cells()[1].$1).size;
      final cut = middle(direction);
      await _show(tester, strip(), direction);
      final own = middle(direction);
      // The middle cell meets its neighbours on both sides: drawn as it is without the corners, its seams too.
      final moved = [
        for (var x = .5; x < size.width; x += 1)
          for (var y = .5; y < size.height; y += 1)
            if (cut.contains(Offset(x, y)) != own.contains(Offset(x, y)))
              Offset(x, y),
      ];
      expect(moved, isEmpty, reason: direction.name);
    }
  });

  testWidgets(
    "a menu's first and last rows stand concentric with its corners",
    (tester) async {
      final theme = NeumorphicThemeData.porcelain().copyWith(
        menuTheme: _cut(_diagonal),
      );
      for (final direction in TextDirection.values) {
        final ltr = direction == TextDirection.ltr;
        await _show(
          tester,
          const NeumorphicMenu<String>(
            items: [
              NeumorphicMenuItem('a', 'Rename'),
              NeumorphicMenuItem('b', 'Move'),
              NeumorphicMenuItem('c', 'Delete'),
            ],
            onSelected: _ignore,
          ),
          direction,
          theme: theme,
        );
        final given = _given();
        final menu = given.reduce(
          (a, b) => _rectOf(a).height >= _rectOf(b).height ? a : b,
        );
        expect(
          _tight(_cornersOf(_shapeOf(menu))!),
          _expected(_diagonal, direction),
        );
        final rows = given.where((e) => _shapeOf(e) != _shapeOf(menu)).toList();
        final mid = _rectOf(menu).center.dy;
        // The first row takes the menu's top start corner, the last its bottom end; the middle row keeps its own.
        expect(rows.where((r) => _rectOf(r).top < mid), isNotEmpty);
        expect(rows.where((r) => _rectOf(r).top > mid), isNotEmpty);
        expect(
          rows.where(
            (r) =>
                _rectOf(r).center.dy > _rectOf(menu).top + 60 &&
                _rectOf(r).center.dy < _rectOf(menu).bottom - 60,
          ),
          isEmpty,
          reason: 'the middle row is its own',
        );
        final outer = _cornersOf(_shapeOf(menu))!;
        for (final row in rows) {
          final first = _rectOf(row).top < mid;
          final inner = _cornersOf(_shapeOf(row))!;
          expect(
            _tight(inner),
            first
                ? (ltr
                      ? [true, false, false, false]
                      : [false, true, false, false])
                : (ltr
                      ? [false, false, false, true]
                      : [false, false, true, false]),
            reason: '${first ? 'first' : 'last'} row, ${direction.name}',
          );
          // Concentric: a row's round corners are the menu's, its inset less.
          final (a, b) = first
              ? (ltr
                    ? (inner.topRight, outer.topRight)
                    : (inner.topLeft, outer.topLeft))
              : (ltr
                    ? (inner.bottomLeft, outer.bottomLeft)
                    : (inner.bottomRight, outer.bottomRight));
          expect(a.x, lessThan(b.x));
        }
      }
    },
  );

  test('a change of corners lerps corner by corner, no snap', () {
    const own = NeumorphicRoundedBorder(radius: 12);
    const given = NeumorphicRoundedBorder(
      radius: 12,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(6),
        topRight: Radius.circular(12),
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(24),
      ),
    );
    final mid = OutlinedBorder.lerp(own, given, .5)! as NeumorphicRoundedBorder;
    expect(mid.borderRadius!.topLeft.x, 9);
    expect(mid.borderRadius!.bottomRight.x, 18);
    final back =
        OutlinedBorder.lerp(given, own, .25)! as NeumorphicRoundedBorder;
    expect(back.borderRadius!.topLeft.x, 7.5);
  });

  testWidgets("a face moves between its own corners and an app's, no snap", (
    tester,
  ) async {
    // Hovered, the key holds every corner to the least; it eases there.
    final style = NeumorphicStyle(
      fill: const WidgetStatePropertyAll(_opaque),
      corners: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered)
            ? const RawCorners.all(RawCorner.none)
            : null,
      ),
    );
    await _show(
      tester,
      SizedBox(
        width: 200,
        child: NeumorphicButton.filled('Save', onPressed: _none, style: style),
      ),
      TextDirection.ltr,
    );
    final rect = _rectOf(_outlines().first);
    final rest = await _cornerDepth(tester, rect);
    expect(rest, greaterThan(3), reason: 'its own round at rest');
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: rect.center);
    addTearDown(mouse.removePointer);
    await tester.pump();
    final depths = <double>[rest];
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      depths.add(await _cornerDepth(tester, rect));
    }
    await tester.pumpAndSettle();
    final held = await _cornerDepth(tester, rect);
    expect(held, lessThan(rest - 1), reason: 'the least once hovered');
    final most = (rest - held) * .45 + .5;
    for (var i = 1; i < depths.length; i++) {
      expect(
        (depths[i] - depths[i - 1]).abs(),
        lessThanOrEqualTo(most),
        reason: 'frame $i of $depths',
      );
    }
    expect(
      depths.where((d) => d > held + .2 && d < rest - .2).length,
      greaterThan(1),
    );
  });

  group("the theme's shapes", () {
    const least = RawCornerScale(
      extraSmall: 6,
      small: 6,
      medium: 8,
      large: 14,
      extraLarge: 20,
      fullMaxRadius: 24,
    );
    const most = RawCornerScale(
      extraSmall: 6,
      small: 10,
      medium: 16,
      large: 28,
      extraLarge: 20,
      fullMaxRadius: 24,
    );

    for (final (end, scale, slab, control) in [
      ('least', least, 14.0, 8.0),
      ('most', most, 28.0, 16.0),
    ]) {
      testWidgets("a card and a field follow the theme at its $end", (
        tester,
      ) async {
        await _show(
          tester,
          const SizedBox(
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphicCard(title: 'On pace'),
                SizedBox(height: 16),
                NeumorphicTextField(labelText: 'Name'),
              ],
            ),
          ),
          TextDirection.ltr,
          theme: NeumorphicThemeData.porcelain().copyWith(
            shapeScheme: NeumorphicThemeData.defaultShapeScheme.copyWith(
              corners: scale,
            ),
          ),
        );
        final radii = {
          for (final e in _outlines())
            if (_shapeOf(e) case NeumorphicRoundedBorder(:final radius)) radius,
        };
        expect(radii, containsAll([slab, control]));
      });
    }

    testWidgets("a theme's depth casts the relief deeper or shallower", (
      tester,
    ) async {
      final shade = <double, int>{};
      for (final depth in [.5, 1.5]) {
        await _show(
          tester,
          const SizedBox(width: 260, child: NeumorphicCard(title: 'On pace')),
          TextDirection.ltr,
          theme: NeumorphicThemeData.porcelain().copyWith(
            shapeScheme: NeumorphicThemeData.defaultShapeScheme.copyWith(
              depth: depth,
            ),
          ),
        );
        final card = _rectOf(_outlines().first);
        final paint = await _paintOf(tester);
        // The shade cast under the card's bottom end, summed down 24 points.
        var sum = 0;
        for (var d = 1; d <= 24; d++) {
          sum += paint(card.bottomRight + Offset(-24, d + .125))[3];
        }
        shade[depth] = sum;
      }
      expect(shade[1.5]!, greaterThan(shade[.5]! * 1.2), reason: '$shade');
    });

    testWidgets('a theme switched from one band end to the other eases', (
      tester,
    ) async {
      Widget card(RawCornerScale scale) => _app(
        const SizedBox(
          width: 260,
          child: NeumorphicCard(
            title: 'On pace',
            style: NeumorphicStyle(fill: WidgetStatePropertyAll(_opaque)),
          ),
        ),
        TextDirection.ltr,
        theme: NeumorphicThemeData.porcelain().copyWith(
          shapeScheme: NeumorphicThemeData.defaultShapeScheme.copyWith(
            corners: scale,
          ),
        ),
      );
      tester.view.physicalSize = const Size(720, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(card(least));
      await tester.pumpAndSettle();
      final rect = _rectOf(_outlines().first);
      final from = await _cornerDepth(tester, rect);
      await tester.pumpWidget(card(most));
      final depths = <double>[from];
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
        depths.add(await _cornerDepth(tester, rect));
      }
      await tester.pumpAndSettle();
      final to = await _cornerDepth(tester, rect);
      // A card's corner is the slab: from 14 to 28.
      expect(to, greaterThan(from + 2.5), reason: 'from 14 to 28');
      final step = (to - from) * .45 + .5;
      for (var i = 1; i < depths.length; i++) {
        expect(depths[i], greaterThanOrEqualTo(depths[i - 1] - .5));
        expect(
          depths[i] - depths[i - 1],
          lessThanOrEqualTo(step),
          reason: 'frame $i of $depths',
        );
      }
      expect(
        depths.where((d) => d > from + .2 && d < to - .2).length,
        greaterThan(1),
      );
    });
  });
}
