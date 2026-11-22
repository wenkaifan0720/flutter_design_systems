import 'dart:ui' show SemanticsAction;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/padded_host.dart';
import 'support/value_owner.dart';

void main() {
  group('MinimalSlider', () {
    testWidgets('a tap on the track sets the value, quantised', (tester) async {
      final seen = <double>[];
      double? ended;
      await tester.pumpWidget(
        paddedHost(
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
        paddedHost(
          SizedBox(
            width: 300,
            child: ValueOwner<double>(
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
        paddedHost(
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
}
