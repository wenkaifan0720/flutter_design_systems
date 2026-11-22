import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/page_host.dart';

void main() {
  group('MinimalTimeline', () {
    testWidgets('prints a mono stamp and the event, and opens it', (
      tester,
    ) async {
      var opened = 0;
      await tester.pumpWidget(
        pageApp(
          MinimalTimeline(
            entries: [
              MinimalActivity(
                at: DateTime(2026, 8, 27, 7, 40),
                text: 'Marked done',
                detail: 'note added',
                onPressed: () => opened++,
              ),
              MinimalActivity(
                at: DateTime(2026, 8, 19, 20, 15),
                actor: 'Ana',
                text: 'moved the reminder',
              ),
            ],
          ),
        ),
      );
      expect(find.text('27 Aug 07:40'), findsOneWidget);
      await tester.tap(find.text('27 Aug 07:40'));
      expect(opened, 1);
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('27 Aug 07:40, Marked done, note added'),
        ),
        isSemantics(isButton: true),
      );
      expect(
        find.bySemanticsLabel('19 Aug 20:15, Ana, moved the reminder'),
        findsOneWidget,
      );
    });

    testWidgets('a figure the event set prints after its words, in mono', (
      tester,
    ) async {
      await tester.pumpWidget(
        pageApp(
          MinimalTimeline(
            entries: [
              MinimalActivity(
                at: DateTime(2026, 9, 24, 17, 5),
                actor: 'Katherine',
                text: 'set it due',
                figure: '25 Sep',
              ),
            ],
          ),
        ),
      );
      final t = MinimalThemeData.preset('standard', Brightness.light);
      final event = tester.widget<RichText>(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText() == 'Katherine set it due 25 Sep',
        ),
      );
      final faces = <String, TextStyle?>{};
      event.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) {
          faces[span.text!] = span.style;
        }
        return true;
      });
      expect(faces['set it due']?.fontFamily, t.bodySmall.fontFamily);
      expect(faces['25 Sep']?.fontFamily, t.mono.fontFamily);
      // At the event's size, so the line keeps one measure.
      expect(faces['25 Sep']?.fontSize, t.bodySmall.fontSize);
      expect(
        find.bySemanticsLabel('24 Sep 17:05, Katherine, set it due 25 Sep'),
        findsOneWidget,
      );
    });

    testWidgets('an empty log says so', (tester) async {
      await tester.pumpWidget(pageApp(const MinimalTimeline(entries: [])));
      expect(find.text('No activity yet'), findsOneWidget);
    });

    testWidgets('rules run between entries, none under the last', (
      tester,
    ) async {
      await tester.pumpWidget(
        pageApp(
          MinimalTimeline(
            entries: [
              MinimalActivity(
                at: DateTime(2026, 3, 11, 20, 15),
                text: 'Reminder moved',
              ),
              MinimalActivity(at: DateTime(2026, 3, 10, 9, 2), text: 'Created'),
            ],
          ),
        ),
      );
      bool ruled(int entry) => tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(MinimalActivity).at(entry),
              matching: find.byType(Container),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .any((d) => d.border != null);
      expect(ruled(0), isTrue);
      expect(ruled(1), isFalse);
    });

    testWidgets('with one dot in the log, every event starts on its keyline', (
      tester,
    ) async {
      // The x where [words] start in the entry that prints them.
      double startOf(String words) {
        final finder = find.byWidgetPredicate(
          (widget) =>
              widget is RichText && widget.text.toPlainText().contains(words),
        );
        final paragraph = tester.renderObject<RenderParagraph>(finder);
        final at = tester
            .widget<RichText>(finder)
            .text
            .toPlainText()
            .indexOf(words);
        final caret = paragraph.getOffsetForCaret(
          TextPosition(offset: at),
          Rect.zero,
        );
        return paragraph.localToGlobal(caret).dx;
      }

      await tester.pumpWidget(
        pageApp(
          MinimalTimeline(
            entries: [
              MinimalActivity(
                at: DateTime(2026, 3, 12, 7, 12),
                actor: 'Ana',
                text: 'marked it done',
                tone: MinimalTone.success,
              ),
              MinimalActivity(
                at: DateTime(2026, 3, 11, 20, 15),
                text: 'Reminder moved',
              ),
              MinimalActivity(at: DateTime(2026, 3, 10, 9, 2), text: 'Created'),
            ],
          ),
        ),
      );
      final keyline = startOf('Ana');
      expect(startOf('Reminder moved'), moreOrLessEquals(keyline));
      expect(startOf('Created'), moreOrLessEquals(keyline));

      // A log with no dots keeps no slot: its words start after the gap.
      await tester.pumpWidget(
        pageApp(
          MinimalTimeline(
            entries: [
              MinimalActivity(
                at: DateTime(2026, 3, 11, 20, 15),
                text: 'Reminder moved',
              ),
            ],
          ),
        ),
      );
      expect(startOf('Reminder moved'), lessThan(keyline - 10));
    });
  });
}
