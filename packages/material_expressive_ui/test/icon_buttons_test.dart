/// The icon buttons family: the XS–XL × narrow/uniform/wide size ladder,
/// the four styles' colours (ambient and vibrant), the press morph, toggle
/// colours, shapes and semantics, the touch target and the hero assertion.
library;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'support/brand_shapes.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

ExpressiveColorScheme get _c => _theme.colors;

Widget _app(Widget child) => MaterialApp(
  home: ExpressiveHost(
    light: _theme,
    brightness: Brightness.light,
    child: Center(child: child),
  ),
);

ExpressiveSurface _surface(WidgetTester tester) =>
    tester.widget<ExpressiveSurface>(find.byType(ExpressiveSurface).first);

Size _surfaceSize(WidgetTester tester) =>
    tester.getSize(find.byType(ExpressiveSurface).first);

BorderRadius _radii(WidgetTester tester) =>
    (_surface(tester).shape as ExpressiveCornerBorder).radiiOn(
      Offset.zero & _surfaceSize(tester),
    );

void main() {
  testWidgets(
    'state style and mark shapes keep icon content inside its outline',
    (tester) async {
      const sets = [roundedTestShapes, cookieTestShapes, scallopedTestShapes];
      for (final set in sets) {
        for (final density in [
          ExpressiveDensity.standard,
          ExpressiveDensity.comfortable,
          ExpressiveDensity.compact,
        ]) {
          for (final width in [120.0, 240.0, 390.0]) {
            for (final scale in [1.0, 1.3]) {
              await tester.pumpWidget(
                _app(
                  ExpressiveTheme(
                    data: _theme.copyWith(density: density),
                    child: MediaQuery(
                      data: MediaQueryData(
                        textScaler: TextScaler.linear(scale),
                      ),
                      child: SizedBox(
                        width: width,
                        child: Center(
                          child: ExpressiveIconButton.filled(
                            ExpressiveSymbols.add,
                            onPressed: () {},
                            style: shapedStyle(
                              set.mark,
                              const ExpressiveComponentThemeData(
                                iconSize: WidgetStatePropertyAll(28),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final face = tester.getRect(find.byType(ExpressiveSurface).first);
              final icon = tester
                  .getRect(find.byType(Icon).first)
                  .shift(-face.topLeft)
                  .deflate(1);
              final path = _surface(tester).shape
                  .getOuterPath(Offset.zero & face.size);
              for (final point in [
                icon.topLeft,
                icon.topCenter,
                icon.topRight,
                icon.centerLeft,
                icon.centerRight,
                icon.bottomLeft,
                icon.bottomCenter,
                icon.bottomRight,
              ]) {
                expect(
                  path.contains(point),
                  isTrue,
                  reason: '$set $density $width $scale $point',
                );
              }
              expect(tester.getSize(find.byType(Icon).first).width, 28);
              expect(tester.takeException(), isNull);
            }
          }
        }
      }
    },
  );

  group('ExpressiveIconButton', () {
    testWidgets('sizes by IconButtonDefaults.*ContainerSize(widthOption)', (
      tester,
    ) async {
      // Compose: icon + narrow (leading + trailing), uniform (leading × 2),
      // wide (leading + trailing) space; the container height.
      const expected = <ExpressiveIconButtonSize, List<Size>>{
        ExpressiveIconButtonSize.extraSmall: [
          Size(28, 32),
          Size(32, 32),
          Size(40, 32),
        ],
        ExpressiveIconButtonSize.small: [
          Size(32, 40),
          Size(40, 40),
          Size(52, 40),
        ],
        ExpressiveIconButtonSize.medium: [
          Size(48, 56),
          Size(56, 56),
          Size(72, 56),
        ],
        ExpressiveIconButtonSize.large: [
          Size(64, 96),
          Size(96, 96),
          Size(128, 96),
        ],
        ExpressiveIconButtonSize.extraLarge: [
          Size(104, 136),
          Size(136, 136),
          Size(184, 136),
        ],
      };
      for (final MapEntry(key: size, value: sizes) in expected.entries) {
        for (final width in ExpressiveIconButtonWidth.values) {
          expect(
            ExpressiveIconButton.containerSize(size, width),
            sizes[width.index],
            reason: '${size.name} ${width.name}',
          );
          await tester.pumpWidget(
            _app(
              ExpressiveHeroMoment(
                child: ExpressiveIconButton.filled(
                  ExpressiveSymbols.add,
                  size: size,
                  width: width,
                  onPressed: () {},
                ),
              ),
            ),
          );
          expect(_surfaceSize(tester), sizes[width.index]);
        }
      }
      expect(
        ExpressiveIconButtonSize.values.map(ExpressiveIconButton.iconSizeOf),
        [20, 24, 24, 32, 40],
      );
    });

    testWidgets('keeps the 48dp touch target around a smaller container', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          ExpressiveIconButton(
            ExpressiveSymbols.close,
            size: ExpressiveIconButtonSize.extraSmall,
            onPressed: () => taps++,
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(ExpressiveIconButton)),
        const Size(48, 48),
      );
      expect(_surfaceSize(tester), const Size(32, 32));
      // A touch in the margin reaches the button.
      final corner = tester.getTopLeft(find.byType(ExpressiveIconButton));
      await tester.tapAt(corner + const Offset(2, 2));
      expect(taps, 1);
    });

    testWidgets('paints each style in IconButtonDefaults\' colours', (
      tester,
    ) async {
      Future<(Color, Color, BorderSide)> paintOf(Widget button) async {
        await tester.pumpWidget(_app(button));
        // One button swapped for the next in place springs its colours
        // from the last: read them settled.
        await tester.pumpAndSettle();
        final s = _surface(tester);
        return (s.color, s.contentColor!, s.side);
      }

      // Standard: transparent, the ambient icon colour (the host's
      // onSurface); vibrant: onSurfaceVariant.
      var (container, content, side) = await paintOf(
        ExpressiveIconButton(ExpressiveSymbols.menu, onPressed: () {}),
      );
      expect(container.a, 0);
      expect(content, _c.onSurface);
      (_, content, _) = await paintOf(
        ExpressiveIconButton(
          ExpressiveSymbols.menu,
          vibrant: true,
          onPressed: () {},
        ),
      );
      expect(content, _c.onSurfaceVariant);

      (container, content, _) = await paintOf(
        ExpressiveIconButton.filled(ExpressiveSymbols.add, onPressed: () {}),
      );
      expect(container, _c.primary);
      expect(content, _c.onPrimary);

      (container, content, _) = await paintOf(
        ExpressiveIconButton.filledTonal(
          ExpressiveSymbols.add,
          onPressed: () {},
        ),
      );
      expect(container, _c.secondaryContainer);
      expect(content, _c.onSecondaryContainer);

      // Outlined: the ambient colour for content and outline; vibrant:
      // onSurfaceVariant on outlineVariant. 1dp at every size.
      (container, content, side) = await paintOf(
        ExpressiveIconButton.outlined(ExpressiveSymbols.add, onPressed: () {}),
      );
      expect(container.a, 0);
      expect(content, _c.onSurface);
      expect(side.color, _c.onSurface);
      expect(side.width, 1);
      (_, content, side) = await paintOf(
        ExpressiveHeroMoment(
          child: ExpressiveIconButton.outlined(
            ExpressiveSymbols.add,
            vibrant: true,
            size: ExpressiveIconButtonSize.extraLarge,
            onPressed: () {},
          ),
        ),
      );
      expect(content, _c.onSurfaceVariant);
      expect(side.color, _c.outlineVariant);
      expect(side.width, 1);

      // Disabled filled: onSurface at 10 % under onSurface at 38 %.
      (container, content, _) = await paintOf(
        const ExpressiveIconButton.filled(
          ExpressiveSymbols.add,
          onPressed: null,
        ),
      );
      expect(container, _c.onSurface.withValues(alpha: 0.1));
      expect(content, _c.onSurface.withValues(alpha: 0.38));
    });

    testWidgets('follows the ambient icon colour', (tester) async {
      await tester.pumpWidget(
        _app(
          IconTheme.merge(
            data: IconThemeData(color: _c.tertiary),
            child: ExpressiveIconButton(
              ExpressiveSymbols.eco,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(_surface(tester).contentColor, _c.tertiary);
    });

    testWidgets('round, square, and the pressed shape on a spring', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ExpressiveIconButton.filled(ExpressiveSymbols.add, onPressed: () {}),
        ),
      );
      expect(_radii(tester).topLeft.x, 20); // S round: full.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ExpressiveIconButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final mid = _radii(tester).topLeft.x;
      expect(mid, lessThan(20));
      await tester.pumpAndSettle();
      expect(
        _radii(tester).topLeft.x,
        _theme.shapes.small.radiiOn(Offset.zero & const Size(40, 40)).topLeft.x,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_radii(tester).topLeft.x, 20);

      await tester.pumpWidget(
        _app(
          ExpressiveIconButton.filled(
            ExpressiveSymbols.add,
            shape: ExpressiveIconButtonShape.square,
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _radii(tester).topLeft.x,
        _theme.shapes.medium
            .radiiOn(Offset.zero & const Size(40, 40))
            .topLeft
            .x,
      );
    });

    testWidgets('announces its label as a button, disabled without a tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          ExpressiveIconButton(
            ExpressiveSymbols.search,
            semanticLabel: 'Search',
            onPressed: () {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(ExpressiveIconButton)),
        matchesSemantics(
          label: 'Search',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.pumpWidget(
        _app(
          const ExpressiveIconButton(
            ExpressiveSymbols.search,
            semanticLabel: 'Search',
            onPressed: null,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(ExpressiveIconButton)),
        isSemantics(
          label: 'Search',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('L and XL assert an ExpressiveHeroMoment', (tester) async {
      await tester.pumpWidget(
        _app(
          ExpressiveIconButton.filled(
            ExpressiveSymbols.mic,
            size: ExpressiveIconButtonSize.large,
            onPressed: () {},
          ),
        ),
      );
      expect(tester.takeException(), isA<FlutterError>());
      await tester.pumpWidget(
        _app(
          ExpressiveHeroMoment(
            child: ExpressiveIconButton.filled(
              ExpressiveSymbols.mic,
              size: ExpressiveIconButtonSize.extraLarge,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('in an ExpressiveButtonGroup', () {
    testWidgets('a pressed icon button widens; its neighbours give way', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ExpressiveButtonGroup(
            size: ExpressiveButtonSize.medium,
            children: <Widget>[
              ExpressiveIconButton.filledTonal(
                ExpressiveSymbols.replay10,
                size: ExpressiveIconButtonSize.medium,
                width: ExpressiveIconButtonWidth.narrow,
                semanticLabel: 'Back',
                onPressed: () {},
              ),
              ExpressiveIconToggleButton.filled(
                ExpressiveSymbols.playArrow,
                size: ExpressiveIconButtonSize.medium,
                width: ExpressiveIconButtonWidth.wide,
                value: false,
                semanticLabel: 'Play',
                onChanged: (_) {},
              ),
              ExpressiveIconButton.filledTonal(
                ExpressiveSymbols.forward30,
                size: ExpressiveIconButtonSize.medium,
                width: ExpressiveIconButtonWidth.narrow,
                semanticLabel: 'Forward',
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      final surfaces = find.byType(ExpressiveSurface);
      List<double> widths() => <double>[
        for (var i = 0; i < 3; i++) tester.getSize(surfaces.at(i)).width,
      ];
      expect(widths(), <double>[48, 72, 48]);
      final gesture = await tester.startGesture(
        tester.getCenter(surfaces.at(1)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      // Growth per side: min(0.15 × 72 / 2, 24) = 5.4.
      final pressed = widths();
      expect(pressed[0], closeTo(48 - 5.4, 0.01));
      expect(pressed[1], closeTo(72 + 2 * 5.4, 0.01));
      expect(pressed[2], closeTo(48 - 5.4, 0.01));
      // The glyph stays centred in the width the group fixes.
      expect(
        tester.getCenter(find.byType(ExpressiveIcon).at(1)).dx,
        closeTo(tester.getCenter(surfaces.at(1)).dx, 0.01),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(widths(), <double>[48, 72, 48]);
    });
  });

  group('ExpressiveIconToggleButton', () {
    testWidgets('flips on a tap, in the toggle colours and checked shape', (
      tester,
    ) async {
      var checked = false;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => ExpressiveIconToggleButton.filled(
              ExpressiveSymbols.favorite,
              value: checked,
              onChanged: (value) => setState(() => checked = value),
            ),
          ),
        ),
      );
      expect(_surface(tester).color, _c.surfaceContainer);
      expect(_surface(tester).contentColor, _c.onSurfaceVariant);
      expect(_radii(tester).topLeft.x, 20);

      await tester.tap(find.byType(ExpressiveIconToggleButton));
      await tester.pumpAndSettle();
      expect(checked, isTrue);
      expect(_surface(tester).color, _c.primary);
      expect(_surface(tester).contentColor, _c.onPrimary);
      // A round S toggle checks to selected.container.shape.round: medium.
      expect(
        _radii(tester).topLeft.x,
        _theme.shapes.medium
            .radiiOn(Offset.zero & const Size(40, 40))
            .topLeft
            .x,
      );
    });

    testWidgets('standard checks to primary; outlined to inverseSurface, '
        'without its outline', (tester) async {
      await tester.pumpWidget(
        _app(
          ExpressiveIconToggleButton(
            ExpressiveSymbols.star,
            value: true,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_surface(tester).contentColor, _c.primary);
      await tester.pumpWidget(
        _app(
          ExpressiveIconToggleButton.outlined(
            ExpressiveSymbols.star,
            value: true,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_surface(tester).color, _c.inverseSurface);
      expect(_surface(tester).contentColor, _c.inverseOnSurface);
      expect(_surface(tester).side, BorderSide.none);
      await tester.pumpWidget(
        _app(
          ExpressiveIconToggleButton.filledTonal(
            ExpressiveSymbols.star,
            value: false,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_surface(tester).color, _c.secondaryContainer);
    });

    testWidgets('fills its glyph when checked', (tester) async {
      await tester.pumpWidget(
        _app(
          ExpressiveIconToggleButton(
            ExpressiveSymbols.bookmark,
            value: true,
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.widget<ExpressiveIcon>(find.byType(ExpressiveIcon)).selected,
        isTrue,
      );
    });

    testWidgets('is a toggle to assistive technology', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          ExpressiveIconToggleButton(
            ExpressiveSymbols.notifications,
            value: true,
            semanticLabel: 'Notify me',
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(ExpressiveIconToggleButton)),
        isSemantics(
          label: 'Notify me',
          isButton: true,
          hasToggledState: true,
          isToggled: true,
        ),
      );
      handle.dispose();
    });
  });
}
