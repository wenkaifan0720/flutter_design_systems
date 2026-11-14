/// The selection controls: the checkbox (tri-state, error, disabled), the
/// radio button and group, the switch (thumb sizes and positions, press,
/// drag, RTL) and the labelled rows — geometry from the generated tokens,
/// what a tap or drag reports, and semantics. Ports Cody v2's toggle tests
/// (foundation_controls_test.dart, foundation_test.dart) to Expressive.
library;

import 'dart:ui' show CheckedState, SemanticsAction, Tristate;

import 'package:material_ui/material_ui.dart'
    show InkResponse, MaterialType, Material;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/checkbox_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/list_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/switch_tokens.g.dart';

import 'support/pressable.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

Widget _app(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
  ExpressiveThemeData? theme,
}) => ExpressiveHost(
  light: theme ?? _theme,
  brightness: Brightness.light,
  child: Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Shortcuts(
        shortcuts: WidgetsApp.defaultShortcuts,
        child: Center(child: child),
      ),
    ),
  ),
);

/// The switch's thumb: the box its layout places.
Rect _thumb(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byType(CustomSingleChildLayout),
        matching: find.byType(DecoratedBox),
      )
      .first,
);

/// The switch's track.
Rect _track(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byType(ExpressiveSwitch),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SizedBox &&
              w.width == SwitchTokens.trackWidth &&
              w.height == SwitchTokens.trackHeight,
        ),
      )
      .first,
);

const _zero = ExpressiveCornerBorder.all(ExpressiveCornerSize.dp(0));

/// An app's square shape scale: every step 0.
const _squareShapes = ExpressiveShapes(
  none: _zero,
  extraSmall: _zero,
  small: _zero,
  medium: _zero,
  large: _zero,
  largeIncreased: _zero,
  extraLarge: _zero,
  extraLargeIncreased: _zero,
  extraExtraLarge: _zero,
  full: _zero,
);

void main() {
  testWidgets(
    'checkbox style resolves the complete state and falls through to its theme',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      const base = Color(0xff123456);
      const focused = Color(0xff654321);
      final seen = <Set<WidgetState>>[];
      final theme = _theme.copyWith(
        checkboxTheme: const ExpressiveComponentThemeData(
          backgroundColor: WidgetStatePropertyAll(base),
          side: WidgetStatePropertyAll(BorderSide(width: 3)),
        ),
      );
      await tester.pumpWidget(
        _app(
          ExpressiveCheckbox(
            value: true,
            isError: true,
            focusNode: focus,
            onChanged: (_) {},
            style: ExpressiveComponentThemeData(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                seen.add({...states});
                return states.contains(WidgetState.focused) &&
                        states.contains(WidgetState.selected) &&
                        states.contains(WidgetState.error)
                    ? focused
                    : null;
              }),
            ),
          ),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();
      dynamic painter() => tester
          .widget<CustomPaint>(
            find.byWidgetPredicate(
              (w) =>
                  w is CustomPaint &&
                  w.painter.runtimeType.toString() == '_CheckboxPainter',
            ),
          )
          .painter;
      expect(painter().box, base);
      expect(painter().stroke, 3);
      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(painter().box, focused);
      expect(
        seen.any(
          (states) => states.containsAll({
            WidgetState.focused,
            WidgetState.selected,
            WidgetState.error,
          }),
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'switch style applies to its track and keeps the thumb contained',
    (tester) async {
      const shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(9)),
      );
      await tester.pumpWidget(
        _app(
          ExpressiveSwitch(
            value: true,
            onChanged: (_) {},
            style: const ExpressiveComponentThemeData(
              backgroundColor: WidgetStatePropertyAll(Color(0xff123456)),
              shape: WidgetStatePropertyAll(shape),
              side: WidgetStatePropertyAll(
                BorderSide(color: Color(0xff654321), width: 3),
              ),
              minimumSize: WidgetStatePropertyAll(Size(80, 40)),
            ),
          ),
        ),
      );
      final tracks = find.descendant(
        of: find.byType(ExpressiveSwitch),
        matching: find.byType(DecoratedBox),
      );
      final decoration =
          tester.widget<DecoratedBox>(tracks.first).decoration
              as ShapeDecoration;
      expect(decoration.color, const Color(0xff123456));
      expect((decoration.shape as OutlinedBorder).side.width, 3);
      expect(tester.getSize(tracks.first), const Size(80, 40));
      expect(
        tester.getRect(tracks.first).contains(_thumb(tester).center),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  group('checkbox', () {
    // Cody: 'the check reports the flipped value and springs on the way on'.
    testWidgets('reports the flipped value; ExpressiveCheckbox.mark is the '
        'box alone, not a control', (tester) async {
      bool? reported;
      await tester.pumpWidget(
        _app(ExpressiveCheckbox(value: false, onChanged: (v) => reported = v)),
      );
      expect(
        tester.getSize(find.byType(ExpressiveCheckbox)),
        const Size.square(HostBehavior.minimumInteractiveComponentSize),
      );
      await tester.tap(find.byType(ExpressiveCheckbox));
      expect(reported, isTrue);

      // Turning on draws the check on a spring that settles.
      await tester.pumpWidget(
        _app(ExpressiveCheckbox(value: true, onChanged: (v) => reported = v)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ExpressiveCheckbox));
      expect(reported, isFalse);

      await tester.pumpWidget(_app(const ExpressiveCheckbox.mark(value: true)));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(ExpressiveCheckbox),
          matching: find.byType(ExpressivePressable),
        ),
        findsNothing,
      );
      // The 20dp box in its 2dp padding: 24dp, no touch target.
      expect(
        tester.getSize(find.byType(ExpressiveCheckbox)),
        const Size.square(
          CheckboxBehavior.boxSize + CheckboxBehavior.boxPadding * 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tri-state: indeterminate reports checked, semantics mixed', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      bool? reported;
      await tester.pumpWidget(
        _app(
          ExpressiveCheckbox(
            value: null,
            tristate: true,
            semanticLabel: 'All items',
            onChanged: (v) => reported = v,
          ),
        ),
      );
      final data = tester
          .getSemantics(find.byType(ExpressiveCheckbox))
          .getSemanticsData();
      expect(data.flagsCollection.isChecked, CheckedState.mixed);
      expect(data.label, 'All items');
      await tester.tap(find.byType(ExpressiveCheckbox));
      expect(reported, isTrue);
      semantics.dispose();
    });

    testWidgets('disabled and error: never reports; error still paints', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ExpressiveCheckbox(value: false, onChanged: null),
              ExpressiveCheckbox(
                value: true,
                isError: true,
                onChanged: (_) => taps++,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(ExpressiveCheckbox).first);
      expect(taps, 0);
      await tester.tap(find.byType(ExpressiveCheckbox).last);
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Space toggles a focused checkbox', (tester) async {
      var value = false;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, update) => ExpressiveCheckbox(
              value: value,
              focusNode: focus,
              onChanged: (v) => update(() => value = v),
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });
  });

  group('radio', () {
    testWidgets('ring geometry, selection and semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      var picked = 0;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, update) => Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (var i = 0; i < 2; i++)
                  ExpressiveRadio(
                    selected: picked == i,
                    onPressed: () => update(() => picked = i),
                  ),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(ExpressiveRadio).first),
        const Size.square(HostBehavior.minimumInteractiveComponentSize),
      );
      await tester.tap(find.byType(ExpressiveRadio).last);
      await tester.pumpAndSettle();
      expect(picked, 1);
      final data = tester
          .getSemantics(find.byType(ExpressiveRadio).last)
          .getSemanticsData();
      expect(data.flagsCollection.isChecked, CheckedState.isTrue);
      expect(data.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      semantics.dispose();
    });

    // Cody: 'choice row retains selected semantics and disables activation'.
    testWidgets('radio rows keep checked semantics; a disabled row never '
        'activates', (tester) async {
      final semantics = tester.ensureSemantics();
      String? chosen;
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 360,
            child: ExpressiveRadioGroup<String>(
              value: 'everyday',
              onChanged: (v) => chosen = v,
              options: const <ExpressiveRadioOption<String>>[
                ExpressiveRadioOption<String>(
                  value: 'everyday',
                  label: 'Everyday',
                ),
                ExpressiveRadioOption<String>(
                  value: 'unavailable',
                  label: 'Unavailable',
                  enabled: false,
                ),
              ],
            ),
          ),
        ),
      );
      final everyday = tester
          .getSemantics(find.text('Everyday'))
          .getSemanticsData();
      expect(everyday.flagsCollection.isChecked, CheckedState.isTrue);
      final unavailable = tester
          .getSemantics(find.text('Unavailable'))
          .getSemanticsData();
      expect(unavailable.flagsCollection.isEnabled, Tristate.isFalse);
      await tester.tap(pressableOf(find.text('Unavailable')));
      expect(chosen, isNull);
      await tester.tap(pressableOf(find.text('Everyday')));
      expect(chosen, 'everyday');
      semantics.dispose();
    });

    // Cody: 'selection group keeps content inset at $direction/$scale'.
    for (final direction in TextDirection.values) {
      for (final scale in <double>[1, 2]) {
        testWidgets('radio group keeps its rows inset at $direction/$scale', (
          tester,
        ) async {
          var selected = 0;
          const groupKey = ValueKey<String>('group');
          await tester.pumpWidget(
            _app(
              direction: direction,
              scale: scale,
              StatefulBuilder(
                builder: (context, update) => SizedBox(
                  width: 350,
                  child: ExpressiveRadioGroup<int>(
                    key: groupKey,
                    value: selected,
                    onChanged: (v) => update(() => selected = v),
                    options: const <ExpressiveRadioOption<int>>[
                      ExpressiveRadioOption<int>(
                        value: 0,
                        label: 'Home studio',
                        supportingText:
                            '742 Evergreen Terrace, apartment 12, Springfield',
                      ),
                      ExpressiveRadioOption<int>(
                        value: 1,
                        label: 'Card ending 4242',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          final group = tester.getRect(find.byKey(groupKey));
          final radio = tester.getRect(find.byType(ExpressiveRadio).first);
          final inset = direction == TextDirection.ltr
              ? radio.left - group.left
              : group.right - radio.right;
          // The list's leading space, then the 24dp ring.
          expect(inset, closeTo(ListTokens.itemLeadingSpace, 0.01));
          expect(
            tester.getSize(find.byType(ExpressiveRadioRow).last).height,
            greaterThanOrEqualTo(ListTokens.itemOneLineContainerHeight),
          );
          await tester.tap(pressableOf(find.text('Card ending 4242')));
          await tester.pumpAndSettle();
          expect(selected, 1);
          await tester.tap(pressableOf(find.text('Home studio')));
          await tester.pumpAndSettle();
          expect(selected, 0);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  // Flutter clips ink to the material it paints on: a material only the
  // control's 24dp cut the 40dp halo to a 24dp square (the 11-09 state
  // sheets). Read on the pixels the hover paints.
  testWidgets('hover paints the whole 40dp halo about a checkbox and a '
      'radio: a circle, a square only for the checkbox on a square scale', (
    tester,
  ) async {
    for (final square in [false, true]) {
      for (final radio in [false, true]) {
        final where =
            '${radio ? 'radio' : 'checkbox'}, '
            '${square ? 'a square' : 'Material\'s'} shape scale';
        const key = ValueKey<String>('halo');
        await tester.pumpWidget(
          _app(
            RepaintBoundary(
              key: key,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: radio
                    ? ExpressiveRadio(selected: false, onPressed: () {})
                    : ExpressiveCheckbox(value: false, onChanged: (_) {}),
              ),
            ),
            theme: square ? _theme.copyWith(shapes: _squareShapes) : null,
          ),
        );
        await tester.pumpAndSettle();
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        final origin = tester.getTopLeft(find.byKey(key));
        final centre =
            tester.getCenter(
              find.byType(radio ? ExpressiveRadio : ExpressiveCheckbox),
            ) -
            origin;
        Future<ByteData> shot() async => (await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = await image.toByteData();
          image.dispose();
          return data!;
        }))!;
        int pixel(ByteData data, Offset at) => data.getUint32(
          (at.dy.floor() * boundary.size.width.round() + at.dx.floor()) * 4,
        );
        final idle = await shot();
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: tester.getCenter(find.byKey(key)));
        await tester.pumpAndSettle();
        final hovered = await shot();
        await mouse.removePointer();
        bool tinted(Offset at) =>
            pixel(idle, centre + at) != pixel(hovered, centre + at);

        // Past the control's 24dp box, inside the 20dp radius.
        for (final at in const [
          Offset(0, 17),
          Offset(17, 0),
          Offset(0, -17),
          Offset(-17, 0),
        ]) {
          expect(tinted(at), isTrue, reason: '$where: no halo at $at');
        }
        // Outside the circle, inside its square: tinted only where the
        // halo is a square.
        for (final at in const [
          Offset(16, 16),
          Offset(-16, 16),
          Offset(16, -16),
          Offset(-16, -16),
        ]) {
          expect(
            tinted(at),
            square && !radio,
            reason: '$where: the halo at $at',
          );
        }
        // Nothing past the halo.
        expect(tinted(const Offset(0, 22)), isFalse, reason: where);
      }
    }
    // Drawn pixels are the rasterizer's, as a golden's: macOS runs it.
  }, tags: const ['goldens']);

  group('switch', () {
    testWidgets('track, thumb sizes and positions from SwitchTokens', (
      tester,
    ) async {
      Future<void> pump(bool value, {Widget? icon}) async {
        await tester.pumpWidget(
          _app(
            ExpressiveSwitch(
              value: value,
              uncheckedIcon: icon,
              onChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pump(false);
      expect(
        tester.getSize(find.byType(ExpressiveSwitch)),
        const Size(
          SwitchTokens.trackWidth,
          HostBehavior.minimumInteractiveComponentSize,
        ),
      );
      final track = _track(tester);
      expect(
        track.size,
        const Size(SwitchTokens.trackWidth, SwitchTokens.trackHeight),
      );
      var thumb = _thumb(tester);
      expect(thumb.width, SwitchTokens.unselectedHandleWidth);
      // Centred vertically, (32 − 16) / 2 = 8dp in.
      expect(thumb.left - track.left, 8);
      expect(thumb.center.dy, track.center.dy);

      await pump(true);
      thumb = _thumb(tester);
      expect(thumb.width, SwitchTokens.selectedHandleWidth);
      // maxBound: (52 − 24) − (32 − 24) / 2 = 24dp.
      expect(thumb.left - track.left, 24);

      await pump(false, icon: const Icon(ExpressiveSymbols.close));
      thumb = _thumb(tester);
      expect(thumb.width, SwitchTokens.selectedHandleWidth);
      expect(thumb.left - track.left, 4);
      expect(
        tester.getSize(find.byIcon(ExpressiveSymbols.close)),
        const Size.square(SwitchTokens.selectedIconSize),
      );
    });

    testWidgets('the thumb grows to 28dp at once on press, springs back on '
        'release', (tester) async {
      await tester.pumpWidget(
        _app(ExpressiveSwitch(value: true, onChanged: (_) {})),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ExpressiveSwitch)),
      );
      await tester.pump();
      final track = _track(tester);
      var thumb = _thumb(tester);
      expect(thumb.width, SwitchTokens.pressedHandleWidth);
      // Pressed and checked: maxBound − the 2dp outline.
      expect(thumb.left - track.left, 22);
      await gesture.cancel();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      thumb = _thumb(tester);
      expect(thumb.width, SwitchTokens.selectedHandleWidth);
      expect(thumb.left - track.left, 24);
    });

    testWidgets('a pressed switch draws one press layer: the pressable\'s '
        'ink, centred on the thumb', (tester) async {
      await tester.pumpWidget(
        _app(ExpressiveSwitch(value: false, onChanged: (_) {})),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ExpressiveSwitch)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final inSwitch = find.descendant(
        of: find.byType(ExpressiveSwitch),
        matching: find.byWidgetPredicate((w) => w is InkResponse),
      );
      // One ink, the pressable's; nothing paints a held layer of its own.
      expect(inSwitch, findsOneWidget);
      // The only painters are the pressable's surface and its outline
      // (ExpressiveSurface, the transparent Material's border).
      final painters = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(ExpressiveSwitch),
              matching: find.byType(CustomPaint),
            ),
          )
          .expand((w) => <CustomPainter?>[w.painter, w.foregroundPainter])
          .whereType<CustomPainter>()
          .map((p) => p.runtimeType.toString())
          .toSet();
      expect(
        painters.difference(const {'_SurfacePainter', '_ShapeBorderPainter'}),
        isEmpty,
      );
      expect(
        find.descendant(
          of: find.byType(ExpressiveSwitch),
          matching: find.byType(ExpressivePressable),
        ),
        findsOneWidget,
      );
      // The press morph ran: the thumb is the pressed 28dp, unchecked at the
      // outline's inset.
      final track = _track(tester);
      final thumb = _thumb(tester);
      expect(thumb.width, SwitchTokens.pressedHandleWidth);
      expect(thumb.left - track.left, 2);
      // The ink's ripple and state layers centre on the thumb, at the state
      // layer's radius.
      final ink = tester.widget<InkResponse>(inSwitch);
      final box = tester.renderObject<RenderBox>(inSwitch);
      final origin = box.localToGlobal(Offset.zero);
      final rect = ink.getRectCallback(box)!().shift(origin);
      expect(rect.center.dx, closeTo(thumb.center.dx, 0.5));
      expect(rect.center.dy, closeTo(thumb.center.dy, 0.5));
      expect(ink.radius, SwitchTokens.stateLayerSize / 2);
      expect(ink.splashColor, _theme.colors.onSurface.withValues(alpha: 0.1));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    // Cody: 'toggle supports dragging and semantic toggled state'.
    testWidgets('supports dragging and semantic toggled state', (tester) async {
      final semantics = tester.ensureSemantics();
      var value = false;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, update) => ExpressiveSwitch(
              value: value,
              semanticLabel: 'Notify me',
              onChanged: (v) => update(() => value = v),
            ),
          ),
        ),
      );
      await tester.drag(find.byType(ExpressiveSwitch), const Offset(55, 0));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      final data = tester
          .getSemantics(find.byType(ExpressiveSwitch))
          .getSemanticsData();
      expect(data.flagsCollection.isToggled, Tristate.isTrue);
      expect(data.label, 'Notify me');
      await tester.tap(find.byType(ExpressiveSwitch));
      await tester.pumpAndSettle();
      expect(value, isFalse);
      semantics.dispose();
    });

    testWidgets('drags toward the start under RTL', (tester) async {
      var value = false;
      await tester.pumpWidget(
        _app(
          direction: TextDirection.rtl,
          StatefulBuilder(
            builder: (context, update) => ExpressiveSwitch(
              value: value,
              onChanged: (v) => update(() => value = v),
            ),
          ),
        ),
      );
      await tester.drag(find.byType(ExpressiveSwitch), const Offset(55, 0));
      await tester.pumpAndSettle();
      expect(value, isFalse);
      await tester.drag(find.byType(ExpressiveSwitch), const Offset(-55, 0));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      final track = _track(tester);
      // Checked sits at the end: the left, in RTL.
      expect(_thumb(tester).left - track.left, 4);
    });

    // Cody: 'disabled segmented picker and switch never mutate'.
    testWidgets('a disabled switch never mutates', (tester) async {
      var changes = 0;
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ExpressiveSwitch(value: false, onChanged: null),
              const ExpressiveSwitch(value: true),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(ExpressiveSwitch).first);
      await tester.drag(
        find.byType(ExpressiveSwitch).first,
        const Offset(50, 0),
      );
      await tester.drag(
        find.byType(ExpressiveSwitch).last,
        const Offset(-50, 0),
      );
      await tester.pumpAndSettle();
      expect(changes, 0);
      expect(tester.takeException(), isNull);
    });
  });

  // Flutter's rule (Material's and Cupertino's Checkbox, Radio, Switch and
  // their list tiles): a null handler disables the control at its full
  // size, so a developer swapping the import keeps a 48dp control that
  // reads as disabled. The bare mark a row puts inside itself is `.mark`.
  testWidgets('a null handler disables a checkbox, radio, switch or row at '
      'full size; .mark is the bare control', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const ExpressiveCheckbox(value: true, semanticLabel: 'Box'),
              const ExpressiveRadio(selected: true, semanticLabel: 'Ring'),
              const ExpressiveSwitch(value: true, semanticLabel: 'Toggle'),
              const ExpressiveCheckboxRow(label: 'Receipts', value: true),
              const ExpressiveSwitchRow(label: 'Alerts', value: false),
              const ExpressiveRadioGroup<String>(
                value: 'a',
                options: <ExpressiveRadioOption<String>>[
                  ExpressiveRadioOption(value: 'a', label: 'Monthly'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    const target = HostBehavior.minimumInteractiveComponentSize;
    expect(
      tester.getSize(find.byType(ExpressiveCheckbox).first),
      const Size.square(target),
    );
    expect(
      tester.getSize(find.byType(ExpressiveRadio).first),
      const Size.square(target),
    );
    expect(tester.getSize(find.byType(ExpressiveSwitch).first).height, target);
    for (final label in <String>['Box', 'Ring', 'Toggle']) {
      final data = tester.getSemantics(find.bySemanticsLabel(label));
      expect(
        data.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
        reason: label,
      );
      expect(
        data.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
        reason: label,
      );
    }
    // Disabled colours: the disabled checked box, the rows' words dimmed.
    final dim = _theme.colors.onSurface.withValues(
      alpha: CheckboxTokens.unselectedDisabledContainerOpacity,
    );
    for (final label in <String>['Receipts', 'Alerts', 'Monthly']) {
      expect(
        tester.widget<Text>(find.text(label)).style!.color,
        dim,
        reason: label,
      );
    }
    await tester.tap(find.byType(ExpressiveSwitch).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // The marks: no pressable, their own size, enabled colours.
    await tester.pumpWidget(
      _app(
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ExpressiveCheckbox.mark(value: true),
            ExpressiveRadio.mark(selected: true),
            ExpressiveSwitch.mark(value: true),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ExpressivePressable), findsNothing);
    expect(
      tester.getSize(find.byType(ExpressiveSwitch)),
      const Size(SwitchTokens.trackWidth, SwitchTokens.trackHeight),
    );
    expect(
      tester.getSize(find.byType(ExpressiveRadio)).height,
      lessThan(target),
    );
    semantics.dispose();
  });

  group('rows', () {
    testWidgets('the whole row toggles; the control inside is a mark', (
      tester,
    ) async {
      var alerts = false;
      var receipts = false;
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 360,
            child: StatefulBuilder(
              builder: (context, update) => Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ExpressiveSwitchRow(
                    label: 'Price alerts',
                    value: alerts,
                    checkedIcon: const Icon(ExpressiveSymbols.check),
                    onChanged: (v) => update(() => alerts = v),
                  ),
                  ExpressiveCheckboxRow(
                    label: 'Email me receipts',
                    value: receipts,
                    onChanged: (v) => update(() => receipts = v),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(ExpressiveSwitchRow)).height,
        ListTokens.itemOneLineContainerHeight,
      );
      // The switch at the end, the checkbox at the start.
      final row = tester.getRect(find.byType(ExpressiveSwitchRow));
      expect(
        row.right - tester.getRect(find.byType(ExpressiveSwitch)).right,
        ListTokens.itemTrailingSpace,
      );
      await tester.tap(pressableOf(find.text('Price alerts')));
      await tester.pumpAndSettle();
      expect(alerts, isTrue);
      await tester.tap(pressableOf(find.byType(ExpressiveSwitch)));
      await tester.pumpAndSettle();
      expect(alerts, isFalse);
      await tester.tap(pressableOf(find.text('Email me receipts')));
      await tester.pumpAndSettle();
      expect(receipts, isTrue);
      expect(
        find.descendant(
          of: find.byType(ExpressiveCheckbox),
          matching: find.byType(ExpressivePressable),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('disabled rows dim and never report', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ExpressiveCheckboxRow(
                  label: 'Sold out',
                  value: false,
                  enabled: false,
                  onChanged: (_) => taps++,
                ),
                ExpressiveSwitchRow(
                  label: 'Managed',
                  value: true,
                  enabled: false,
                  onChanged: (_) => taps++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(pressableOf(find.text('Sold out')));
      await tester.tap(pressableOf(find.text('Managed')));
      await tester.pumpAndSettle();
      expect(taps, 0);
      final text = tester.widget<Text>(find.text('Sold out'));
      expect(
        text.style!.color,
        _theme.colors.onSurface.withValues(
          alpha: CheckboxTokens.unselectedDisabledContainerOpacity,
        ),
      );
    });
  });

  testWidgets('every control in a transparent Material (the host) and at '
      'text scale 2 lays out without exceptions', (tester) async {
    await tester.pumpWidget(
      _app(
        scale: 2,
        Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            child: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ExpressiveCheckboxRow(
                    label: 'A label long enough to wrap onto a second line',
                    supportingText: 'And supporting text under it',
                    value: null,
                    tristate: true,
                    onChanged: (_) {},
                  ),
                  ExpressiveSwitchRow(
                    label: 'A label long enough to wrap onto a second line',
                    value: true,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
