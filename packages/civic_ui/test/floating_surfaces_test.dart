// What floats in Civic floats one way (its rules: the strong 2 pt ink edge
// is a field's alone, and only what floats, an open list or a dialog, casts
// the soft shadow): an open list, the date picker's calendar, a popover, a
// menu and a dialog stand on the page's face, their corners rounded, a
// hairline round them and the soft shadow under them. A combobox's or a
// select's list stood square on the field's ink edge, without the shadow.
//
// By night the shadow is lost on the dark ground: each stands on the raised
// band, its edge reading at 3:1 against the page, a card and its own face.
// The calendar's popover was the page's face (1.1:1 on the ground) on a
// hairline of 2.1:1.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:async';

import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';

double _contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

const _people = ['Maya Reed', 'Sam Okafor', 'Noor Haddad'];

/// Opens one floating surface and returns a finder of words on it.
typedef _Opener = Future<Finder> Function(
  WidgetTester tester,
  BuildContext page,
);

final Map<String, _Opener> _surfaces = {
  'a combobox list': (tester, _) async {
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    return find.text('Sam Okafor');
  },
  'a select list': (tester, _) async {
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    return find.text('Later');
  },
  "a date picker's calendar": (tester, _) async {
    await tester.tap(find.text('Choose date'));
    await tester.pumpAndSettle();
    return find.byType(CivicCalendar);
  },
  'a popover': (tester, _) async {
    await tester.tap(find.text('Who counts as a visitor?'));
    await tester.pumpAndSettle();
    return find.text('Anyone staying less than 14 days.');
  },
  'a menu': (tester, _) async {
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    return find.text('Print this page');
  },
  'a dialog': (tester, page) async {
    unawaited(
      showCivicDialog<void>(
        context: page,
        builder: (context) => const CivicDialog(
          title: 'Cancel your application?',
          content: Text('You will lose the answers you have given.'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return find.text('Cancel your application?');
  },
};

Future<BuildContext> _pump(WidgetTester tester, Brightness brightness) async {
  tester.view.physicalSize = const Size(1440, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final page = GlobalKey();
  await tester.pumpWidget(
    kitApp(
      brightness: brightness,
      home: CivicScaffold(
        body: SingleChildScrollView(
          key: page,
          padding: const EdgeInsets.all(CivicSpacing.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CivicSpacing.s24,
            children: [
              SizedBox(
                width: 360,
                child: CivicSelect<String>(
                  labelText: 'Due',
                  items: const [
                    CivicSelectItem(value: 'today', label: 'Today'),
                    CivicSelectItem(value: 'later', label: 'Later'),
                  ],
                  value: 'today',
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(
                width: 360,
                child: CivicCombobox<String>(
                  labelText: 'Assignee',
                  options: _people,
                ),
              ),
              CivicDatePicker(
                labelText: 'Start',
                value: DateTime(2026, 11, 24),
                firstDate: DateTime(2026),
                lastDate: DateTime(2026, 12, 31),
                onChanged: (_) {},
              ),
              CivicPopover(
                title: 'Who counts as a visitor',
                content: const Text('Anyone staying less than 14 days.'),
                builder: (context, anchor) => CivicLink(
                  onPressed: anchor.toggle,
                  child: const Text('Who counts as a visitor?'),
                ),
              ),
              CivicMenu<String>(
                items: const [
                  CivicMenuItem(value: 'print', label: 'Print this page'),
                ],
                onSelected: (_) {},
                builder: (context, anchor) => CivicButton.secondary(
                  onPressed: anchor.toggle,
                  child: const Text('Actions'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return page.currentContext!;
}

/// The floating surface [words] stand on: the nearest box round them with
/// an edge.
BoxDecoration _surface(WidgetTester tester, Finder words) => tester
    .widgetList<DecoratedBox>(
      find.ancestor(of: words.first, matching: find.byType(DecoratedBox)),
    )
    .map((b) => b.decoration)
    .whereType<BoxDecoration>()
    .firstWhere((d) => d.border != null && d.color != null);

void main() {
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: open) in _surfaces.entries) {
      testWidgets('$name floats as everything that floats does '
          '(${brightness.name})', (tester) async {
        final page = await _pump(tester, brightness);
        final t = CivicTheme.of(page);
        final d = _surface(tester, await open(tester, page));
        final edge = (d.border! as Border).top;
        // Rounded, on a hairline, never the field's ink edge, under the
        // soft shadow.
        expect(d.borderRadius, isNotNull, reason: 'square');
        expect(
          (d.borderRadius! as BorderRadius).topLeft.x,
          greaterThan(0),
          reason: 'square',
        );
        expect(edge.width, 1, reason: "the field's edge width");
        expect(edge.color, isNot(t.border), reason: "the field's ink");
        expect(d.boxShadow, isNotEmpty, reason: 'no shadow');
        if (brightness == Brightness.dark) {
          expect(d.color, t.surface, reason: 'not on the raised band');
          for (final (under, color) in [
            ('the page', t.ground),
            ('a card', t.background),
            ('its face', d.color!),
          ]) {
            expect(
              _contrast(edge.color, color),
              greaterThanOrEqualTo(3),
              reason: 'its edge against $under',
            );
          }
        }
      });
    }
  }
}
