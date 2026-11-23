import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/padded_host.dart';
import 'support/value_owner.dart';

void main() {
  group('MinimalNumberField', () {
    testWidgets('its buttons step within the bounds and announce the value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <int>[];
      await tester.pumpWidget(
        paddedHost(
          ValueOwner<int>(
            initial: 2,
            builder: (v, set) => MinimalNumberField(
              value: v,
              min: 1,
              max: 3,
              labelText: 'Sets',
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
        paddedHost(
          ValueOwner<int>(
            initial: 0,
            builder: (v, set) => MinimalNumberField(
              value: v,
              min: 0,
              max: 20,
              labelText: 'Pages',
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
        paddedHost(
          MinimalNumberField(
            value: 1,
            min: 0,
            max: 3,
            labelText: 'Rest',
            onChanged: (_) => taps += 1,
          ),
        ),
      );
      final plus = tester.getRect(find.bySemanticsLabel('Increase Rest'));
      await tester.tapAt(plus.topCenter - const Offset(0, 6));
      expect(taps, 1);

      await tester.pumpWidget(
        paddedHost(
          const MinimalNumberField(value: 1, min: 0, max: 3, labelText: 'Rest'),
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
        paddedHost(
          MinimalNumberField(
            value: 20,
            min: 5,
            max: 50,
            step: 5,
            labelText: 'Pages',
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
        paddedHost(
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
        paddedHost(
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
}
