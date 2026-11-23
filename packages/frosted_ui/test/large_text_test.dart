// Large text (200%): a pill, a toggle's plates and a meter's scale row grow with their
// words instead of cutting them; the statement's three stops stand one under another; and right to left, the colour
// tracks run with their thumbs and the time picker stands at the page's start.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';

Future<void> _pump(
  WidgetTester t,
  Widget part, {
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
  Size size = const Size(390, 844),
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: FrostedHost(child: page!),
        ),
      ),
      home: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [part],
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  expect(t.takeException(), isNull);
}

void main() {
  testWidgets('at 200% a button grows by its words and holds them inside', (
    t,
  ) async {
    Widget button() =>
        Align(child: FrostedButton('Transfer', onPressed: () {}));
    await _pump(t, button());
    final rest = t.getSize(find.byType(FrostedButton)).height;
    await _pump(t, button(), scale: 2);
    final pill = t.getRect(find.byType(FrostedButton));
    final words = t.getRect(find.text('Transfer'));
    expect(pill.height, greaterThan(rest));
    expect(words.top, greaterThanOrEqualTo(pill.top));
    expect(words.bottom, lessThanOrEqualTo(pill.bottom));
  });

  testWidgets('a word cut short keeps the pill its whole inset', (t) async {
    await _pump(
      t,
      Align(
        child: SizedBox(
          width: 200,
          child: FrostedButton('Remind me Thursday morning', onPressed: () {}),
        ),
      ),
      scale: 2,
    );
    final pill = t.getRect(find.byType(FrostedButton));
    final words = t.getRect(find.byType(Text).last);
    expect(
      words.left - pill.left,
      greaterThanOrEqualTo(FrostedChromeMetrics.buttonInset - 0.5),
    );
    expect(
      pill.right - words.right,
      greaterThanOrEqualTo(FrostedChromeMetrics.buttonInset - 0.5),
    );
  });

  testWidgets('at 200% a chip and a chosen tag hold their words inside', (
    t,
  ) async {
    Widget parts() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FrostedChip('Design', selected: true, onPressed: () {}),
        FrostedMultiSelect<String>(
          labelText: 'Tags',
          values: const ['Review'],
          onChanged: (_) {},
        ),
      ],
    );
    // The chip's glass, inside its touch target, grows round its words.
    Finder glass() => find
        .descendant(
          of: find.byType(FrostedChip),
          matching: find.byType(FrostedFace),
        )
        .first;
    await _pump(t, parts());
    final rest = t.getSize(glass()).height;
    await _pump(t, parts(), scale: 2);
    final chip = t.getRect(glass());
    expect(chip.height, greaterThan(rest));
    final design = t.getRect(find.text('Design'));
    expect(design.top, greaterThanOrEqualTo(chip.top));
    expect(design.bottom, lessThanOrEqualTo(chip.bottom));
    // The tag's glass is the nearest face round its words.
    final review = find.text('Review');
    final tag = t.getRect(
      find.ancestor(of: review, matching: find.byType(SizedBox)).first,
    );
    final words = t.getRect(review);
    expect(words.top, greaterThanOrEqualTo(tag.top));
    expect(words.bottom, lessThanOrEqualTo(tag.bottom));
  });

  testWidgets("at 200% a status tag's figure keeps the tag's size", (t) async {
    const part = Align(
      alignment: AlignmentDirectional.centerStart,
      child: FrostedTag('results', figure: '13'),
    );
    await _pump(t, part);
    final rest = t.getSize(find.byType(FrostedTag));
    await _pump(t, part, scale: 2);
    final tag = t.getRect(find.byType(FrostedTag));
    expect(tag.size, rest);
    final figure = t.getRect(find.text('13'));
    expect(figure.top, greaterThanOrEqualTo(tag.top));
    expect(figure.bottom, lessThanOrEqualTo(tag.bottom));
  });

  testWidgets('a section head on the canvas stands a gap over its glass', (
    t,
  ) async {
    await _pump(
      t,
      const FrostedListSection(
        title: 'Accounts',
        aside: '3 accounts',
        tile: false,
        rows: [FrostedListTile(title: 'Everyday', meta: 'Checking')],
      ),
    );
    // The section's column: the head, then its glass.
    final column = t.renderObject<RenderFlex>(
      find
          .descendant(
            of: find.byType(FrostedListSection),
            matching: find.byType(Column),
          )
          .first,
    );
    final head = column.firstChild!;
    final glass = column.childAfter(head)!;
    final headBottom =
        (head.parentData! as FlexParentData).offset.dy + head.size.height;
    final glassTop = (glass.parentData! as FlexParentData).offset.dy;
    final gap = FrostedBreakpoints.gap(
      t.element(find.byType(FrostedListSection)),
    );
    expect(glassTop - headBottom, gap);
    expect(
      t.getRect(find.text('Accounts')).bottom,
      lessThan(column.localToGlobal(Offset(0, glassTop)).dy),
    );
  });

  testWidgets('at 200% a loss stands as tall as the act beside it', (t) async {
    await _pump(
      t,
      FrostedDialog(
        title: 'Delete Lisbon in May?',
        confirmLabel: 'Delete',
        cancelLabel: 'Keep',
        isDestructiveAction: true,
        onConfirm: () {},
        onCancel: () {},
      ),
      scale: 2,
    );
    double tall(String word) {
      final face = find.ancestor(
        of: find.text(word),
        matching: find.byType(FrostedFace),
      );
      return t.getSize(face.first).height;
    }

    expect(tall('Delete'), closeTo(tall('Keep'), 0.5));
    expect(t.getSize(find.text('Delete')).height, lessThan(tall('Delete')));
  });

  testWidgets("at 200% a toggle group's plates hold their words", (t) async {
    await _pump(
      t,
      FrostedToggleGroup<String>(
        segments: const [
          FrostedButtonSegment('l', 'Left'),
          FrostedButtonSegment('r', 'Right'),
        ],
        selected: const {'l'},
        onSelectionChanged: (_) {},
      ),
      scale: 2,
    );
    final words = t.getSize(find.text('Left')).height;
    final group = t.getSize(find.byType(FrostedToggleGroup<String>)).height;
    expect(
      group,
      greaterThanOrEqualTo(words + 2 * FrostedChromeMetrics.segmentsInset),
    );
  });

  testWidgets("from 1.2 the statement's stops stand one under another", (
    t,
  ) async {
    await _pump(
      t,
      FrostedStatementTimeline(
        paid: DateTime(2026, 10, 12),
        closed: DateTime(2026, 10, 28),
        due: DateTime(2026, 11, 12),
        paidAmount: 1180.22,
        closedAmount: 1326.44,
      ),
      scale: 1.6,
    );
    final paid = t.getRect(find.textContaining('Paid'));
    final closed = t.getRect(find.textContaining('Closed'));
    final due = t.getRect(find.textContaining('Due'));
    expect(closed.top, greaterThan(paid.bottom));
    expect(due.top, greaterThan(closed.bottom));
    expect(closed.left, paid.left);
  });

  testWidgets('from 1.2 the net stands whole under the in-and-out words', (
    t,
  ) async {
    await _pump(
      t,
      const FrostedInOut(
        moneyIn: 6825,
        spent: 2486.12,
        bands: [FrostedBand(1150, name: 'Rent')],
      ),
      scale: 2,
    );
    final net = find.textContaining('+\$4,338.88');
    expect(net, findsOneWidget);
    final words = t.getRect(find.textContaining('of what came in'));
    final figure = t.getRect(net);
    expect(figure.top, greaterThan(words.bottom));
    expect(figure.right, lessThanOrEqualTo(390 - 16 + 0.5));
  });

  testWidgets('right to left a hex value keeps its # in front', (t) async {
    await _pump(
      t,
      FrostedColorPicker(
        value: const Color(0xB3FF7A59),
        onChanged: (_) {},
        showAlpha: true,
      ),
      direction: TextDirection.rtl,
    );
    final field = t.widget<TextField>(
      find.descendant(
        of: find.byType(FrostedTextField),
        matching: find.byType(TextField),
      ),
    );
    expect(field.textDirection, TextDirection.ltr);
  });

  testWidgets('right to left the colour tracks run with their thumbs', (
    t,
  ) async {
    await _pump(
      t,
      FrostedColorPicker(
        value: const Color(0xFF5B6CFF),
        onChanged: (_) {},
        showAlpha: true,
      ),
      direction: TextDirection.rtl,
    );
    final gradients = [
      for (final box in t.widgetList<DecoratedBox>(find.byType(DecoratedBox)))
        // The tracks: a gradient in a bordered capsule (the colour area's
        // gradients carry no border).
        if (box.decoration case BoxDecoration(
          gradient: final LinearGradient g,
          border: _?,
        ))
          g,
    ];
    expect(gradients, isNotEmpty);
    for (final g in gradients) {
      expect(g.begin, AlignmentDirectional.centerStart);
      expect(g.end, AlignmentDirectional.centerEnd);
    }
  });

  testWidgets('right to left the time picker stands at the page start', (
    t,
  ) async {
    await _pump(
      t,
      FrostedTimePicker(
        value: const FrostedTime(hour: 9, minute: 30),
        onChanged: (_) {},
      ),
      direction: TextDirection.rtl,
      size: const Size(1440, 900),
    );
    final picker = t.getRect(find.byType(FrostedTimePicker));
    final drawn = t.getRect(
      find
          .descendant(
            of: find.byType(FrostedTimePicker),
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    expect(drawn.width, lessThan(picker.width));
    expect(drawn.right, closeTo(picker.right, 0.5));
  });

  // A figure is never broken across lines.
  int linesOf(WidgetTester t, String text) {
    final p = t.renderObject<RenderParagraph>(find.text(text));
    final boxes = p.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.length),
    );
    return {for (final b in boxes) b.top.round()}.length;
  }

  testWidgets('at 200% a quick amount keeps its figure on one line', (t) async {
    await _pump(
      t,
      FrostedQuickAmounts(
        options: const [
          FrostedQuickAmount(100, 'A month'),
          FrostedQuickAmount(200, 'Two months'),
          FrostedQuickAmount(1160, 'The rest'),
        ],
        value: 100,
        onChanged: (_) {},
      ),
      scale: 2,
    );
    expect(linesOf(t, r'$1,160'), 1);
  });

  testWidgets("at 200% a card's expiry stays whole and its groups apart", (
    t,
  ) async {
    await _pump(
      t,
      const FrostedCardNumber(
        number: '4242424242427730',
        expires: '09/29',
        cvc: '317',
        name: 'Maren Holt',
      ),
      scale: 2,
    );
    expect(linesOf(t, '09/29'), 1);
    // Expiry and code shrink by one scale: "317" no taller than "09/29".
    expect(
      t.getRect(find.text('317')).height,
      moreOrLessEquals(t.getRect(find.text('09/29')).height, epsilon: .5),
    );
    final groups = [
      for (var i = 0; i < 3; i++) t.getRect(find.text('4242').at(i)),
      t.getRect(find.text('7730')),
    ]..sort((a, b) => a.left.compareTo(b.left));
    for (var i = 1; i < groups.length; i++) {
      expect(groups[i].left - groups[i - 1].right, greaterThanOrEqualTo(7.5));
    }
  });

  testWidgets("at 200% a card's three figure cells shrink by one scale", (
    t,
  ) async {
    await _pump(
      t,
      const FrostedStats(
        variant: FrostedStatVariant.cells,
        children: [
          FrostedFigure(1326.44, caption: 'Due', note: 'Nov 12'),
          FrostedFigure(2673.56, caption: 'Available'),
          FrostedFigure(4000, caption: 'Limit', cents: false),
        ],
      ),
      scale: 2,
    );
    final figures = [
      for (var i = 0; i < 3; i++) t.getRect(find.byType(FrostedAmount).at(i)),
    ];
    for (final f in figures.skip(1)) {
      expect(f.height, moreOrLessEquals(figures.first.height, epsilon: .5));
    }
    // Each still inside the page's 16 inset.
    for (final f in figures) {
      expect(f.left, greaterThanOrEqualTo(16 - .5));
      expect(f.right, lessThanOrEqualTo(390 - 16 + .5));
    }
  });

  testWidgets("at 200% a pie's key wraps a long name under its ring", (
    t,
  ) async {
    await _pump(
      t,
      const Align(
        child: FrostedPieChart(
          label: 'Time spent',
          size: 140,
          slices: [
            FrostedPieSlice('Focus', 18),
            FrostedPieSlice('Meetings', 12),
            FrostedPieSlice('Email', 8),
          ],
        ),
      ),
      scale: 2,
    );
    final ring = t.getRect(find.byType(FrostedPieChart));
    expect(
      t.getRect(find.text('Meetings')).right,
      lessThanOrEqualTo(ring.right),
    );
  });

  testWidgets(
    "a swiped row is a target tall, its tiles' words in the page's direction",
    (t) async {
      Widget row() => FrostedSwipeActions(
        initiallyOpen: true,
        trailing: [
          FrostedSwipeAction(
            label: 'Delete',
            icon: FrostedGlyphs.delete,
            tone: FrostedSwipeTone.destructive,
            onPressed: () {},
          ),
        ],
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Harbor Transit'),
        ),
      );
      for (final direction in TextDirection.values) {
        await _pump(t, row(), direction: direction);
        expect(
          t.getSize(find.byType(FrostedSwipeActions)).height,
          greaterThanOrEqualTo(FrostedBreakpoints.touchHitTarget),
        );
        expect(Directionality.of(t.element(find.text('DELETE'))), direction);
      }
    },
  );

  testWidgets('at 200% filter chips and segments grow round their words', (
    t,
  ) async {
    Widget parts() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FrostedFilterChipGroup<String>(
          options: const [
            FrostedFilterOption('all', 'All'),
            FrostedFilterOption('in', 'Income'),
          ],
          value: 'all',
          onChanged: (_) {},
        ),
        FrostedSegmentedButton<String>(
          label: 'Theme',
          segments: const [
            FrostedButtonSegment('light', 'Light'),
            FrostedButtonSegment('dark', 'Dark'),
          ],
          value: 'light',
          onChanged: (_) {},
        ),
      ],
    );
    Rect face(String word) => t.getRect(
      find
          .ancestor(of: find.text(word), matching: find.byType(FrostedFace))
          .first,
    );
    await _pump(t, parts());
    final chip = face('Income').height;
    final segment = face('Dark').height;
    final word = t.getSize(find.text('Income')).height;
    await _pump(t, parts(), scale: 2);
    expect(t.getSize(find.text('Income')).height, greaterThan(word));
    for (final (w, rest) in [('Income', chip), ('Dark', segment)]) {
      final box = face(w);
      final words = t.getRect(find.text(w));
      expect(box.height, greaterThan(rest), reason: w);
      expect(words.top, greaterThanOrEqualTo(box.top), reason: w);
      expect(words.bottom, lessThanOrEqualTo(box.bottom), reason: w);
    }
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      "a form row's segments stand beside its words, under them at 200% "
      '($direction)',
      (t) async {
        Widget row() => FrostedFormRow(
          label: 'Backdrop',
          trailing: FrostedSegmentedButton<String>(
            label: 'Backdrop',
            // Short enough to stand beside 'Backdrop' at 1x in the test
            // font, whose every glyph is an em wide.
            segments: const [
              FrostedButtonSegment('dawn', 'Dawn'),
              FrostedButtonSegment('dusk', 'Dusk'),
              FrostedButtonSegment('sky', 'Sky'),
            ],
            value: 'dawn',
            onChanged: (_) {},
          ),
        );
        final rtl = direction == TextDirection.rtl;
        final strip = find.byType(FrostedSegmentedButton<String>);
        final label = find.text('Backdrop');
        await _pump(t, row(), direction: direction);
        var words = t.getRect(label);
        var control = t.getRect(strip);
        // The words stand cap-centred (ui_core's DesignCapCenter): the middle
        // of their capitals, their box's, meets the control's, not the middle
        // of their line.
        final caps = find.ancestor(
          of: label,
          matching: find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == 'DesignCapCenter',
          ),
        );
        expect(
          (control.center.dy - t.getRect(caps.first).center.dy).abs(),
          lessThan(1),
        );
        expect(rtl ? control.left : 390 - control.right, closeTo(16, .5));
        await _pump(t, row(), scale: 2, direction: direction);
        words = t.getRect(label);
        control = t.getRect(strip);
        expect(control.top, greaterThanOrEqualTo(words.bottom));
        // At the row's start, whole within it.
        expect(rtl ? 390 - control.right : control.left, closeTo(16, .5));
        expect(control.width, lessThanOrEqualTo(358));
      },
    );
  }
}
