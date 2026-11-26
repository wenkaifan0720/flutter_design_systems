// A form's column and the host. A typed date takes its line beside its
// button, its figures spaced evenly ("11 / 9 / 2026"); a radio group's
// question stands at a field label's size unless it is the page's question
// or one of a few (isQuestion), as a segmented control's and a slider's
// can; an error summary scrolled into view stands clear of the view's top
// edge, or, where it shows from the page's start, brings the page back
// there. The host blends a change of theme or palette. A monogram's
// initials and a chip's glyph grow with the reader's text.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'screens_matrix.dart' show loadScreenFonts;

Future<void> _show(
  WidgetTester tester,
  Widget home, {
  double width = 390,
  double text = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          CivicHost(child: child ?? const SizedBox.shrink()),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

double _size(WidgetTester tester, String words) => tester
    .renderObject<RenderParagraph>(find.text(words))
    .text
    .style!
    .fontSize!;

void main() {
  setUpAll(loadScreenFonts);

  for (final width in [390.0, 1440.0]) {
    testWidgets('a typed date takes its line beside its button, its figures '
        'spaced evenly (${width.toInt()})', (tester) async {
      await _show(
        tester,
        CivicScreen(
          body: CivicDatePicker(
            labelText: 'Date started',
            value: DateTime(2026, 11, 9),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            onChanged: (_) {},
          ),
        ),
        width: width,
      );
      final button = tester.getRect(
        find
            .ancestor(
              of: find.text('Choose date'),
              matching: find.byType(RawButton),
            )
            .first,
      );
      final well = tester.getRect(
        find
            .ancestor(of: find.text('2026'), matching: find.byType(CivicWell))
            .first,
      );
      final label = tester.getRect(find.text('Date started'));
      final column = tester.getRect(find.byType(CivicDatePicker));
      expect(well.left, moreOrLessEquals(label.left, epsilon: 1));
      if (button.top >= well.bottom) {
        // A phone: the well takes the column, the button under it.
        expect(well.right, moreOrLessEquals(column.right, epsilon: 1));
        expect(button.left, moreOrLessEquals(column.left, epsilon: 1));
      } else {
        // The well and the button share the line, the button at its end.
        expect(button.right, moreOrLessEquals(column.right, epsilon: 1));
        expect(
          button.left - well.right,
          moreOrLessEquals(CivicSpacing.s8, epsilon: 1),
        );
      }
      // Every figure stands the same gap from the text either side of it.
      final words =
          [
                ...find.text('11').evaluate(),
                ...find.text('/').evaluate(),
                ...find.text('9').evaluate(),
                ...find.text('2026').evaluate(),
              ]
              .map(
                (e) => tester.getRect(find.byElementPredicate((x) => x == e)),
              )
              .toList()
            ..sort((a, b) => a.left.compareTo(b.left));
      expect(words, hasLength(5));
      final gaps = [
        for (var i = 1; i < words.length; i++)
          words[i].left - words[i - 1].right,
      ];
      for (final gap in gaps) {
        expect(gap, moreOrLessEquals(gaps.first, epsilon: 1), reason: '$gaps');
      }
    });
  }

  testWidgets("a radio group's question stands at a field label's size, a "
      "question's with isQuestion", (tester) async {
    Widget group({bool question = false}) => CivicRadioGroup<String>(
      labelText: question ? 'How did you hear about us?' : 'Status',
      isQuestion: question,
      groupValue: null,
      onChanged: (_) {},
      children: const [CivicRadio(value: 'a', labelText: 'To read')],
    );
    await _show(
      tester,
      CivicScreen(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CivicTextField(labelText: 'Title', onChanged: (_) {}),
            group(),
            group(question: true),
            CivicSegmentedControl<String>(
              labelText: 'How often do you read?',
              isQuestion: true,
              value: 'a',
              onChanged: (_) {},
              segments: const [
                CivicSegment(value: 'a', label: 'Daily'),
                CivicSegment(value: 'b', label: 'Weekly'),
              ],
            ),
            CivicSlider(
              labelText: 'Pages a day',
              isQuestion: true,
              value: 0.5,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
    final label = _size(tester, 'Title');
    expect(_size(tester, 'Status'), label);
    final question = _size(tester, 'How did you hear about us?');
    expect(question, greaterThan(label));
    expect(_size(tester, 'How often do you read?'), question);
    expect(_size(tester, 'Pages a day'), question);
  });

  for (final far in [false, true]) {
    testWidgets(
      far
          ? 'an error summary below the first screen scrolls into view clear '
                'of the top edge'
          : 'an error summary on the first screen brings the page back to '
                'its start',
      (tester) async {
        final errors = ValueNotifier<List<String>>(const []);
        addTearDown(errors.dispose);
        final before = far ? 1200.0 : 300.0;
        await _show(
          tester,
          Material(
            child: SingleChildScrollView(
              child: ValueListenableBuilder(
                valueListenable: errors,
                builder: (context, list, _) => Column(
                  children: [
                    SizedBox(height: before),
                    if (list.isNotEmpty)
                      CivicErrorSummary(
                        title: 'There is a problem',
                        errors: [
                          for (final e in list)
                            CivicErrorSummaryItem(text: e, onPressed: () {}),
                        ],
                      ),
                    const SizedBox(height: 2000),
                    const Text('Save book'),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.scrollUntilVisible(find.text('Save book'), 400);
        await tester.pumpAndSettle();
        errors.value = const ['Enter a title'];
        await tester.pumpAndSettle();
        final summary = tester.getRect(find.byType(CivicErrorSummary));
        expect(
          summary.top,
          moreOrLessEquals(far ? CivicSpacing.s16 : before, epsilon: 1),
        );
      },
    );
  }

  testWidgets('the host blends a change of brightness and of palette', (
    tester,
  ) async {
    const probe = ValueKey('probe');
    Widget app(Brightness b, RawNamedPalette palette) => MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          CivicHost(brightness: b, palette: palette, child: child!),
      home: Builder(
        builder: (context) => ColoredBox(
          key: probe,
          color: context.civicTheme.action,
          child: const SizedBox.expand(),
        ),
      ),
    );
    Color seen() => tester.widget<ColoredBox>(find.byKey(probe)).color;
    final first = CivicThemeData.palettes.first;
    final plum = CivicThemeData.palettes.firstWhere((p) => p.id == 'plum');
    await tester.pumpWidget(app(Brightness.light, first));
    await tester.pumpAndSettle();
    final day = seen();
    await tester.pumpWidget(app(Brightness.dark, first));
    await tester.pump(const Duration(milliseconds: 80));
    final night = CivicThemeData.dark().action;
    expect(seen(), isNot(day));
    expect(seen(), isNot(night));
    await tester.pumpAndSettle();
    expect(seen(), night);
    await tester.pumpWidget(app(Brightness.dark, plum));
    await tester.pump(const Duration(milliseconds: 80));
    expect(seen(), isNot(night));
    expect(seen(), isNot(plum.darkSwatches.first));
    await tester.pumpAndSettle();
    expect(seen(), plum.darkSwatches.first);
  });

  testWidgets("a monogram's initials and a chip's glyph grow with the "
      "reader's text", (tester) async {
    Future<(double, double)> measure(double text) async {
      await _show(
        tester,
        CivicScreen(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CivicAvatar(name: 'Ana Ruiz'),
              CivicChip(
                label: 'Zone B',
                icon: LucideIcons.mapPin,
                selected: false,
                onSelected: (_) {},
              ),
            ],
          ),
        ),
        text: text,
      );
      return (
        tester.getRect(find.text('AR')).height,
        tester.getSize(find.byIcon(LucideIcons.mapPin)).height,
      );
    }

    final (initials, glyph) = await measure(1);
    final (initials2, glyph2) = await measure(2);
    expect(initials2, greaterThan(initials * 1.1));
    expect(glyph2, greaterThan(glyph * 1.5));
    // The initials keep inside the circle.
    expect(
      tester.getRect(find.text('AR')).height,
      lessThanOrEqualTo(tester.getSize(find.byType(CivicAvatar)).height),
    );
  });
}
