// ignore_for_file: avoid_relative_lib_imports
import 'package:comic_ui/comic_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../example/lib/kit_gallery/gate_screens.dart';
import 'support.dart';

void main() {
  setUpAll(loadComicFonts);

  Future<void> phone(
    WidgetTester tester,
    Widget child, {
    double scale = 1,
    TextDirection direction = TextDirection.ltr,
  }) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(780, 1688);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      comicApp(
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 27),
            child: child,
          ),
        ),
        direction: direction,
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (page, label, bad, good, action, error, success) in [
    (
      gateAccount,
      'Email address',
      'wrong',
      'reader@example.com',
      'Save details',
      'Enter a valid email address.',
      'Delivery details saved.',
    ),
    (
      gateShop,
      'Card number',
      '1',
      '4242 4242 4242 4242',
      'Pay €21',
      'Enter a valid card number.',
      'Order placed. Thank you!',
    ),
  ]) {
    testWidgets('$action requires a valid $label', (tester) async {
      await phone(tester, page());
      final field = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is ComicTextField && w.label == label,
        ),
        matching: find.byType(EditableText),
      );
      final submit = find.text(action.toUpperCase());
      Future<void> submitValue(String value) async {
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
      }

      await submitValue(bad);
      expect(find.text(error), findsOneWidget);
      expect(find.text(success), findsNothing);
      await submitValue(good);
      expect(find.text(error), findsNothing);
      expect(find.text(success), findsOneWidget);
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle();
    });
  }

  for (final dir in TextDirection.values) {
    testWidgets(
      'all seven days fit a phone at twice the text size in ${dir.name}',
      (tester) async {
        int? picked;
        await phone(
          tester,
          ComicDatePicker(
            value: DateTime(2026, 11, 17),
            currentDate: DateTime(2026, 11, 17),
            onChanged: (v) => picked = v.day,
          ),
          scale: 2,
          direction: dir,
        );
        final calendar = find.byType(ComicDatePicker);
        final scroll = tester.stateList<ScrollableState>(
          find.descendant(of: calendar, matching: find.byType(Scrollable)),
        );
        for (final view in scroll) {
          if (view.position.axis == Axis.horizontal) {
            expect(view.position.maxScrollExtent, 0);
          }
        }
        final bounds = tester.getRect(calendar);
        for (final day in ['1', '8', '30']) {
          final finder = find.text(day);
          expect(bounds.contains(tester.getCenter(finder)), isTrue);
          await tester.tap(finder);
          await tester.pumpAndSettle();
          expect(picked, int.parse(day));
          final paragraph = tester.renderObject<RenderParagraph>(finder);
          expect(
            paragraph.getMaxIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(paragraph.size.width + 0.5),
          );
        }
      },
    );
    // As Material's DropdownMenu: the closed field holds its value on one line and ends it with an ellipsis where it
    // outgrows the field; the value is read whole, and the open menu shows it whole.
    testWidgets(
      'a closed select keeps the delivery method on one line, read and listed whole, in ${dir.name}',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await phone(
          tester,
          ComicSelect<String>(
            label: 'Delivery',
            value: 'standard',
            options: const [
              ComicSelectOption('standard', 'Standard delivery'),
              ComicSelectOption('express', 'Express delivery'),
            ],
            onChanged: (_) {},
          ),
          scale: 2,
          direction: dir,
        );
        final text = tester.renderObject<RenderParagraph>(
          find.text('Standard delivery'),
        );
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
        expect(text.didExceedMaxLines, isTrue);
        final line = TextPainter(
          text: text.text,
          textDirection: dir,
          textScaler: text.textScaler,
          maxLines: 1,
        )..layout();
        expect(text.size.height, closeTo(line.height, .5));
        line.dispose();
        expect(
          tester.getSemantics(find.bySemanticsLabel('Delivery')),
          isSemantics(label: 'Delivery', value: 'Standard delivery'),
        );
        await tester.tap(find.text('Standard delivery'));
        await tester.pumpAndSettle();
        // The open menu lists the value whole: not cut short, wrapping only between its words.
        final listed = tester.renderObject<RenderParagraph>(
          find.text('Standard delivery').last,
        );
        expect(listed.didExceedMaxLines, isFalse);
        for (final word in const ['Standard', 'delivery']) {
          final one = TextPainter(
            text: TextSpan(text: word, style: listed.text.style),
            textDirection: dir,
            textScaler: listed.textScaler,
            maxLines: 1,
          )..layout();
          expect(listed.size.width + .5, greaterThanOrEqualTo(one.width));
          one.dispose();
        }
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'density labels keep their scale and keyboard selection in a narrow trough',
    (tester) async {
      var chosen = 0;
      Widget control() => StatefulBuilder(
        builder: (context, setState) => ComicSegmentedButton<int>(
          label: 'Density',
          segments: const [
            ComicButtonSegment(0, 'Standard'),
            ComicButtonSegment(1, 'Comfortable'),
            ComicButtonSegment(2, 'Compact'),
          ],
          value: chosen,
          onChanged: (v) => setState(() => chosen = v),
        ),
      );
      final label = find.text('Comfortable');
      Future<double> inkHeight(double scale) async {
        await phone(tester, control(), scale: scale);
        final p = tester.renderObject<RenderParagraph>(label);
        final glyph = p
            .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 1),
            )
            .single
            .toRect();
        return p.localToGlobal(glyph.bottomLeft).dy -
            p.localToGlobal(glyph.topLeft).dy;
      }

      final normal = await inkHeight(1);
      final enlarged = await inkHeight(2);
      expect(enlarged, greaterThan(normal * 1.85));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(chosen, 1);
    },
  );

  testWidgets('an RTL chart preserves the reading order of each count', (
    tester,
  ) async {
    await phone(
      tester,
      const Column(
        children: [
          ComicBar(value: 2, of: 6, label: 'Sheets', figure: '2 of 6'),
          ComicBar(value: 5, of: 6, label: 'أوراق', figure: '٥ من ٦'),
        ],
      ),
      scale: 2,
      direction: TextDirection.rtl,
    );
    for (final (s, rtl) in [('2 of 6', false), ('٥ من ٦', true)]) {
      final p = tester.renderObject<RenderParagraph>(find.text(s));
      double x(int i) => p
          .getBoxesForSelection(
            TextSelection(baseOffset: i, extentOffset: i + 1),
          )
          .first
          .left;
      expect(
        x(0),
        rtl ? greaterThan(x(s.length - 1)) : lessThan(x(s.length - 1)),
      );
    }
  });

  testWidgets(
    'neighbouring bottom destinations leave room between their captions',
    (tester) async {
      await phone(
        tester,
        const ComicNavigationBar(
          destinations: [
            ComicNavItem(label: 'Today', short: 'Today', icon: Icons.home),
            ComicNavItem(label: 'Places', short: 'Places', icon: Icons.map),
            ComicNavItem(label: 'Figures', short: 'Figures', icon: Icons.star),
            ComicNavItem(label: 'You', short: 'You', icon: Icons.person),
          ],
        ),
        scale: 2,
      );
      Rect ink(String s) {
        final p = tester.renderObject<RenderParagraph>(find.text(s));
        final boxes = p.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: s.length),
        );
        final bounds = boxes
            .map((b) => b.toRect())
            .reduce((a, b) => a.expandToInclude(b));
        return Rect.fromPoints(
          p.localToGlobal(bounds.topLeft),
          p.localToGlobal(bounds.bottomRight),
        );
      }

      expect(
        ink('FIGURES').left - ink('PLACES').right,
        greaterThanOrEqualTo(7),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
