/// The buttons family: the common buttons' size ladder, colours, press
/// morph, v2 alias layer and hero assertion; toggle buttons; the standard
/// group's squish; the segmented control (the connected group); the link.
/// Cody's controls tests for the segmented control are ported here (see
/// the `Cody:` names).
library;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'support/brand_shapes.dart';

import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/connected_button_group_small_tokens.g.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

ExpressiveColorScheme get _c => _theme.colors;

Widget _app(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) => MaterialApp(
  home: ExpressiveHost(
    light: _theme,
    brightness: Brightness.light,
    child: Directionality(
      textDirection: direction,
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: Center(child: child),
        ),
      ),
    ),
  ),
);

Finder _surfaceIn(Finder of) =>
    find.descendant(of: of, matching: find.byType(ExpressiveSurface)).first;

ExpressiveSurface _surface(WidgetTester tester, [Finder? of]) =>
    tester.widget<ExpressiveSurface>(
      of == null ? find.byType(ExpressiveSurface).first : _surfaceIn(of),
    );

Size _surfaceSize(WidgetTester tester, [Finder? of]) => tester.getSize(
  of == null ? find.byType(ExpressiveSurface).first : _surfaceIn(of),
);

BorderRadius _radii(WidgetTester tester, Finder of) {
  final surface = _surface(tester, of);
  final size = _surfaceSize(tester, of);
  return (surface.shape as ExpressiveCornerBorder).radiiOn(Offset.zero & size);
}

Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle();

void main() {
  testWidgets(
    'app shapes contain button labels across width, density and text scale',
    (tester) async {
      for (final shapes in const [
        roundedTestShapes,
        cookieTestShapes,
        scallopedTestShapes,
      ]) {
        for (final density in const [
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
                    child: SizedBox(
                      width: width,
                      child: ExpressiveFilledButton(
                        'Continue',
                        expand: true,
                        style: shapedStyle(shapes.wide),
                        onPressed: () {},
                      ),
                    ),
                  ),
                  scale: scale,
                ),
              );
              await _settle(tester);
              final face = find.byType(ExpressiveSurface).first;
              final faceRect = tester.getRect(face);
              final content = tester
                  .getRect(find.text('Continue'))
                  .shift(-faceRect.topLeft)
                  .deflate(1);
              final path = tester
                  .widget<ExpressiveSurface>(face)
                  .shape
                  .getOuterPath(Offset.zero & faceRect.size);
              for (final point in [
                content.topLeft,
                content.topCenter,
                content.topRight,
                content.centerLeft,
                content.centerRight,
                content.bottomLeft,
                content.bottomCenter,
                content.bottomRight,
              ]) {
                expect(
                  path.contains(point),
                  isTrue,
                  reason: '$width $scale $density $point',
                );
              }
              expect(tester.takeException(), isNull);
            }
          }
        }
      }
    },
  );

  testWidgets(
    'widget style resolves before component theme through press states',
    (tester) async {
      await tester.pumpWidget(
        _app(
          ExpressiveTheme(
            data: _theme.copyWith(
              buttonTheme: const ExpressiveComponentThemeData(
                backgroundColor: WidgetStatePropertyAll(Color(0xff112233)),
              ),
            ),
            child: ExpressiveFilledButton(
              'Styled',
              onPressed: () {},
              style: ExpressiveComponentThemeData(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.pressed)
                      ? const Color(0xff445566)
                      : null,
                ),
                shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
                overlayColor: const WidgetStatePropertyAll(Color(0x00000000)),
              ),
            ),
          ),
        ),
      );
      expect(_surface(tester).color, const Color(0xff112233));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Styled')),
      );
      // The container's colour springs to the pressed one.
      await _settle(tester);
      expect(_surface(tester).color, const Color(0xff445566));
      await gesture.up();
      await _settle(tester);
      expect(_surface(tester).color, const Color(0xff112233));
    },
  );

  group('ExpressiveButton', () {
    testWidgets('each size is its container height, 58dp at least wide', (
      tester,
    ) async {
      for (final size in ExpressiveButtonSize.values) {
        await tester.pumpWidget(
          _app(
            ExpressiveHeroMoment(
              child: ExpressiveFilledButton('Go', onPressed: () {}, size: size),
            ),
          ),
        );
        final box = _surfaceSize(tester);
        expect(box.height, size.height, reason: size.name);
        expect(box.width, greaterThanOrEqualTo(ButtonBehavior.minWidth));
      }
      expect(ExpressiveButtonSize.values.map((s) => s.height), <double>[
        32,
        40,
        56,
        96,
        136,
      ]);
    });

    testWidgets('pads the label by the size ladder', (tester) async {
      const cases = <ExpressiveButtonSize, double>{
        ExpressiveButtonSize.extraSmall: 12,
        ExpressiveButtonSize.small: 16,
        ExpressiveButtonSize.medium: 24,
        ExpressiveButtonSize.large: 48,
        ExpressiveButtonSize.extraLarge: 64,
      };
      for (final MapEntry(key: size, value: start) in cases.entries) {
        await tester.pumpWidget(
          _app(
            ExpressiveHeroMoment(
              child: ExpressiveFilledButton(
                'Book the table',
                onPressed: () {},
                size: size,
              ),
            ),
          ),
        );
        final surface = tester.getRect(find.byType(ExpressiveSurface).first);
        final label = tester.getRect(find.text('Book the table'));
        expect(label.left - surface.left, closeTo(start, 0.01));
        expect(surface.right - label.right, closeTo(start, 0.01));
      }
    });

    testWidgets('paints each style in its roles', (tester) async {
      final cases = <(Widget, Color, Color)>[
        (
          ExpressiveFilledButton('A', onPressed: () {}),
          _c.primary,
          _c.onPrimary,
        ),
        (
          ExpressiveFilledButton.tonal('A', onPressed: () {}),
          _c.secondaryContainer,
          _c.onSecondaryContainer,
        ),
        (
          ExpressiveElevatedButton('A', onPressed: () {}),
          _c.surfaceContainerLow,
          _c.primary,
        ),
        (
          ExpressiveOutlinedButton('A', onPressed: () {}),
          const Color(0x00000000),
          _c.onSurfaceVariant,
        ),
        (
          ExpressiveTextButton('A', onPressed: () {}),
          const Color(0x00000000),
          _c.primary,
        ),
        (
          ExpressiveFilledButton(
            'A',
            onPressed: () {},
            style: ExpressiveFilledButton.styleFrom(
              backgroundColor: _c.error,
              foregroundColor: _c.onError,
            ),
          ),
          _c.error,
          _c.onError,
        ),
      ];
      for (final (button, container, content) in cases) {
        // Each button fresh: the same button changing style springs from
        // its old colours.
        await tester.pumpWidget(
          _app(KeyedSubtree(key: UniqueKey(), child: button)),
        );
        final surface = _surface(tester);
        expect(surface.color, container, reason: '$button');
        expect(surface.contentColor, content, reason: '$button');
      }
      await tester.pumpWidget(
        _app(ExpressiveOutlinedButton('A', onPressed: () {})),
      );
      final pressable = tester.widget<ExpressivePressable>(
        find.byType(ExpressivePressable),
      );
      expect(pressable.side.color, _c.outlineVariant);
      expect(pressable.side.width, 1);
    });

    testWidgets('disabled: no action, the disabled colours', (tester) async {
      await tester.pumpWidget(_app(const ExpressiveFilledButton('Save')));
      final surface = _surface(tester);
      expect(surface.color, _c.onSurface.withValues(alpha: 0.1));
      expect(surface.contentColor, _c.onSurfaceVariant.withValues(alpha: 0.38));
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(ExpressivePressable)),
        isSemantics(hasEnabledState: true, isEnabled: false, isButton: true),
      );
      handle.dispose();
    });

    testWidgets('springs to the pressed shape and back', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(ExpressiveFilledButton('Save', onPressed: () => taps++)),
      );
      final button = find.bySubtype<ExpressiveButton>();
      expect(_radii(tester, button).topLeft.x, 20);
      final gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 200));
      await _settle(tester);
      expect(_radii(tester, button).topLeft.x, 8, reason: 'cornerSmall');
      await gesture.up();
      await _settle(tester);
      expect(_radii(tester, button).topLeft.x, 20);
      expect(taps, 1);
    });

    testWidgets('square rests on the size corner', (tester) async {
      await tester.pumpWidget(
        _app(
          ExpressiveFilledButton(
            'Save',
            onPressed: () {},
            shape: ExpressiveButtonShape.square,
            size: ExpressiveButtonSize.medium,
          ),
        ),
      );
      expect(_radii(tester, find.bySubtype<ExpressiveButton>()).topLeft.x, 16);
    });

    testWidgets('a text button pads as every style at its size (Compose\'s '
        '`shapes` overload: contentPaddingFor)', (tester) async {
      Future<(double, double)> measure(Widget button) async {
        await tester.pumpWidget(_app(ExpressiveHeroMoment(child: button)));
        final surface = tester.getRect(find.byType(ExpressiveSurface).first);
        final label = tester.getRect(find.text('Book the table'));
        return (label.left - surface.left, surface.right - label.right);
      }

      // SmallContentPadding: 16dp either side, as the filled button's.
      var (start, end) = await measure(
        ExpressiveTextButton('Book the table', onPressed: () {}),
      );
      expect(start, closeTo(16, 0.01));
      expect(end, closeTo(16, 0.01));
      // M keeps the ladder's 24dp.
      (start, end) = await measure(
        ExpressiveTextButton(
          'Book the table',
          size: ExpressiveButtonSize.medium,
          onPressed: () {},
        ),
      );
      expect(start, closeTo(24, 0.01));
      expect(end, closeTo(24, 0.01));
    });

    testWidgets('v2 aliases: variants and sizes', (tester) async {
      expect(ExpressiveButtonSize.extraSmall, ExpressiveButtonSize.extraSmall);
      expect(ExpressiveButtonSize.small, ExpressiveButtonSize.small);
      expect(ExpressiveButtonSize.medium, ExpressiveButtonSize.medium);
      expect(
        const ExpressiveFilledButton('A').kind,
        ExpressiveButtonKind.filled,
      );
      expect(
        const ExpressiveFilledButton('A').size,
        ExpressiveButtonSize.small,
      );
      expect(
        const ExpressiveFilledButton.tonal('A').kind,
        ExpressiveButtonKind.tonal,
      );
      expect(const ExpressiveTextButton('A').kind, ExpressiveButtonKind.text);
      await tester.pumpWidget(
        _app(
          ExpressiveFilledButton(
            'Save',
            onPressed: () {},
            size: ExpressiveButtonSize.medium,
            icon: ExpressiveSymbols.check,
          ),
        ),
      );
      expect(_surfaceSize(tester).height, 56);
    });

    testWidgets('L and XL are heroes: they assert ExpressiveHeroMoment', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ExpressiveFilledButton(
            'Go',
            onPressed: () {},
            size: ExpressiveButtonSize.extraLarge,
          ),
        ),
      );
      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('icons take the size ladder and the gap', (tester) async {
      await tester.pumpWidget(
        _app(
          ExpressiveFilledButton(
            'Add',
            onPressed: () {},
            size: ExpressiveButtonSize.medium,
            icon: ExpressiveSymbols.add,
          ),
        ),
      );
      final icon = tester.getRect(find.byType(Icon));
      final label = tester.getRect(find.text('Add'));
      expect(icon.width, 24);
      expect(label.left - icon.right, closeTo(8, 0.01));
    });

    // Cody: "grouped controls fit narrow phones at large text sizes" and
    // the button's two-line label.
    testWidgets('long labels wrap on narrow phones at large text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _app(
          Padding(
            padding: const EdgeInsets.all(16),
            child: ExpressiveFilledButton(
              'Confirm the booking for three nights',
              onPressed: () {},
              icon: ExpressiveSymbols.check,
              expand: true,
            ),
          ),
          scale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(_surfaceSize(tester).height, greaterThan(40));
      // The wrapped label is as wide as its longest line: the icon stays
      // beside it and the pair centres in the button.
      final surface = tester.getRect(find.byType(ExpressiveSurface).first);
      final icon = tester.getRect(find.byType(Icon));
      final label = tester.getRect(
        find.text('Confirm the booking for three nights'),
      );
      expect(label.height, greaterThan(40));
      expect(label.left - icon.right, closeTo(8, 0.01));
      expect(icon.left - surface.left, closeTo(surface.right - label.right, 1));
    });

    testWidgets('sits in a Row at its own width', (tester) async {
      await tester.pumpWidget(
        _app(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ExpressiveTextButton('Cancel', onPressed: () {}),
              ExpressiveFilledButton('Save', onPressed: () {}),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ExpressiveToggleButton', () {
    testWidgets('toggles, takes the checked colours and shape', (tester) async {
      var checked = false;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, update) => ExpressiveToggleButton(
              value: checked,
              onChanged: (v) => update(() => checked = v),
              label: 'Mute',
              icon: ExpressiveSymbols.volumeOff,
            ),
          ),
        ),
      );
      final button = find.byType(ExpressiveToggleButton);
      expect(_surface(tester).color, _c.surfaceContainer);
      expect(_radii(tester, button).topLeft.x, 20);
      await tester.tap(button);
      await _settle(tester);
      expect(checked, isTrue);
      expect(_surface(tester).color, _c.primary);
      expect(_surface(tester).contentColor, _c.onPrimary);
      expect(_radii(tester, button).topLeft.x, 12, reason: 'round → square');
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(ExpressivePressable)),
        isSemantics(isButton: true, hasToggledState: true, isToggled: true),
      );
      handle.dispose();
    });

    testWidgets('a content slot and colours in place of the style\'s', (
      tester,
    ) async {
      var checked = false;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, update) => ExpressiveToggleButton(
              value: checked,
              onChanged: (v) => update(() => checked = v),
              label: 'Play',
              size: ExpressiveButtonSize.medium,
              colors: ExpressiveToggleButtonColors(
                container: _c.primary,
                content: _c.onPrimary,
              ),
              child: ExpressiveIcon(
                checked ? ExpressiveSymbols.pause : ExpressiveSymbols.playArrow,
              ),
            ),
          ),
        ),
      );
      final button = find.byType(ExpressiveToggleButton);
      expect(find.text('Play'), findsNothing);
      expect(_surface(tester).color, _c.primary, reason: 'unchecked, given');
      expect(_surface(tester).contentColor, _c.onPrimary);
      expect(
        tester.widget<ExpressiveIcon>(find.byType(ExpressiveIcon)).size,
        isNull,
        reason: 'the slot takes the size\'s icon size from the icon theme',
      );
      expect(tester.getSize(find.byType(Icon)), const Size.square(24));
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(ExpressivePressable)),
        isSemantics(label: 'Play', isButton: true, hasToggledState: true),
      );
      handle.dispose();
      await tester.tap(button);
      await _settle(tester);
      expect(checked, isTrue);
      expect(_surface(tester).color, _c.primary, reason: 'checked, the style');
      expect(_surface(tester).contentColor, _c.onPrimary);
    });

    testWidgets('square checks to round; outlined drops its outline', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ExpressiveToggleButton(
            value: true,
            onChanged: (_) {},
            label: 'Bold',
            shape: ExpressiveButtonShape.square,
            kind: ExpressiveToggleButtonKind.outlined,
          ),
        ),
      );
      await _settle(tester);
      expect(_radii(tester, find.byType(ExpressiveToggleButton)).topLeft.x, 20);
      expect(_surface(tester).color, _c.inverseSurface);
      final pressable = tester.widget<ExpressivePressable>(
        find.byType(ExpressivePressable),
      );
      expect(pressable.side, BorderSide.none);
    });
  });

  group('ExpressiveButtonGroup', () {
    // At large text a phone's group is wider than its column: a label never
    // breaks inside a word; the buttons narrow toward their longest words,
    // then flow onto another row, an expanded group's rows each filling it.
    for (final expand in [true, false]) {
      testWidgets('at text 2.0 on a phone it reflows, words whole '
          '(expand: $expand)', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _app(
            Padding(
              padding: const EdgeInsets.all(36),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: ExpressiveButtonGroup(
                  expand: expand,
                  children: <Widget>[
                    ExpressiveFilledButton.tonal(
                      'Reply',
                      icon: ExpressiveSymbols.reply,
                      onPressed: () {},
                    ),
                    ExpressiveFilledButton.tonal('Forward', onPressed: () {}),
                    ExpressiveFilledButton.tonal(
                      'Archive',
                      icon: ExpressiveSymbols.archive,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            scale: 2,
          ),
        );
        expect(tester.takeException(), isNull);
        for (final word in ['Reply', 'Forward', 'Archive']) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(word),
          );
          expect(
            paragraph.size.height,
            closeTo(paragraph.getMaxIntrinsicHeight(double.infinity), 0.01),
            reason: '"$word" is on one line',
          );
        }
        final reply = tester.getRect(find.text('Reply'));
        final archive = tester.getRect(find.text('Archive'));
        expect(archive.top, greaterThan(reply.bottom), reason: 'two rows');
        final group = tester.getRect(find.byType(ExpressiveButtonGroup));
        expect(group.width, lessThanOrEqualTo(390 - 72 + 0.01));
      });
    }

    testWidgets('a pressed button widens; its neighbours give way', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 400,
            child: ExpressiveButtonGroup(
              expand: true,
              children: <Widget>[
                ExpressiveFilledButton.tonal('Day', onPressed: () {}),
                ExpressiveFilledButton.tonal('Week', onPressed: () {}),
                ExpressiveFilledButton.tonal('Month', onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      double width(String label) => _surfaceSize(
        tester,
        find.ancestor(
          of: find.text(label),
          matching: find.bySubtype<ExpressiveButton>(),
        ),
      ).width;
      // The test's window is 800 wide: from 600 an expanded group keeps to
      // a control's 320, or to three equal shares each as wide as "Month"
      // needs on one line, within its 400.
      final rest = width('Month');
      // Growth per side: min(0.15 × rest / 2, 24).
      final grow = 0.15 * rest / 2;
      expect(width('Day'), closeTo(rest, 0.01));
      expect(width('Week'), closeTo(rest, 0.01));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Week')),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await _settle(tester);
      expect(width('Week'), closeTo(rest + 2 * grow, 0.01));
      expect(width('Day'), closeTo(rest - grow, 0.01));
      expect(width('Month'), closeTo(rest - grow, 0.01));
      await gesture.up();
      await _settle(tester);
      expect(width('Week'), closeTo(rest, 0.01));
    });
  });

  group('ExpressiveSegmentedButton', () {
    testWidgets('a press narrows the neighbours\' padding, never their '
        'labels: each stays on one line and the row keeps its height', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ExpressiveSegmentedButton<int>(
            expand: false,
            segments: const [
              ExpressiveButtonSegment(0, 'Day'),
              ExpressiveButtonSegment(1, 'Week'),
              ExpressiveButtonSegment(2, 'Month'),
            ],
            value: 1,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final row = find.byType(ExpressiveSegmentedButton<int>);
      final rest = tester.getSize(row);
      double lineOf(String label) =>
          tester.renderObject<RenderParagraph>(find.text(label)).size.height;
      final line = lineOf('Week');
      for (final pressed in ['Day', 'Week', 'Month']) {
        final press = await tester.startGesture(
          tester.getCenter(find.text(pressed)),
        );
        // Held: the press springs to its full width and stays there.
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 34));
        }
        for (final label in ['Day', 'Week', 'Month']) {
          expect(lineOf(label), line, reason: '$label, $pressed pressed');
        }
        expect(tester.getSize(row), rest, reason: '$pressed pressed');
        await press.up();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('a focused segment\'s ring stands inside it: the next '
        'segment, 2dp on, would paint over a ring outside', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await tester.pumpWidget(
        _app(
          ExpressiveSegmentedButton<int>(
            expand: false,
            segments: const [
              ExpressiveButtonSegment(0, 'Day'),
              ExpressiveButtonSegment(1, 'Week'),
            ],
            value: 1,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final rings = [
        for (final paint in tester.widgetList<CustomPaint>(
          find.byType(CustomPaint),
        ))
          if (paint.foregroundPainter.runtimeType.toString() ==
              '_FocusRingPainter')
            paint.foregroundPainter!,
      ];
      expect(rings, hasLength(1));
      expect((rings.single as dynamic).inward, isTrue);
    });

    // The single-choice button reports its one value; the helper hands the
    // tests a set either way.
    Widget control({
      required Set<int> selected,
      ValueChanged<Set<int>>? onChanged,
      bool multi = false,
      TextDirection direction = TextDirection.ltr,
    }) {
      const segments = <ExpressiveButtonSegment<int>>[
        ExpressiveButtonSegment(0, 'Upcoming'),
        ExpressiveButtonSegment(1, 'Past'),
        ExpressiveButtonSegment(2, 'Saved'),
      ];
      return _app(
        SizedBox(
          width: 480,
          child: multi
              ? ExpressiveMultiChoiceSegmentedButton<int>(
                  segments: segments,
                  value: selected,
                  onChanged: onChanged,
                )
              : ExpressiveSegmentedButton<int>(
                  segments: segments,
                  value: selected.isEmpty ? null : selected.single,
                  onChanged: onChanged == null
                      ? null
                      : (value) => onChanged(<int>{value}),
                ),
        ),
        direction: direction,
      );
    }

    // Cody: "segmented choice commits on tap and drag, including RTL" (tap;
    // Material's connected group has no drag-to-select).
    testWidgets('Cody: segmented choice commits on tap, including RTL', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        var value = <int>{0};
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, update) => control(
              selected: value,
              onChanged: (v) => update(() => value = v),
              direction: direction,
            ),
          ),
        );
        await tester.tap(find.text('Past'), warnIfMissed: false);
        await _settle(tester);
        expect(value, <int>{1});
        await tester.tap(find.text('Saved'), warnIfMissed: false);
        await _settle(tester);
        expect(value, <int>{2});
        // Single select keeps its one selection.
        await tester.tap(find.text('Saved'), warnIfMissed: false);
        await _settle(tester);
        expect(value, <int>{2});
      }
    });

    // Cody: "disabled segmented picker and switch never mutate".
    testWidgets('Cody: disabled segmented picker never mutates', (
      tester,
    ) async {
      await tester.pumpWidget(control(selected: <int>{0}));
      await tester.tap(find.text('Past'), warnIfMissed: false);
      await _settle(tester);
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(
          find.descendant(
            of: find.widgetWithText(ExpressiveToggleButton, 'Past'),
            matching: find.byType(ExpressivePressable),
          ),
        ),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    // Cody: "segmented control accepts taps outside the painted 32pt slab".
    testWidgets('Cody: accepts taps outside the painted slab', (tester) async {
      var value = <int>{0};
      await tester.pumpWidget(
        control(selected: value, onChanged: (v) => value = v),
      );
      final segment = find.widgetWithText(ExpressiveToggleButton, 'Saved');
      final painted = tester.getRect(_surfaceIn(segment));
      final target = tester.getRect(segment);
      expect(painted.height, 40);
      expect(target.height, greaterThanOrEqualTo(48));
      await tester.tapAt(Offset(painted.center.dx, target.top + 2));
      expect(value, <int>{2});
    });

    testWidgets('multi select toggles each segment', (tester) async {
      var value = <int>{0};
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, update) => control(
            selected: value,
            multi: true,
            onChanged: (v) => update(() => value = v),
          ),
        ),
      );
      await tester.tap(find.text('Saved'), warnIfMissed: false);
      await _settle(tester);
      expect(value, <int>{0, 2});
      await tester.tap(find.text('Upcoming'), warnIfMissed: false);
      await _settle(tester);
      expect(value, <int>{2});
      await tester.tap(find.text('Saved'), warnIfMissed: false);
      await _settle(tester);
      expect(value, <int>{2}, reason: 'the last selection stays');
    });

    testWidgets('connected shapes: full outside, small inside, full checked', (
      tester,
    ) async {
      await tester.pumpWidget(control(selected: <int>{1}, onChanged: (_) {}));
      await _settle(tester);
      final first = _radii(
        tester,
        find.widgetWithText(ExpressiveToggleButton, 'Upcoming'),
      );
      expect(first.topLeft.x, 20);
      expect(
        first.topRight.x,
        ConnectedButtonGroupSmallTokens.innerCornerCornerSize,
      );
      final middle = _radii(
        tester,
        find.widgetWithText(ExpressiveToggleButton, 'Past'),
      );
      expect(middle.topLeft.x, 20, reason: 'checked rounds out');
      final last = _radii(
        tester,
        find.widgetWithText(ExpressiveToggleButton, 'Saved'),
      );
      expect(last.topLeft.x, 8);
      expect(last.bottomRight.x, 20);
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(
          find.descendant(
            of: find.widgetWithText(ExpressiveToggleButton, 'Past'),
            matching: find.byType(ExpressivePressable),
          ),
        ),
        isSemantics(
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      handle.dispose();
      expect(
        tester.getRect(find.text('Upcoming')).right,
        lessThan(tester.getRect(find.text('Past')).left),
      );
    });
  });

  group('ExpressiveLink', () {
    testWidgets('a tappable, underlined primary span in running text', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Text.rich(
            TextSpan(
              text: 'By continuing you accept the ',
              children: <InlineSpan>[
                ExpressiveLink.span('terms', onPressed: () => taps++),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('terms'));
      expect(text.style!.color, _c.primary);
      expect(text.style!.decoration, TextDecoration.underline);
      await tester.tap(find.text('terms'), warnIfMissed: false);
      expect(taps, 1);
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(ExpressivePressable)),
        isSemantics(isLink: true),
      );
      handle.dispose();
    });
  });

  group('content under a fixed width', () {
    void expectCentred(WidgetTester tester, String label) {
      final surface = tester.getRect(
        _surfaceIn(
          find.ancestor(
            of: find.text(label),
            matching: find.bySubtype<ExpressiveButton>(),
          ),
        ),
      );
      final text = tester.getRect(find.text(label));
      expect(text.center.dx, closeTo(surface.center.dx, 0.01));
      // Centred by its capitals (DesignCapCenter; the label check reads
      // them): its line box sits off the middle by the typeface's ascent and
      // descent, under a pixel and a half.
      expect(text.center.dy, closeTo(surface.center.dy, 1.5));
    }

    testWidgets('a sized button centres its label in the container', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 300,
            child: ExpressiveFilledButton('Continue', onPressed: () {}),
          ),
        ),
      );
      expect(_surfaceSize(tester).width, 300);
      expectCentred(tester, 'Continue');
    });

    testWidgets('a weighted group segment centres its label', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 330,
            child: ExpressiveButtonGroup(
              expand: true,
              children: <Widget>[
                ExpressiveFilledButton.tonal('Day', onPressed: () {}),
                ExpressiveFilledButton.tonal('Week', onPressed: () {}),
                ExpressiveFilledButton.tonal('Month', onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      for (final label in <String>['Day', 'Week', 'Month']) {
        expectCentred(tester, label);
      }
      // Pressing re-lays the segments out at new widths; still centred.
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Week')),
      );
      await _settle(tester);
      for (final label in <String>['Day', 'Week', 'Month']) {
        expectCentred(tester, label);
      }
      await gesture.up();
      await _settle(tester);
    });

    testWidgets('an unconstrained button keeps its own width', (tester) async {
      await tester.pumpWidget(
        _app(ExpressiveFilledButton('Go', onPressed: () {})),
      );
      expect(_surfaceSize(tester).width, lessThan(100));
      expectCentred(tester, 'Go');
    });
  });
}
