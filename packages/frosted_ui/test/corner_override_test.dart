// A part's own corners (cornerFreedom perCorner) and the theme's shapes
// (shapeScheme within Frosted's bands): every shaped part takes its style's
// corners over its own, mirrored right to left, a style's shape winning; a
// strip of pieces takes them on its ends; a menu's rows stand concentric
// with its corners; a change of corners eases, with no snap.
import 'dart:typed_data';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';
import 'package:material_ui/material_ui.dart'
    show MaterialApp, Material, MaterialType;

const _shotKey = ValueKey('shot');

// Only the top start corner round (large); the others square.
const _start = RawCorners.only(topStart: RawCorner.large);

// The top start and the bottom end square; the other two the part's own.
const _diagonal = RawCorners(
  topStart: RawCorner.none,
  bottomEnd: RawCorner.none,
);

FrostedStyle _cut(RawCorners corners) =>
    FrostedStyle(corners: WidgetStatePropertyAll(corners));

void _none() {}

void _ignore(Object? _) {}

const _places = [
  FrostedNavItem(FrostedGlyphs.house, 'Home'),
  FrostedNavItem(FrostedGlyphs.wallet, 'Accounts'),
];

Widget _app(Widget part, TextDirection direction, {FrostedThemeData? theme}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) => FrostedHost(
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
  FrostedThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(720, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // A fresh tree: nothing left open from the last part.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(_app(part, direction, theme: theme));
  await tester.pumpAndSettle();
}

Iterable<Element> _faces() => find
    .descendant(of: find.byKey(_shotKey), matching: find.byType(FrostedFace))
    .evaluate();

// The outline a face, a press or a painted box is drawn to.
OutlinedBorder? _shapeOf(Element e) => switch (e.widget) {
  final FrostedFace face => face.shape,
  final FrostedPressable press => press.shape,
  DecoratedBox(decoration: ShapeDecoration(:final OutlinedBorder shape)) =>
    shape,
  _ => null,
};

// The faces, presses and painted boxes drawn to an app's corners.
List<Element> _given() => [
  for (final e
      in find
          .descendant(
            of: find.byKey(_shotKey),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is FrostedFace ||
                  w is FrostedPressable ||
                  w is DecoratedBox,
            ),
          )
          .evaluate())
    if (_shapeOf(e) is RawCornerBorder) e,
];

// The faces alone drawn to an app's corners.
List<Element> _faceGiven() => [
  for (final e in _given())
    if (e.widget is FrostedFace) e,
];

Rect _rectOf(Element e) {
  final box = e.renderObject! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

// Which screen corners of the face (top left, top right, bottom left, bottom
// right) are square, as the face draws its outline in its own reading
// direction.
List<bool> _square(Element e) {
  final box = e.renderObject! as RenderBox;
  final rect = Offset.zero & box.size;
  final path = _shapeOf(e)!
      .getOuterPath(rect, textDirection: Directionality.maybeOf(e));
  const d = 0.5;
  return [
    path.contains(rect.topLeft + const Offset(d, d)),
    path.contains(rect.topRight + const Offset(-d, d)),
    path.contains(rect.bottomLeft + const Offset(d, -d)),
    path.contains(rect.bottomRight + const Offset(-d, -d)),
  ];
}

// The square screen corners [cut] makes in [direction].
List<bool> _expected(RawCorners cut, TextDirection direction) {
  final ltr = direction == TextDirection.ltr;
  if (cut == _start) return [!ltr, ltr, true, true];
  return [ltr, !ltr, !ltr, ltr];
}

// Each shaped part, built with a style.
final Map<String, Widget Function(FrostedStyle s)> _parts = {
  'glass button': (s) =>
      FrostedButton.glass('Share', onPressed: _none, style: s),
  'icon button': (s) => FrostedIconButton(
    FrostedGlyphs.share,
    semanticLabel: 'Share',
    onPressed: _none,
    style: s,
  ),
  'chip': (s) =>
      FrostedChip('Vegetarian', selected: true, onPressed: _none, style: s),
  'card': (s) => SizedBox(
    width: 260,
    child: FrostedCard(style: s, child: const Text('On pace')),
  ),
  'text field': (s) => SizedBox(
    width: 260,
    child: FrostedTextField(
      labelText: 'Name',
      value: 'Lisbon',
      onChanged: _ignore,
      style: s,
    ),
  ),
  'select': (s) => SizedBox(
    width: 260,
    child: FrostedSelect<String>(
      labelText: 'Room',
      options: const [
        FrostedSelectOption('k', 'Kitchen'),
        FrostedSelectOption('s', 'Study'),
      ],
      value: 'k',
      onChanged: _ignore,
      style: s,
    ),
  ),
  'avatar': (s) =>
      FrostedAvatar('MH', name: 'Profile', onPressed: _none, style: s),
  'badge': (s) =>
      FrostedBadge(3, style: s, child: const Icon(FrostedGlyphs.house)),
  'checkbox': (s) => FrostedCheckbox(
    value: true,
    semanticLabel: 'Walk',
    onChanged: _ignore,
    style: s,
  ),
  'option': (s) => SizedBox(
    width: 260,
    child: FrostedOption(
      label: 'Dining out',
      selected: true,
      onPressed: _none,
      style: s,
    ),
  ),
  'tab bar': (s) => FrostedTabBar(
    tabs: const ['Spending', 'Income'],
    selectedIndex: 0,
    onChanged: _ignore,
    style: s,
  ),
  'navigation bar': (s) => SizedBox(
    width: 390,
    child: FrostedNavigationBar(
      items: _places,
      selectedIndex: 0,
      onDestinationSelected: _ignore,
      style: s,
    ),
  ),
  'dialog': (s) => SizedBox(
    width: 340,
    child: FrostedDialog(
      title: 'Freeze this card?',
      message: 'Payments stop until you unfreeze it.',
      confirmLabel: 'Freeze',
      cancelLabel: 'Cancel',
      onConfirm: _none,
      onCancel: _none,
      style: s,
    ),
  ),
  'snack bar': (s) =>
      SizedBox(width: 340, child: FrostedSnackBar('Saved to Drafts', style: s)),
};

// The fill of the shot's paint at a point, taken at four pixels a point.
Future<double Function(Offset)> _alphaOf(WidgetTester tester) async {
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
    return bytes.getUint8(4 * (y * width + x) + 3) / 255;
  };
}

// How far in along the diagonal from [rect]'s top left the paint begins:
// 0 for a square corner, about 0.29 of the radius for a round one.
Future<double> _cornerDepth(WidgetTester tester, Rect rect) async {
  final alpha = await _alphaOf(tester);
  final ref = alpha(rect.center);
  for (var i = 0.0; i < rect.shortestSide / 2; i += 0.25) {
    if (alpha(rect.topLeft + Offset(i + .125, i + .125)) > ref * .6) return i;
  }
  return rect.shortestSide / 2;
}

const _opaque = Color(0xFF203040);

void main() {
  test('every corner of a Frosted part may take its own step', () {
    expect(
      FrostedThemeData.shapeLimits.cornerFreedom,
      RawCornerFreedom.perCorner,
    );
    const given = RawCorners(
      topStart: RawCorner.full,
      topEnd: RawCorner.none,
      bottomEnd: RawCorner.extraLarge,
    );
    expect(
      FrostedThemeData.shapeLimits.clampCorners(
        given,
        base: const RawCorners.all(RawCorner.medium),
        look: 'Frosted',
      ),
      const RawCorners(
        topStart: RawCorner.full,
        topEnd: RawCorner.none,
        bottomStart: RawCorner.medium,
        bottomEnd: RawCorner.extraLarge,
      ),
    );
  });

  for (final MapEntry(key: name, value: build) in _parts.entries) {
    testWidgets("a $name takes its style's corners, mirrored right to left", (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await _show(tester, build(const FrostedStyle()), direction);
        expect(_given(), isEmpty, reason: 'its own corners, ${direction.name}');
        for (final cut in [_start, _diagonal]) {
          await _show(tester, build(_cut(cut)), direction);
          final given = _given();
          expect(given, isNotEmpty, reason: '$cut, ${direction.name}');
          for (final face in given) {
            expect(
              _square(face),
              _expected(cut, direction),
              reason: '$cut, ${direction.name}',
            );
          }
        }
      }
    });
  }

  for (final (name, part) in [
    (
      'switch',
      (FrostedStyle s) => FrostedSwitch(
        value: true,
        onChanged: _ignore,
        semanticLabel: 'Face ID',
        style: s,
      ),
    ),
    (
      'slider',
      (FrostedStyle s) => SizedBox(
        width: 260,
        child: FrostedSlider(
          value: 40,
          max: 100,
          onChanged: _ignore,
          semanticLabel: 'Alert at',
          style: s,
        ),
      ),
    ),
  ]) {
    testWidgets("a $name's bead stays a round drop of glass", (tester) async {
      await _show(tester, part(_cut(_diagonal)), TextDirection.ltr);
      expect(_given(), isEmpty);
    });
  }

  testWidgets("a part's paint and its ink follow its corners", (tester) async {
    for (final direction in TextDirection.values) {
      await _show(
        tester,
        const FrostedButton.glass(
          'Save',
          onPressed: _none,
          style: FrostedStyle(
            fill: WidgetStatePropertyAll(_opaque),
            corners: WidgetStatePropertyAll(_diagonal),
          ),
        ),
        direction,
      );
      final face = _given().first;
      final rect = _rectOf(face);
      final alpha = await _alphaOf(tester);
      final ltr = direction == TextDirection.ltr;
      // 1 in from each screen corner: paint where the corner is square, the
      // ground where it is round.
      final painted = [
        alpha(rect.topLeft + const Offset(1, 1)),
        alpha(rect.topRight + const Offset(-1.25, 1)),
        alpha(rect.bottomLeft + const Offset(1, -1.25)),
        alpha(rect.bottomRight + const Offset(-1.25, -1.25)),
      ].map((a) => a > .6).toList();
      expect(painted, [ltr, !ltr, !ltr, ltr], reason: direction.name);
      // Its press and its focus are drawn to the same outline.
      final pressable = tester.widget<FrostedPressable>(
        find
            .descendant(
              of: find.byKey(_shotKey),
              matching: find.byType(FrostedPressable),
            )
            .first,
      );
      expect(pressable.shape, _shapeOf(face));
    }
  });

  testWidgets("the ink act keeps its pill: the theme's corners pass it by", (
    tester,
  ) async {
    final theme = FrostedThemeData.opal().copyWith(
      components: const FrostedComponentThemes(
        button: FrostedStyle(corners: WidgetStatePropertyAll(_diagonal)),
      ),
    );
    await _show(
      tester,
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FrostedButton('Save', onPressed: _none),
          FrostedButton.glass('Share', onPressed: _none),
        ],
      ),
      TextDirection.ltr,
      theme: theme,
    );
    final given = _given();
    expect(given, isNotEmpty, reason: 'the glass act takes them');
    final ink = _rectOf(
      find
          .descendant(
            of: find.byKey(_shotKey),
            matching: find.byType(FrostedFace),
          )
          .evaluate()
          .first,
    );
    for (final e in given) {
      expect(_rectOf(e).overlaps(ink.deflate(1)), isFalse);
    }
  });

  testWidgets('own corners that square the ink act fail an assert', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        FrostedButton('Save', onPressed: _none, style: _cut(_diagonal)),
        TextDirection.ltr,
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets("a style's shape wins, as given, outside Frosted's bands", (
    tester,
  ) async {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(3)),
    );
    await _show(
      tester,
      const FrostedButton.glass(
        'Save',
        onPressed: _none,
        style: FrostedStyle(
          shape: WidgetStatePropertyAll(shape),
          corners: WidgetStatePropertyAll(_diagonal),
        ),
      ),
      TextDirection.ltr,
    );
    expect(_given(), isEmpty);
    expect(_faces().map(_shapeOf), contains(shape));
  });

  testWidgets("an app's corners are drawn in the theme's scale", (
    tester,
  ) async {
    final theme = FrostedThemeData.opal().copyWith(
      shapeScheme: const RawShapeScheme(
        corners: RawCornerScale(
          extraSmall: 6,
          small: 10,
          medium: 12,
          large: 24,
          extraLarge: 22,
        ),
      ),
    );
    await _show(
      tester,
      FrostedButton.glass('Save', onPressed: _none, style: _cut(_start)),
      TextDirection.ltr,
      theme: theme,
    );
    final border =
        _shapeOf(_given().firstWhere((e) => e.widget is FrostedFace))!
            as RawCornerBorder;
    expect(
      border.borderRadius.resolve(TextDirection.ltr).topLeft,
      const Radius.circular(24),
    );
  });

  testWidgets("a segmented strip's ends take its corners; the joins stay", (
    tester,
  ) async {
    Widget strip(String value) => FrostedSegmentedButton<String>(
      segments: const [
        FrostedButtonSegment('a', 'Day'),
        FrostedButtonSegment('b', 'Week'),
        FrostedButtonSegment('c', 'Month'),
      ],
      value: value,
      onChanged: _ignore,
      label: 'Range',
      style: _cut(_diagonal),
    );
    for (final direction in TextDirection.values) {
      final ltr = direction == TextDirection.ltr;
      await _show(tester, strip('b'), direction);
      final given = _faceGiven()
        ..sort((a, b) => _rectOf(b).width.compareTo(_rectOf(a).width));
      // The strip round them, and the two end segments; the middle one and
      // the plate under it keep their own corners.
      expect(given, hasLength(3), reason: direction.name);
      expect(_square(given.first), _expected(_diagonal, direction));
      final ends = given.skip(1).toList()
        ..sort((a, b) => _rectOf(a).left.compareTo(_rectOf(b).left));
      // The start segment stands on the reading start: its top start
      // square; the end one's bottom end.
      expect(
        _square(ends.first),
        ltr ? [true, false, false, false] : [false, false, true, false],
      );
      expect(
        _square(ends.last),
        ltr ? [false, false, false, true] : [false, true, false, false],
      );
      // Chosen at an end, the plate takes that end's corners.
      await _show(tester, strip('a'), direction);
      expect(_faceGiven(), hasLength(4), reason: 'the plate at the start');
    }
  });

  testWidgets(
    "a menu's first and last rows stand concentric with its corners",
    (tester) async {
      final theme = FrostedThemeData.opal().copyWith(
        components: const FrostedComponentThemes(
          menu: FrostedStyle(corners: WidgetStatePropertyAll(_diagonal)),
        ),
      );
      for (final direction in TextDirection.values) {
        final ltr = direction == TextDirection.ltr;
        await _show(
          tester,
          const FrostedMenu<String>(
            items: [
              FrostedMenuItem('a', 'Rename', checked: true),
              FrostedMenuItem('b', 'Move'),
              FrostedMenuItem('c', 'Delete'),
            ],
            onSelected: _ignore,
          ),
          direction,
          theme: theme,
        );
        final given = _given();
        final menu = given.reduce(
          (a, b) => _rectOf(a).width >= _rectOf(b).width ? a : b,
        );
        expect(_square(menu), _expected(_diagonal, direction));
        final rows = given.where((e) => e != menu).toList();
        final mid = _rectOf(menu).center.dy;
        // The first row (its plate) takes the menu's top start corner, the
        // last its bottom end; the middle row keeps its own.
        expect(rows.where((r) => _rectOf(r).top < mid), isNotEmpty);
        expect(rows.where((r) => _rectOf(r).top > mid), isNotEmpty);
        for (final row in rows) {
          final first = _rectOf(row).top < mid;
          expect(
            _square(row),
            first
                ? (ltr
                      ? [true, false, false, false]
                      : [false, true, false, false])
                : (ltr
                      ? [false, false, false, true]
                      : [false, false, true, false]),
            reason: '${first ? 'first' : 'last'} row, ${direction.name}',
          );
          // Concentric: a row's own corners are the menu's, its inset less.
          final inner = (_shapeOf(row)! as RawCornerBorder).borderRadius
              .resolve(direction);
          final outer = (_shapeOf(menu)! as RawCornerBorder).borderRadius
              .resolve(direction);
          final corner = first
              ? (ltr
                    ? (inner.topRight, outer.topRight)
                    : (inner.topLeft, outer.topLeft))
              : (ltr
                    ? (inner.bottomLeft, outer.bottomLeft)
                    : (inner.bottomRight, outer.bottomRight));
          expect(corner.$1.x, lessThan(corner.$2.x));
        }
      }
    },
  );

  testWidgets("a menu row's corner runs concentric with the menu's", (
    tester,
  ) async {
    const round = RawCorners(topStart: RawCorner.extraLarge);
    final theme = FrostedThemeData.opal().copyWith(
      components: const FrostedComponentThemes(
        menu: FrostedStyle(corners: WidgetStatePropertyAll(round)),
      ),
    );
    await _show(
      tester,
      const FrostedMenu<String>(
        items: [
          FrostedMenuItem('a', 'Rename', checked: true),
          FrostedMenuItem('b', 'Move'),
        ],
        onSelected: _ignore,
      ),
      TextDirection.ltr,
      theme: theme,
    );
    final faces = _faceGiven()
      ..sort((a, b) => _rectOf(b).width.compareTo(_rectOf(a).width));
    final menu = faces.first, row = faces.last;
    double topLeft(Element e) => (_shapeOf(e)! as RawCornerBorder).borderRadius
        .resolve(TextDirection.ltr)
        .topLeft
        .x;
    final inset = _rectOf(row).left - _rectOf(menu).left;
    expect(inset, greaterThan(0));
    expect(topLeft(menu), 22);
    expect(topLeft(row), closeTo(topLeft(menu) - inset, .01));
  });

  testWidgets("a face moves between its own corners and an app's, no snap", (
    tester,
  ) async {
    // Hovered, the key squares every corner; it eases there.
    final style = FrostedStyle(
      fill: const WidgetStatePropertyAll(_opaque),
      corners: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered)
            ? const RawCorners.all(RawCorner.none)
            : null,
      ),
    );
    await _show(
      tester,
      FrostedButton.glass('Save', onPressed: _none, style: style),
      TextDirection.ltr,
    );
    final rect = _rectOf(_faces().first);
    final rest = await _cornerDepth(tester, rect);
    expect(rest, greaterThan(4), reason: 'a capsule at rest');
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: rect.center);
    addTearDown(mouse.removePointer);
    await tester.pump();
    final depths = <double>[rest];
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      depths.add(await _cornerDepth(tester, rect));
    }
    expect(depths.last, 0, reason: 'square once hovered');
    // 120 ms eased out: no frame moves more than its lerp rate allows (the
    // steepest 16 ms of easeOutCubic is 0.4 of the way), and the corner
    // passes through several frames between.
    final most = rest * .45 + .25;
    for (var i = 1; i < depths.length; i++) {
      expect(
        (depths[i] - depths[i - 1]).abs(),
        lessThanOrEqualTo(most),
        reason: 'frame $i of $depths',
      );
    }
    expect(depths.where((d) => d > 0 && d < rest).length, greaterThan(2));
  });

  group("the theme's shapes", () {
    const most = RawCornerScale(
      extraSmall: 8,
      small: 14,
      medium: 16,
      large: 24,
      extraLarge: 28,
    );
    const least = RawCornerScale(
      extraSmall: 4,
      small: 6,
      medium: 8,
      large: 12,
      extraLarge: 16,
    );

    test("an app's scale is held to Frosted's bands at both ends", () {
      final opal = FrostedThemeData.opal();
      final rounder = opal.copyWith(
        shapeScheme: FrostedThemeData.defaultShapeScheme.copyWith(
          corners: FrostedThemeData.defaultShapeScheme.corners.scaled(3),
        ),
      );
      expect(rounder.shapeScheme.corners, most);
      final squarer = opal.copyWith(
        shapeScheme: FrostedThemeData.defaultShapeScheme.copyWith(
          corners: FrostedThemeData.defaultShapeScheme.corners.scaled(0),
        ),
      );
      expect(squarer.shapeScheme.corners, least);
      expect(opal.shapeScheme, FrostedThemeData.defaultShapeScheme);
    });

    test("a corner of Frosted's own moves as far as its step", () {
      final t = FrostedThemeData.opal().copyWith(
        shapeScheme: const RawShapeScheme(corners: most),
      );
      // A field's well (14, medium) as medium moves from 12 to 16.
      expect(t.corner(RawCorner.medium, 14), 18);
      expect(t.corner(RawCorner.large, 18), 24);
      // Capsules and hairlines stay.
      expect(t.corner(RawCorner.full, 7), 7);
      expect(t.corner(RawCorner.none, 2), 2);
      final s = FrostedThemeData.opal().copyWith(
        shapeScheme: const RawShapeScheme(corners: least),
      );
      expect(s.corner(RawCorner.medium, 14), 10);
      // Never under 0.
      expect(s.corner(RawCorner.extraSmall, 1), 0);
    });

    test('two themes lerp their shapes', () {
      final a = FrostedThemeData.opal();
      final b = a.copyWith(shapeScheme: const RawShapeScheme(corners: most));
      expect(a.lerp(b, .5).shapeScheme.corners.large, 21);
      expect(a.lerp(b, 1).shapeScheme.corners, most);
    });

    for (final (end, scale, large) in [
      ('least', least, 12.0),
      ('most', most, 24.0),
    ]) {
      testWidgets("a card's corner follows the theme at its $end", (
        tester,
      ) async {
        await _show(
          tester,
          const SizedBox(
            width: 260,
            child: FrostedCard(child: Text('On pace')),
          ),
          TextDirection.ltr,
          theme: FrostedThemeData.opal().copyWith(
            shapeScheme: RawShapeScheme(corners: scale),
          ),
        );
        final face = _faces().first.widget as FrostedFace;
        expect(face.radius.topLeft, Radius.circular(large));
      });
    }

    testWidgets('a theme switched from one band end to the other eases', (
      tester,
    ) async {
      Widget card(RawCornerScale scale) => _app(
        const SizedBox(
          width: 260,
          height: 120,
          child: FrostedCard(
            style: FrostedStyle(fill: WidgetStatePropertyAll(_opaque)),
            child: SizedBox.expand(),
          ),
        ),
        TextDirection.ltr,
        theme: FrostedThemeData.opal().copyWith(
          shapeScheme: RawShapeScheme(corners: scale),
        ),
      );
      tester.view.physicalSize = const Size(720, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(card(least));
      await tester.pumpAndSettle();
      final rect = _rectOf(_faces().first);
      final from = await _cornerDepth(tester, rect);
      await tester.pumpWidget(card(most));
      final depths = <double>[from];
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        depths.add(await _cornerDepth(tester, rect));
      }
      await tester.pumpAndSettle();
      final to = await _cornerDepth(tester, rect);
      expect(to, greaterThan(from + 2), reason: 'from 12 to 24');
      expect(depths.last, to);
      final step = (to - from) * .45 + .25;
      for (var i = 1; i < depths.length; i++) {
        expect(depths[i], greaterThanOrEqualTo(depths[i - 1] - .25));
        expect(
          depths[i] - depths[i - 1],
          lessThanOrEqualTo(step),
          reason: 'frame $i of $depths',
        );
      }
    });
  });
}
