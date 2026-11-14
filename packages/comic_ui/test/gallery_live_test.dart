// Exercise the actual specimen builders shipped in the example, not replicas.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/design_review.dart';
import '../example/lib/kit_gallery/demos/controls.dart';
import '../example/lib/kit_gallery/demos/inventory.dart';
import '../example/lib/kit_gallery/demos/complete.dart';
import '../example/lib/kit_gallery/demos/chrome.dart';
import '../example/lib/kit_gallery/demos/rows.dart';
import '../example/lib/kit_gallery/demos/raised.dart';
import '../example/lib/kit_gallery/demos/panels.dart';
import 'gallery_support.dart';
import 'support.dart';

Future<void> _mount(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 1000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    kitScreen(
      brightness: Brightness.light,
      title: 'Try a control',
      sections: [child],
    ),
  );
  await settle(tester);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target, warnIfMissed: true);
  await settle(tester);
  expect(tester.takeException(), isNull);
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });

  for (final (name, build, target, message)
      in <(String, Widget Function(), String, String)>[
        ('act', kitSpecimenActButton, 'DO THE THING', 'The task is done.'),
        ('line', kitSpecimenLineButton, 'LATER', 'Saved for later.'),
        ('quiet', kitSpecimenQuiet, 'LATER', 'Saved for later.'),
        ('danger', kitSpecimenDanger, 'REMOVE ISSUE', 'Issue removed.'),
        ('link', kitSpecimenLink, 'Read this issue', 'Issue opened.'),
        ('button', kitSpecimenButton, 'A PLAIN BUTTON', 'Button pressed.'),
      ]) {
    testWidgets('$name gives a visible result in the example', (tester) async {
      await _mount(tester, build());
      await _tap(tester, find.text(target));
      expect(find.text(message), findsOneWidget);
    });
  }

  testWidgets('icon toggles selection', (tester) async {
    await _mount(tester, kitSpecimenIconButton());
    await _tap(
      tester,
      find
          .descendant(
            of: find.byType(ComicIconButton).last,
            matching: find.byType(ComicPressable),
          )
          .first,
    );
    expect(
      tester
          .widget<ComicIconButton>(find.byType(ComicIconButton).last)
          .selected,
      isTrue,
    );
  });
  testWidgets('send gives a visible result', (tester) async {
    await _mount(tester, kitSpecimenSendButton());
    await _tap(
      tester,
      find
          .descendant(
            of: find.byType(ComicSendButton),
            matching: find.byType(ComicPressable),
          )
          .first,
    );
    expect(find.text('Message sent.'), findsOneWidget);
  });
  testWidgets('select field opens and chooses', (tester) async {
    await _mount(tester, kitSpecimenSelectField());
    await _tap(tester, find.text('Thursday'));
    await _tap(tester, find.text('Friday'));
    expect(
      tester.widget<ComicSelectField>(find.byType(ComicSelectField)).value,
      'Friday',
    );
  });
  testWidgets('choices change value', (tester) async {
    await _mount(tester, kitSpecimenChoices());
    await _tap(tester, find.text('New'));
    expect(tester.widget<ComicChoices>(find.byType(ComicChoices)).value, 'new');
  });
  testWidgets('choice box toggles', (tester) async {
    await _mount(tester, kitSpecimenChoiceBox());
    await _tap(tester, find.text('Your own content'));
    expect(
      tester.widget<ComicChoiceBox>(find.byType(ComicChoiceBox)).selected,
      isFalse,
    );
  });
  testWidgets('chips select', (tester) async {
    await _mount(tester, kitSpecimenChip());
    await _tap(tester, find.text('Hot'));
    expect(
      tester
          .widgetList<ComicChip>(find.byType(ComicChip))
          .map((w) => w.selected),
      [false, true],
    );
  });
  testWidgets('checkboxes toggle independently', (tester) async {
    await _mount(tester, kitSpecimenCheck());
    await _tap(tester, find.byType(ComicCheckbox).first);
    await _tap(tester, find.byType(ComicCheckbox).last);
    expect(
      tester
          .widgetList<ComicCheckbox>(find.byType(ComicCheckbox))
          .map((w) => w.value),
      [false, true],
    );
  });
  testWidgets('stepper increments and decrements', (tester) async {
    await _mount(tester, kitSpecimenStepper());
    final buttons = find.descendant(
      of: find.byType(ComicNumberField),
      matching: find.byType(ComicPressable),
    );
    await _tap(tester, buttons.last);
    expect(
      tester.widget<ComicNumberField>(find.byType(ComicNumberField)).value,
      3,
    );
    await _tap(tester, buttons.first);
    expect(
      tester.widget<ComicNumberField>(find.byType(ComicNumberField)).value,
      2,
    );
  });
  testWidgets('switches toggle independently', (tester) async {
    await _mount(tester, kitSpecimenSwitch());
    await _tap(tester, find.byType(ComicSwitch).first);
    await _tap(tester, find.byType(ComicSwitch).last);
    expect(
      tester
          .widgetList<ComicSwitch>(find.byType(ComicSwitch))
          .map((w) => w.value),
      [false, true],
    );
  });
  testWidgets('select opens and changes selection', (tester) async {
    await _mount(tester, kitSpecimenSelect());
    await _tap(tester, find.text('Print'));
    await _tap(tester, find.text('Digital'));
    expect(
      tester
          .widget<ComicSelect<String>>(find.byType(ComicSelect<String>))
          .value,
      'digital',
    );
  });
  testWidgets('radio chooses another option', (tester) async {
    await _mount(tester, kitSpecimenRadio());
    await _tap(tester, find.text('Collect'));
    expect(
      tester
          .widget<ComicRadioGroup<String>>(find.byType(ComicRadioGroup<String>))
          .value,
      'collect',
    );
  });
  testWidgets('segments change selection', (tester) async {
    await _mount(tester, kitSpecimenSegmented());
    await _tap(tester, find.text('Saved'));
    expect(
      tester
          .widget<ComicSegmentedButton<String>>(
            find.byType(ComicSegmentedButton<String>),
          )
          .value,
      'saved',
    );
  });
  testWidgets('check row toggles', (tester) async {
    await _mount(tester, kitSpecimenCheckRow());
    await _tap(tester, find.text('Keep a copy'));
    expect(
      tester.widget<ComicCheckRow>(find.byType(ComicCheckRow)).value,
      isFalse,
    );
  });
  for (final (name, build, text) in <(String, Widget Function(), String)>[
    ('field', kitSpecimenField, 'Alex'),
    ('search', kitSpecimenSearch, 'Issue 12'),
    ('code', kitSpecimenCode, '123456'),
    ('text area', kitSpecimenTextArea, 'A note'),
    ('input', kitSpecimenInput, 'Hello'),
  ]) {
    testWidgets('$name accepts editing', (tester) async {
      await _mount(tester, build());
      await tester.enterText(find.byType(EditableText).first, text);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .controller
            .text,
        text,
      );
    });
  }
  testWidgets('filter toggles', (tester) async {
    await _mount(tester, kitSpecimenFilter());
    final filter = find.byWidgetPredicate(
      (w) => w is ComicChip && w.onSelected != null,
    );
    await _tap(tester, filter);
    expect(tester.widget<ComicChip>(filter).selected, isFalse);
  });
  testWidgets('removable chip removes and restores', (tester) async {
    final removable = find.byWidgetPredicate(
      (w) => w is ComicChip && w.onDeleted != null,
    );
    await _mount(tester, kitSpecimenRemove());
    await _tap(
      tester,
      find.descendant(
        of: removable,
        matching: find.byWidgetPredicate(
          (w) => w is ComicPressable && w.label == 'Delete History',
        ),
      ),
    );
    expect(removable, findsNothing);
    await _tap(tester, find.text('RESTORE HISTORY'));
    expect(removable, findsOneWidget);
  });
  testWidgets('slider drags to a new value', (tester) async {
    await _mount(tester, kitSpecimenSlider());
    await tester.drag(find.byType(ComicSlider), const Offset(80, 0));
    await settle(tester);
    expect(
      tester.widget<ComicSlider>(find.byType(ComicSlider)).value,
      greaterThan(40),
    );
  });
  testWidgets('date chooses another day', (tester) async {
    await _mount(tester, kitSpecimenDate());
    await _tap(tester, find.text('7'));
    expect(
      tester.widget<ComicDatePicker>(find.byType(ComicDatePicker)).value,
      DateTime(2026, 11, 7),
    );
  });
  testWidgets('time opens and chooses', (tester) async {
    await _mount(tester, kitSpecimenTime());
    await _tap(tester, find.text('PM'));
    await _tap(tester, find.text('AM'));
    expect(
      tester.widget<ComicTimePicker>(find.byType(ComicTimePicker)).value,
      const ComicTime(7, 30),
    );
  });
  testWidgets('drawer selects a destination', (tester) async {
    await _mount(tester, kitSpecimenSideNav());
    await _tap(tester, find.text('Today'));
    expect(
      tester
          .widget<ComicNavigationDrawer>(find.byType(ComicNavigationDrawer))
          .selectedIndex,
      0,
    );
  });
  testWidgets('navigation bar selects a destination', (tester) async {
    await _mount(tester, kitSpecimenTabBar());
    await _tap(tester, find.text('PLACES'));
    expect(
      tester
          .widget<ComicNavigationBar>(find.byType(ComicNavigationBar))
          .selectedIndex,
      1,
    );
  });
  testWidgets('tabs change selection', (tester) async {
    await _mount(tester, kitSpecimenTabs());
    await _tap(tester, find.text('Read'));
    expect(
      tester.widget<ComicTabBar>(find.byType(ComicTabBar)).selectedIndex,
      2,
    );
  });
  testWidgets('page dots choose another page', (tester) async {
    await _mount(tester, kitSpecimenDots());
    final presses = find.descendant(
      of: find.byType(ComicPageDots),
      matching: find.byType(ComicPressable),
    );
    await _tap(tester, presses.last);
    expect(
      tester.widget<ComicPageDots>(find.byType(ComicPageDots)).selectedIndex,
      3,
    );
  });
  testWidgets('disclosure collapses and opens', (tester) async {
    await _mount(tester, kitSpecimenDisclosure());
    await _tap(tester, find.text('About this edition'));
    expect(find.text('An offset reprint of the original issue.'), findsNothing);
    await _tap(tester, find.text('About this edition'));
    expect(
      find.text('An offset reprint of the original issue.'),
      findsOneWidget,
    );
  });
  testWidgets('whole switch row toggles', (tester) async {
    await _mount(tester, kitSpecimenSwitchRow());
    await _tap(tester, find.text('A note each week'));
    expect(
      tester.widget<ComicSwitchRow>(find.byType(ComicSwitchRow)).value,
      isFalse,
    );
  });
  testWidgets('row actions update their own rows', (tester) async {
    await _mount(tester, kitSpecimenActionRow());
    await _tap(tester, find.text('CONFIRM'));
    expect(find.text('Confirmed'), findsOneWidget);
    await _tap(tester, find.text('SIGN'));
    expect(find.text('Signed'), findsOneWidget);
  });
  testWidgets('dialog specimen actions report the decision', (tester) async {
    await _mount(tester, kitSpecimenDialog());
    await _tap(tester, find.text('KEEP'));
    expect(find.text('Issue kept in your collection.'), findsOneWidget);
  });
  testWidgets('sheet closes and can reopen', (tester) async {
    await _mount(tester, kitSpecimenSheet());
    await _tap(
      tester,
      find.descendant(
        of: find.byType(ComicBottomSheet),
        matching: find.byType(ComicIconButton),
      ),
    );
    expect(find.byType(ComicBottomSheet), findsNothing);
    await _tap(tester, find.text('SHOW DETAILS'));
    expect(find.byType(ComicBottomSheet), findsOneWidget);
  });
  testWidgets('menu chooses and reports', (tester) async {
    await _mount(tester, kitSpecimenMenu());
    await _tap(tester, find.text('Save this issue'));
    expect(find.text('Issue saved.'), findsOneWidget);
  });
  testWidgets('snack action dismisses and can restore', (tester) async {
    await _mount(tester, kitSpecimenSnackBar());
    await _tap(tester, find.text('UNDO'));
    expect(find.byType(ComicSnackBar), findsNothing);
    await _tap(tester, find.text('SAVE AGAIN'));
    expect(find.byType(ComicSnackBar), findsOneWidget);
  });
  testWidgets('reply sends typed text and clears the composer', (tester) async {
    await _mount(tester, kitSpecimenReply());
    await tester.enterText(find.byType(EditableText), 'See you soon');
    await _tap(
      tester,
      find.byWidgetPredicate((w) => w is ComicPressable && w.label == 'Send'),
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
    expect(find.text('Reply sent.'), findsOneWidget);
  });
  testWidgets('ordinary tabs change the displayed content', (tester) async {
    await tester.pumpWidget(reviewTabs(Brightness.light));
    await _tap(tester, find.text('Finished'));
    expect(find.text('You have finished this issue.'), findsOneWidget);
    expect(find.text('A small adventure'), findsNothing);
  });
  testWidgets('ordinary dialog opens and returns a decision', (tester) async {
    await tester.pumpWidget(reviewDialog(Brightness.light));
    await _tap(tester, find.byKey(const ValueKey('review/dialog-open')));
    await _tap(tester, find.text('KEEP THEM'));
    expect(find.byType(ComicDialog), findsNothing);
    expect(find.text('Your items are kept.'), findsOneWidget);
  });
  testWidgets('raised example menu opens and chooses', (tester) async {
    await tester.pumpWidget(kitRaisedDemo(Brightness.light));
    await settle(tester);
    await _tap(tester, find.text('MENU'));
    await _tap(tester, find.text('Share').hitTestable());
    expect(find.text('Share link copied.'), findsOneWidget);
  });
  testWidgets('raised example tooltip opens on touch', (tester) async {
    await tester.pumpWidget(kitRaisedDemo(Brightness.light));
    await settle(tester);
    await _tap(tester, find.text('EXPLAIN'));
    expect(find.text('SAVE THIS ISSUE TO YOUR COLLECTION'), findsOneWidget);
  });
  testWidgets('raised example dialog opens and closes', (tester) async {
    await tester.pumpWidget(kitRaisedDemo(Brightness.light));
    await settle(tester);
    await _tap(tester, find.text('DIALOG'));
    expect(find.text('It will stay in your collection.'), findsOneWidget);
    await _tap(tester, find.text('KEEP').last);
    expect(find.text('It will stay in your collection.'), findsNothing);
  });
  testWidgets('raised example sheet opens and closes', (tester) async {
    await tester.pumpWidget(kitRaisedDemo(Brightness.light));
    await settle(tester);
    await _tap(tester, find.text('SHEET'));
    expect(
      find.text('A longer explanation belongs in this panel.'),
      findsOneWidget,
    );
    await _tap(
      tester,
      find
          .descendant(
            of: find.byType(ComicBottomSheet).last,
            matching: find.byType(ComicPressable),
          )
          .first,
    );
    expect(
      find.text('A longer explanation belongs in this panel.'),
      findsNothing,
    );
  });
  testWidgets('raised example announcement action reports undo', (
    tester,
  ) async {
    await tester.pumpWidget(kitRaisedDemo(Brightness.light));
    await settle(tester);
    await _tap(tester, find.text('ANNOUNCEMENT'));
    expect(find.text('Issue saved'), findsOneWidget);
    await _tap(tester, find.text('UNDO').last);
    expect(find.text('Save undone.'), findsOneWidget);
  });
}
