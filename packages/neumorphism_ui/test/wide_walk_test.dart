// The faults a walk of the gallery in a browser at 1440 and 600 found (design6 P, 11-12) that no shared check caught,
// each held here at a desk's width in a page's column (720):
// - one row, one height: a removable chip's face is as tall as any chip's (it stood 60 px among 34 px chips);
// - stretch from 600 up: choice tiles keep to their words, from the column's edge (two 350 px tiles held "Basic" and
//   "Home"); a menu, a tooltip, a toast and an action sheet shown in place keep the width they have raised;
// - nothing cut: a month shows its seven days whole (a 320 px room cut its Saturday);
// - examples on the column's edge: the time picker's readout starts where its hour row does (it stood centred); an
//   example's drawn face, not its target, stands on the edge (11-12);
// - a tab bar and a month keep to their cells from 600 up; a sheet floating in a wide window drops its handle (11-12).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/internal/reach.dart'
    show NeumorphicFaceEdge, NeumorphicTallTarget;

import 'support.dart';

const _column = 720.0;

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1440, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    neumorphicApp(
      Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: SizedBox(
            width: _column,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [child],
            ),
          ),
        ),
      ),
      width: 1440,
    ),
  );
  await tester.pumpAndSettle();
}

Rect _rect(WidgetTester tester, Finder f) => tester.getRect(f);

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadNeumorphicGlyphs();
  });

  testWidgets('a removable chip stands as tall as the chips beside it', (
    tester,
  ) async {
    await _pump(
      tester,
      Wrap(
        spacing: 8,
        children: [
          NeumorphicChip('All', selected: true, onPressed: () {}),
          NeumorphicChip('Unread', onPressed: () {}),
          NeumorphicChip('Draft', onDeleted: () {}),
        ],
      ),
    );
    final plain = _rect(tester, find.byType(NeumorphicChip).at(1));
    final removable = _rect(tester, find.byType(NeumorphicChip).at(2));
    expect(removable.height, plain.height, reason: 'one row, one reach');
    final face = _rect(
      tester,
      find
          .descendant(
            of: find.byType(NeumorphicChip).at(2),
            matching: find.byType(NeumorphicSurface),
          )
          .first,
    );
    final t = NeumorphicTheme.of(tester.element(find.byType(Wrap)));
    expect(
      face.height,
      moreOrLessEquals(t.density.height(36), epsilon: 0.5),
      reason: "the removable chip's face is a chip's height, not its cross's target",
    );
    // The cross is the chip's own face; its spoken target is the platform's, reaching past the band.
    expect(
      tester.getSemantics(find.byType(NeumorphicTallTarget)).rect.height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('choice tiles keep to their words from 600 up', (tester) async {
    await _pump(
      tester,
      NeumorphicChoices(
        value: 'basic',
        options: const [
          NeumorphicChoice('Basic', note: 'One room', value: 'basic'),
          NeumorphicChoice('Home', note: 'Every room', value: 'home'),
        ],
        onChanged: (_) {},
      ),
    );
    final tiles = find.byType(NeumorphicChoiceBox);
    expect(tiles, findsNWidgets(2));
    for (var i = 0; i < 2; i++) {
      expect(_rect(tester, tiles.at(i)).width, lessThanOrEqualTo(240));
    }
    expect(_rect(tester, tiles.first).left, 48, reason: "on the column's edge");
  });

  testWidgets('raised faces in place keep their raised width', (tester) async {
    await _pump(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeumorphicMenu<String>(
            autofocus: false,
            items: const [
              NeumorphicMenuItem('copy', 'Copy'),
              NeumorphicMenuItem('share', 'Share'),
            ],
            onSelected: (_) {},
          ),
          const NeumorphicTooltipFace(message: 'A tooltip says one thing'),
          NeumorphicSnackBar(
            'The thermostat is back online',
            title: 'Connected',
          ),
          NeumorphicActionSheet<String>(
            title: 'Bedroom',
            actions: const [NeumorphicActionSheetAction('share', 'Share')],
            onSelected: (_) {},
            onCancel: () {},
          ),
        ],
      ),
    );
    for (final (type, most) in [
      (NeumorphicMenu<String>, 320.0),
      (NeumorphicTooltipFace, 280.0),
      (NeumorphicSnackBar, 560.0),
      (NeumorphicActionSheet<String>, 560.0),
    ]) {
      final face = find.descendant(
        of: find.byType(type),
        matching: find.byType(NeumorphicSurface),
      );
      final box = _rect(tester, face.first);
      expect(box.width, lessThanOrEqualTo(most + 0.5), reason: '$type');
      expect(box.left, 48, reason: "$type starts on the column's edge");
    }
  });

  testWidgets('a month shows its seven days whole', (tester) async {
    await _pump(
      tester,
      NeumorphicDatePicker(
        value: DateTime(2026, 11, 12),
        first: DateTime(2026),
        last: DateTime(2027),
        onChanged: (_) {},
      ),
    );
    for (final s in tester.stateList<ScrollableState>(
      find.descendant(
        of: find.byType(NeumorphicDatePicker),
        matching: find.byType(Scrollable),
      ),
    )) {
      expect(
        s.position.maxScrollExtent,
        0,
        reason: 'no day of the month is cut off to the side',
      );
    }
  });

  testWidgets("the time picker's readout starts on the column's edge", (
    tester,
  ) async {
    await _pump(
      tester,
      NeumorphicTimePicker(
        value: const NeumorphicTime(9, 0),
        minuteStep: 15,
        onChanged: (_) {},
      ),
    );
    final readout = tester.renderObject<RenderParagraph>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('9:00'),
      ),
    );
    final start = readout
        .localToGlobal(
          readout.getOffsetForCaret(const TextPosition(offset: 0), Rect.zero),
        )
        .dx;
    expect(start, moreOrLessEquals(48, epsilon: 1));
  });

  // design6 P, 11-12: an example starts on the column's edge with its drawn face, never its target; a minimum target
  // pads outward and is only hit-tested. (It overturns the bare checkbox's 10 px margin.)
  Rect faceOf(WidgetTester tester, Finder control) => tester.getRect(
    find
        .descendant(of: control, matching: find.byType(NeumorphicFaceEdge))
        .first,
  );

  testWidgets("a bare checkbox's mark starts on the column's edge", (
    tester,
  ) async {
    await _pump(
      tester,
      NeumorphicCheckbox(value: true, label: 'Receipt', onChanged: (_) {}),
    );
    final box = find.byType(NeumorphicCheckbox);
    final face = faceOf(tester, box);
    expect(face.left, 48);
    expect(face.width, 28, reason: "the box's edge is the mark's");
    final target = tester.getRect(
      find.descendant(of: box, matching: find.byType(NeumorphicTap)),
    );
    expect(target.size, const Size(48, 48), reason: 'the target is whole');
    expect(target.left, 38, reason: 'and reaches out past the column');
    // A press in the target's margin beside the mark still reaches it. (The margin past the column's own edge takes no
    // press: Flutter hands a press only to boxes holding it.)
    var pressed = false;
    await _pump(
      tester,
      NeumorphicCheckbox(
        value: false,
        label: 'Receipt',
        onChanged: (_) => pressed = true,
      ),
    );
    await tester.tapAt(Offset(48 + 28 + 6, target.center.dy));
    expect(pressed, isTrue);
  });

  testWidgets(
    "round keys, a stepper's keys, stars and a month's arrow start on the edge",
    (tester) async {
      await _pump(
        tester,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NeumorphicRoundButton(
              NeumorphicGlyphs.plus,
              label: 'Add',
              onPressed: () {},
            ),
            NeumorphicNumberField(
              value: '2',
              onDecrease: () {},
              onIncrease: () {},
            ),
            NeumorphicRating(label: 'Rating', value: 3, onChanged: (_) {}),
            NeumorphicDatePicker(
              value: DateTime(2026, 11, 12),
              first: DateTime(2026),
              last: DateTime(2027),
              onChanged: (_) {},
            ),
          ],
        ),
      );
      final key = find.byType(NeumorphicRoundButton).first;
      expect(faceOf(tester, key).left, 48);
      expect(
        tester
            .getSize(
              find.descendant(of: key, matching: find.byType(NeumorphicTap)),
            )
            .width,
        48,
        reason: "the key's target stays whole round its face",
      );
      final stepper = find.byType(NeumorphicNumberField);
      expect(faceOf(tester, stepper).left, 48, reason: "the minus key's face");
      // The number field keeps its keys within 200 of its start (the face the width check finds round them is the
      // card it stands in: shared_checks_test names that read).
      final keys = find.descendant(
        of: stepper,
        matching: find.byType(NeumorphicFaceEdge),
      );
      expect(tester.getRect(keys.last).right, lessThanOrEqualTo(48 + 200.5));
      expect(
        faceOf(tester, find.byType(NeumorphicRating)).left,
        48,
        reason: "the first star's face",
      );
      expect(
        faceOf(tester, find.byType(NeumorphicDatePicker)).left,
        48,
        reason: "the month's back arrow",
      );
    },
  );

  testWidgets("two fields side by side level their grooves and words", (
    tester,
  ) async {
    await _pump(
      tester,
      const NeumorphicRow(
        spans: [7, 5],
        children: [
          NeumorphicTextField(label: 'Town', initialValue: 'Bristol'),
          NeumorphicTextField(label: 'Postcode', initialValue: 'BS1 4DJ'),
        ],
      ),
    );
    final fields = find.byType(NeumorphicTextField);
    Rect groove(int i) => tester.getRect(
      find
          .descendant(
            of: fields.at(i),
            matching: find.byType(DesignKeylineFace),
          )
          .first,
    );
    Rect words(int i) => tester.getRect(
      find.descendant(of: fields.at(i), matching: find.byType(EditableText)),
    );
    expect(groove(0).top, groove(1).top);
    expect(groove(0).bottom, groove(1).bottom);
    for (var i = 0; i < 2; i++) {
      expect(
        words(i).center.dy,
        moreOrLessEquals(groove(i).center.dy, epsilon: .5),
        reason: 'the words on the middle of the groove',
      );
    }
  });

  testWidgets('a tab bar and a month keep to their cells from 600 up', (
    tester,
  ) async {
    await _pump(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeumorphicTabBar(
            tabs: const ['Overview', 'Activity', 'Files'],
            onChanged: (_) {},
          ),
          NeumorphicCalendar(
            controller: DesignCalendarController(
              firstDate: DateTime(2026),
              lastDate: DateTime(2027),
              initialMonth: DateTime(2026, 11),
            ),
          ),
        ],
      ),
    );
    final bar = tester.getRect(
      find
          .descendant(
            of: find.byType(NeumorphicTabBar),
            matching: find.byType(DesignKeylineFace),
          )
          .first,
    );
    expect(bar.left, 48, reason: "the bar starts on the column's edge");
    expect(bar.width, lessThanOrEqualTo(380), reason: 'three tabs, not a band');
    final month = tester.getRect(find.byType(DesignCalendar));
    expect(month.left, 48);
    expect(month.width, lessThanOrEqualTo(7 * 48 + .5));
  });

  testWidgets(
    'a sheet floating in a wide window has no handle, and keeps its close key',
    (tester) async {
      for (final (width, handle) in [(1440.0, false), (390.0, true)]) {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          neumorphicApp(
            Builder(
              builder: (context) => NeumorphicButton(
                'Help',
                onPressed: () => showNeumorphicBottomSheet<void>(
                  context,
                  builder: (_) => const NeumorphicBottomSheet(
                    title: 'How can we help?',
                    child: Text('Ask us anything'),
                  ),
                ),
              ),
            ),
            width: width,
          ),
        );
        await tester.tap(find.text('Help'));
        await tester.pumpAndSettle();
        final drags = find.descendant(
          of: find.byType(NeumorphicBottomSheet),
          matching: find.byWidgetPredicate(
            (w) => w is GestureDetector && w.onVerticalDragUpdate != null,
          ),
        );
        expect(drags, handle ? findsOneWidget : findsNothing, reason: '$width');
        expect(
          find.descendant(
            of: find.byType(NeumorphicBottomSheet),
            matching: find.byType(NeumorphicRoundButton),
          ),
          findsWidgets,
          reason: 'its close key at $width',
        );
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
}
