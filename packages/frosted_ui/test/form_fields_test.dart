// Forms: in one column every field takes the column's width (a text field, a select, a date field, a filled
// segmented control, a slider's track); a select alone in a row keeps to its content. A wrong field reads as wrong:
// its glass takes the danger's tint and its message leads with the danger mark. A date field holds a nullable day and
// shows it with its year; a text form field validates, saves and resets with its Form.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';
import 'package:frosted_ui/src/frosted/internal/well.dart';

Future<void> _pump(
  WidgetTester t,
  Widget body, {
  double width = 390,
  Brightness brightness = Brightness.light,
}) async {
  t.view.physicalSize = Size(width, 1400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) =>
          FrostedHost(brightness: brightness, child: page!),
      home: FrostedScaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: body,
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

/// The union of the faces [f] draws.
Rect _drawn(WidgetTester t, Finder f) => find
    .descendant(of: f, matching: find.byType(FrostedFace))
    .evaluate()
    .map((e) {
      final box = e.renderObject! as RenderBox;
      return box.localToGlobal(Offset.zero) & box.size;
    })
    .reduce((a, b) => a.expandToInclude(b));

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('at ${width.round()} every field takes the column', (t) async {
      await _pump(
        t,
        FrostedFormSection(
          bare: true,
          children: [
            FrostedTextField(labelText: 'Title', value: '', onChanged: (_) {}),
            FrostedSelect<String>(
              labelText: 'Shelf',
              value: 'read',
              options: const [FrostedSelectOption('read', 'Read')],
              onChanged: (_) {},
            ),
            FrostedDateField(
              labelText: 'Finished',
              value: null,
              onChanged: (_) {},
            ),
            FrostedFormField(
              labelText: 'Format',
              child: FrostedSegmentedButton<int>(
                label: 'Format',
                fill: true,
                value: 0,
                segments: const [
                  FrostedButtonSegment(0, 'Paper'),
                  FrostedButtonSegment(1, 'Ebook'),
                ],
                onChanged: (_) {},
              ),
            ),
            FrostedFormField(
              labelText: 'Rating',
              child: FrostedSlider(
                semanticLabel: 'Rating',
                value: 3,
                min: 1,
                max: 5,
                onChanged: (_) {},
              ),
            ),
          ],
        ),
        width: width,
      );
      final column = t.getRect(find.byType(FrostedFormSection));
      for (final (name, f) in [
        ('text field', find.byType(FrostedTextField)),
        ('select', find.byType(FrostedSelect<String>)),
        ('date field', find.byType(FrostedDateField)),
        ('segmented', find.byType(FrostedSegmentedButton<int>)),
      ]) {
        final r = _drawn(t, f);
        expect(
          r.left,
          moreOrLessEquals(column.left, epsilon: 0.5),
          reason: name,
        );
        expect(
          r.right,
          moreOrLessEquals(column.right, epsilon: 0.5),
          reason: name,
        );
      }
      // The slider's track (its first face) meets both edges.
      final track = find
          .descendant(
            of: find.byType(FrostedSlider),
            matching: find.byType(FrostedFace),
          )
          .first;
      final r = t.getRect(track);
      expect(r.left, moreOrLessEquals(column.left, epsilon: 0.5));
      expect(r.right, moreOrLessEquals(column.right, epsilon: 0.5));
    });
  }

  testWidgets(
    "in a column that doesn't stretch, a select takes its width as a text field does",
    (t) async {
      await _pump(
        t,
        Column(
          children: [
            FrostedTextField(labelText: 'Title', value: '', onChanged: (_) {}),
            FrostedSelect<String>(
              labelText: 'Shelf',
              value: 'read',
              options: const [FrostedSelectOption('read', 'Read')],
              onChanged: (_) {},
            ),
          ],
        ),
      );
      final field = _drawn(t, find.byType(FrostedTextField));
      final select = _drawn(t, find.byType(FrostedSelect<String>));
      expect(field.width, greaterThan(300));
      expect(select.width, moreOrLessEquals(field.width, epsilon: 1));
    },
  );

  testWidgets('a select alone in a row keeps to its content', (t) async {
    await _pump(
      t,
      Row(
        children: [
          FrostedSelect<String>(
            value: 'all',
            options: const [
              FrostedSelectOption('all', 'All'),
              FrostedSelectOption('read', 'Read'),
            ],
            onChanged: (_) {},
          ),
        ],
      ),
      width: 1440,
    );
    expect(t.takeException(), isNull);
    expect(t.getSize(find.byType(FrostedSelect<String>)).width, lessThan(240));
  });

  for (final brightness in Brightness.values) {
    testWidgets('${brightness.name}: a wrong field reads as wrong', (t) async {
      await _pump(
        t,
        Column(
          children: [
            FrostedTextField(
              key: const Key('right'),
              labelText: 'Title',
              value: '',
              onChanged: (_) {},
            ),
            FrostedTextField(
              key: const Key('wrong'),
              labelText: 'Title',
              value: '',
              onChanged: (_) {},
              errorText: 'Give the book a title',
            ),
          ],
        ),
        brightness: brightness,
      );
      FrostedFace well(String key) => t.widget<FrostedFace>(
        find
            .descendant(
              of: find.byKey(Key(key)),
              matching: find.byType(FrostedFace),
            )
            .first,
      );
      final scheme = t
          .element(find.byKey(const Key('wrong')))
          .frostedTheme
          .colorScheme;
      expect(well('right').wash, isNull);
      expect(well('wrong').wash, scheme.overTint);
      // The rim stays the glass's.
      expect(well('wrong').ring, well('right').ring);
      final words = find.byType(FrostedErrorWords);
      expect(words, findsOneWidget);
      final mark = t.widget<Icon>(
        find.descendant(of: words, matching: find.byType(Icon)),
      );
      expect(mark.icon, FrostedGlyphs.danger);
      expect(mark.color, scheme.over);
    });
  }

  testWidgets('a date field: no day, then the day picked with its year', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    DateTime? day;
    await _pump(
      t,
      StatefulBuilder(
        builder: (context, setState) => FrostedDateField(
          labelText: 'Finished',
          value: day,
          firstDate: DateTime(2026, 11),
          lastDate: DateTime(2026, 11, 30),
          onChanged: (d) => setState(() => day = d),
        ),
      ),
    );
    expect(find.text('Select a date'), findsOneWidget);
    await t.tap(find.byType(FrostedDateField));
    await t.pumpAndSettle();
    await t.tap(find.text('9').last);
    await t.pumpAndSettle();
    await t.tap(find.text('OK').last);
    await t.pumpAndSettle();
    expect(day, DateTime(2026, 11, 9));
    expect(find.text('Nov 9, 2026'), findsOneWidget);
    final node = t.getSemantics(find.bySemanticsLabel(RegExp('Finished')));
    final data = node.getSemanticsData();
    expect(data.label, contains('Finished'));
    expect(data.value, 'Nov 9, 2026');
    handle.dispose();
  });

  testWidgets('a text form field validates, saves and resets with its form', (
    t,
  ) async {
    final form = GlobalKey<FormState>();
    String? saved;
    await _pump(
      t,
      Form(
        key: form,
        child: FrostedTextFormField(
          labelText: 'Title',
          initialValue: 'Dune',
          validator: (v) =>
              (v ?? '').trim().isEmpty ? 'Give the book a title' : null,
          onSaved: (v) => saved = v,
        ),
      ),
    );
    expect(form.currentState!.validate(), isTrue);
    await t.enterText(find.byType(TextField), '  ');
    await t.pump();
    expect(form.currentState!.validate(), isFalse);
    await t.pump();
    expect(find.text('Give the book a title'), findsOneWidget);
    expect(find.byType(FrostedErrorWords), findsOneWidget);
    await t.enterText(find.byType(TextField), 'Piranesi');
    form.currentState!
      ..validate()
      ..save();
    await t.pump();
    expect(saved, 'Piranesi');
    expect(find.text('Give the book a title'), findsNothing);
    form.currentState!.reset();
    await t.pump();
    expect(find.text('Dune'), findsOneWidget);
  });

  testWidgets(
    "a wrong field's label takes the danger's ink, as its message does",
    (t) async {
      for (final brightness in Brightness.values) {
        await _pump(
          t,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FrostedTextField(
                labelText: 'Title',
                errorText: 'Enter the title',
                value: '',
                onChanged: (_) {},
              ),
              FrostedTextField(
                labelText: 'Author',
                value: '',
                onChanged: (_) {},
              ),
            ],
          ),
          brightness: brightness,
        );
        final scheme = FrostedTheme.of(t.element(find.text('Title')))
            .colorScheme;
        Color? ink(String words) => t
            .widget<RichText>(
              find.descendant(
                of: find.text(words),
                matching: find.byType(RichText),
              ),
            )
            .text
            .style
            ?.color;
        expect(ink('Title'), scheme.over, reason: brightness.name);
        expect(ink('Enter the title'), scheme.over, reason: brightness.name);
        expect(ink('Author'), isNot(scheme.over), reason: brightness.name);
      }
    },
  );

  for (final width in [390.0, 1440.0]) {
    testWidgets('at ${width.round()} a filled strip shares its width equally', (
      t,
    ) async {
      await _pump(
        t,
        FrostedSegmentedButton<String>(
          segments: const [
            FrostedButtonSegment('system', 'System'),
            FrostedButtonSegment('light', 'Light'),
            FrostedButtonSegment('dark', 'Dark'),
          ],
          value: 'system',
          onChanged: (_) {},
          label: 'Appearance',
          fill: true,
        ),
        width: width,
      );
      final [a, b, c] = [
        for (final w in ['System', 'Light', 'Dark'])
          t.getCenter(find.text(w)).dx,
      ];
      expect(b - a, moreOrLessEquals(c - b, epsilon: 1));
    });
  }
}
