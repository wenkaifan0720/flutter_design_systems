import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_parts.dart' show LedgerDayRulerLabels;
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

Future<void> _show(
  WidgetTester t,
  Widget child, {
  double width = 390,
  double maxWidth = 360,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(width, 844);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      builder: (context, page) => LedgerHost(
        brightness: Brightness.light,
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale,
          child: Directionality(textDirection: direction, child: page!),
        ),
      ),
      home: Material(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> _key(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyEvent(key);
  await t.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(ledgerLoadFonts);

  testWidgets('the OTP field and the selected value each have a single name', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    await _show(t, const LedgerCodeField(labelText: 'Verification code'));
    expect(
      t.getSemantics(find.byType(EditableText)).getSemanticsData().label,
      'Verification code',
    );
    await _show(
      t,
      const LedgerCodeField(
        labelText: 'Verification code',
        semanticLabel: 'Code for login',
      ),
    );
    expect(
      t.getSemantics(find.byType(EditableText)).getSemanticsData().label,
      'Code for login',
    );
    expect(find.text('VERIFICATION CODE', findRichText: true), findsOneWidget);
    await _show(
      t,
      LedgerSelect<String>(
        labelText: 'Paper size',
        value: 'A4',
        items: const [LedgerSelectItem(value: 'A4', label: 'A4')],
        onChanged: (_) {},
      ),
    );
    final button = t.getSemantics(find.bySemanticsLabel('Paper size').first);
    expect(button.getSemanticsData().label, 'Paper size');
    expect(button.getSemanticsData().value, 'A4');
    handle.dispose();
  });

  testWidgets(
    'inline search exposes one enabled editor and accepts keyboard input',
    (t) async {
      final handle = t.ensureSemantics();
      var query = '';
      await _show(
        t,
        LedgerSearchField(
          hintText: 'Search titles',
          onChanged: (v) => query = v,
        ),
      );
      final editor = find.byType(EditableText);
      final data = t.getSemantics(editor).getSemanticsData();
      expect(data.label, 'Search titles');
      expect(data.flagsCollection.isTextField, isTrue);
      expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
      await _key(t, LogicalKeyboardKey.tab);
      expect(t.widget<EditableText>(editor).focusNode.hasFocus, isTrue);
      t.testTextInput.enterText('Field');
      await t.pump();
      expect(query, 'Field');
      handle.dispose();
    },
  );

  testWidgets(
    'a selected tag can be deleted separately from the named editor, and typing adds the next',
    (t) async {
      final handle = t.ensureSemantics();
      var values = ['Work'];
      await _show(
        t,
        StatefulBuilder(
          builder: (context, set) => LedgerMultiSelect<String>(
            values: values,
            options: const ['Work', 'Home'],
            labelText: 'Labels',
            onChanged: (v) => set(() => values = v),
          ),
        ),
      );
      final editor = find.byType(EditableText);
      expect(t.getSemantics(editor).label, 'Labels');
      expect(find.bySemanticsLabel('Delete Work'), findsOneWidget);
      await t.tap(editor);
      await t.enterText(editor, 'Ho');
      await t.pumpAndSettle();
      await _key(t, LogicalKeyboardKey.arrowDown);
      await _key(t, LogicalKeyboardKey.enter);
      expect(values, ['Work', 'Home']);
      handle.dispose();
    },
  );

  testWidgets(
    'stepper announcements use the same quantity format as the displayed value',
    (t) async {
      final handle = t.ensureSemantics();
      await _show(
        t,
        LedgerStepper(
          labelText: 'Copies',
          value: 2,
          step: 1,
          min: 1,
          format: (value) => '$value copies',
          onChanged: (_) {},
        ),
      );
      final data = t
          .getSemantics(find.bySemanticsLabel('Copies').first)
          .getSemanticsData();
      expect(find.text('2 copies'), findsOneWidget);
      expect(
        [data.decreasedValue, data.value, data.increasedValue],
        ['1 copies', '2 copies', '3 copies'],
      );
      handle.dispose();
    },
  );

  testWidgets('standalone navigation accepts Tab, arrows and Enter', (t) async {
    var tab = 0;
    await _show(
      t,
      StatefulBuilder(
        builder: (context, set) => LedgerNavBar(
          items: const [
            LedgerNavItem(Icons.home, 'Home'),
            LedgerNavItem(Icons.book, 'Books'),
          ],
          selectedIndex: tab,
          onDestinationSelected: (v) => set(() => tab = v),
        ),
      ),
    );
    await _key(t, LogicalKeyboardKey.tab);
    await _key(t, LogicalKeyboardKey.arrowRight);
    await _key(t, LogicalKeyboardKey.enter);
    expect(tab, 1);
  });

  testWidgets(
    'each selected tab controls the panel bearing its accessible name',
    (t) async {
      final handle = t.ensureSemantics();
      var tab = 0;
      await _show(
        t,
        SizedBox(
          height: 180,
          child: StatefulBuilder(
            builder: (context, set) => LedgerTabs(
              tabs: const ['Overview', 'Activity'],
              selectedIndex: tab,
              onSelected: (v) => set(() => tab = v),
              children: const [Text('Private draft'), Text('Created today')],
            ),
          ),
        ),
      );
      for (final (index, title, body) in [
        (0, 'Overview', 'Private draft'),
        (1, 'Activity', 'Created today'),
      ]) {
        if (index != 0) {
          await t.tap(find.text(title));
          await t.pumpAndSettle();
        }
        SemanticsNode? panel = t.getSemantics(find.text(body));
        while (panel != null && panel.role != ui.SemanticsRole.tabPanel) {
          panel = panel.parent;
        }
        expect(panel?.label, title);
        final label = t
            .getSemantics(find.bySemanticsLabel(RegExp('^$title\\nTab ')).first)
            .getSemanticsData();
        expect(label.controlsNodes, {panel!.identifier});
      }
      handle.dispose();
    },
  );

  testWidgets(
    'large text fits field captions, date labels, and pie percentages',
    (t) async {
      await _show(
        t,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LedgerInputGroup(
              labelText: 'Parcel weight in kilograms',
              after: 'kg',
            ),
            LedgerDatePicker(
              labelText: 'Due date',
              value: DateTime(2026, 11, 18),
              onChanged: (_) {},
            ),
            const LedgerPieChart(
              label: 'Plan',
              shares: [LedgerShare('Rent', 65), LedgerShare('Bills', 35)],
            ),
          ],
        ),
        scale: 2,
        direction: TextDirection.rtl,
      );
      for (final words in [
        'PARCEL WEIGHT IN KILOGRAMS',
        'Due date',
        '65%',
        '35%',
      ]) {
        final finder = find.text(words, findRichText: true).first;
        final p = t.renderObject<RenderParagraph>(finder);
        expect(p.didExceedMaxLines, isFalse, reason: words);
        if (words.endsWith('%')) {
          final boxes = p.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: words.length),
          );
          expect(boxes.map((b) => b.top).toSet(), hasLength(1), reason: words);
        }
      }
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('close month labels stay visible without intersecting at 200%', (
    t,
  ) async {
    await _show(
      t,
      const LedgerDayRulerLabels(
        width: 320,
        marks: [
          (text: 'January 1', x: 0, first: true, today: false),
          (text: '4', x: 32, first: false, today: true),
        ],
      ),
      scale: 2,
    );
    expect(
      t.getRect(find.text('January 1')).overlaps(t.getRect(find.text('4'))),
      isFalse,
    );
  });

  testWidgets('large type leaves every transaction amount visible on a phone', (
    t,
  ) async {
    final table = RawDataTableController<(String, String, String)>(
      rows: const [
        ('Harbour Books', 'Everyday checking', '−\$64.18'),
        ('Blue Bottle', 'Wren card', '−\$6.75'),
      ],
      columns: [
        RawDataColumn(id: 'name', label: 'Entry', sortKey: (row) => row.$1),
        RawDataColumn(
          id: 'account',
          label: 'Account',
          sortKey: (row) => row.$2,
        ),
        RawDataColumn(
          id: 'amount',
          label: 'Amount',
          numeric: true,
          sortKey: (row) => row.$3,
        ),
      ],
    );
    addTearDown(table.dispose);
    await _show(
      t,
      LedgerDataTable<(String, String, String)>(
        controller: table,
        cellText: (row, column) => switch (column.id) {
          'name' => row.$1,
          'account' => row.$2,
          _ => row.$3,
        },
      ),
      scale: 2,
    );
    for (final word in [
      'Harbour Books',
      'Everyday checking',
      '−\$64.18',
      '−\$6.75',
    ]) {
      final f = find.text(word);
      final p = t.renderObject<RenderParagraph>(f);
      expect(p.didExceedMaxLines, isFalse, reason: word);
      final rect = t.getRect(f);
      expect(rect.left, greaterThanOrEqualTo(0), reason: word);
      expect(rect.right, lessThanOrEqualTo(390), reason: word);
      for (final token in RegExp(r'\S+').allMatches(word)) {
        expect(
          p.getBoxesForSelection(
            TextSelection(baseOffset: token.start, extentOffset: token.end),
          ),
          hasLength(1),
          reason: 'whole word ${token.group(0)}',
        );
      }
      if (word.startsWith('−')) {
        final ink = p.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: word.length),
        );
        expect(ink.last.right, lessThanOrEqualTo(p.size.width + 1));
      }
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('open swipe actions fit their captions at double text size', (
    t,
  ) async {
    await _show(
      t,
      LedgerSwipeActions(
        initiallyOpen: true,
        trailing: [
          LedgerSwipeAction(
            'Delete',
            onPressed: () {},
            tone: LedgerSwipeTone.destructive,
          ),
          LedgerSwipeAction('Snooze', onPressed: () {}),
        ],
        child: const SizedBox(height: 64, width: 342),
      ),
      scale: 2,
    );
    for (final name in ['DELETE', 'SNOOZE']) {
      final f = find.text(name);
      final p = t.renderObject<RenderParagraph>(f);
      final mapped = MatrixUtils.transformRect(
        p.getTransformTo(null),
        Offset.zero & p.size,
      );
      expect(mapped.width, closeTo(p.size.width, .5), reason: name);
      expect(p.didExceedMaxLines, isFalse, reason: name);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('calendar days enlarge inside their columns', (t) async {
    Future<Rect> day(double scale) async {
      await _show(
        t,
        LedgerDatePicker(
          value: DateTime(2026, 11, 4),
          presentation: LedgerDatePickerPresentation.inline,
          onChanged: (_) {},
        ),
        scale: scale,
      );
      final p = t.renderObject<RenderParagraph>(find.text('4'));
      final ink = p
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 1),
          )
          .single
          .toRect();
      return MatrixUtils.transformRect(p.getTransformTo(null), ink);
    }

    final original = await day(1);
    final large = await day(2);
    expect(large.height, greaterThan(original.height * 1.7));
    expect(t.takeException(), isNull);
  });

  testWidgets('the error text meets text contrast on Ledger paper', (t) async {
    await _show(
      t,
      const LedgerTextField(
        labelText: 'Amount',
        errorText: 'Enter what was paid',
      ),
    );
    final finder = find.text('Enter what was paid');
    final theme = LedgerTheme.of(t.element(finder));
    final p = t.renderObject<RenderParagraph>(finder);
    expect(
      LedgerThemeData.contrast(p.text.style!.color!, theme.background),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('compact step progress reads the numerator first in RTL', (
    t,
  ) async {
    await _show(
      t,
      const LedgerStepProgress(
        steps: ['Address', 'Payment', 'Review'],
        currentStep: 0,
      ),
      scale: 2,
      direction: TextDirection.rtl,
    );
    final p = t.renderObject<RenderParagraph>(
      find.textContaining('ADDRESS').last,
    );
    final text = p.text.toPlainText();
    double xOf(String digit) {
      final at = text.indexOf(digit);
      return p
          .getBoxesForSelection(
            TextSelection(baseOffset: at, extentOffset: at + 1),
          )
          .first
          .left;
    }

    expect(xOf('1'), lessThan(xOf('3')));
  });

  testWidgets(
    "a pushed page's masthead keeps the title under its crumb at small text",
    (t) async {
      // At 0.85 the meta's line is shorter than the crumb's reach (the pointer's
      // 24): the gap under the crumb gives up what it has, and no more.
      await _show(
        t,
        const LedgerTopBar(
          title: 'Receipt',
          leading: SizedBox.square(dimension: 36),
        ),
        width: 1440,
        maxWidth: 1200,
        scale: 0.85,
      );
      expect(t.takeException(), isNull);
      expect(find.text('Receipt'), findsOneWidget);
    },
  );

  testWidgets(
    'a pushed title uses the space beyond its centre at double text size',
    (t) async {
      await _show(
        t,
        const LedgerTopBar(
          title: 'Top bar & screen',
          leading: SizedBox.square(dimension: 36),
        ),
        scale: 2,
        maxWidth: 390,
      );
      expect(
        t
            .renderObject<RenderParagraph>(find.text('Top bar & screen'))
            .didExceedMaxLines,
        isFalse,
      );
    },
  );

  testWidgets(
    'a short pull can reveal the refresh indicator without overflow',
    (t) async {
      var refreshed = false;
      await _show(
        t,
        SizedBox(
          height: 280,
          child: LedgerPullToRefresh(
            onRefresh: () async {
              refreshed = true;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [SizedBox(height: 900)],
            ),
          ),
        ),
      );
      final scroll = find.byType(ListView);
      final gesture = await t.startGesture(t.getCenter(scroll));
      for (var i = 0; i < 25; i++) {
        await gesture.moveBy(const Offset(0, 8));
        await t.pump(const Duration(milliseconds: 16));
        expect(t.takeException(), isNull);
      }
      await gesture.up();
      await t.pumpAndSettle();
      expect(refreshed, isTrue);
    },
  );
}
