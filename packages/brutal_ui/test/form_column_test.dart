// Brutal's forms: in one column every field stands on the column's edges (a select too, a slider's and a range
// slider's track); a text field checks itself in a form, as TextFormField does; a hint reads lighter than typed words
// in every preset; a date with its year in Brutal's formats.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _column(
  List<Widget> children, {
  BrutalThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: BrutalTheme(
    data: theme ?? BrutalThemeData.light(),
    // Inside the app: MaterialApp sets its own direction from its locale.
    child: Directionality(
      textDirection: direction,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  ),
);

// The narrowest face a part draws: a slider's track.
Rect _track(WidgetTester tester, Finder slider) {
  final faces = find.descendant(
    of: slider,
    matching: find.byType(BrutalSurface),
  );
  final rects = [
    for (final e in faces.evaluate()) tester.getRect(find.byWidget(e.widget)),
  ]..sort((a, b) => a.height.compareTo(b.height));
  return rects.first;
}

// The widest face a field draws: its box.
Rect _box(WidgetTester tester, Finder field) {
  final faces = find.descendant(
    of: field,
    matching: find.byWidgetPredicate(
      (w) => w is BrutalSurface || w is AnimatedBrutalSurface,
    ),
  );
  final rects = [
    for (final e in faces.evaluate()) tester.getRect(find.byWidget(e.widget)),
  ]..sort((a, b) => b.width.compareTo(a.width));
  return rects.first;
}

void main() {
  setUpAll(brutalLoadFonts);

  testWidgets(
    'on a desk a select stands on its column\'s edges, as a text field does',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _column([
          const BrutalTextField(labelText: 'Name'),
          BrutalSelect<String>(
            labelText: 'City',
            value: 'north',
            items: const [
              BrutalSelectItem(value: 'north', label: 'North quarter'),
            ],
            onChanged: (_) {},
          ),
        ]),
      );
      final field = _box(tester, find.byType(BrutalTextField));
      final select = _box(tester, find.byType(BrutalSelect<String>));
      expect(select.left, field.left);
      expect(select.right, field.right);
    },
  );

  for (final direction in TextDirection.values) {
    testWidgets(
      'a slider\'s and a range slider\'s track meet the column\'s edges (${direction.name})',
      (tester) async {
        await tester.pumpWidget(
          _column([
            BrutalSlider(value: .5, onChanged: (_) {}, semanticLabel: 'Volume'),
            BrutalRangeSlider(
              values: const BrutalRangeValues(20, 60),
              min: 0,
              max: 100,
              onChanged: (_) {},
            ),
          ], direction: direction),
        );
        for (final slider in [
          find.byType(BrutalSlider),
          find.byType(BrutalRangeSlider),
        ]) {
          final whole = tester.getRect(slider);
          final track = _track(tester, slider);
          expect(
            track.left,
            moreOrLessEquals(whole.left, epsilon: .5),
            reason: '$slider',
          );
          expect(
            track.right,
            moreOrLessEquals(whole.right, epsilon: .5),
            reason: '$slider',
          );
        }
      },
    );
  }

  for (final direction in TextDirection.values) {
    testWidgets(
      "a slider's ink runs from its start to its thumb's centre (${direction.name})",
      (tester) async {
        await tester.pumpWidget(
          _column([
            BrutalSlider(
              value: .25,
              onChanged: (_) {},
              semanticLabel: 'Volume',
            ),
          ], direction: direction),
        );
        final slider = find.byType(BrutalSlider);
        final whole = tester.getRect(slider);
        Iterable<Rect> rects(Finder f) => [
          for (final e in find.descendant(of: slider, matching: f).evaluate())
            tester.getRect(find.byWidget(e.widget)),
        ];
        final thumb = rects(
          find.byWidgetPredicate(
            (w) => w is BrutalSurface || w is AnimatedBrutalSurface,
          ),
        ).firstWhere((r) => (r.width - r.height).abs() < 1 && r.width >= 20);
        final ink = rects(find.byType(ColoredBox)).firstWhere(
          (r) => r.height <= 8 && r.width > 0 && r.width < whole.width - 1,
        );
        if (direction == TextDirection.ltr) {
          expect(ink.right, moreOrLessEquals(thumb.center.dx, epsilon: 1));
        } else {
          expect(ink.left, moreOrLessEquals(thumb.center.dx, epsilon: 1));
        }
      },
    );
  }

  testWidgets(
    'a text field checks itself in a form: its error under it, the focus to it',
    (tester) async {
      final form = GlobalKey<RawFormState>();
      var sent = 0;
      String? saved;
      await tester.pumpWidget(
        _column([
          RawForm(
            key: form,
            onSubmit: () => sent++,
            child: BrutalTextField(
              labelText: 'Name',
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter a name' : null,
              onSaved: (v) => saved = v,
            ),
          ),
        ]),
      );
      expect(form.currentState!.submit(), isFalse);
      await tester.pump();
      expect(find.text('Enter a name'), findsOneWidget);
      expect(sent, 0);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<BrutalTextField>(),
        isNotNull,
      );
      await tester.enterText(find.byType(EditableText), 'Ada');
      await tester.pump();
      expect(form.currentState!.submit(), isTrue);
      await tester.pump();
      expect(find.text('Enter a name'), findsNothing);
      expect(sent, 1);
      expect(saved, 'Ada');
    },
  );

  testWidgets(
    'a hint reads lighter than typed words, and still at 4.5:1, in every preset',
    (tester) async {
      for (final id in BrutalThemeData.presets) {
        for (final b in Brightness.values) {
          final theme = BrutalThemeData.preset(id, b);
          await tester.pumpWidget(
            _column([
              const BrutalTextField(
                labelText: 'Email',
                hintText: 'you@example.com',
              ),
            ], theme: theme),
          );
          final hint = tester
              .widget<Text>(find.text('you@example.com'))
              .style!
              .color!;
          final c = theme.colors;
          expect(
            RawPalette.contrastRatio(hint, c.surface),
            greaterThanOrEqualTo(4.5),
            reason: '$id $b on the box',
          );
          // The help's grey stood 1.9 to 2.4:1 from typed words; a hint stands 2.5:1 off at least.
          expect(
            RawPalette.contrastRatio(hint, c.ink),
            greaterThanOrEqualTo(2.5),
            reason: '$id $b apart from typed words',
          );
        }
      }
    },
  );

  test('a date with its year', () {
    expect(BrutalFormat.date(DateTime(2026, 3, 14)), '14 Mar 2026');
    expect(BrutalFormat.date(DateTime(2027, 11, 2)), '2 Nov 2027');
  });

  testWidgets(
    "on a phone a date field's calendar keeps clear of its page's footer",
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) => BrutalHost(child: child!),
          home: BrutalScreen(
            topBar: const BrutalAppBar(title: 'Book'),
            footer: BrutalButton.filled('Save', onPressed: () {}),
            body: Column(
              children: [
                const SizedBox(height: 360),
                BrutalDatePicker(
                  labelText: 'Day',
                  value: null,
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2027),
                  currentDate: DateTime(2026, 11, 14),
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byType(BrutalDatePicker));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final calendar = tester.getRect(find.byType(BrutalCalendar));
      final footer = tester.getRect(find.widgetWithText(BrutalButton, 'Save'));
      expect(
        calendar.bottom <= footer.top || calendar.top >= footer.bottom,
        isTrue,
        reason: '$calendar over $footer',
      );
      expect(calendar.top, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
    },
  );
}
