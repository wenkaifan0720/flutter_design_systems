import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

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
          label: 'Title',
          helper: 'Choose a name',
          error: 'Already used',
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
          ComicTextField(label: label, hint: 'Your handle', error: error),
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
          help: 'As it should be on the list',
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
    // The form's label in the text field's own style, as written (design6 P: one label style in a form).
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
                hint: 'Reply',
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
          hint: 'Search',
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
        comicApp(ComicSearchField(hint: 'Search', controller: first)),
      );
      await tester.pumpWidget(
        comicApp(ComicSearchField(hint: 'Search', controller: second)),
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
      comicApp(ComicInputOtp(label: 'Code', length: 4, controller: controller)),
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
          label: 'Format',
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
          label: 'Format',
          options: [ComicSelectOption('print', 'Print')],
        ),
      ),
    );
    await tester.tap(find.byType(ComicSelectField));
    await tester.pumpAndSettle();
    expect(find.byType(ComicMenu<String>), findsNothing);
  });

  testWidgets('radio arrows skip disabled options and mirror in RTL', (
    tester,
  ) async {
    final changes = <String>[];
    await tester.pumpWidget(
      comicApp(
        ComicRadioGroup<String>(
          label: 'Format',
          value: 'a',
          options: const [
            ComicRadio('a', 'First'),
            ComicRadio('b', 'Closed', enabled: false),
            ComicRadio('c', 'Last'),
          ],
          onChanged: changes.add,
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
          typeface: const ComicTypeface(scale: 1.15),
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
                        label: 'A longer label',
                        hint: 'Your issue',
                        helper: 'An explanation',
                        enabled: false,
                      ),
                      const ComicTextArea(label: 'Notes'),
                      const ComicInputOtp(label: 'Verification code'),
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
