// A property's value stands beside its label, and from 160% text under it,
// at the label's start, whole rather than cut short by the label's grown
// column (a habit's page at 200%: `12d · best 21d`, `2026-06-02`). A form
// row's control and an activity's time do the same: beside at 100%, under
// their words from 160%.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _list(double scale) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: MinimalTheme(
      data: MinimalThemeData.standard(),
      child: const Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 354,
          child: MinimalDescriptionList(
            properties: [
              MinimalProperty(
                icon: LucideIcons.flame,
                label: 'Streak',
                value: '12d',
                detail: 'best 21d',
                mono: true,
              ),
              MinimalProperty(
                icon: LucideIcons.calendar,
                label: 'Started',
                value: '2026-06-02',
                mono: true,
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

/// Whether every paragraph printing [text] prints it whole.
bool _whole(WidgetTester tester, String text) => find
    .textContaining(text, findRichText: true)
    .evaluate()
    .every((e) => !(e.renderObject! as RenderParagraph).didExceedMaxLines);

void main() {
  testWidgets('at 100% the value stands beside its label', (tester) async {
    await tester.pumpWidget(_list(1));
    final label = tester.getRect(find.text('Started'));
    final value = tester.getRect(
      find.textContaining('2026-06-02', findRichText: true),
    );
    expect(value.left, greaterThan(label.right));
    expect((value.center.dy - label.center.dy).abs(), lessThan(4));
  });

  // A form row's control (Settings' week start) beside its label, and from
  // 160% under it, its words whole. Short day names: the test font draws
  // each letter a full em wide, and beside the label at 200% even these are
  // cut.
  Widget formRow(double scale) => Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: MinimalTheme(
        data: MinimalThemeData.standard(),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 354,
            child: MinimalFormRow(
              label: 'Starts on',
              icon: LucideIcons.calendar,
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 176),
                child: MinimalSegmentedButton<String>(
                  expand: false,
                  segments: const [
                    MinimalButtonSegment('Mon', 'Mon'),
                    MinimalButtonSegment('Sun', 'Sun'),
                  ],
                  value: 'Mon',
                  semanticLabel: 'Week starts on',
                  small: true,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('a form row\'s control stands beside its label at 100%', (
    tester,
  ) async {
    await tester.pumpWidget(formRow(1));
    final label = tester.getRect(find.text('Starts on'));
    final control = tester.getRect(find.byType(MinimalSegmentedButton<String>));
    expect(control.left, greaterThan(label.right));
    expect(control.width, greaterThanOrEqualTo(176));
  });

  testWidgets('from 160% a form row\'s control stands under its label, its '
      'words whole', (tester) async {
    for (final scale in [1.6, 2.0]) {
      await tester.pumpWidget(formRow(scale));
      final label = tester.getRect(find.text('Starts on'));
      final control = tester.getRect(
        find.byType(MinimalSegmentedButton<String>),
      );
      expect(control.top, greaterThanOrEqualTo(label.bottom - 1));
      for (final day in ['Mon', 'Sun']) {
        expect(_whole(tester, day), isTrue);
      }
    }
  });

  for (final scale in [1.6, 2.0]) {
    testWidgets('at ${(scale * 100).round()}% the value stands whole under '
        'its label, at its start', (tester) async {
      await tester.pumpWidget(_list(scale));
      for (final (label, value) in [
        ('Streak', '12d'),
        ('Started', '2026-06-02'),
      ]) {
        final name = tester.getRect(find.text(label));
        final shown = tester.getRect(
          find.textContaining(value, findRichText: true),
        );
        // Under it: a one-line label is drawn by its capitals, a value on
        // two lines where it is laid, so the boxes may touch by a pixel or
        // three; the value's top is past the label's middle.
        expect(shown.top, greaterThan(name.center.dy));
        expect(shown.left, closeTo(name.left, 1));
        expect(_whole(tester, value), isTrue);
      }
    });
  }

  // An activity's stamp beside its event, and from 160% over it, so the
  // event keeps the row's width rather than a word or two a line.
  Widget log(double scale) => Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: MinimalTheme(
        data: MinimalThemeData.standard(),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 354,
            child: MinimalTimeline(
              entries: [
                MinimalActivity(
                  at: DateTime(2026, 8, 27, 7, 40),
                  text: 'Marked done',
                  detail: 'note added',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  for (final (scale, over) in [(1.0, false), (1.6, true), (2.0, true)]) {
    testWidgets('at ${(scale * 100).round()}% an activity\'s stamp stands '
        '${over ? 'over' : 'beside'} its event', (tester) async {
      await tester.pumpWidget(log(scale));
      final stamp = tester.getRect(find.text('27 Aug 07:40'));
      final event = tester.getRect(
        find.textContaining('Marked done', findRichText: true),
      );
      if (over) {
        expect(event.top, greaterThanOrEqualTo(stamp.bottom - 1));
        expect(event.left, closeTo(stamp.left, 1));
      } else {
        expect(event.left, greaterThan(stamp.right));
      }
    });
  }
}
