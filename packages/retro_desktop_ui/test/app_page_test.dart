// An app's pages on a desk and a phone: a description list's glyphs in one column, a desk footer's buttons at the
// strip's end, a page's title said once on a desk, fields kept to a line that reads (a search to its list), a settings
// page's group headings in one face, and a form's reset taking its fields back for the next entry.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

Future<void> _at(
  WidgetTester tester,
  double width,
  Widget home, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(retroDesktopApp(home, direction: direction));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

const _facts = [
  RetroDesktopFact('Author', 'Susanna Clarke', icon: RetroDesktopGlyphs.person),
  RetroDesktopFact('Status', 'Reading', icon: RetroDesktopGlyphs.book),
  RetroDesktopFact('Favourite', 'Yes', icon: RetroDesktopGlyphs.check),
  RetroDesktopFact('Started', '2 Oct 2026', icon: RetroDesktopGlyphs.calendar),
];

const _places = [
  RetroDesktopNavItem(
    label: 'Books',
    short: 'Books',
    icon: RetroDesktopGlyphs.book,
  ),
  RetroDesktopNavItem(
    label: 'Settings',
    short: 'Settings',
    icon: RetroDesktopGlyphs.settings,
  ),
];

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final direction in TextDirection.values) {
    final rtl = direction == TextDirection.rtl;
    testWidgets(
      "a description list's glyphs stand in one column (${direction.name})",
      (tester) async {
        await _at(
          tester,
          1440,
          const RetroDesktopScaffold(body: RetroDesktopDescriptionList(_facts)),
          direction: direction,
        );
        final glyphs = [
          for (final f in _facts) tester.getRect(find.byIcon(f.icon!)),
        ];
        final labels = [
          for (final f in _facts) tester.getRect(find.text(f.label)),
        ];
        for (final g in glyphs.skip(1)) {
          expect(
            rtl ? g.right : g.left,
            rtl ? glyphs.first.right : glyphs.first.left,
          );
        }
        // The labels still stand against their values.
        for (final l in labels.skip(1)) {
          expect(
            rtl ? l.left : l.right,
            moreOrLessEquals(
              rtl ? labels.first.left : labels.first.right,
              epsilon: .5,
            ),
          );
        }
      },
    );

    testWidgets(
      "on a desk a footer's buttons stand at the strip's end (${direction.name})",
      (tester) async {
        await _at(
          tester,
          1440,
          RetroDesktopScaffold(
            appBar: const RetroDesktopAppBar(title: 'Piranesi'),
            footer: RetroDesktopButton(
              'Save',
              key: const ValueKey('save'),
              isDefaultAction: true,
              onPressed: () {},
            ),
            body: const Text('Susanna Clarke'),
          ),
          direction: direction,
        );
        final save = tester.getRect(find.byKey(const ValueKey('save')));
        expect(
          rtl ? save.left : save.right,
          moreOrLessEquals(rtl ? 24 : 1440 - 24, epsilon: 4),
        );
      },
    );
  }

  testWidgets(
    "under the shell on a desk a page's title is said once, by its window",
    (tester) async {
      await _at(
        tester,
        1440,
        RetroDesktopAppShell.branches(
          brand: 'Shelf',
          destinations: _places,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          branches: [
            (context) => RetroDesktopScaffold(
              appBar: const RetroDesktopAppBar(title: 'Books'),
              body: Builder(
                builder: (context) => RetroDesktopButton(
                  'Open',
                  key: const ValueKey('open'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const RetroDesktopScaffold(
                        appBar: RetroDesktopAppBar(title: 'Piranesi'),
                        body: Text('Susanna Clarke'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            (context) =>
                const RetroDesktopScaffold(body: Text('Settings body')),
          ],
        ),
      );
      await tester.tap(
        find
            .descendant(
              of: find.byKey(const ValueKey('open')),
              matching: find.byType(Text),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Susanna Clarke'), findsOneWidget);
      expect(find.text('Piranesi'), findsOneWidget);
      // The way back stays in the page's bar.
      expect(find.bySemanticsLabel(RegExp('Back')), findsWidgets);
    },
  );

  testWidgets(
    'fields keep to a line that reads at the start of a wide window, and take a phone whole; a search its column',
    (tester) async {
      Widget form() => RetroDesktopScaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RetroDesktopTextField(
              key: ValueKey('title'),
              labelText: 'Title',
            ),
            RetroDesktopDateField(
              key: const ValueKey('date'),
              labelText: 'Started',
              value: null,
              onChanged: (_) {},
            ),
            const RetroDesktopSearchField(
              key: ValueKey('search'),
              hintText: 'Find a book',
            ),
            RetroDesktopNumberField(
              key: const ValueKey('number'),
              value: 2,
              unit: 'copies',
              helperText:
                  'How many copies to order for the shelf, counted from the copies it already holds, '
                  'and kept for the next order too',
              onChanged: (_) {},
            ),
            RetroDesktopCombobox<String>(
              key: const ValueKey('combo'),
              labelText: 'Country',
              options: const ['Austria', 'Chile'],
              onSelected: (_) {},
            ),
            const RetroDesktopInputGroup(
              key: ValueKey('group'),
              labelText: 'Site',
              prefix: 'https://',
              hintText: 'studio',
            ),
            RetroDesktopSelect<int>(
              key: const ValueKey('select'),
              labelText: 'Status',
              value: 0,
              options: const [
                RetroDesktopOption(0, 'To read'),
                RetroDesktopOption(1, 'Read'),
              ],
              onChanged: (_) {},
            ),
          ],
        ),
      );
      await _at(tester, 1440, form());
      final column = tester.getRect(
        find
            .ancestor(
              of: find.byKey(const ValueKey('title')),
              matching: find.byType(Column),
            )
            .first,
      );
      // The field as drawn, its label and note with it: what its measure holds, in a column that stretches it.
      Rect drawn(String key) => tester.getRect(
        find
            .descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      for (final key in const ['title', 'date', 'combo', 'group', 'select']) {
        final field = drawn(key);
        expect(field.width, RetroDesktopTextField.measure, reason: key);
        expect(field.left, column.left, reason: key);
      }
      // A number field keeps its own width, within the measure.
      final number = drawn('number');
      expect(number.width, lessThanOrEqualTo(RetroDesktopTextField.measure));
      expect(number.left, column.left);
      // A search keeps to the list it searches, not to a form's measure: its words run past the measure.
      final searchWords = tester.getRect(
        find.descendant(
          of: find.byKey(const ValueKey('search')),
          matching: find.byType(EditableText),
        ),
      );
      expect(
        searchWords.right,
        greaterThan(column.left + RetroDesktopTextField.measure),
      );
      await _at(tester, 390, form());
      final narrow = tester.getRect(
        find
            .ancestor(
              of: find.byKey(const ValueKey('title')),
              matching: find.byType(Column),
            )
            .first,
      );
      expect(drawn('title').width, narrow.width);
    },
  );

  testWidgets("a settings page's group headings are set in one face", (
    tester,
  ) async {
    await _at(
      tester,
      1440,
      RetroDesktopScaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 24,
          children: [
            RetroDesktopSegmentedButton<int>(
              label: 'Theme',
              value: 0,
              segments: const [
                RetroDesktopButtonSegment(0, 'Light'),
                RetroDesktopButtonSegment(1, 'Dark'),
              ],
              onChanged: (_) {},
            ),
            RetroDesktopRadioGroup<int>(
              labelText: 'Appearance',
              value: 0,
              options: const [
                RetroDesktopRadio(0, 'Platinum'),
                RetroDesktopRadio(1, 'Chisel'),
              ],
              onChanged: (_) {},
            ),
            RetroDesktopListSection(
              title: 'Palette',
              children: [
                RetroDesktopListTile(title: 'Classic', onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );
    TextStyle face(String words) =>
        tester.widget<Text>(find.text(words)).style!;
    final section = face('Palette');
    for (final words in const ['Theme', 'Appearance']) {
      final style = face(words);
      expect(style.fontFamily, section.fontFamily, reason: words);
      expect(style.fontSize, section.fontSize, reason: words);
      expect(style.fontWeight, section.fontWeight, reason: words);
    }
  });

  testWidgets("a form's reset takes its fields back and hides their errors", (
    tester,
  ) async {
    final form = GlobalKey<RawFormState>();
    await _at(
      tester,
      390,
      RawForm(
        key: form,
        child: RetroDesktopTextField(
          key: const ValueKey('title'),
          labelText: 'Title',
          validator: (value) =>
              (value ?? '').trim().isEmpty ? 'Enter the title' : null,
        ),
      ),
    );
    form.currentState!.submit();
    await tester.pumpAndSettle();
    expect(find.text('Enter the title'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Dune');
    await tester.pump();
    form.currentState!.reset();
    await tester.pumpAndSettle();
    expect(find.text('Enter the title'), findsNothing);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
  });
}
