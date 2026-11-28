/// An app's own corners on a part of Expressive: a style's `corners`, a step
/// per corner on the theme's scale, held to Expressive's bands and mirrored
/// in a right-to-left app; a joined part's outer corners only; a style's
/// `shape` wins; a change of corners springs, never snaps.
library;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

final _theme = ExpressiveThemeData.preset('baseline', Brightness.light);

Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      home: ExpressiveHost(
        theme: _theme,
        brightness: Brightness.light,
        child: Directionality(
          textDirection: direction,
          child: Center(child: child),
        ),
      ),
    );

ExpressiveComponentThemeData _corners(RawCorners corners) =>
    ExpressiveComponentThemeData(corners: WidgetStatePropertyAll(corners));

Finder _surfaceIn(Finder of) =>
    find.descendant(of: of, matching: find.byType(ExpressiveSurface)).first;

BorderRadius _radii(
  WidgetTester tester,
  Finder of, [
  TextDirection direction = TextDirection.ltr,
]) {
  final surface = tester.widget<ExpressiveSurface>(_surfaceIn(of));
  final size = tester.getSize(_surfaceIn(of));
  return (surface.shape as ExpressiveCornerBorder).radiiOn(
    Offset.zero & size,
    direction,
  );
}

void main() {
  test("Expressive's own scheme: Compose's corners of 4, 8, 12, 16 and 28, "
      'a step per corner open to an app', () {
    final c = ExpressiveThemeData.defaultShapeScheme.corners;
    expect(
      [c.extraSmall, c.small, c.medium, c.large, c.extraLarge],
      [4, 8, 12, 16, 28],
    );
    expect(_theme.shapeScheme, ExpressiveThemeData.defaultShapeScheme);
    expect(
      ExpressiveThemeData.shapeLimits.cornerFreedom,
      RawCornerFreedom.perCorner,
    );
    expect(ExpressiveThemeData.shapeLimits.cornerSteps, isNull);
  });

  test("an app's scheme is held to Expressive's bands, each step said once "
      'in debug', () {
    final lines = <String>[];
    final before = debugPrint;
    debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');
    late RawCornerScale held;
    try {
      for (var i = 0; i < 2; i++) {
        held = _theme
            .copyWith(
              shapeScheme: const RawShapeScheme(
                corners: RawCornerScale(
                  extraSmall: 0,
                  small: 2,
                  medium: 30,
                  large: 16,
                  extraLarge: 48,
                ),
              ),
            )
            .shapeScheme
            .corners;
      }
    } finally {
      debugPrint = before;
    }
    expect(
      [held.extraSmall, held.small, held.medium, held.extraLarge],
      [0, 4, 16, 36],
    );
    // Each step held is said once, on the first theme only.
    expect(lines.where((l) => l.contains('Expressive')), [
      "Expressive holds small 2 to 4, the band's least.",
      "Expressive holds medium 30 to 16, the band's most.",
      "Expressive holds extraLarge 48 to 36, the band's most.",
    ]);
  });

  for (final direction in TextDirection.values) {
    testWidgets('a button takes its own corners, mirrored in '
        '${direction.name}', (tester) async {
      await tester.pumpWidget(
        _app(
          ExpressiveFilledButton(
            'Save',
            onPressed: () {},
            style: _corners(const RawCorners.only(topStart: RawCorner.large)),
          ),
          direction: direction,
        ),
      );
      final r = _radii(tester, find.byType(ExpressiveFilledButton), direction);
      final start = direction == TextDirection.ltr ? r.topLeft : r.topRight;
      final others = direction == TextDirection.ltr
          ? [r.topRight, r.bottomLeft, r.bottomRight]
          : [r.topLeft, r.bottomLeft, r.bottomRight];
      expect(start, const Radius.circular(16));
      expect(others, everyElement(Radius.zero));
    });
  }

  testWidgets("a card's corners left unnamed keep the card's own", (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ExpressiveCard(
          style: _corners(
            const RawCorners(
              topEnd: RawCorner.none,
              bottomStart: RawCorner.none,
            ),
          ),
          child: const SizedBox(width: 200, height: 100),
        ),
      ),
    );
    final r = _radii(tester, find.byType(ExpressiveCard));
    expect(r.topLeft, const Radius.circular(12));
    expect(r.bottomRight, const Radius.circular(12));
    expect(r.topRight, Radius.zero);
    expect(r.bottomLeft, Radius.zero);
  });

  testWidgets("a step is the theme's: an app's scheme moves it", (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ExpressiveTheme(
          data: _theme.copyWith(
            shapeScheme: ExpressiveThemeData.defaultShapeScheme.copyWith(
              corners: ExpressiveThemeData.defaultShapeScheme.corners.copyWith(
                medium: 10,
              ),
            ),
          ),
          child: ExpressiveCard(
            style: _corners(const RawCorners.all(RawCorner.medium)),
            child: const SizedBox(width: 200, height: 100),
          ),
        ),
      ),
    );
    expect(
      _radii(tester, find.byType(ExpressiveCard)),
      BorderRadius.circular(10),
    );
  });

  testWidgets("a pill surface takes an app's corners over its own full ones", (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ExpressiveSurface(
          shape: const StadiumBorder(),
          color: const Color(0xFF6750A4),
          style: _corners(
            const RawCorners(
              topEnd: RawCorner.none,
              bottomStart: RawCorner.none,
            ),
          ),
          child: const SizedBox(width: 200, height: 48),
        ),
      ),
    );
    final clip = tester.widget<ClipPath>(
      find.descendant(
        of: find.byType(ExpressiveSurface),
        matching: find.byType(ClipPath),
      ),
    );
    final r =
        ((clip.clipper! as ShapeBorderClipper).shape as ExpressiveCornerBorder)
            .radiiOn(Offset.zero & const Size(200, 48), TextDirection.ltr);
    expect(r.topLeft, const Radius.circular(24));
    expect(r.bottomRight, const Radius.circular(24));
    expect(r.topRight, Radius.zero);
    expect(r.bottomLeft, Radius.zero);
  });

  testWidgets("a style's shape wins over its corners", (tester) async {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    );
    await tester.pumpWidget(
      _app(
        ExpressiveFilledButton(
          'Save',
          onPressed: () {},
          style: const ExpressiveComponentThemeData(
            shape: WidgetStatePropertyAll(shape),
            corners: WidgetStatePropertyAll(RawCorners.all(RawCorner.none)),
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<ExpressiveSurface>(
            _surfaceIn(find.byType(ExpressiveFilledButton)),
          )
          .shape,
      shape,
    );
  });

  testWidgets("a segmented button's corners reach its outer edge only", (
    tester,
  ) async {
    Future<List<BorderRadius>> radii(
      ExpressiveComponentThemeData? style,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 360,
            child: ExpressiveSegmentedButton<int>(
              segments: const [
                ExpressiveButtonSegment(0, 'Day'),
                ExpressiveButtonSegment(1, 'Week'),
                ExpressiveButtonSegment(2, 'Month'),
              ],
              value: null,
              onChanged: (_) {},
              style: style,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return [
        for (final label in ['Day', 'Week', 'Month'])
          _radii(
            tester,
            find.ancestor(
              of: find.text(label),
              matching: find.byType(ExpressivePressable),
            ),
          ),
      ];
    }

    final own = await radii(null);
    final cut = await radii(_corners(const RawCorners.all(RawCorner.none)));
    expect(cut[0].topLeft, Radius.zero);
    expect(cut[0].bottomLeft, Radius.zero);
    expect(cut[0].topRight, own[0].topRight);
    expect(cut[0].bottomRight, own[0].bottomRight);
    expect(cut[1], own[1]);
    expect(cut[2].topRight, Radius.zero);
    expect(cut[2].bottomRight, Radius.zero);
    expect(cut[2].topLeft, own[2].topLeft);
    expect(cut[2].bottomLeft, own[2].bottomLeft);
    expect(own[0].topLeft, isNot(Radius.zero));
  });

  testWidgets("a split button's corners reach each half's outer side", (
    tester,
  ) async {
    Future<List<BorderRadius>> radii(
      ExpressiveComponentThemeData? style,
    ) async {
      await tester.pumpWidget(
        _app(
          ExpressiveSplitButton(
            'Send',
            onPressed: () {},
            onMenuOpenChanged: (_) {},
            menuLabel: 'More',
            style: style,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final halves = find.descendant(
        of: find.byType(ExpressiveSplitButton),
        matching: find.byType(ExpressivePressable),
      );
      return [_radii(tester, halves.at(0)), _radii(tester, halves.at(1))];
    }

    final own = await radii(null);
    final cut = await radii(_corners(const RawCorners.all(RawCorner.none)));
    expect([cut[0].topLeft, cut[0].bottomLeft], everyElement(Radius.zero));
    expect(cut[0].topRight, own[0].topRight);
    expect(cut[0].bottomRight, own[0].bottomRight);
    expect([cut[1].topRight, cut[1].bottomRight], everyElement(Radius.zero));
    expect(cut[1].topLeft, own[1].topLeft);
    expect(cut[1].bottomLeft, own[1].bottomLeft);
  });

  testWidgets("a press springs to its state's corners through the outline "
      'between, never snapping', (tester) async {
    await tester.pumpWidget(
      _app(
        ExpressiveFilledButton(
          'Save',
          onPressed: () {},
          style: ExpressiveComponentThemeData(
            corners: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed)
                  ? const RawCorners.all(RawCorner.none)
                  : null,
            ),
          ),
        ),
      ),
    );
    final button = find.byType(ExpressiveFilledButton);
    final rest = _radii(tester, button).topLeft.x;
    expect(rest, greaterThan(0));
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump();
    final frames = <double>[];
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      frames.add(_radii(tester, button).topLeft.x);
    }
    expect(
      frames.where((r) => r > 0 && r < rest),
      isNotEmpty,
      reason: 'the corners pass through the outlines between: $frames',
    );
    await tester.pumpAndSettle();
    expect(_radii(tester, button), BorderRadius.zero);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_radii(tester, button).topLeft.x, rest);
  });

  test('a joined part reaches its outer corners: a row, a column', () {
    expect(ExpressiveOuterCorners.inRow(0, 1), ExpressiveOuterCorners.all);
    expect(ExpressiveOuterCorners.inRow(0, 3), ExpressiveOuterCorners.start);
    expect(ExpressiveOuterCorners.inRow(1, 3), ExpressiveOuterCorners.none);
    expect(ExpressiveOuterCorners.inRow(2, 3), ExpressiveOuterCorners.end);
    expect(ExpressiveOuterCorners.inColumn(0, 2), ExpressiveOuterCorners.top);
    expect(
      ExpressiveOuterCorners.inColumn(1, 2),
      ExpressiveOuterCorners.bottom,
    );
    expect(
      ExpressiveOuterCorners.top.of(const RawCorners.all(RawCorner.none)),
      const RawCorners(topStart: RawCorner.none, topEnd: RawCorner.none),
    );
    expect(ExpressiveOuterCorners.none.of(null), isNull);
  });
}
