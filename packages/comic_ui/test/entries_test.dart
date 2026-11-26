import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/src/comic/internal/reach.dart' show ComicOutward;

import 'support.dart';

void main() {
  setUpAll(loadComicFonts);
  testWidgets('field owns its labels and editing UI', (tester) async {
    final controller = TextEditingController(text: 'A line');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      comicApp(
        ComicTextField(
          controller: controller,
          labelText: 'Title',
          helperText: 'Choose a name',
          errorText: 'Already used',
        ),
      ),
    );
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Already used'), findsOneWidget);
    expect(find.text('Choose a name'), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration!.labelText, isNull);
    expect(field.decoration!.border, InputBorder.none);
    expect(field.selectionControls, isA<ComicTextSelectionControls>());
    expect(field.contextMenuBuilder, ComicTextContextMenu.editable);
    await tester.enterText(find.byType(EditableText), 'Changed');
    expect(controller.text, 'Changed');
  });

  testWidgets('a hint-only field keeps its spoken name when errors appear', (
    tester,
  ) async {
    for (final (label, error, expected) in [
      (null, null, 'Your handle'),
      (null, 'Already used', 'Your handle'),
      ('Username', 'Already used', 'Username'),
    ]) {
      await tester.pumpWidget(
        comicApp(
          ComicTextField(
            labelText: label,
            hintText: 'Your handle',
            errorText: error,
          ),
        ),
      );
      final data = tester
          .getSemantics(find.byType(EditableText))
          .getSemanticsData();
      expect(data.label, expected);
      expect(data.hint, error ?? '');
      expect(data.flagsCollection.isTextField, isTrue);
      if (error != null) {
        final announcement = tester
            .getSemantics(find.text(error))
            .getSemanticsData();
        expect(announcement.label, error);
        expect(announcement.flagsCollection.isLiveRegion, isTrue);
      }
    }
  });

  testWidgets('a form group associates its name and help with its editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      comicApp(
        const ComicFormField(
          'Your name',
          helperText: 'As it should be on the list',
          child: ComicTextField(),
        ),
      ),
    );
    final data = tester
        .getSemantics(find.byType(EditableText))
        .getSemanticsData();
    expect(data.label, 'Your name');
    expect(data.hint, 'As it should be on the list');
    expect(data.flagsCollection.isTextField, isTrue);
    // The form's label in the text field's own style, as written: one label style in a form.
    expect(find.text('Your name'), findsOneWidget);
  });

  for (final talk in [false, true]) {
    testWidgets('field talk=$talk exposes its full editing target', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        comicApp(
          Center(
            child: SizedBox(
              width: 300,
              child: ComicTextField(
                hintText: 'Reply',
                onPaper: talk,
                focusNode: focus,
              ),
            ),
          ),
        ),
      );
      final field = find.byType(TextField);
      final rect = tester.getRect(field);
      expect(rect.height, greaterThanOrEqualTo(48));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await tester.tapAt(Offset(rect.center.dx, rect.top + 2));
      await tester.pump();
      expect(focus.hasFocus, isTrue);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }

  testWidgets('search clear reports once and preserves edit focus', (
    tester,
  ) async {
    final changes = <String>[];
    final controller = TextEditingController(text: 'Issue');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      comicApp(
        ComicSearchField(
          hintText: 'Search',
          controller: controller,
          onChanged: changes.add,
        ),
      ),
    );
    final clear = find.byWidgetPredicate(
      (w) => w is ComicIconButton && w.label == 'Clear',
    );
    await tester.tap(clear);
    await tester.pump();
    expect(changes, ['']);
    expect(controller.text, isEmpty);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    expect(clear, findsNothing);
  });

  testWidgets(
    'search can replace an external controller without disposing it',
    (tester) async {
      final first = TextEditingController(text: 'First');
      final second = TextEditingController(text: 'Second');
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await tester.pumpWidget(
        comicApp(ComicSearchField(hintText: 'Search', controller: first)),
      );
      await tester.pumpWidget(
        comicApp(ComicSearchField(hintText: 'Search', controller: second)),
      );
      first.text = 'Still usable';
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller,
        same(second),
      );
      await tester.pumpWidget(const SizedBox());
      second.text = 'Also usable';
    },
  );

  testWidgets('code input filters a paste and caps the digit count', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      comicApp(
        ComicInputOtp(labelText: 'Code', length: 4, controller: controller),
      ),
    );
    await tester.enterText(find.byType(EditableText), 'a12 34b56');
    expect(controller.text, '1234');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).autofillHints,
      contains(AutofillHints.oneTimeCode),
    );
  });

  testWidgets('select opens Comic menu and reports the chosen value', (
    tester,
  ) async {
    final changes = <String>[];
    await tester.pumpWidget(
      comicApp(
        ComicSelect<String>(
          labelText: 'Format',
          value: 'print',
          options: const [
            ComicSelectOption('print', 'Print'),
            ComicSelectOption('digital', 'Digital'),
          ],
          onChanged: changes.add,
        ),
      ),
    );
    await tester.tap(find.byType(ComicSelectField));
    await tester.pumpAndSettle();
    expect(find.byType(ComicMenu<String>), findsOneWidget);
    await tester.tap(find.text('Digital'));
    await tester.pumpAndSettle();
    expect(changes, ['digital']);
  });

  testWidgets('disabled select cannot open a menu', (tester) async {
    await tester.pumpWidget(
      comicApp(
        const ComicSelect<String>(
          labelText: 'Format',
          options: [ComicSelectOption('print', 'Print')],
        ),
      ),
    );
    await tester.tap(find.byType(ComicSelectField));
    await tester.pumpAndSettle();
    expect(find.byType(ComicMenu<String>), findsNothing);
  });

  testWidgets('a select field shows its label and is named by it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      comicApp(
        ComicSelectField(
          labelText: 'Delivery day',
          value: 'Thursday',
          onPressed: () {},
        ),
      ),
    );
    // The label stands above the box, in a text field's label style.
    final label = tester.widget<Text>(find.text('Delivery day'));
    final theme = ComicTheme.of(tester.element(find.text('Delivery day')));
    expect(label.style, theme.type.title);
    expect(
      tester.getBottomLeft(find.text('Delivery day')).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.byType(ComicPressable)).dy),
    );
    // One node: the label is the select's name, its value read after it.
    expect(find.bySemanticsLabel('Delivery day'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Delivery day')),
      isSemantics(
        label: 'Delivery day',
        value: 'Thursday',
        isButton: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a select field with only a semantic label draws no label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      comicApp(
        ComicSelectField(
          semanticLabel: 'Delivery day',
          value: 'Thursday',
          onPressed: () {},
        ),
      ),
    );
    expect(find.text('Delivery day'), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Delivery day')),
      isSemantics(label: 'Delivery day', value: 'Thursday'),
    );
    // A semantic label speaks in place of a shown one.
    await tester.pumpWidget(
      comicApp(
        ComicSelectField(
          labelText: 'Day',
          semanticLabel: 'Delivery day',
          value: 'Thursday',
          onPressed: () {},
        ),
      ),
    );
    expect(find.text('Day'), findsOneWidget);
    expect(find.bySemanticsLabel('Day'), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Delivery day')),
      isSemantics(label: 'Delivery day', value: 'Thursday'),
    );
    // With neither, the value is its name, as before.
    await tester.pumpWidget(
      comicApp(ComicSelectField(value: 'Thursday', onPressed: () {})),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Thursday')),
      isSemantics(label: 'Thursday', isButton: true),
    );
    handle.dispose();
  });

  testWidgets(
    'a labelled select is named by its label and opens from its box',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        comicApp(
          ComicSelect<String>(
            labelText: 'Format',
            value: 'print',
            options: const [
              ComicSelectOption('print', 'Print'),
              ComicSelectOption('digital', 'Digital'),
            ],
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Format'), findsOneWidget);
      expect(find.bySemanticsLabel('Format'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Format')),
        isSemantics(label: 'Format', value: 'Print', isButton: true),
      );
      handle.dispose();
    },
  );

  for (final width in [390.0, 800.0]) {
    for (final bottom in [false, true]) {
      testWidgets(
        'a labelled select field opens its menu from its box, not its label '
        '(${width.round()} wide, ${bottom ? 'at the foot' : 'at the top'})',
        (tester) async {
          tester.view.physicalSize = Size(width, 700);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          Future<(Rect, Rect)> open({String? label}) async {
            await tester.pumpWidget(
              comicApp(
                Align(
                  alignment: bottom
                      ? Alignment.bottomCenter
                      : Alignment.topCenter,
                  child: ComicMenuAnchor<String>(
                    matchAnchorWidth: true,
                    items: const [
                      ComicMenuItem('thu', 'Thursday', selected: true),
                      ComicMenuItem('fri', 'Friday'),
                    ],
                    onSelected: (_) {},
                    builder: (context, open) => ComicSelectField(
                      labelText: label,
                      value: 'Thursday',
                      onPressed: open,
                    ),
                  ),
                ),
              ),
            );
            final box = tester.getRect(find.byType(ComicPressable));
            await tester.tap(find.byType(ComicPressable));
            await tester.pumpAndSettle();
            final menu = tester.getRect(find.byType(ComicMenu<String>));
            await tester.tapAt(Offset.zero);
            await tester.pumpAndSettle();
            return (box, menu);
          }

          final (plainBox, plainMenu) = await open();
          final (box, menu) = await open(label: 'Delivery day');
          // The menu stands against the box as it does with no label.
          expect(box.size, plainBox.size);
          expect(menu.width, plainMenu.width);
          expect(menu.left - box.left, plainMenu.left - plainBox.left);
          expect(menu.top - box.top, plainMenu.top - plainBox.top);
        },
      );
    }
  }

  testWidgets('radio arrows skip disabled options and mirror in RTL', (
    tester,
  ) async {
    final changes = <String>[];
    var chosen = 'a';
    await tester.pumpWidget(
      comicApp(
        StatefulBuilder(
          builder: (context, setState) => ComicRadioGroup<String>(
            labelText: 'Format',
            groupValue: chosen,
            options: const [
              ComicRadio('a', 'First'),
              ComicRadio('b', 'Closed', enabled: false),
              ComicRadio('c', 'Last'),
            ],
            onChanged: (next) => setState(() => changes.add(chosen = next)),
          ),
        ),
        direction: TextDirection.rtl,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(changes, ['c']);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(changes, ['c', 'a']);
  });

  // A, B, C and D with B turned off, chosen C, nothing, A or B, in each direction: one Tab stop at the choice (the
  // first that can be chosen when none can, or when the chosen one is turned off), the next Tab out, the arrows
  // choosing as they move and passing B.
  for (final direction in TextDirection.values) {
    for (final initial in <String?>['c', null, 'a', 'b']) {
      testWidgets('a radio group is one Tab stop whose arrows choose, '
          '${direction.name}, chosen ${initial ?? 'none'}', (tester) async {
        final semantics = tester.ensureSemantics();
        final before = FocusNode();
        addTearDown(before.dispose);
        var chosen = initial;
        await tester.pumpWidget(
          comicApp(
            StatefulBuilder(
              builder: (context, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Focus(focusNode: before, child: const Text('Before')),
                  ComicRadioGroup<String>(
                    key: const ValueKey('radios'),
                    labelText: 'Format',
                    groupValue: chosen,
                    options: const [
                      ComicRadio('a', 'A'),
                      ComicRadio('b', 'B', enabled: false),
                      ComicRadio('c', 'C'),
                      ComicRadio('d', 'D'),
                    ],
                    onChanged: (next) => setState(() => chosen = next),
                  ),
                  const Focus(child: Text('After')),
                ],
              ),
            ),
            direction: direction,
          ),
        );
        await tester.pumpAndSettle();
        (await const DesignRadioGroupCheck(look: 'Comic').check(
          tester.element(find.byKey(const ValueKey('radios'))),
          before: before,
          sendKeyEvent: tester.sendKeyEvent,
          pump: tester.pump,
        )).verify();
        // After a move, one radio is checked, and each is a radio, not a button.
        before.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(chosen, isNotNull);
        for (final name in const ['A', 'B', 'C', 'D']) {
          expect(
            tester.getSemantics(find.bySemanticsLabel(name)),
            isSemantics(
              label: name,
              hasCheckedState: true,
              isChecked: name.toLowerCase() == chosen,
              isInMutuallyExclusiveGroup: true,
              isButton: false,
            ),
            reason: name,
          );
        }
        semantics.dispose();
      });
    }
  }

  // A press anywhere in the box an option takes in its column chooses it: on its ring, on its words, in the gaps
  // between them. RawRadio's own detector takes a press only where the face paints, so the face lies on a box that is
  // hit all over. The room the row's wash and pop stand out into on each side (ComicOutward) is painted only, as in
  // the published group: a tap reaches the box a screen reader outlines.
  for (final direction in TextDirection.values) {
    testWidgets(
      "a press anywhere in a radio's box chooses it, ${direction.name}",
      (tester) async {
        final semantics = tester.ensureSemantics();
        var chosen = 'c';
        await tester.pumpWidget(
          comicApp(
            StatefulBuilder(
              builder: (context, setState) => Padding(
                padding: const EdgeInsets.all(24),
                child: ComicRadioGroup<String>(
                  labelText: 'Format',
                  groupValue: chosen,
                  options: const [
                    ComicRadio('a', 'A'),
                    ComicRadio('b', 'B', enabled: false),
                    ComicRadio('c', 'C', note: 'Kept for a week'),
                    ComicRadio('d', 'D'),
                  ],
                  onChanged: (next) => setState(() => chosen = next),
                ),
              ),
            ),
            direction: direction,
          ),
        );
        await tester.pumpAndSettle();
        Rect boxOf(String value) => tester.getRect(
          find
              .ancestor(
                of: find.byWidgetPredicate(
                  (w) => w is RawRadio<String> && w.value == value,
                ),
                matching: find.byType(ComicOutward),
              )
              .first,
        );
        const values = ['a', 'c', 'd'];
        for (final (i, value) in values.indexed) {
          final other = values[(i + 1) % values.length];
          final box = boxOf(value);
          // The box a tap reaches is the box a screen reader outlines.
          expect(
            tester
                .getSemantics(find.bySemanticsLabel(value.toUpperCase()))
                .rect
                .size,
            box.size,
          );
          for (final at in [
            box.centerLeft + const Offset(2, 0),
            box.center,
            box.centerRight - const Offset(2, 0),
            box.topCenter + const Offset(0, 2),
            box.bottomCenter - const Offset(0, 2),
          ]) {
            await tester.tapAt(boxOf(other).center);
            await tester.pumpAndSettle();
            expect(chosen, other);
            await tester.tapAt(at);
            await tester.pumpAndSettle();
            expect(chosen, value, reason: '$value pressed at $at in $box');
          }
        }
        semantics.dispose();
      },
    );
  }

  testWidgets('check row has one checkbox action', (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      comicApp(
        ComicCheckRow(
          label: 'Keep a copy',
          value: false,
          onChanged: changes.add,
        ),
      ),
    );
    expect(find.bySemanticsLabel('Keep a copy'), findsOneWidget);
    await tester.tap(find.text('Keep a copy'));
    await tester.pump();
    expect(changes, [true]);
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'calendar keyboard reveals its whole target in ${direction.name}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final theme = ComicThemeData.offset().copyWith(
          shapes: ComicShapes.rounded(8),
          strokes: ComicStrokes.bold,
          density: ComicDensity.compact,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: ComicTheme(
              data: theme,
              child: Directionality(
                textDirection: direction,
                child: Center(
                  child: SizedBox(
                    // Force overflow independently of the chosen border: seven
                    // 48px date targets cannot fit this narrow reading column.
                    width: 280,
                    child: ComicDatePicker(
                      value: DateTime(2026, 11, 2),
                      currentDate: DateTime(2026, 11, 2),
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Finder day(int number) => find.byWidgetPredicate(
          (widget) =>
              widget is ComicPressable &&
              widget.label == 'November $number, 2026',
        );
        tester.widget<ComicPressable>(day(2)).focusNode!.requestFocus();
        await tester.pump();
        for (var i = 0; i < 6; i++) {
          await tester.sendKeyEvent(
            direction == TextDirection.ltr
                ? LogicalKeyboardKey.arrowRight
                : LogicalKeyboardKey.arrowLeft,
          );
          await tester.pumpAndSettle();
        }
        final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
        expect(scroll.position.maxScrollExtent, greaterThan(0));
        final viewport = tester.getRect(find.byType(SingleChildScrollView));
        final target = tester.getRect(day(8));
        expect(target.left, greaterThanOrEqualTo(viewport.left - .001));
        expect(target.right, lessThanOrEqualTo(viewport.right + .001));
        expect(
          tester.getSemantics(day(8)).rect.width,
          greaterThanOrEqualTo(ComicTapTarget.targetOf(tester.element(day(8)))),
        );
        expect(
          tester.widget<ComicPressable>(day(8)).focusNode!.hasFocus,
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('inputs wrap at 390 and 2x ${direction.name}', (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        comicApp(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const ComicTextField(
                        labelText: 'A longer label',
                        hintText: 'Your issue',
                        helperText: 'An explanation',
                        enabled: false,
                      ),
                      const ComicTextArea(labelText: 'Notes'),
                      const ComicInputOtp(labelText: 'Verification code'),
                      ComicSegmentedButton<String>(
                        label: 'View',
                        value: 'all',
                        segments: const [
                          ComicButtonSegment('all', 'All issues'),
                          ComicButtonSegment('saved', 'Saved issues'),
                        ],
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          direction: direction,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
