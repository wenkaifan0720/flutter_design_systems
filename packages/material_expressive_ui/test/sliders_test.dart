/// The sliders family: the slider's geometry per size (track, handle, touch
/// target) from the generated tokens, Compose's input model (a tap moves
/// on release, a drag follows the finger, steps snap, keys step, RTL and
/// bottom-to-top reverse), the handle narrowing while held, the range
/// slider's nearer-handle rule, semantics, the value indicator; and the
/// quantity stepper. Ports Cody v2's slider and stepper tests
/// (foundation_controls_test.dart) to Expressive.
library;

import 'dart:ui' show SemanticsAction;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/slider_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/small_icon_button_tokens.g.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

/// [child] in a 300dp-wide column, under the Expressive host.
Widget _app(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double width = 300,
}) => ExpressiveHost(
  light: _theme,
  brightness: Brightness.light,
  child: Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Shortcuts(
        shortcuts: WidgetsApp.defaultShortcuts,
        child: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);

/// Cody's host: a padded, scrolling column (foundation_controls_test.dart).
Widget _codyHost(Widget child) => ExpressiveHost(
  light: _theme,
  brightness: Brightness.light,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    ),
  ),
);

/// The handle's pill (the only box the slider decorates at rest).
Rect _pill(WidgetTester tester, Finder slider) => tester.getRect(
  find.descendant(of: slider, matching: find.byType(DecoratedBox)).first,
);

/// The track's painted box.
Rect _track(WidgetTester tester, Finder slider) => tester.getRect(
  find.descendant(of: slider, matching: find.byType(CustomPaint)).first,
);

void main() {
  testWidgets('slider stateful overrides fall through to its component theme', (
    tester,
  ) async {
    const base = Color(0xff123456);
    const held = Color(0xff654321);
    const border = BeveledRectangleBorder(
      side: BorderSide(color: Color(0xff112233), width: 2),
    );
    final theme = _theme.copyWith(
      sliderTheme: const ExpressiveComponentThemeData(
        backgroundColor: WidgetStatePropertyAll(base),
      ),
    );
    await tester.pumpWidget(
      _app(
        ExpressiveTheme(
          data: theme,
          child: ExpressiveSlider(
            value: .5,
            onChanged: (_) {},
            style: ExpressiveComponentThemeData(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed) ? held : null,
              ),
              shape: const WidgetStatePropertyAll(border),
              side: const WidgetStatePropertyAll(
                BorderSide(color: Color(0xff112233), width: 2),
              ),
            ),
          ),
        ),
      ),
    );
    Color active() =>
        (tester.widget<CustomPaint>(find.byType(CustomPaint).first).painter
                    as dynamic)
                .activeTrackColor
            as Color;
    expect(active(), base);
    final decoration =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration
            as ShapeDecoration;
    expect(decoration.shape, border);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ExpressiveSlider)),
    );
    await tester.pump();
    expect(active(), held);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(active(), base);
  });

  testWidgets('slider padding keeps pointer coordinates in its track', (
    tester,
  ) async {
    double? changed;
    await tester.pumpWidget(
      _app(
        ExpressiveSlider(
          value: 0,
          onChanged: (value) => changed = value,
          style: const ExpressiveComponentThemeData(
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 24),
            ),
            minimumSize: WidgetStatePropertyAll(Size(0, 80)),
          ),
        ),
      ),
    );
    await tester.tapAt(tester.getCenter(find.byType(ExpressiveSlider)));
    await tester.pump();
    expect(changed, closeTo(.5, .01));
    expect(
      tester.getSize(find.byType(ExpressiveSlider)).height,
      greaterThanOrEqualTo(80),
    );
  });

  group('slider geometry', () {
    testWidgets('XS is Compose\'s default slider inside a 48dp target', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(ExpressiveSlider(value: 0.5, onChanged: (_) {})),
      );
      final slider = find.byType(ExpressiveSlider);
      expect(
        tester.getSize(slider).height,
        HostBehavior.minimumInteractiveComponentSize,
      );
      final pill = _pill(tester, slider);
      expect(pill.width, SliderTokens.handleWidth);
      expect(pill.height, SliderTokens.handleHeight);
      final track = _track(tester, slider);
      expect(track.height, SliderTokens.inactiveTrackHeight);
      // The track spans the slider less half a handle at each end.
      expect(track.width, 300 - SliderTokens.handleWidth);
      // At 0.5 the handle sits at the track's middle.
      expect(pill.center.dx, closeTo(track.center.dx, 0.01));
    });

    testWidgets('each size sets the track and the handle', (tester) async {
      const expected = <ExpressiveSliderSize, (double, double)>{
        ExpressiveSliderSize.extraSmall: (16, 44),
        ExpressiveSliderSize.small: (24, 44),
        ExpressiveSliderSize.medium: (40, 52),
        ExpressiveSliderSize.large: (56, 68),
        ExpressiveSliderSize.extraLarge: (96, 108),
      };
      for (final MapEntry(key: size, value: (track, handle))
          in expected.entries) {
        await tester.pumpWidget(
          _app(ExpressiveSlider(value: 0.3, size: size, onChanged: (_) {})),
        );
        final slider = find.byType(ExpressiveSlider);
        expect(_track(tester, slider).height, track, reason: '$size');
        expect(_pill(tester, slider).height, handle, reason: '$size');
        expect(
          tester.getSize(slider).height,
          handle < HostBehavior.minimumInteractiveComponentSize
              ? HostBehavior.minimumInteractiveComponentSize
              : handle,
          reason: '$size',
        );
      }
    });

    testWidgets('a stepped handle is inset by the track corner', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(ExpressiveSlider(value: 0.25, steps: 3, onChanged: (_) {})),
      );
      final slider = find.byType(ExpressiveSlider);
      final track = _track(tester, slider);
      final corner = track.height / 2;
      final expected = track.left + (track.width - corner * 2) * 0.25 + corner;
      expect(_pill(tester, slider).center.dx, closeTo(expected, 0.01));
    });

    testWidgets('the handle narrows to half while pressed', (tester) async {
      await tester.pumpWidget(
        _app(ExpressiveSlider(value: 0.5, onChanged: (_) {})),
      );
      final slider = find.byType(ExpressiveSlider);
      final gesture = await tester.startGesture(tester.getCenter(slider));
      await tester.pump();
      expect(
        _pill(tester, slider).width,
        SliderTokens.handleWidth / SliderBehavior.interactedThumbDivisor,
      );
      await gesture.up();
      await tester.pump();
      expect(_pill(tester, slider).width, SliderTokens.handleWidth);
    });

    testWidgets('an inset icon sits in the active track, else past it', (
      tester,
    ) async {
      Future<Rect> iconAt(double value) async {
        await tester.pumpWidget(
          _app(
            ExpressiveSlider(
              value: value,
              size: ExpressiveSliderSize.medium,
              icon: ExpressiveSymbols.volumeUp,
              onChanged: (_) {},
            ),
          ),
        );
        return tester.getRect(find.byType(Icon));
      }

      final high = await iconAt(0.8);
      final track = _track(tester, find.byType(ExpressiveSlider));
      expect(high.left, closeTo(track.left + ExpressiveSpacing.s10, 0.01));
      final low = await iconAt(0.02);
      expect(
        low.left,
        greaterThan(_pill(tester, find.byType(ExpressiveSlider)).right),
      );
    });
  });

  group('slider input', () {
    // Cody: 'stepped slider clamps and commits the final value'.
    testWidgets('stepped slider clamps and commits the final value', (
      tester,
    ) async {
      var value = 0.25;
      double? committed;
      await tester.pumpWidget(
        _codyHost(
          StatefulBuilder(
            builder: (context, update) => ExpressiveSlider(
              semanticLabel: 'Volume',
              value: value,
              steps: 3,
              onChanged: (v) => update(() => value = v),
              onChangeEnd: (v) => committed = v,
            ),
          ),
        ),
      );
      await tester.drag(find.byType(ExpressiveSlider), const Offset(900, 0));
      await tester.pumpAndSettle();
      expect(value, 1);
      expect(committed, 1);
    });

    testWidgets('a tap moves the value to the finger and commits', (
      tester,
    ) async {
      var value = 0.0;
      double? committed;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, update) => ExpressiveSlider(
              value: value,
              onChanged: (v) => update(() => value = v),
              onChangeEnd: (v) => committed = v,
            ),
          ),
        ),
      );
      final track = _track(tester, find.byType(ExpressiveSlider));
      await tester.tapAt(
        Offset(track.left + track.width * 0.75, track.center.dy),
      );
      await tester.pump();
      expect(value, closeTo(0.75, 0.001));
      expect(committed, closeTo(0.75, 0.001));
    });

    testWidgets('steps snap a tap to the nearest tick', (tester) async {
      var value = 0.0;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, update) => ExpressiveSlider(
              value: value,
              min: 0,
              max: 10,
              steps: 9,
              onChanged: (v) => update(() => value = v),
            ),
          ),
        ),
      );
      final track = _track(tester, find.byType(ExpressiveSlider));
      await tester.tapAt(
        Offset(track.left + track.width * 0.33, track.center.dy),
      );
      await tester.pump();
      expect(value, closeTo(3, 0.0001));
    });

    testWidgets('RTL runs the track from the right', (tester) async {
      var value = 0.5;
      await tester.pumpWidget(
        _app(
          direction: TextDirection.rtl,
          StatefulBuilder(
            builder: (context, update) => ExpressiveSlider(
              value: value,
              onChanged: (v) => update(() => value = v),
            ),
          ),
        ),
      );
      await tester.drag(find.byType(ExpressiveSlider), const Offset(-900, 0));
      await tester.pump();
      expect(value, 1);
      final slider = find.byType(ExpressiveSlider);
      expect(
        _pill(tester, slider).left,
        closeTo(
          _track(tester, slider).left - SliderTokens.handleWidth / 2,
          0.01,
        ),
      );
    });

    testWidgets('arrows step 1% (or one step), Home and End jump', (
      tester,
    ) async {
      var value = 0.5;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, update) => ExpressiveSlider(
              value: value,
              focusNode: focus,
              onChanged: (v) => update(() => value = v),
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.pump();
      // Focus narrows the handle, as a press does.
      expect(
        _pill(tester, find.byType(ExpressiveSlider)).width,
        SliderTokens.handleWidth / SliderBehavior.interactedThumbDivisor,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, closeTo(0.51, 1e-9));
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(value, closeTo(0.41, 1e-9));
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(value, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(value, 0);
    });

    testWidgets('keyboard focus rings the narrowed handle, concentric; a '
        'tap\'s focus does not', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await tester.pumpWidget(
        _app(ExpressiveSlider(value: 0.5, focusNode: focus, onChanged: (_) {})),
      );
      Iterable<CustomPaint> rings() => tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(ExpressiveSlider),
              matching: find.byType(CustomPaint),
            ),
          )
          .where((p) => '${p.foregroundPainter.runtimeType}' == '_HandleRing');
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      focus.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(rings(), isEmpty);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await tester.pump();
      expect(rings(), hasLength(1));
      // The ring's box is the narrowed pill grown by the gap and half the
      // stroke, its corners the pill's grown by the same.
      final pill = _pill(tester, find.byType(ExpressiveSlider));
      final canvas = TestRecordingCanvas();
      rings().single.foregroundPainter!.paint(canvas, pill.size);
      final drawn =
          canvas.invocations
                  .singleWhere((c) => c.invocation.memberName == #drawRRect)
                  .invocation
                  .positionalArguments
                  .first
              as RRect;
      const out =
          ExpressiveFocusRing.offset + ExpressiveFocusRing.thickness / 2;
      expect(drawn.outerRect, (Offset.zero & pill.size).inflate(out));
      expect(drawn.tlRadiusX, closeTo(pill.shortestSide / 2 + out, .01));
    });

    testWidgets('a disabled slider never reports', (tester) async {
      var reported = false;
      await tester.pumpWidget(
        _app(ExpressiveSlider(value: 0.5, onChanged: null)),
      );
      await tester.drag(find.byType(ExpressiveSlider), const Offset(100, 0));
      await tester.tap(find.byType(ExpressiveSlider));
      await tester.pump();
      expect(reported, isFalse);
      expect(
        _pill(tester, find.byType(ExpressiveSlider)).width,
        SliderTokens.handleWidth,
      );
    });

    testWidgets('a bottom-to-top vertical slider rises as it is dragged up', (
      tester,
    ) async {
      var value = 0.5;
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 240,
            child: StatefulBuilder(
              builder: (context, update) => ExpressiveVerticalSlider(
                value: value,
                topToBottom: false,
                onChanged: (v) => update(() => value = v),
              ),
            ),
          ),
        ),
      );
      final slider = find.byType(ExpressiveVerticalSlider);
      expect(_track(tester, slider).width, SliderTokens.inactiveTrackHeight);
      final pill = _pill(tester, slider);
      expect(pill.width, SliderTokens.handleHeight);
      expect(pill.height, SliderTokens.handleWidth);
      await tester.drag(slider, const Offset(0, -60));
      await tester.pump();
      expect(value, greaterThan(0.5));
    });
  });

  group('range slider', () {
    testWidgets('a press takes the nearer handle; handles never cross', (
      tester,
    ) async {
      var start = 0.2;
      var end = 0.6;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, update) => ExpressiveRangeSlider(
              start: start,
              end: end,
              onChanged: (s, e) => update(() {
                start = s;
                end = e;
              }),
            ),
          ),
        ),
      );
      final track = _track(tester, find.byType(ExpressiveRangeSlider));
      Offset at(double f) =>
          Offset(track.left + track.width * f, track.center.dy);
      await tester.tapAt(at(0.9));
      await tester.pump();
      expect(start, closeTo(0.2, 1e-9));
      expect(end, closeTo(0.9, 0.001));
      await tester.tapAt(at(0.1));
      await tester.pump();
      expect(start, closeTo(0.1, 0.001));
      // Dragging the start handle past the end stops at the end.
      await tester.dragFrom(at(0.1), Offset(track.width, 0));
      await tester.pump();
      expect(start, closeTo(end, 1e-9));
    });

    testWidgets('each handle is its own slider to a screen reader', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          ExpressiveRangeSlider(start: 0.25, end: 0.75, onChanged: (_, _) {}),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Minimum')),
        matchesSemantics(
          label: 'Minimum',
          value: '0.25',
          increasedValue: '0.26',
          decreasedValue: '0.24',
          isSlider: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          hasFocusAction: true,
        ),
      );
      expect(find.bySemanticsLabel('Maximum'), findsOneWidget);
      handle.dispose();
    });
  });

  group('slider semantics and indicator', () {
    testWidgets('the slider announces its value and steps by action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var value = 20.0;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, update) => ExpressiveSlider(
              value: value,
              min: 0,
              max: 100,
              steps: 9,
              semanticLabel: 'Brightness',
              valueLabel: (v) => '${v.round()}%',
              onChanged: (v) => update(() => value = v),
            ),
          ),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Brightness'));
      expect(node.value, '20%');
      expect(node.increasedValue, '30%');
      tester.semantics.increase(find.semantics.byLabel('Brightness'));
      await tester.pump();
      expect(value, 30);
      handle.dispose();
    });

    testWidgets('the value indicator shows while held', (tester) async {
      await tester.pumpWidget(
        _app(
          ExpressiveSlider(
            value: 0.4,
            valueLabel: (v) => '${(v * 100).round()}',
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('40'), findsNothing);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ExpressiveSlider)),
      );
      await tester.pumpAndSettle();
      final label = find.text('40');
      expect(label, findsOneWidget);
      final pill = _pill(tester, find.byType(ExpressiveSlider));
      expect(
        tester.getRect(label).bottom,
        lessThan(pill.top - SliderTokens.valueIndicatorActiveBottomSpace),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('40'), findsNothing);
    });
  });

  group('quantity stepper', () {
    // Cody: 'stepper repeats while held and stops at its bounds'.
    testWidgets('stepper repeats while held and stops at its bounds', (
      tester,
    ) async {
      var value = 2;
      await tester.pumpWidget(
        _codyHost(
          StatefulBuilder(
            builder: (context, update) => ExpressiveNumberField(
              value: value,
              min: 1,
              max: 5,
              label: 'Guests',
              onChanged: (v) => update(() => value = v),
            ),
          ),
        ),
      );
      final plus = find.bySemanticsLabel('Increase Guests');
      final gesture = await tester.startGesture(tester.getCenter(plus));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(value, 5);
      await tester.tap(plus);
      await tester.pumpAndSettle();
      expect(value, 5);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tap steps exactly once; keys and actions step too', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var value = 3;
      await tester.pumpWidget(
        _app(
          width: 200,
          StatefulBuilder(
            builder: (context, update) => ExpressiveNumberField(
              value: value,
              label: 'Servings',
              onChanged: (v) => update(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Increase Servings'));
      await tester.pumpAndSettle();
      expect(value, 4);
      await tester.tap(find.bySemanticsLabel('Decrease Servings'));
      await tester.pumpAndSettle();
      expect(value, 3);
      tester.semantics.tap(find.semantics.byLabel('Decrease Servings'));
      await tester.pumpAndSettle();
      expect(value, 2);
      handle.dispose();
    });

    testWidgets('buttons are the small icon button and disable at a bound', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(width: 200, ExpressiveNumberField(value: 0, onChanged: (_) {})),
      );
      final minus = find.bySemanticsLabel('Decrease Quantity');
      expect(
        tester
            .getSemantics(minus)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      final box = find
          .descendant(
            of: find.byType(ExpressiveNumberField),
            matching: find.byType(ExpressiveSurface),
          )
          .first;
      expect(
        tester.getSize(box),
        const Size.square(SmallIconButtonTokens.containerHeight),
      );
      expect(find.text('0'), findsOneWidget);
      handle.dispose();
    });
  });
}
