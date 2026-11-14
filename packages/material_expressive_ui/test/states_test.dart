/// The interaction states: the state-layer opacities from the generated
/// `StateTokens`, and the shared pressable every pressable component builds
/// on — taps and keyboard activation, the press and selected shape morph on
/// the component's spring, the ripple and state-layer colours, semantics
/// by role, elevation by state and the 48dp touch target.
library;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/state_tokens.g.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

final ExpressiveCornerBorder _rest = _theme.shapes.full;
final ExpressiveCornerBorder _pressed = _theme.shapes.small;
final ExpressiveCornerBorder _selected = _theme.shapes.medium;

Widget _app(Widget child) => ExpressiveHost(
  light: _theme,
  brightness: Brightness.light,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      // What WidgetsApp gives an app: Enter and Space activate.
      child: Shortcuts(
        shortcuts: WidgetsApp.defaultShortcuts,
        child: Center(child: child),
      ),
    ),
  ),
);

/// A pressable [size] × [size] with the test shapes.
Widget _pressable({
  VoidCallback? onPressed,
  ValueChanged<bool>? onPressedChanged,
  bool selected = false,
  ExpressivePressRole role = ExpressivePressRole.button,
  ExpressiveStateElevation elevation = ExpressiveStateElevation.none,
  double size = HostBehavior.minimumInteractiveComponentSize + 8,
  FocusNode? focusNode,
  Key? key,
}) => ExpressivePressable(
  key: key,
  shapes: ExpressivePressShapes(
    shape: _rest,
    pressed: _pressed,
    selected: _selected,
  ),
  motion: ButtonBehavior.pressMotion,
  color: _theme.colors.primary,
  contentColor: _theme.colors.onPrimary,
  onPressed: onPressed,
  onPressedChanged: onPressedChanged,
  selected: selected,
  role: role,
  elevation: elevation,
  focusNode: focusNode,
  semanticLabel: 'Save',
  child: SizedBox.square(dimension: size),
);

ShapeBorder _shapeOf(WidgetTester tester) =>
    tester.widget<ExpressiveSurface>(find.byType(ExpressiveSurface)).shape;

void main() {
  group('ExpressiveStateLayers', () {
    test('are the generated StateTokens, on every theme', () {
      const layers = ExpressiveStateLayers.tokens;
      expect(layers.hoverOpacity, StateTokens.hoverStateLayerOpacity);
      expect(layers.focusOpacity, StateTokens.focusStateLayerOpacity);
      expect(layers.pressedOpacity, StateTokens.pressedStateLayerOpacity);
      expect(layers.draggedOpacity, StateTokens.draggedStateLayerOpacity);
      expect(
        <double>[
          layers.hoverOpacity,
          layers.focusOpacity,
          layers.pressedOpacity,
          layers.draggedOpacity,
        ],
        <double>[0.08, 0.1, 0.1, 0.16],
      );
      for (final id in ExpressiveThemeData.presets) {
        for (final b in Brightness.values) {
          expect(ExpressiveThemeData.preset(id, b).states, layers);
        }
      }
    });

    test('show the strongest interaction, and nothing when disabled', () {
      const layers = ExpressiveStateLayers.tokens;
      expect(layers.opacityOf(<WidgetState>{}), 0);
      expect(layers.opacityOf({WidgetState.hovered}), 0.08);
      expect(layers.opacityOf({WidgetState.hovered, WidgetState.focused}), 0.1);
      expect(
        layers.opacityOf({WidgetState.focused, WidgetState.dragged}),
        0.16,
      );
      expect(layers.opacityOf({WidgetState.pressed, WidgetState.hovered}), 0.1);
      expect(layers.opacityOf({WidgetState.pressed, WidgetState.disabled}), 0);
      final content = _theme.colors.onPrimary;
      expect(layers.layerOf(content, <WidgetState>{}), isNull);
      expect(
        layers.layerOf(content, {WidgetState.hovered}),
        content.withValues(alpha: 0.08),
      );
      final container = _theme.colors.primary;
      expect(
        layers.composite(container, content, {WidgetState.focused}),
        Color.alphaBlend(content.withValues(alpha: 0.1), container),
      );
    });
  });

  group('ExpressivePressShapes', () {
    test('pressed wins over selected, selected over rest', () {
      final shapes = ExpressivePressShapes(
        shape: _rest,
        pressed: _pressed,
        selected: _selected,
      );
      expect(shapes.resolve(pressed: false), _rest);
      expect(shapes.resolve(pressed: false, selected: true), _selected);
      expect(shapes.resolve(pressed: true, selected: true), _pressed);
      expect(ExpressivePressShapes.all(_rest).resolve(pressed: true), _rest);
    });

    test(
      'ListItemShapes\' order: pressed, selected, focused, hovered, rest',
      () {
        final focused = _theme.shapes.large;
        final hovered = _theme.shapes.extraSmall;
        final shapes = ExpressivePressShapes(
          shape: _rest,
          pressed: _pressed,
          selected: _selected,
          focused: focused,
          hovered: hovered,
        );
        expect(shapes.resolve(pressed: false, hovered: true), hovered);
        expect(
          shapes.resolve(pressed: false, focused: true, hovered: true),
          focused,
        );
        expect(
          shapes.resolve(pressed: false, selected: true, focused: true),
          _selected,
        );
        expect(shapes.resolve(pressed: true, focused: true), _pressed);
      },
    );

    testWidgets('a pressable morphs to its hovered shape under a mouse, and '
        'to its focused shape on keyboard focus only', (tester) async {
      final hovered = _theme.shapes.extraSmall;
      final focused = _theme.shapes.large;
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _app(
          ExpressivePressable(
            shapes: ExpressivePressShapes(
              shape: _rest,
              hovered: hovered,
              focused: focused,
            ),
            motion: ButtonBehavior.pressMotion,
            color: _theme.colors.primary,
            contentColor: _theme.colors.onPrimary,
            focusNode: node,
            onPressed: () {},
            child: const SizedBox.square(dimension: 56),
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(ExpressivePressable)));
      await tester.pumpAndSettle();
      expect(_shapeOf(tester), hovered);
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(_shapeOf(tester), _rest);
      // Focus from a touch keeps the rest shape; from the keyboard it morphs.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(_shapeOf(tester), _rest);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await tester.pumpAndSettle();
      expect(_shapeOf(tester), focused);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    });
  });

  group('ExpressivePressable', () {
    testWidgets('a tap runs onPressed; disabled, nothing', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(_pressable(onPressed: () => taps++)));
      await tester.tap(find.byType(ExpressivePressable));
      await tester.pumpAndSettle();
      expect(taps, 1);

      await tester.pumpWidget(_app(_pressable()));
      await tester.tap(find.byType(ExpressivePressable), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('morphs to the pressed shape on the spring, and back', (
      tester,
    ) async {
      final changes = <bool>[];
      await tester.pumpWidget(
        _app(_pressable(onPressed: () {}, onPressedChanged: changes.add)),
      );
      expect(_shapeOf(tester), _rest);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ExpressivePressable)),
      );
      await tester.pump();
      expect(changes, <bool>[true]);
      // Mid-flight: neither end.
      await tester.pump(const Duration(milliseconds: 16));
      final mid = _shapeOf(tester);
      expect(mid, isNot(_rest));
      expect(mid, isNot(_pressed));
      await tester.pumpAndSettle();
      expect(_shapeOf(tester), _pressed);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(changes, <bool>[true, false]);
      expect(_shapeOf(tester), _rest);
    });

    testWidgets('press morph runs on the motion key\'s effects spring: '
        'no overshoot', (tester) async {
      await tester.pumpWidget(_app(_pressable(onPressed: () {})));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ExpressivePressable)),
      );
      final size = tester.getSize(find.byType(ExpressiveSurface));
      final rect = Offset.zero & size;
      double radius() =>
          (_shapeOf(tester) as ExpressiveCornerBorder).radiiOn(rect).topLeft.x;
      final target = _pressed.radiiOn(rect).topLeft.x;
      final start = radius();
      var lowest = start;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final r = radius();
        if (r < lowest) lowest = r;
      }
      expect(lowest, greaterThanOrEqualTo(target - 1e-6));
      expect(radius(), closeTo(target, 1e-3));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('selected wears the selected shape; a press still wins', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_pressable(onPressed: () {})));
      await tester.pumpWidget(
        _app(_pressable(onPressed: () {}, selected: true)),
      );
      await tester.pumpAndSettle();
      expect(_shapeOf(tester), _selected);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ExpressivePressable)),
      );
      await tester.pumpAndSettle();
      expect(_shapeOf(tester), _pressed);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_shapeOf(tester), _selected);
    });

    testWidgets('draws the ripple and state layers in the content colour', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_pressable(onPressed: () {})));
      final ink = tester.widget<InkResponse>(find.byType(InkResponse));
      final content = _theme.colors.onPrimary;
      expect(ink.splashColor, content.withValues(alpha: 0.1));
      expect(
        ink.overlayColor!.resolve({WidgetState.hovered}),
        content.withValues(alpha: 0.08),
      );
      expect(
        ink.overlayColor!.resolve({WidgetState.focused}),
        content.withValues(alpha: 0.1),
      );
      // The pressed layer is the ripple itself.
      expect(ink.overlayColor!.resolve({WidgetState.pressed}), isNull);
      expect(ink.highlightColor!.a, 0);
    });

    testWidgets('inkRect centres the unbounded ink on a part, drawn whole', (
      tester,
    ) async {
      const part = Rect.fromLTWH(4, 8, 16, 16);
      await tester.pumpWidget(
        _app(
          ExpressivePressable(
            shapes: ExpressivePressShapes.all(_rest),
            motion: ButtonBehavior.pressMotion,
            color: _theme.colors.primary,
            contentColor: _theme.colors.onPrimary,
            bounded: false,
            rippleRadius: 20,
            inkRect: (size) => part,
            onPressed: () {},
            child: const SizedBox(width: 52, height: 32),
          ),
        ),
      );
      final inkFinder = find.byWidgetPredicate((w) => w is InkResponse);
      expect(inkFinder, findsOneWidget);
      final ink = tester.widget<InkResponse>(inkFinder);
      final box = tester.renderObject<RenderBox>(inkFinder);
      // The ink reaches the ripple's radius past the pressable, so a circle
      // about a part at its edge is not clipped.
      expect(box.size, const Size(52 + 40, 32 + 40));
      final surface = tester.getRect(find.byType(ExpressiveSurface));
      final rect = ink
          .getRectCallback(box)!()
          .shift(box.localToGlobal(Offset.zero));
      expect(rect, part.shift(surface.topLeft));
      expect(ink.radius, 20);
      expect(ink.highlightShape, BoxShape.circle);
    });

    testWidgets('keyboard focus and Enter activate it', (tester) async {
      var taps = 0;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _app(_pressable(onPressed: () => taps++, focusNode: focus)),
      );
      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('keeps a 48dp touch target around a smaller container', (
      tester,
    ) async {
      const small = HostBehavior.minimumInteractiveComponentSize - 16;
      var taps = 0;
      await tester.pumpWidget(
        _app(_pressable(onPressed: () => taps++, size: small)),
      );
      expect(
        tester.getSize(find.byType(ExpressiveMinimumInteractiveSize)),
        const Size.square(HostBehavior.minimumInteractiveComponentSize),
      );
      expect(
        tester.getSize(find.byType(ExpressiveSurface)),
        const Size.square(small),
      );
      // A tap in the margin, outside the drawn container, still lands.
      final corner = tester.getTopLeft(
        find.byType(ExpressiveMinimumInteractiveSize),
      );
      await tester.tapAt(corner + const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(taps, 1);

      await tester.pumpWidget(
        _app(ExpressiveShrinkTapTargets(child: _pressable(size: small))),
      );
      expect(
        tester.getSize(find.byType(ExpressiveMinimumInteractiveSize)),
        const Size.square(small),
      );
    });

    testWidgets('states its role to assistive technology', (tester) async {
      final handle = tester.ensureSemantics();
      Future<SemanticsNode> nodeFor(
        ExpressivePressRole role, {
        bool selected = false,
      }) async {
        await tester.pumpWidget(
          _app(_pressable(onPressed: () {}, role: role, selected: selected)),
        );
        return tester.getSemantics(find.byType(ExpressivePressable));
      }

      expect(
        await nodeFor(ExpressivePressRole.button),
        isSemantics(
          label: 'Save',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        await nodeFor(ExpressivePressRole.toggle, selected: true),
        isSemantics(isButton: true, hasToggledState: true, isToggled: true),
      );
      expect(
        await nodeFor(ExpressivePressRole.tab, selected: true),
        isSemantics(isSelected: true),
      );
      expect(
        await nodeFor(ExpressivePressRole.radio),
        isSemantics(
          hasCheckedState: true,
          isChecked: false,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('raises its elevation by state', (tester) async {
      const elevation = ExpressiveStateElevation(
        rest: ExpressiveElevationLevel.level1,
        pressed: ExpressiveElevationLevel.level3,
      );
      await tester.pumpWidget(
        _app(_pressable(onPressed: () {}, elevation: elevation)),
      );
      ExpressiveElevationLevel level() => tester
          .widget<ExpressiveSurface>(find.byType(ExpressiveSurface))
          .shadowElevation;
      expect(level(), ExpressiveElevationLevel.level1);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ExpressivePressable)),
      );
      await tester.pumpAndSettle();
      expect(level(), ExpressiveElevationLevel.level3);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(level(), ExpressiveElevationLevel.level1);
    });

    testWidgets('content inherits the content colour', (tester) async {
      late Color text;
      late Color? icon;
      await tester.pumpWidget(
        _app(
          ExpressivePressable(
            shapes: ExpressivePressShapes.all(_rest),
            motion: ButtonBehavior.pressMotion,
            color: _theme.colors.secondaryContainer,
            contentColor: _theme.colors.onSecondaryContainer,
            onPressed: () {},
            child: Builder(
              builder: (context) {
                text = DefaultTextStyle.of(context).style.color!;
                icon = IconTheme.of(context).color;
                return const SizedBox.square(dimension: 56);
              },
            ),
          ),
        ),
      );
      expect(text, _theme.colors.onSecondaryContainer);
      expect(icon, _theme.colors.onSecondaryContainer);
    });

    group('a pressable inside (Compose: a child clickable)', () {
      const inner = Key('inner');

      /// A 240 × 56 pressable, enabled with [onPressed], holding a label
      /// and, at its end, the test pressable ('Save'): enabled with
      /// [onInner], disabled without.
      Widget outer({
        VoidCallback? onPressed,
        ValueChanged<bool>? onPressedChanged,
        VoidCallback? onInner,
      }) => _app(
        ExpressivePressable(
          shapes: ExpressivePressShapes.all(_rest),
          motion: ButtonBehavior.pressMotion,
          color: _theme.colors.surfaceContainer,
          contentColor: _theme.colors.onSurface,
          onPressed: onPressed,
          onPressedChanged: onPressedChanged,
          child: SizedBox(
            width: 240,
            height: 56,
            child: Row(
              children: <Widget>[
                const Expanded(child: Text('Label')),
                _pressable(key: inner, onPressed: onInner),
              ],
            ),
          ),
        ),
      );

      testWidgets('takes its own taps; the rest is the outer one\'s', (
        tester,
      ) async {
        var outerTaps = 0;
        var innerTaps = 0;
        final outerPressed = <bool>[];
        await tester.pumpWidget(
          outer(
            onPressed: () => outerTaps++,
            onPressedChanged: outerPressed.add,
            onInner: () => innerTaps++,
          ),
        );
        await tester.tap(find.byKey(inner));
        await tester.pumpAndSettle();
        expect((outerTaps, innerTaps), (0, 1));

        // Held, it is the inner one's alone: the outer one neither presses
        // nor ripples under it.
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(inner)),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(outerPressed, isEmpty);
        await gesture.up();
        await tester.pumpAndSettle();
        expect((outerTaps, innerTaps), (0, 2));

        // Anywhere else is the outer pressable's.
        await tester.tapAt(tester.getCenter(find.text('Label')));
        await tester.pumpAndSettle();
        expect((outerTaps, innerTaps), (1, 2));
        expect(outerPressed, <bool>[true, false]);
      });

      testWidgets('disabled, it consumes nothing: the tap is the outer '
          'one\'s', (tester) async {
        var outerTaps = 0;
        await tester.pumpWidget(outer(onPressed: () => outerTaps++));
        await tester.tapAt(tester.getCenter(find.byKey(inner)));
        await tester.pumpAndSettle();
        expect(outerTaps, 1);
      });

      testWidgets('inside a disabled one, it still takes its taps', (
        tester,
      ) async {
        var innerTaps = 0;
        await tester.pumpWidget(outer(onInner: () => innerTaps++));
        await tester.tap(find.byKey(inner));
        await tester.pumpAndSettle();
        expect(innerTaps, 1);
      });

      testWidgets('keeps a node of its own; the content\'s text still joins '
          'the outer one\'s', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(outer(onPressed: () {}, onInner: () {}));
        final outerNode = tester.getSemantics(find.text('Label'));
        expect(
          outerNode,
          isSemantics(
            label: 'Label',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
        final innerNode = tester.getSemantics(find.byKey(inner));
        expect(innerNode.isMergedIntoParent, isFalse);
        expect(
          innerNode,
          isSemantics(
            label: 'Save',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );

        // Disabled, it is the outer one's content again, merged into it.
        await tester.pumpWidget(outer(onPressed: () {}));
        expect(
          tester.getSemantics(find.text('Label')).getSemanticsData().label,
          'Label\nSave',
        );
        handle.dispose();
      });

      testWidgets('gaining and losing input leaves the outer node in place', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(outer(onPressed: () {}));
        final id = tester.getSemantics(find.text('Label')).id;
        await tester.pumpWidget(outer(onPressed: () {}, onInner: () {}));
        expect(tester.getSemantics(find.text('Label')).id, id);
        expect(tester.getSemantics(find.byKey(inner)).id, isNot(id));
        await tester.pumpWidget(outer(onPressed: () {}));
        expect(tester.getSemantics(find.text('Label')).id, id);
        handle.dispose();
      });
    });
  });

  group('ExpressiveSemanticsGroup', () {
    testWidgets(
      'activating semantics after layout keeps nested actions separate',
      (tester) async {
        const parent = ValueKey('lazy-semantics-parent');
        const action = ValueKey('lazy-semantics-action');
        expect(tester.binding.semanticsEnabled, isFalse);
        await tester.pumpWidget(
          _app(
            ExpressiveSemanticsGroup(
              key: parent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Notes'),
                  _pressable(key: action, onPressed: () {}),
                ],
              ),
            ),
          ),
        );
        for (var pass = 0; pass < 2; pass++) {
          final handle = tester.ensureSemantics();
          await tester.pump();
          final outer = tester.getSemantics(find.byKey(parent));
          final inner = tester.getSemantics(find.byKey(action));
          expect(outer.getSemanticsData().label, 'Notes');
          expect(inner.id, isNot(outer.id));
          expect(inner.isMergedIntoParent, isFalse);
          handle.dispose();
          await tester.pump();
          expect(tester.binding.semanticsEnabled, isFalse);
        }
        expect(tester.takeException(), isNull);
      },
      semanticsEnabled: false,
    );

    testWidgets('reparenting while semantics is off joins the new parent', (
      tester,
    ) async {
      const left = ValueKey('left-semantic-parent');
      const right = ValueKey('right-semantic-parent');
      final action = GlobalKey();
      Widget tree(bool moved, {bool enabled = true}) => _app(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (key, receives) in [(left, !moved), (right, moved)])
              ExpressiveSemanticsGroup(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(key == left ? 'Left' : 'Right'),
                    if (receives)
                      _pressable(
                        key: action,
                        onPressed: enabled ? () {} : null,
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
      await tester.pumpWidget(tree(false, enabled: false));
      await tester.pumpWidget(tree(true));
      final handle = tester.ensureSemantics();
      await tester.pump();
      final inner = tester.getSemantics(find.byKey(action));
      final outer = tester.getSemantics(find.byKey(right));
      expect(inner.parent, outer);
      expect(inner.isMergedIntoParent, isFalse);
      await tester.pumpWidget(tree(false));
      expect(
        tester.getSemantics(find.byKey(action)).parent,
        tester.getSemantics(find.byKey(left)),
      );
      handle.dispose();
      await tester.pump();
      expect(tester.takeException(), isNull);
    }, semanticsEnabled: false);

    testWidgets('merges its content, a container inside included', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          ExpressiveSemanticsGroup(
            child: Semantics(
              container: true,
              label: 'Passport',
              child: Semantics(
                container: true,
                checked: true,
                child: const SizedBox.square(dimension: 24),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(ExpressiveSemanticsGroup)),
        isSemantics(label: 'Passport', hasCheckedState: true, isChecked: true),
      );
      handle.dispose();
    });
  });
}
