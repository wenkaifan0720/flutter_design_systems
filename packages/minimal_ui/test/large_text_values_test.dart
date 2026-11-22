// A date picker's value and a bar chart's axis labels at 100%, 200% and
// 300% text on a phone, against Material at the same size: a date pill grows
// and wraps between its words, as Material's text field grows, rather than
// cutting the date short, and keeps the row's inset under it; a chart's
// labels grow to 1.3x, as Material's navigation bar labels do, and stay whole
// in their columns (a Due date and an Hours logged chart at 300%).
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

Future<void> _pump(WidgetTester t, Widget child, double scale) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(390, 844);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          textScaler: TextScaler.linear(scale),
        ),
        child: MinimalTheme(
          data: MinimalThemeData.standard(),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: SizedBox(width: 342, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

/// [text] laid out whole: nothing past its lines, and each word on one line.
void _whole(WidgetTester t, String text) {
  final p = t.renderObject<RenderParagraph>(find.text(text));
  expect(p.didExceedMaxLines, isFalse, reason: text);
  for (final word in RegExp(r'\S+').allMatches(text)) {
    expect(
      p.getBoxesForSelection(
        TextSelection(baseOffset: word.start, extentOffset: word.end),
      ),
      hasLength(1),
      reason: '${word.group(0)} in $text',
    );
  }
  expect(
    p.size.width,
    greaterThanOrEqualTo(p.getMinIntrinsicWidth(double.infinity) - 0.5),
    reason: text,
  );
}

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

void main() {
  setUpAll(minimalLoadFonts);

  for (final scale in const [1.0, 2.0, 3.0]) {
    final at = '${(scale * 100).round()}%';

    testWidgets('a date reads whole in its pill at $at', (t) async {
      await _pump(
        t,
        MinimalDatePicker(
          label: 'Due date',
          value: DateTime(2026, 11, 20),
          mode: MinimalDatePickerMode.date,
          first: DateTime(2020),
          last: DateTime(2040, 12, 31),
          onChanged: (_) {},
        ),
        scale,
      );
      expect(t.takeException(), isNull);
      const date = '20 Nov 2026';
      _whole(t, date);
      final value = t.getRect(find.text(date));
      final pill = t.getRect(
        find
            .ancestor(of: find.text(date), matching: find.byType(DecoratedBox))
            .first,
      );
      // The figures inside the pill's hairline, the pill inside the row.
      expect(value.top, greaterThanOrEqualTo(pill.top), reason: '$pill');
      expect(value.bottom, lessThanOrEqualTo(pill.bottom), reason: '$pill');
      // The pill keeps the row's inset above and below it, (44 - 28) / 2
      // at the standard density, as at 100%: never on the row's rule.
      final row = t.getRect(find.byType(MinimalDatePicker));
      expect(pill.top - row.top, greaterThanOrEqualTo(8 - 0.01), reason: at);
      expect(
        row.bottom - pill.bottom,
        greaterThanOrEqualTo(8 - 0.01),
        reason: at,
      );
      expect(row.height, greaterThanOrEqualTo(MinimalLayout.minHitTarget));
      if (scale == 1) {
        // At 100% the row is one line in a 28 px pill, in the row's
        // 44 px.
        expect(pill.height, 28);
        expect(row.height, MinimalLayout.minHitTarget);
        expect(
          t.renderObject<RenderParagraph>(find.text(date)).size.height,
          lessThan(28),
        );
      }
    });

    testWidgets('a bar chart\'s labels read whole at $at, at most 1.3x', (
      t,
    ) async {
      await _pump(
        t,
        const MinimalBarChart(
          [2.5, 3, 3.5, 4, 2.75, 0, 0],
          labels: _days,
          highlight: 3,
          semanticLabel: 'Hours logged',
        ),
        scale,
      );
      expect(t.takeException(), isNull);
      final rects = [for (final d in _days) t.getRect(find.text(d))];
      for (final d in _days) {
        final p = t.renderObject<RenderParagraph>(find.text(d));
        expect(
          p.size.width,
          greaterThanOrEqualTo(p.getMaxIntrinsicWidth(double.infinity) - 0.5),
          reason: '$d at $at',
        );
        expect(
          p.textScaler.scale(10) / 10,
          closeTo(
            scale > MinimalBarChart.maxLabelScale
                ? MinimalBarChart.maxLabelScale
                : scale,
            0.001,
          ),
          reason: d,
        );
      }
      for (var i = 0; i + 1 < rects.length; i++) {
        expect(
          rects[i].right,
          lessThanOrEqualTo(rects[i + 1].left),
          reason: '${_days[i]} and ${_days[i + 1]}',
        );
      }
    });
  }
}
