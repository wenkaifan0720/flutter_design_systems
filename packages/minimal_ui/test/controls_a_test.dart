import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderEditable, RenderParagraph;
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

// The host stands above the Navigator, as an app mounts it.
Widget _host(Widget child, {MinimalDensity? density}) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset(
      'standard',
      Brightness.light,
    ).copyWith(density: density),
    dark: MinimalThemeData.preset(
      'standard',
      Brightness.dark,
    ).copyWith(density: density),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: Center(
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  ),
);

/// A parent that owns a value, as a page does, for controls that report
/// changes rather than keep them.
class _Owner<T> extends StatefulWidget {
  const _Owner({required this.initial, required this.builder});

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;

  @override
  State<_Owner<T>> createState() => _OwnerState<T>();
}

class _OwnerState<T> extends State<_Owner<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}

/// Geist's cap height over its em: the capitals Minimal centres a line by.
const double _capHeight = 0.710;

/// Where the capitals of the line under [root] (its editable, or its
/// paragraph) are drawn, their middle in global coordinates: the baseline on
/// the whole logical pixel the engine puts it on, the capitals' height above
/// it, wherever the line is painted (a cap label moves what it paints).
double _capitalsMiddle(RenderObject root) {
  RenderBox? line;
  void visit(RenderObject node) {
    if (line != null) return;
    if (node is RenderEditable || node is RenderParagraph) {
      line = node as RenderBox;
      return;
    }
    node.visitChildren(visit);
  }

  visit(root);
  final box = line!;
  // The size the first words are set in, the spans' styles merged down to
  // them (an empty line's own style's), as ui_core reads it.
  double? sizeOf(InlineSpan? span, [TextStyle? inherited]) {
    if (span == null) return null;
    final own = inherited == null ? span.style : inherited.merge(span.style);
    if (span is TextSpan) {
      if (span.text?.isNotEmpty ?? false) return own?.fontSize;
      for (final child in span.children ?? const <InlineSpan>[]) {
        final found = sizeOf(child, own);
        if (found != null) return found;
      }
    }
    return inherited == null ? own?.fontSize : null;
  }

  final (size, scaler) = switch (box) {
    final RenderParagraph p => (sizeOf(p.text), p.textScaler),
    final RenderEditable e => (sizeOf(e.text), e.textScaler),
    _ => (null, TextScaler.noScaling),
  };
  final fontSize = scaler.scale(size ?? 14);
  final laid = box.getDryBaseline(box.constraints, TextBaseline.alphabetic)!;
  final baseline = (laid + 0.5).floorToDouble();
  return box.localToGlobal(Offset(0, baseline - _capHeight * fontSize / 2)).dy;
}

void main() {
  group('MinimalSwitch', () {
    testWidgets('a tap flips it, and it announces a labelled switch', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <bool>[];
      await tester.pumpWidget(
        _host(
          _Owner<bool>(
            initial: false,
            builder: (v, set) => MinimalSwitch(
              value: v,
              label: 'Reminders',
              onChanged: (next) {
                seen.add(next);
                set(next);
              },
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Reminders')),
        matchesSemantics(
          label: 'Reminders',
          isButton: true,
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.tap(find.byType(MinimalSwitch));
      await tester.pumpAndSettle();
      expect(seen, [true]);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Reminders')),
        matchesSemantics(
          label: 'Reminders',
          isButton: true,
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a drag throws the thumb; Space flips it from the keyboard', (
      tester,
    ) async {
      final seen = <bool>[];
      await tester.pumpWidget(
        _host(
          _Owner<bool>(
            initial: false,
            builder: (v, set) => MinimalSwitch(
              value: v,
              label: 'Digest',
              onChanged: (next) {
                seen.add(next);
                set(next);
              },
            ),
          ),
        ),
      );
      await tester.drag(find.byType(MinimalSwitch), const Offset(30, 0));
      await tester.pumpAndSettle();
      expect(seen, [true]);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(seen, [true, false]);
    });

    testWidgets('with no onChanged it is disabled and swallows taps', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const MinimalSwitch(value: true, label: 'Sync')),
      );
      await tester.tap(find.byType(MinimalSwitch), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Sync')),
        matchesSemantics(
          label: 'Sync',
          isButton: true,
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('an on thumb is the paper in light and the accent ink in '
        'dark', (tester) async {
      Color thumb() => tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: find.byType(MinimalSwitch),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .map((c) => c.decoration)
          .whereType<ShapeDecoration>()
          .firstWhere((d) => d.shape is CircleBorder)
          .color!;
      Widget host(String preset, Brightness b) => MaterialApp(
        builder: (context, navigator) => MinimalHost(
          light: MinimalThemeData.preset(preset, Brightness.light),
          dark: MinimalThemeData.preset(preset, Brightness.dark),
          brightness: b,
          child: navigator!,
        ),
        home: Center(child: MinimalSwitch(value: true, onChanged: (_) {})),
      );
      for (final preset in MinimalThemeData.presets) {
        await tester.pumpWidget(host(preset, Brightness.light));
        await tester.pumpAndSettle();
        expect(thumb(), MinimalThemeData.preset(preset, Brightness.light).card);
        await tester.pumpWidget(host(preset, Brightness.dark));
        await tester.pumpAndSettle();
        expect(
          thumb(),
          MinimalThemeData.preset(preset, Brightness.dark).primaryForeground,
        );
      }
    });

    testWidgets('its 18 px track lands taps across a 44 px target', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(MinimalSwitch(value: false, onChanged: (_) => taps += 1)),
      );
      final box = tester.getRect(find.byType(MinimalSwitch));
      expect(box.height, 18);
      await tester.tapAt(box.topCenter - const Offset(0, 12));
      expect(taps, 1);
    });
  });

  group('MinimalCheckbox', () {
    testWidgets('a tap ticks it, and it announces its checked state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <bool>[];
      await tester.pumpWidget(
        _host(
          _Owner<bool>(
            initial: false,
            builder: (v, set) => MinimalCheckbox(
              value: v,
              label: 'Meditate',
              onChanged: (next) {
                seen.add(next);
                set(next);
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(MinimalCheckbox));
      await tester.pumpAndSettle();
      expect(seen, [true]);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Meditate')),
        matchesSemantics(
          label: 'Meditate',
          isButton: true,
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('MinimalCheckMark is a mark: checked, not a control', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const MinimalCheckMark(value: true, label: 'Kept')),
      );
      expect(find.byType(MinimalPressable), findsNothing);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Kept')),
        matchesSemantics(label: 'Kept', hasCheckedState: true, isChecked: true),
      );
      handle.dispose();
    });

    testWidgets('a null onChanged disables it: it dims', (tester) async {
      await tester.pumpWidget(
        _host(const MinimalCheckbox(value: false, onChanged: null)),
      );
      final opacity = tester.widget<AnimatedOpacity>(
        find
            .descendant(
              of: find.byType(MinimalPressable),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      );
      expect(opacity.opacity, 0.45);
    });
  });

  group('MinimalSlider', () {
    testWidgets('a tap on the track sets the value, quantised', (tester) async {
      final seen = <double>[];
      double? ended;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 316,
            child: MinimalSlider(
              label: 'Goal',
              value: 10,
              min: 10,
              max: 50,
              divisions: 8,
              onChanged: seen.add,
              onChangeEnd: (v) => ended = v,
            ),
          ),
        ),
      );
      final track = tester.getRect(find.byType(CustomPaint).last);
      // Three quarters along the travel: 40.
      await tester.tapAt(
        Offset(track.left + 8 + (track.width - 16) * 0.74, track.center.dy),
      );
      await tester.pumpAndSettle();
      expect(seen.last, 40);
      expect(ended, 40);
    });

    testWidgets('it announces a slider with its value, and the arrow keys '
        'step it', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            child: _Owner<double>(
              initial: 0.5,
              builder: (v, set) => MinimalSlider(
                label: 'Volume',
                value: v,
                valueLabel: '${(v * 100).round()}%',
                onChanged: set,
              ),
            ),
          ),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Volume'));
      expect(node.value, '50%');
      expect(node.getSemanticsData().flagsCollection.isSlider, isTrue);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.increase),
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.bySemanticsLabel('Volume')).value, '60%');
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.bySemanticsLabel('Volume')).value, '0%');
      handle.dispose();
    });

    testWidgets('a formatted value announces every step in its own units; '
        'a fixed label never switches to a percentage', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MinimalSlider(
                  label: 'Daily reading goal',
                  value: 20,
                  min: 10,
                  max: 50,
                  divisions: 8,
                  unit: 'pages',
                  onChanged: (_) {},
                ),
                MinimalSlider(
                  label: 'Snooze',
                  value: 0.3,
                  valueLabel: '10',
                  unit: 'min',
                  onChanged: (_) {},
                ),
                MinimalSlider(label: 'Chime', value: 0.5, onChanged: (_) {}),
              ],
            ),
          ),
        ),
      );
      SemanticsData node(String label) =>
          tester.getSemantics(find.bySemanticsLabel(label)).getSemanticsData();
      final pages = node('Daily reading goal');
      expect(pages.value, '20 pages');
      expect(pages.increasedValue, '25 pages');
      expect(pages.decreasedValue, '15 pages');
      expect(find.text('20 pages'), findsOneWidget);
      // The figure prints in mono, the unit word in the body face.
      final line = tester.widget<Text>(find.text('20 pages'));
      final spans = (line.textSpan! as TextSpan).children!.cast<TextSpan>();
      final t = MinimalThemeData.preset('standard', Brightness.light);
      expect(spans.first.text, '20');
      expect(spans.first.style!.fontFamily, t.mono.fontFamily);
      expect(spans.last.text, ' pages');
      expect(spans.last.style!.fontFamily, t.body.fontFamily);
      final snooze = node('Snooze');
      expect(snooze.value, '10 min');
      expect(snooze.increasedValue, '10 min');
      expect(snooze.decreasedValue, '10 min');
      final chime = node('Chime');
      expect(chime.value, '50%');
      expect(chime.increasedValue, '60%');
      expect(chime.decreasedValue, '40%');
      handle.dispose();
    });
  });

  group('MinimalNumberField', () {
    testWidgets('its buttons step within the bounds and announce the value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <int>[];
      await tester.pumpWidget(
        _host(
          _Owner<int>(
            initial: 2,
            builder: (v, set) => MinimalNumberField(
              value: v,
              min: 1,
              max: 3,
              label: 'Sets',
              onChanged: (next) {
                seen.add(next);
                set(next);
              },
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Increase Sets')),
        matchesSemantics(
          label: 'Increase Sets',
          value: '2',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Increase Sets'));
      await tester.pump();
      expect(seen, [3]);
      expect(find.text('3'), findsOneWidget);
      // At the max, increase disables itself.
      final atMax = tester
          .getSemantics(find.bySemanticsLabel('Increase Sets'))
          .getSemanticsData();
      expect(atMax.value, '3');
      expect(atMax.flagsCollection.isEnabled, Tristate.isFalse);
      await tester.tap(
        find.bySemanticsLabel('Increase Sets'),
        warnIfMissed: false,
      );
      await tester.tap(find.bySemanticsLabel('Decrease Sets'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Decrease Sets'));
      await tester.pump();
      // At the min, decrease has disabled itself.
      await tester.tap(
        find.bySemanticsLabel('Decrease Sets'),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(seen, [3, 2, 1]);
      handle.dispose();
    });

    testWidgets('holding a button repeats until released', (tester) async {
      final seen = <int>[];
      await tester.pumpWidget(
        _host(
          _Owner<int>(
            initial: 0,
            builder: (v, set) => MinimalNumberField(
              value: v,
              min: 0,
              max: 20,
              label: 'Pages',
              onChanged: (next) {
                seen.add(next);
                set(next);
              },
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.bySemanticsLabel('Increase Pages')),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await tester.pump(const Duration(seconds: 1));
      expect(seen.length, greaterThan(2));
      expect(seen, [for (var i = 1; i <= seen.length; i++) i]);
    });

    testWidgets('its 32 px strip lands taps across a 44 px target, and with '
        'no onChanged it is disabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          MinimalNumberField(
            value: 1,
            min: 0,
            max: 3,
            label: 'Rest',
            onChanged: (_) => taps += 1,
          ),
        ),
      );
      final plus = tester.getRect(find.bySemanticsLabel('Increase Rest'));
      await tester.tapAt(plus.topCenter - const Offset(0, 6));
      expect(taps, 1);

      await tester.pumpWidget(
        _host(
          const MinimalNumberField(value: 1, min: 0, max: 3, label: 'Rest'),
        ),
      );
      await tester.tap(
        find.bySemanticsLabel('Increase Rest'),
        warnIfMissed: false,
      );
      expect(taps, 1);
      // Disabled, the whole frame dims once — not just its glyphs.
      final dim = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byType(MinimalNumberField),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(dim.opacity, 0.45);
      expect(find.byType(MinimalPressable), findsNothing);
    });

    testWidgets('a unit prints in the body face after the mono figure, and '
        'is announced with it', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          MinimalNumberField(
            value: 20,
            min: 5,
            max: 50,
            step: 5,
            label: 'Pages',
            unit: 'pages',
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Increase Pages'))
            .getSemanticsData()
            .value,
        '20 pages',
      );
      final t = MinimalThemeData.preset('standard', Brightness.light);
      final shown = tester
          .widgetList<Text>(find.text('20 pages'))
          .where((w) => w.textSpan != null)
          .single;
      final spans = (shown.textSpan! as TextSpan).children!.cast<TextSpan>();
      expect(spans.first.style!.fontFamily, t.mono.fontFamily);
      expect(spans.last.text, ' pages');
      expect(spans.last.style!.fontFamily, t.body.fontFamily);
      handle.dispose();
    });

    testWidgets('steppers of different ranges share one footprint', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinimalNumberField(value: 3, min: 1, max: 5, onChanged: (_) {}),
              MinimalNumberField(value: 20, min: 5, max: 50, onChanged: (_) {}),
            ],
          ),
        ),
      );
      final sizes = tester
          .widgetList<MinimalNumberField>(find.byType(MinimalNumberField))
          .map((w) => tester.getSize(find.byWidget(w)).width)
          .toList();
      expect(sizes[0], sizes[1]);
    });

    testWidgets('a stepper with a unit lines up with ones without', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MinimalNumberField(
                value: 6,
                min: 1,
                max: 12,
                format: (v) => '$v×',
                onChanged: (_) {},
              ),
              // A short unit (the test face sets every glyph an em wide).
              MinimalNumberField(
                value: 2,
                min: 1,
                max: 12,
                unit: 'h',
                onChanged: (_) {},
              ),
              MinimalNumberField(value: 3, min: 1, max: 5, onChanged: (_) {}),
            ],
          ),
        ),
      );
      final widths = tester
          .widgetList<MinimalNumberField>(find.byType(MinimalNumberField))
          .map((w) => tester.getSize(find.byWidget(w)).width)
          .toSet();
      expect(widths, hasLength(1));
    });
  });

  group('MinimalCounter', () {
    testWidgets('it rolls to the new value and lands exactly on it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(MinimalCounter(12, format: (v) => '${v}d')),
      );
      expect(find.bySemanticsLabel('12d'), findsOneWidget);

      await tester.pumpWidget(
        _host(MinimalCounter(13, format: (v) => '${v}d')),
      );
      await tester.pump(const Duration(milliseconds: 60));
      // Mid-roll: the old units digit leaves while the new one arrives.
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsNothing);
      expect(find.bySemanticsLabel('13d'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('under disableAnimations it swaps at once', (tester) async {
      Widget counter(int v) => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MinimalCounter(v),
      );
      await tester.pumpWidget(_host(counter(9)));
      await tester.pumpWidget(_host(counter(10)));
      await tester.pump();
      expect(find.text('9'), findsNothing);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('MinimalSegmentedButton', () {
    testWidgets('a tap picks a segment, which announces itself selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <int>[];
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            child: _Owner<int>(
              initial: 0,
              builder: (v, set) => MinimalSegmentedButton(
                segments: const [
                  MinimalButtonSegment(0, 'Week'),
                  MinimalButtonSegment(1, 'Month'),
                  MinimalButtonSegment(2, 'Year'),
                ],
                value: v,
                label: 'Range',
                onChanged: (next) {
                  seen.add(next);
                  set(next);
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();
      expect(seen, [2]);
      final year = tester.getSemantics(find.text('Year')).getSemanticsData();
      expect(year.label, 'Year');
      expect(year.flagsCollection.isButton, isTrue);
      expect(year.flagsCollection.isSelected, Tristate.isTrue);
      expect(year.flagsCollection.isEnabled, Tristate.isTrue);
      expect(year.hasAction(SemanticsAction.tap), isTrue);
      // Tapping the current segment reports nothing.
      await tester.tap(find.text('Year'));
      expect(seen, [2]);
      handle.dispose();
    });

    testWidgets('the arrow keys move the choice; taps above the strip land', (
      tester,
    ) async {
      final seen = <int>[];
      // The strip stands in a taller band, as in a row, so its padded hit
      // area is not clipped by a parent hugging its 32 px.
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            height: 60,
            child: _Owner<int>(
              initial: 0,
              builder: (v, set) => Center(
                child: MinimalSegmentedButton(
                  segments: const [
                    MinimalButtonSegment(0, 'List'),
                    MinimalButtonSegment(1, 'Board'),
                  ],
                  value: v,
                  onChanged: (next) {
                    seen.add(next);
                    set(next);
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(seen, [1]);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(seen, [1, 0]);

      final strip = tester.getRect(
        find.bySubtype<MinimalSegmentedButton<Object?>>(),
      );
      expect(strip.height, MinimalChromeMetrics.control);
      await tester.tapAt(strip.topRight + const Offset(-20, -5));
      await tester.pumpAndSettle();
      expect(seen, [1, 0, 1]);
    });

    testWidgets('it is one focus stop: after an arrow, Enter and Space keep '
        'the new choice', (tester) async {
      final seen = <int>[];
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 300,
                child: _Owner<int>(
                  initial: 0,
                  builder: (v, set) => MinimalSegmentedButton(
                    segments: const [
                      MinimalButtonSegment(0, 'Week'),
                      MinimalButtonSegment(1, 'Month'),
                      MinimalButtonSegment(2, 'Year'),
                    ],
                    value: v,
                    onChanged: (next) {
                      seen.add(next);
                      set(next);
                    },
                  ),
                ),
              ),
              MinimalButton('After', onPressed: () {}),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(seen, [1]);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(seen, [1, 2]);
      // The next Tab leaves the control rather than visiting each segment.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        find.ancestor(
          of: find.byWidget(focused.widget),
          matching: find.byType(MinimalButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('expand: false hugs its labels; small is 28 px; no onChanged '
        'disables it', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 300,
            child: Align(
              alignment: Alignment.centerRight,
              child: MinimalSegmentedButton(
                segments: [
                  MinimalButtonSegment(0, 'List'),
                  MinimalButtonSegment(1, 'Board'),
                ],
                value: 0,
                small: true,
                expand: false,
              ),
            ),
          ),
        ),
      );
      final box = tester.getRect(
        find.bySubtype<MinimalSegmentedButton<Object?>>(),
      );
      expect(box.width, lessThan(300));
      expect(box.height, MinimalChromeMetrics.controlSm);
      final list = tester.getSize(find.text('List')).width;
      final board = tester.getSize(find.text('Board')).width;
      // The two segments share the widest label's width.
      expect(box.width, greaterThan(2 * (list > board ? list : board)));
      // Disabled, the whole track dims — thumb and frame, not just labels.
      final dim = tester.widget<Opacity>(
        find
            .descendant(
              of: find.bySubtype<MinimalSegmentedButton<Object?>>(),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(dim.opacity, 0.45);
      expect(find.byType(MinimalPressable), findsNothing);
      // The disabled choice is the thumb's hairline alone: its words keep
      // the rest's muted ink and regular weight.
      final t = MinimalThemeData.preset('standard', Brightness.light);
      final chosen = tester.widget<Text>(find.text('List')).style!;
      expect(chosen.color, t.mutedForeground);
      expect(chosen.fontWeight, FontWeight.w400);
    });
  });

  group('MinimalTabBar', () {
    testWidgets('a tap picks a tab; counts print; arrows move it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <int>[];
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 340,
            child: _Owner<int>(
              initial: 0,
              builder: (v, set) => MinimalTabBar(
                tabs: const ['Overview', 'Activity', 'Notes'],
                counts: const [null, 12, 3],
                selectedIndex: v,
                onChanged: (next) {
                  seen.add(next);
                  set(next);
                },
              ),
            ),
          ),
        ),
      );
      expect(find.text('12'), findsOneWidget);
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(seen, [1]);
      final node = tester.getSemantics(find.text('Activity'));
      expect(
        node.getSemanticsData().flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(seen, [1, 2]);
      // Focus moved with the choice: Enter and Space keep it.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(seen, [1, 2]);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(seen, [1, 2, 0]);
      expect(tester.getSize(find.byType(MinimalTabBar)).height, 44);
      handle.dispose();
    });

    testWidgets('the first label sits exactly on the strip inset', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 340,
            child: MinimalTabBar(
              tabs: const ['Overview', 'Activity'],
              selectedIndex: 0,
              padding: MinimalInsets.gutter,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      final strip = tester.getRect(find.byType(MinimalTabBar));
      final label = tester.getRect(find.text('Overview'));
      expect(label.left - strip.left, MinimalChromeMetrics.gutter);
    });

    testWidgets('with no onChanged the strip is disabled', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 340,
            child: MinimalTabBar(
              tabs: ['Overview', 'History'],
              selectedIndex: 0,
            ),
          ),
        ),
      );
      await tester.tap(find.text('History'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final node = tester.getSemantics(find.text('History'));
      expect(
        node.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
    });
  });

  group('MinimalColorPicker', () {
    testWidgets('one gap stands between every part', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 320,
            child: MinimalColorPicker(
              value: const Color(0xFF2563EB),
              onChanged: (_) {},
              showAlpha: true,
              swatches: const [Color(0xFF2563EB), Color(0xFF16A34A)],
            ),
          ),
        ),
      );
      final picker = find.byType(MinimalColorPicker);
      final tracks = find.descendant(
        of: picker,
        matching: find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_ChannelTrack',
        ),
      );
      expect(tracks, findsNWidgets(2));
      final area = tester.getRect(find.byType(DesignColorArea));
      final hue = tester.getRect(tracks.first);
      final alpha = tester.getRect(tracks.last);
      final hex = tester.getRect(
        find
            .ancestor(
              of: find.byType(MinimalTextField),
              matching: find.byType(Row),
            )
            .first,
      );
      final swatches = tester.getRect(
        find.descendant(of: picker, matching: find.byType(Wrap)).last,
      );
      expect(hue.top - area.bottom, moreOrLessEquals(16));
      expect(alpha.top - hue.bottom, moreOrLessEquals(16));
      expect(hex.top - alpha.bottom, moreOrLessEquals(16));
      expect(swatches.top - hex.bottom, moreOrLessEquals(16));
    });
  });

  group('MinimalChip', () {
    testWidgets('a chip taps, prints its count and announces selection', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          MinimalChip(
            'Open',
            count: 2,
            selected: true,
            onPressed: () => taps += 1,
          ),
        ),
      );
      expect(find.text('2'), findsOneWidget);
      expect(tester.getSize(find.byType(MinimalChip)).height, 28);
      await tester.tap(find.text('Open'));
      expect(taps, 1);
      final node = tester.getSemantics(find.text('Open'));
      expect(
        node.getSemanticsData().flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(
        node.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isTrue,
      );
      handle.dispose();
    });

    testWidgets('with no onPressed it is disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const MinimalChip('Archived')));
      final node = tester.getSemantics(find.text('Archived'));
      expect(
        node.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      handle.dispose();
    });

    testWidgets('a disabled chosen chip keeps the muted ink, so it never '
        'reads stronger than an enabled one', (tester) async {
      final t = MinimalThemeData.preset('standard', Brightness.light);
      await tester.pumpWidget(
        _host(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinimalChip('Idle', onPressed: () {}),
              MinimalChip('Live', selected: true, onPressed: () {}),
              const MinimalChip('Off', selected: true),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      Color? ink(String label) =>
          tester.widget<Text>(find.text(label)).style?.color;
      expect(ink('Live'), t.foreground);
      expect(ink('Idle'), t.mutedForeground);
      expect(ink('Off'), t.mutedForeground);
    });

    testWidgets('a chip row wraps instead of overflowing', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 200,
            child: MinimalChipRow(
              children: [
                for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'])
                  MinimalChip(day, onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final first = tester.getRect(find.text('Mon'));
      final last = tester.getRect(find.text('Sat'));
      expect(last.top, greaterThan(first.bottom));
    });

    testWidgets('a chip row keeps every chip a 44 px target above its first '
        'line and below its last', (tester) async {
      final taps = <String>[];
      await tester.pumpWidget(
        // A 200 px column with room above and below the row, as a page has.
        _host(
          SizedBox(
            width: 200,
            height: 200,
            child: Center(
              child: MinimalChipRow(
                children: [
                  for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'])
                    MinimalChip(day, onPressed: () => taps.add(day)),
                ],
              ),
            ),
          ),
        ),
      );
      final mon = tester.getRect(
        find.ancestor(of: find.text('Mon'), matching: find.byType(MinimalChip)),
      );
      final sat = tester.getRect(
        find.ancestor(of: find.text('Sat'), matching: find.byType(MinimalChip)),
      );
      expect(mon.height, MinimalChromeMetrics.controlSm);
      await tester.tapAt(mon.topCenter - const Offset(0, 6));
      await tester.tapAt(sat.bottomCenter + const Offset(0, 6));
      expect(taps, ['Mon', 'Sat']);
      // Past the 44 px square, nothing lands.
      await tester.tapAt(mon.topCenter - const Offset(0, 10));
      expect(taps, ['Mon', 'Sat']);
    });

    testWidgets('a lone chip in a row takes a tap 6 px above its edge', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          MinimalChipRow(
            children: [MinimalChip('Open', onPressed: () => taps++)],
          ),
        ),
      );
      final chip = tester.getRect(find.byType(MinimalChip));
      await tester.tapAt(chip.topCenter - const Offset(0, 6));
      expect(taps, 1);
    });
  });

  // Round 4, found by the user on a Mac: the composer's hint stood 4 px low.
  // Material's density is compact on a desktop (a web build opened on one
  // too) and tests run as Android, so nothing had seen it. Every part you
  // type into, under a desktop platform: the size it has on a phone, its
  // words where they stand on a phone, and a single line's words (the hint,
  // then what was typed) centred in their box within half a pixel.
  group('text entry on a desktop platform', () {
    const entry = Key('entry');
    final parts =
        <
          String,
          ({Widget part, List<String> words, String? type, bool centred})
        >{
          'MinimalTextField': (
            part: const MinimalTextField(hint: 'Ana Ruiz'),
            words: ['Ana Ruiz'],
            type: 'Bo',
            centred: true,
          ),
          'MinimalTextArea': (
            part: const MinimalTextArea(hint: 'Anything'),
            words: ['Anything'],
            type: 'Bo',
            centred: false,
          ),
          'MinimalSearchField': (
            part: const MinimalSearchField(hint: 'Search habits'),
            words: ['Search habits'],
            type: 'Bo',
            centred: true,
          ),
          'MinimalCombobox': (
            part: const MinimalCombobox<String>(
              options: ['Lisbon', 'London'],
              hint: 'City',
            ),
            words: ['City'],
            type: 'Bo',
            centred: true,
          ),
          'MinimalInputGroup': (
            part: const MinimalInputGroup(hint: 'site', prefixText: 'https://'),
            words: ['site', 'https://'],
            type: 'Bo',
            centred: true,
          ),
          'MinimalPasswordField': (
            part: const MinimalPasswordField(hint: 'Password'),
            words: ['Password'],
            type: 'Bo',
            centred: true,
          ),
          'MinimalInputOtp': (
            part: const MinimalInputOtp(length: 4),
            words: [],
            type: '12',
            centred: true,
          ),
          'MinimalComposer': (
            part: const MinimalComposer(hint: 'Comment on Morning run'),
            words: ['Comment on Morning run'],
            type: 'Bo',
            centred: true,
          ),
          'MinimalComposer assistant': (
            part: const MinimalComposer(
              hint: 'Ask anything',
              style: MinimalComposerStyle.assistant,
            ),
            words: ['Ask anything'],
            type: 'Bo',
            centred: false,
          ),
          'MinimalNumberField': (
            part: MinimalNumberField(
              value: 2,
              min: 0,
              max: 9,
              onChanged: (_) {},
            ),
            words: ['2'],
            type: null,
            centred: true,
          ),
          'MinimalInputRow': (
            part: const MinimalInputRow(label: 'Name', hint: 'Ana Ruiz'),
            words: ['Ana Ruiz'],
            type: 'Bo',
            centred: true,
          ),
          'MinimalSelect': (
            part: MinimalSelect<String>(
              label: 'Plan',
              value: 'pro',
              options: const [
                MinimalSelectOption('free', 'Free'),
                MinimalSelectOption('pro', 'Pro'),
              ],
              onChanged: (_) {},
            ),
            words: ['Pro'],
            type: null,
            centred: true,
          ),
          'MinimalMultiSelect': (
            part: MinimalMultiSelect<String>(
              values: const [],
              options: const ['Lisbon', 'London'],
              hint: 'Add cities',
              onChanged: (_) {},
            ),
            words: ['Add cities'],
            type: 'Bo',
            centred: true,
          ),
          'MinimalColorPicker': (
            part: MinimalColorPicker(
              value: const Color(0xFF3B82F6),
              onChanged: (_) {},
            ),
            words: [],
            type: '#ABCDEF',
            centred: true,
          ),
        };

    /// Whether [d] draws a frame: the box a field's words stand in.
    bool frames(Decoration d) => switch (d) {
      ShapeDecoration(:final shape) =>
        shape is OutlinedBorder && shape.side.style != BorderStyle.none,
      BoxDecoration(:final border) => border != null,
      _ => false,
    };

    /// The part's size, and for each of its words their place in the part
    /// and their centre's distance from their box's (and, in the composer,
    /// the send seat's centre's distance from the line's), with the part
    /// wrapped in [wrap]: larger text, or an app's own Material theme.
    Future<
      ({
        Size size,
        Map<String, Offset> at,
        Map<String, double> off,
        double? seat,
      })
    >
    see(
      WidgetTester tester,
      String name,
      ({Widget part, List<String> words, String? type, bool centred}) c, {
      Widget Function(BuildContext context, Widget part)? wrap,
    }) async {
      await tester.pumpWidget(const SizedBox());
      // A fresh theme each time: the look builds its Material bridge once
      // per theme, under the platform of the moment.
      await tester.pumpWidget(
        _host(
          // Pinned: this compares platforms at one density, and an unset
          // density is compact on a desktop by design.
          density: MinimalDensity.standard,
          SizedBox(
            width: 320,
            child: KeyedSubtree(
              key: entry,
              child: wrap == null
                  ? c.part
                  : Builder(builder: (context) => wrap(context, c.part)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final root = find.byKey(entry);
      final origin = tester.getTopLeft(root);
      final at = <String, Offset>{};
      final off = <String, double>{};
      double? seat;
      void read(String words) {
        final text = find.descendant(of: root, matching: find.text(words));
        final rect = tester.getRect(text.first);
        final box = tester.getRect(
          find
              .ancestor(
                of: text.first,
                matching: find.byWidgetPredicate(
                  (w) => w is DecoratedBox && frames(w.decoration),
                ),
              )
              .first,
        );
        at[words] = rect.topLeft - origin;
        // A one-line line by its capitals; an entry that may wrap by its
        // line, as ui_core keeps it (it moves as lines come and go).
        final field = find.ancestor(
          of: text.first,
          matching: find.byType(TextField),
        );
        final wraps =
            field.evaluate().isNotEmpty &&
            (tester.widget<TextField>(field.first).maxLines ?? 0) != 1;
        final middle = wraps
            ? rect.center.dy
            : _capitalsMiddle(tester.renderObject(text.first));
        off[words] = middle - box.center.dy;
        final send = find.descendant(
          of: root,
          matching: find.byType(MinimalComposerAction),
        );
        if (name == 'MinimalComposer' && seat == null) {
          seat = tester.getRect(send).center.dy - middle;
        }
      }

      c.words.forEach(read);
      final type = c.type;
      if (type != null) {
        await tester.enterText(
          find.descendant(of: root, matching: find.byType(EditableText)).first,
          type,
        );
        await tester.pumpAndSettle();
        // A code field shows each digit in a cell of its own.
        read(name == 'MinimalInputOtp' ? type[0] : type);
      }
      final size = tester.getSize(root);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      return (size: size, at: at, off: off, seat: seat);
    }

    /// An app's own Material theme between the look and the part, setting
    /// what a text field's decoration would otherwise take from it.
    Widget hostTheme(BuildContext context, Widget part) => Theme(
      data: Theme.of(context).copyWith(
        visualDensity: VisualDensity.compact,
        inputDecorationTheme: const InputDecorationThemeData(
          contentPadding: EdgeInsets.all(20),
          isDense: true,
          constraints: BoxConstraints(minHeight: 56),
          filled: true,
          border: OutlineInputBorder(),
        ),
      ),
      child: part,
    );

    /// Text half as large again, as a reader's setting makes it.
    Widget largerText(BuildContext context, Widget part) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(1.5)),
      child: part,
    );

    void sameAs(
      ({
        Size size,
        Map<String, Offset> at,
        Map<String, double> off,
        double? seat,
      })
      phone,
      ({
        Size size,
        Map<String, Offset> at,
        Map<String, double> off,
        double? seat,
      })
      other,
      String where,
    ) {
      expect(
        other.size,
        phone.size,
        reason: 'the size it has on a phone $where',
      );
      for (final words in phone.at.keys) {
        expect(
          (other.at[words]! - phone.at[words]!).distance,
          lessThan(0.5),
          reason: '"$words" where it stands on a phone $where',
        );
      }
    }

    void centred(
      ({
        Size size,
        Map<String, Offset> at,
        Map<String, double> off,
        double? seat,
      })
      seen,
      ({Widget part, List<String> words, String? type, bool centred}) c,
      String where,
    ) {
      if (c.centred) {
        for (final MapEntry(key: words, value: off) in seen.off.entries) {
          expect(
            off.abs(),
            lessThanOrEqualTo(0.5),
            reason: '"$words" centred in its box $where',
          );
        }
      }
      final seat = seen.seat;
      if (seat != null) {
        expect(
          seat.abs(),
          lessThanOrEqualTo(0.5),
          reason: 'the send seat centred on the line $where',
        );
      }
    }

    for (final MapEntry(key: name, value: c) in parts.entries) {
      testWidgets('$name stands as on a phone, its line centred', (
        tester,
      ) async {
        final phone = await see(tester, name, c);
        centred(phone, c, 'on a phone');
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          final desk = await see(tester, name, c);
          sameAs(phone, desk, 'on a desktop');
          centred(desk, c, 'on a desktop');
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('$name keeps its line under an app\'s Material theme', (
        tester,
      ) async {
        final phone = await see(tester, name, c);
        final hosted = await see(tester, name, c, wrap: hostTheme);
        sameAs(phone, hosted, 'under an app\'s theme');
        centred(hosted, c, 'under an app\'s theme');
      });

      testWidgets('$name keeps its line centred in larger text', (
        tester,
      ) async {
        centred(
          await see(tester, name, c, wrap: largerText),
          c,
          'at text scale 1.5',
        );
      });
    }
  });
}
