/// Round 4's control fixes: search grows with its words, two months stand
/// their names on their grids' edges, a wheel stands on its slot's start,
/// and the upload zone marks the words that open the picker.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The host stands above the Navigator, as an app mounts it, so overlays
// read the same tokens as the page; [scale] is the page's text scale.
Widget _host(Widget child, {double scale = 1}) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: child,
        ),
      ),
    ),
  ),
);

/// The nearest box around [of]: the face it stands in.
Rect _box(WidgetTester tester, Finder of) => tester.getRect(
  find.ancestor(of: of, matching: find.byType(Container)).first,
);

/// Where [text]'s first letter starts on the screen, whatever the width of
/// the box it is set in.
double _start(WidgetTester tester, String text) {
  final p = tester.renderObject<RenderParagraph>(find.text(text));
  final boxes = p.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  return p.localToGlobal(Offset(boxes.first.left, 0)).dx;
}

/// What a 1.3 text scale adds to a 16 px line.
const double _grown = 16 * 1.3 - 16;

void main() {
  group('search grows with its words', () {
    testWidgets('the field at text scale 1.3 grows as a text field does', (
      tester,
    ) async {
      final glyph = find.byWidgetPredicate(
        (w) => w is MinimalIcon && w.icon == LucideIcons.search,
      );
      Future<double> face(double scale) async {
        await tester.pumpWidget(
          _host(const MinimalSearchField(hint: 'Search habits'), scale: scale),
        );
        await tester.pumpAndSettle();
        return _box(tester, glyph).height;
      }

      final rest = await face(1);
      expect(await face(1.3), greaterThanOrEqualTo(rest + _grown - 0.5));
    });

    testWidgets('the entry at text scale 1.3 grows as the field does', (
      tester,
    ) async {
      Future<double> entry(double scale) async {
        await tester.pumpWidget(
          _host(
            MinimalSearchEntry(label: 'Search habits', onPressed: () {}),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        return _box(tester, find.text('Search habits')).height;
      }

      final rest = await entry(1);
      expect(await entry(1.3), greaterThanOrEqualTo(rest + _grown - 0.5));
    });
  });

  testWidgets('two months side by side stand their names on their grids\' '
      'edges, as one month does, both chevrons after the last', (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 700,
          child: MinimalCalendar(
            firstDate: DateTime(2026),
            lastDate: DateTime(2026, 12, 31),
            value: DateTime(2026, 3, 18),
            onChanged: (_) {},
            months: 2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final left = tester.getRect(find.byType(MinimalCalendar)).left;
    // A month's seven 44 px slots and the 32 px gutter between the grids,
    // wider than a column step, so the months read as two.
    const second = 7 * MinimalLayout.minHitTarget + MinimalSpacing.s32;
    expect(_start(tester, 'March 2026'), moreOrLessEquals(left, epsilon: 1));
    expect(
      _start(tester, 'April 2026'),
      moreOrLessEquals(left + second, epsilon: 1),
    );
    final previous = find.byWidgetPredicate(
      (w) => w is MinimalIconButton && w.icon == LucideIcons.chevronLeftDir,
    );
    final next = find.byWidgetPredicate(
      (w) => w is MinimalIconButton && w.icon == LucideIcons.chevronRightDir,
    );
    expect(previous, findsOneWidget);
    expect(next, findsOneWidget);
    expect(tester.getRect(previous).left, greaterThan(left + second));
    expect(tester.getRect(previous).left, lessThan(tester.getRect(next).left));
    await tester.tap(previous);
    await tester.pumpAndSettle();
    expect(find.text('February 2026'), findsOneWidget);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('April 2026'), findsOneWidget);
  });

  testWidgets('a wheel on the page stands on its slot\'s start edge, not '
      'centred in it', (tester) async {
    await tester.pumpWidget(
      _host(
        MinimalTimePicker(
          label: 'Remind me at',
          value: DateTime(2026, 8, 28, 21, 30),
          wheel: true,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final slot = tester.getRect(find.byType(MinimalTimePicker));
    final hour = tester.getRect(find.text('HOUR'));
    final minute = tester.getRect(find.text('MINUTE'));
    expect(hour.left, moreOrLessEquals(slot.left, epsilon: 0.5));
    expect(minute.right - hour.left, lessThan(slot.width));
  });

  testWidgets('the upload zone prints its link words in a link\'s ink and '
      'underline, and stays one control', (tester) async {
    var browsed = 0;
    const title = 'Drop a CSV here, or browse';
    await tester.pumpWidget(
      _host(
        MinimalFileUpload(
          title: title,
          link: 'browse',
          onBrowse: () => browsed += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final t = MinimalThemeData.preset('standard', Brightness.light);
    final words = find.text(title, findRichText: true);
    final spans = <TextSpan>[];
    tester.widget<RichText>(words).text.visitChildren((span) {
      if (span is TextSpan && span.text == 'browse') spans.add(span);
      return true;
    });
    expect(spans, hasLength(1));
    expect(spans.single.style?.color, t.primaryInk);
    expect(spans.single.style?.decoration, TextDecoration.underline);
    expect(
      find.descendant(
        of: find.byType(MinimalFileUpload),
        matching: find.byType(MinimalPressable),
      ),
      findsOneWidget,
    );
    await tester.tap(words);
    expect(browsed, 1);
  });

  testWidgets('a selection group\'s padding insets its rows\' words and '
      'checks while its rules span the group', (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 390,
          child: MinimalSelectionGroup(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            children: [
              MinimalChoiceRow(
                title: 'Every day',
                selected: true,
                onPressed: () {},
              ),
              MinimalChoiceRow(
                title: 'Weekdays',
                selected: false,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final group = tester.getRect(find.byType(MinimalSelectionGroup));
    expect(_start(tester, 'Weekdays'), moreOrLessEquals(group.left + 18));
    final check = find.byWidgetPredicate(
      (w) => w is MinimalIcon && w.icon == LucideIcons.check,
    );
    expect(tester.getRect(check).right, moreOrLessEquals(group.right - 18));
    // Each row is the group's whole width, so its rule is too.
    for (final row in tester.widgetList<MinimalChoiceRow>(
      find.byType(MinimalChoiceRow),
    )) {
      expect(tester.getRect(find.byWidget(row)).width, group.width);
    }
  });

  testWidgets('today\'s bar keeps its gap under the digits at text scale 1.3', (
    tester,
  ) async {
    final day = DateTime(2026, 3, 12);
    // The space between today's figure's baseline and the top of its bar.
    Future<double> gap(double scale) async {
      await tester.pumpWidget(
        _host(
          MinimalCalendar(
            firstDate: DateTime(2026),
            lastDate: DateTime(2026, 12, 31),
            value: DateTime(2026, 3, 20),
            today: day,
            onChanged: (_) {},
          ),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();
      final bar = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints ==
                const BoxConstraints.tightFor(width: 10, height: 2),
      );
      expect(bar, findsOneWidget);
      final figure = find.descendant(
        of: find.ancestor(of: bar, matching: find.byType(Stack)).first,
        matching: find.text('${day.day}'),
      );
      // The figure's baseline: its paragraph's top plus the baseline of
      // the same words laid out alone (a box's baseline is read only by its
      // parent while it lays out).
      final p = tester.renderObject<RenderParagraph>(figure);
      final painter = TextPainter(
        text: p.text,
        textDirection: TextDirection.ltr,
        textScaler: p.textScaler,
      )..layout();
      final baseline =
          tester.getTopLeft(figure).dy +
          painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      painter.dispose();
      return tester.getRect(bar).top - baseline;
    }

    final atOne = await gap(1);
    expect(atOne, greaterThan(2));
    expect(await gap(1.3), moreOrLessEquals(atOne, epsilon: 0.5));
  });
}
