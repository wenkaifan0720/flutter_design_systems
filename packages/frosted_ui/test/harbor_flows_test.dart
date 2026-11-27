// Harbor's flows hold at large text and in Arabic: a split saves only on confirmation, a limit edits, cancels and
// saves, and the week strip, the When choices, a revealed Delete and the overview title keep their words at 2x.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

// The gallery is the example app; a test reads its pages from there.
// ignore: avoid_relative_lib_imports
import '../example/lib/gallery.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/harbor.dart';
import 'gallery_support.dart' show loadBundledFonts, settle;

Future<void> open(WidgetTester t, String path, {double width = 390}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(width, 844);
  addTearDown(t.view.reset);
  await t.pumpWidget(GalleryApp(key: UniqueKey(), link: path));
  await settle(t);
}

Future<void> press(WidgetTester t, Finder f) async {
  await Scrollable.ensureVisible(t.element(f), alignment: .5);
  await settle(t);
  await t.tap(f);
  await settle(t);
}

void fits(WidgetTester t, Finder text) {
  final paragraph = t.renderObject<RenderParagraph>(text);
  expect(
    paragraph.didExceedMaxLines,
    isFalse,
    reason: paragraph.text.toPlainText(),
  );
  final words = paragraph.text.toPlainText();
  for (final match in RegExp(r'\S+').allMatches(words)) {
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: match.start, extentOffset: match.end),
    );
    for (final box in boxes) {
      expect(box.left, greaterThanOrEqualTo(-1), reason: words);
      expect(
        box.right,
        lessThanOrEqualTo(paragraph.size.width + 1),
        reason: words,
      );
    }
  }
}

void main() {
  setUpAll(() async {
    await loadBundledFonts();
    await frostedLoadFonts();
  });

  testWidgets(
    'activity search and detail follow the same filtered transactions',
    (t) async {
      await open(t, '/harbor', width: 1440);
      final search = find.descendant(
        of: find.byType(FrostedSearchField),
        matching: find.byType(EditableText),
      );
      final detail = find.byType(HarborTransactionDetail);
      await press(t, find.text('Income'));
      expect(
        t.widget<HarborTransactionDetail>(detail).transaction.isIncome,
        isTrue,
      );
      await t.enterText(search, 'zqxv753');
      await t.testTextInput.receiveAction(TextInputAction.search);
      await settle(t);
      expect(find.text('No matching transactions'), findsOneWidget);
      expect(detail, findsNothing);
      expect(find.text('Blue Fern Café'), findsNothing);
      await t.enterText(search, 'paycheck');
      await settle(t);
      expect(
        t.widget<HarborTransactionDetail>(detail).transaction.category,
        'Paycheck',
      );
      await t.enterText(search, '');
      await press(t, find.text('All'));
      expect(find.text('Blue Fern Café'), findsWidgets);
    },
  );

  testWidgets('split distributes the cents and only saves on confirmation', (
    t,
  ) async {
    await open(t, '/harbor?screen=transaction&text=200');
    await press(t, find.text('Split'));
    expect(find.text('Split transaction'), findsOneWidget);
    expect(find.text(r'1 × $3.38 + 1 × $3.37'), findsOneWidget);
    final number = find.descendant(
      of: find.byType(FrostedNumberField),
      matching: find.byType(EditableText),
    );
    await t.enterText(number, '3');
    await settle(t);
    expect(find.text(r'3 × $2.25'), findsOneWidget);
    await press(t, find.text('Cancel'));
    expect(find.text(r'3 × $2.25'), findsNothing);
    await press(t, find.text('Split'));
    await t.enterText(number, '3');
    await settle(t);
    await press(t, find.text('Save split'));
    expect(find.text(r'3 × $2.25'), findsOneWidget);
    await press(t, find.text('Done'));
    await press(t, find.text('Blue Fern Café').first);
    expect(find.text(r'3 × $2.25'), findsOneWidget);
  });

  testWidgets('monthly spending limit can be edited, cancelled, and saved', (
    t,
  ) async {
    await open(t, '/harbor?screen=settings', width: 1440);
    await press(t, find.text('Monthly spending limit'));
    final amount = find.descendant(
      of: find.byType(FrostedNumberField),
      matching: find.byType(EditableText),
    );
    await t.enterText(amount, '1750');
    await press(t, find.text('Cancel'));
    expect(find.text(r'$2,500'), findsOneWidget);
    await press(t, find.text('Monthly spending limit'));
    await t.enterText(amount, '1750');
    await press(t, find.text('Save limit'));
    expect(find.text(r'$1,750'), findsOneWidget);
  });

  testWidgets(
    'large file sizes and kinds fit reachable cells; checks clear the rim',
    (t) async {
      await open(t, '/data?text=200');
      final table = find.byWidgetPredicate((w) => w is FrostedDataTable);
      final checks = find.descendant(
        of: table,
        matching: find.byType(FrostedCheckbox),
      );
      await settle(t);
      expect(
        t.getTopLeft(checks.first).dx - t.getTopLeft(table).dx,
        greaterThanOrEqualTo(6),
      );
      for (final word in ['Brief', '2.3 MB', '48 KB', 'Document', 'Image']) {
        final text = find.text(word).first;
        await t.ensureVisible(text);
        await settle(t);
        fits(t, text);
      }
    },
  );

  testWidgets('week labels and dates honor 2x text', (t) async {
    await open(t, '/week?text=200');
    final strip = find.byType(FrostedWeekStrip).first;
    for (final word in ['MON', '30']) {
      final text = find.descendant(of: strip, matching: find.text(word)).first;
      fits(t, text);
      final render = t.renderObject<RenderParagraph>(text);
      expect(render.textScaler.scale(12), closeTo(24, .01));
    }
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'every sign-in button shows its full provider at $width and 2x',
      (t) async {
        await open(t, '/sign-in?text=200', width: width);
        for (final provider in ['Apple', 'Google', 'email']) {
          final text = find.text('Continue with $provider').first;
          await t.ensureVisible(text);
          await settle(t);
          fits(t, text);
        }
      },
    );
  }

  testWidgets('all three When choices remain readable and selectable at 2x', (
    t,
  ) async {
    await open(t, '/selection?text=200');
    final when = find.byWidgetPredicate(
      (w) => w is FrostedSegmentedButton && w.label == 'When',
    );
    for (final word in ['Today', 'Tomorrow', 'Choose a date']) {
      final text = find.descendant(of: when, matching: find.text(word));
      await t.ensureVisible(text);
      await settle(t);
      fits(t, text);
    }
    await press(t, find.descendant(of: when, matching: find.text('Tomorrow')));
    expect(t.widget<FrostedSegmentedButton<String>>(when).value, 'tomorrow');
  });

  testWidgets('the revealed Delete label fits at double text', (t) async {
    await open(t, '/swipe?text=200');
    final opened = find
        .byWidgetPredicate((w) => w is FrostedSwipeActions && w.initiallyOpen)
        .first;
    final text = find.descendant(of: opened, matching: find.text('DELETE'));
    await t.ensureVisible(text);
    await settle(t);
    fits(t, text);
  });

  testWidgets('choosing a month keeps the Arabic trigger in Arabic', (t) async {
    await open(t, '/menu?dir=rtl&theme=dark');
    await press(
      t,
      find
          .byWidgetPredicate(
            (w) =>
                w is FrostedButton &&
                (w.label == 'أكتوبر 2026' || w.label == 'October 2026'),
          )
          .first,
    );
    await press(t, find.text('سبتمبر 2026').last);
    expect(
      find.byWidgetPredicate(
        (w) => w is FrostedButton && w.label == 'سبتمبر 2026',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the phone overview title stays on one line at 2x', (t) async {
    await open(t, '/?text=200');
    final title = find.text('Frosted').last;
    final p = t.renderObject<RenderParagraph>(title);
    final lines = p.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 7),
    );
    expect(lines.map((b) => b.top).toSet(), hasLength(1));
  });
}
