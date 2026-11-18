// The lists Fluent 2's fields open (a select, one whose options carry glyphs, a combobox, a tag picker), at 390 and
// 1440 wide, left to right and right to left (in Arabic, as the gallery's right-to-left mode reads): the field's
// width, wider only for its widest option, on the field's leading edge, its words on the field's past Fluent's check
// column (ui_core's DesignWidthCheck.checkList; a select with glyphs keeps the glyph column in its face, its prompt
// showing too), and already there on the first frame the list shows, rather than spreading or moving into place.
// Under a finger on a phone a select opens the bottom sheet of its options instead; in a narrow window under a
// pointer it opens its list, and a field narrower than Fluent's 160 at the window's end opens one its own width.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/src/fluent2_design/components/input/field_core.dart'
    show Fluent2FieldFrame, Fluent2PopoverSurface;

/// Fluent's listbox sets an option's words past its check column: the
/// list's 4, the option's 8, the check's 16 and its 4 gap (32), where the
/// field's words stand at its 12 and its stroke (13).
const _checkColumn = 19.0;

List<Fluent2Option<String>> _options(TextDirection direction) =>
    direction == TextDirection.ltr
    ? const [
        Fluent2Option('day', 'Day'),
        Fluent2Option('week', 'Week'),
        Fluent2Option('quarter', 'The quarter that ends in September'),
      ]
    : const [
        Fluent2Option('day', 'يوم'),
        Fluent2Option('week', 'أسبوع'),
        Fluent2Option('quarter', 'الربع الذي ينتهي في سبتمبر'),
      ];

List<Fluent2Option<String>> _glyphed(TextDirection direction) => [
  for (final o in _options(direction))
    Fluent2Option(o.value, o.label, icon: Fluent2Icons.channel),
];

final _fields = <String, Widget Function(TextDirection)>{
  'select': (d) => Fluent2Select<String>(
    label: 'Period',
    value: 'week',
    options: _options(d),
    onChanged: (_) {},
  ),
  'select with glyphs, its prompt showing': (d) => Fluent2Select<String>(
    label: 'Channel',
    prompt: 'Choose a channel',
    value: null,
    options: _glyphed(d),
    onChanged: (_) {},
  ),
  'select with glyphs': (d) => Fluent2Select<String>(
    label: 'Channel',
    value: 'week',
    options: _glyphed(d),
    onChanged: (_) {},
  ),
  'combobox': (d) => Fluent2Combobox<String>(
    label: 'Period',
    value: 'week',
    options: _options(d),
    onChanged: (_) {},
  ),
  'tag picker': (d) => Fluent2MultiSelect<String>(
    label: 'Periods',
    options: _options(d),
    selected: const ['day'],
    onChanged: (_) {},
  ),
};

Future<void> _stage(
  WidgetTester t,
  Widget field, {
  required double width,
  required TextDirection direction,
}) async {
  t.view.physicalSize = Size(width, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, route) => Directionality(
        textDirection: direction,
        child: Fluent2Theme(data: Fluent2ThemeData.lapis(), child: route!),
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [field],
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

/// Opens the list under [frame] and holds it to the field.
Future<void> _checkList(
  WidgetTester t,
  Finder frame,
  TextDirection direction,
) async {
  final field = t.getRect(frame);
  await t.tapAt(field.center);
  await t.pump();
  final surface = find.byType(Fluent2PopoverSurface);
  expect(surface, findsOneWidget, reason: 'the list shows at once');
  final first = t.getRect(surface);
  await t.pumpAndSettle();
  final settled = t.getRect(surface);
  expect(
    first.left,
    moreOrLessEquals(settled.left, epsilon: .5),
    reason: 'the list stands where it ends from its first frame',
  );
  expect(
    first.width,
    moreOrLessEquals(settled.width, epsilon: .5),
    reason: 'the list is its final width from its first frame',
  );
  final ltr = direction == TextDirection.ltr;
  expect(
    ltr ? settled.left : settled.right,
    moreOrLessEquals(ltr ? field.left : field.right, epsilon: 1),
    reason: "the list starts on the field's leading edge",
  );
  (await const DesignWidthCheck(
    look: 'Fluent 2',
    // A right-to-left entry's caret room (Flutter's editable keeps its 1 gap
    // and the caret at the line's end, its start) the check reads itself.
    listWordsIndent: _checkColumn,
  ).checkList(t.element(frame), runAsync: t.runAsync)).verify();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await fluent2LoadFonts();
  });

  for (final width in [390.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      for (final MapEntry(key: kind, value: build) in _fields.entries) {
        final sheet = kind.startsWith('select') && width < 600;
        testWidgets(
          sheet
              ? 'a select on a phone opens the sheet of its options, '
                    '${direction.name}'
              : 'a $kind\'s list at ${width.round()} wide, ${direction.name}',
          (t) async {
            await _stage(
              t,
              build(direction),
              width: width,
              direction: direction,
            );
            final frame = find.byType(Fluent2FieldFrame).first;
            if (!sheet) {
              return _checkList(t, frame, direction);
            }
            await t.tap(frame);
            await t.pumpAndSettle();
            expect(find.byType(Fluent2PopoverSurface), findsNothing);
            expect(find.text(_options(direction).last.label), findsOneWidget);
          },
          tags: const ['goldens'],
        );
      }
    }
  }

  for (final direction in TextDirection.values) {
    testWidgets('a select\'s list in a 390 window under a pointer, '
        '${direction.name}', (t) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await _stage(
          t,
          _fields['select']!(direction),
          width: 390,
          direction: direction,
        );
        await _checkList(t, find.byType(Fluent2FieldFrame).first, direction);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }, tags: const ['goldens']);

    testWidgets('a time picker 132 wide at a 390 window\'s end, under a '
        'pointer, ${direction.name}', (t) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await _stage(
          t,
          const Align(
            alignment: AlignmentDirectional.topEnd,
            child: SizedBox(
              width: 132,
              child: Fluent2TimePicker(
                label: 'Start',
                value: Fluent2Time(9, 30),
                onChanged: _ignore,
              ),
            ),
          ),
          width: 390,
          direction: direction,
        );
        final frame = find.byType(Fluent2FieldFrame).first;
        await _checkList(t, frame, direction);
        expect(
          t.getRect(find.byType(Fluent2PopoverSurface)).width,
          moreOrLessEquals(t.getRect(frame).width, epsilon: .5),
          reason: "its times fit the field's width, so the list takes it",
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }, tags: const ['goldens']);
  }
}

void _ignore(Fluent2Time _) {}
