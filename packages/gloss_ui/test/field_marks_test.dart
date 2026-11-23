// A select and a combobox read as one kind of field: both end in the same
// pearl dial bead, seated alike. The field the keys are in lights its well
// jade from inside (its rim and a glow from its foot), so it is found at a
// glance, by day and by night: that one mark, no streak of reflected light
// along its floor as well.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

import '../example/lib/kit_gallery/kit.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    kitApp(
      brightness: brightness,
      home: Directionality(
        textDirection: direction,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(width: 360, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// The bead at a field's end: the square round its chevron.
Rect _bead(WidgetTester tester, Finder field) {
  final chevron = find.descendant(
    of: field,
    matching: find.byWidgetPredicate(
      (w) => w is CustomPaint && w.size == const Size(10, 6),
    ),
  );
  expect(chevron, findsOneWidget);
  final bead = find.ancestor(
    of: chevron,
    matching: find.byWidgetPredicate(
      (w) => w is SizedBox && w.width != null && w.width == w.height,
    ),
  );
  expect(bead, findsWidgets, reason: 'no bead round the chevron');
  return tester.getRect(bead.first);
}

// The faces a field's well is drawn with, settled.
Iterable<GlossFace> _faces(WidgetTester tester, Finder field) => tester
    .widgetList<AnimatedGlossSurface>(
      find.descendant(of: field, matching: find.byType(AnimatedGlossSurface)),
    )
    .map((s) => s.face);

void main() {
  setUpAll(glossLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets(
      "a combobox ends in the select's dial bead (${direction.name})",
      (tester) async {
        await _pump(
          tester,
          Column(
            children: [
              GlossSelect<String>(
                key: const Key('select'),
                items: const [
                  GlossSelectItem(value: 'a', label: 'Open studio'),
                  GlossSelectItem(value: 'b', label: 'Field guide'),
                ],
                value: 'a',
                onChanged: (_) {},
              ),
              const GlossCombobox<String>(
                key: Key('combobox'),
                options: ['Open studio', 'Field guide'],
              ),
            ],
          ),
          direction: direction,
        );
        final select = find.byKey(const Key('select'));
        final combobox = find.byKey(const Key('combobox'));
        final a = _bead(tester, select);
        final b = _bead(tester, combobox);
        expect(b.size, a.size);
        // From the end of the well the bead sits in.
        double inset(Finder field, Rect bead) {
          final beads = find.descendant(
            of: field,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is SizedBox &&
                  w.width == bead.width &&
                  w.height == bead.height,
            ),
          );
          final box = tester.getRect(
            find
                .ancestor(
                  of: beads.first,
                  matching: find.byType(AnimatedGlossSurface),
                )
                .first,
          );
          return direction == TextDirection.ltr
              ? box.right - bead.right
              : bead.left - box.left;
        }

        expect(inset(combobox, b), closeTo(inset(select, a), 0.5));
      },
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'a focused text field lights its well jade (${brightness.name})',
      (tester) async {
        final focus = FocusNode();
        addTearDown(focus.dispose);
        await _pump(
          tester,
          GlossTextField(labelText: 'Title', focusNode: focus),
          brightness: brightness,
        );
        final field = find.byType(GlossTextField);
        final colors = GlossTheme.of(tester.element(field)).colors;
        expect(_faces(tester, field).first.edge, isNot(colors.focus));
        focus.requestFocus();
        await tester.pumpAndSettle();
        final face = _faces(tester, field).first;
        expect(face.edge, colors.focus);
        expect(face.glow.a, greaterThan(0));
        expect(face.focus.a, 0, reason: 'a reflection under the jade rim');
      },
    );
  }

  testWidgets('a combobox the keys are in lights its well jade', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await _pump(
      tester,
      GlossCombobox<String>(
        options: const ['Open studio', 'Field guide'],
        focusNode: focus,
      ),
    );
    final field = find.byType(GlossCombobox<String>);
    final colors = GlossTheme.of(tester.element(field)).colors;
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(_faces(tester, field).first.edge, colors.focus);
    expect(_faces(tester, field).first.focus.a, 0);
  });

  testWidgets('a select the keys are in lights its well jade', (tester) async {
    await _pump(
      tester,
      GlossSelect<String>(
        items: const [
          GlossSelectItem(value: 'a', label: 'Open studio'),
          GlossSelectItem(value: 'b', label: 'Field guide'),
        ],
        value: 'a',
        onChanged: (_) {},
      ),
    );
    final field = find.byType(GlossSelect<String>);
    final colors = GlossTheme.of(tester.element(field)).colors;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_faces(tester, field).first.edge, colors.focus);
    expect(_faces(tester, field).first.focus.a, 0);
  });
}
