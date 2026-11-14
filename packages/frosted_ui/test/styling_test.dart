// How a part's look resolves: its own `style:`, then the theme's component
// style, then the theme's knobs (density, typeface), then
// the look. At the look's own settings nothing is cut to a shape of its own;
// a filled segmented strip keeps its height in a taller row.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';

/// Pumps [child] on a phone's page under [theme] (opal by default).
Future<void> _pump(
  WidgetTester t,
  Widget child, {
  FrostedThemeData? theme,
}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? page) =>
          FrostedHost(brightness: Brightness.light, light: theme, child: page!),
      home: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [child],
        ),
      ),
    ),
  );
  expect(t.takeException(), isNull);
}

/// The outermost face drawn under [of].
FrostedFace _face(WidgetTester t, Finder of) => t.widget<FrostedFace>(
  find.descendant(of: of, matching: find.byType(FrostedFace)).first,
);

const _square = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(4)),
);
const _blue = Color(0xFF1F6FEB);
const _red = Color(0xFFD1242F);

void main() {
  group('at the look', () {
    testWidgets('a button, a chip and a card are drawn at their own corners', (
      t,
    ) async {
      await _pump(
        t,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FrostedButton('Save', onPressed: () {}),
            FrostedChip('Vegetarian', onPressed: () {}),
            const SizedBox(width: 300, child: FrostedCard(child: Text('Card'))),
          ],
        ),
      );
      final button = _face(t, find.byType(FrostedButton));
      expect(button.shape, isNull);
      expect(button.radius, BorderRadius.circular(22));
      expect(button.gradients, isNotEmpty, reason: 'the ink act');
      expect(_face(t, find.byType(FrostedChip)).shape, isNull);
      final card = _face(t, find.byType(FrostedCard));
      expect(card.shape, isNull);
      expect(card.radius, BorderRadius.circular(18));
    });
  });

  group('a widget style', () {
    testWidgets('sets the fill, the shape and the words', (t) async {
      await _pump(
        t,
        FrostedButton(
          'Save',
          onPressed: () {},
          style: const FrostedStyle(
            fill: WidgetStatePropertyAll(_blue),
            shape: WidgetStatePropertyAll(_square),
            textStyle: WidgetStatePropertyAll(TextStyle(letterSpacing: 2)),
          ),
        ),
      );
      final face = _face(t, find.byType(FrostedButton));
      expect(face.color, _blue);
      expect(face.gradients, isEmpty);
      expect(face.shape, _square);
      expect(t.widget<Text>(find.text('Save')).style?.letterSpacing, 2);
    });

    testWidgets('resolves per state: a pressed fill while a finger is down', (
      t,
    ) async {
      await _pump(
        t,
        FrostedButton.glass(
          'Save',
          onPressed: () {},
          style: FrostedStyle(
            fill: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed) ? _red : null,
            ),
          ),
        ),
      );
      // At rest the glass button is pane glass: no flat fill of its own.
      expect(_face(t, find.byType(FrostedButton)).color, isNull);
      final gesture = await t.startGesture(t.getCenter(find.text('Save')));
      await t.pump();
      expect(_face(t, find.byType(FrostedButton)).color, _red);
      await gesture.up();
      await t.pump();
      expect(_face(t, find.byType(FrostedButton)).color, isNull);
    });

    testWidgets('wins over the theme\'s component style', (t) async {
      final theme = FrostedThemeData.opal().copyWith(
        components: const FrostedComponentThemes(
          chip: FrostedStyle(fill: WidgetStatePropertyAll(_red)),
        ),
      );
      await _pump(
        t,
        Row(
          children: [
            FrostedChip('Theme', onPressed: () {}),
            FrostedChip(
              'Own',
              onPressed: () {},
              style: const FrostedStyle(fill: WidgetStatePropertyAll(_blue)),
            ),
          ],
        ),
        theme: theme,
      );
      expect(_face(t, find.widgetWithText(FrostedChip, 'Theme')).color, _red);
      expect(_face(t, find.widgetWithText(FrostedChip, 'Own')).color, _blue);
    });

    testWidgets('a side draws an edge inside the face', (t) async {
      await _pump(
        t,
        const SizedBox(
          width: 300,
          child: FrostedCard(
            style: FrostedStyle(
              side: WidgetStatePropertyAll(BorderSide(color: _blue, width: 2)),
            ),
            child: Text('Card'),
          ),
        ),
      );
      final face = _face(t, find.byType(FrostedCard));
      expect(face.edge, _blue);
      expect(face.edges, const EdgeInsets.all(2));
    });

    testWidgets('a field\'s edge follows its focus', (t) async {
      await _pump(
        t,
        SizedBox(
          width: 300,
          child: FrostedTextField(
            label: 'Name',
            value: '',
            onChanged: (_) {},
            style: FrostedStyle(
              edge: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.focused) ? _blue : null,
              ),
            ),
          ),
        ),
      );
      // At rest by day the well wears the look's lit rim (never a dark line);
      // the style's edge waits for focus.
      expect(
        _face(t, find.byType(FrostedTextField)).ring,
        FrostedChromeMetrics.litEdge,
      );
      await t.tap(find.byType(EditableText));
      await t.pump();
      expect(_face(t, find.byType(FrostedTextField)).ring, _blue);
    });
  });

  group('the knobs', () {
    testWidgets('compact density stands a button 8 shorter, its target kept', (
      t,
    ) async {
      await _pump(
        t,
        FrostedButton('Save', onPressed: () {}),
        theme: FrostedThemeData.opal().copyWith(
          density: FrostedDensity.compact,
        ),
      );
      final face = find.descendant(
        of: find.byType(FrostedButton),
        matching: find.byType(FrostedFace),
      );
      expect(t.getSize(face.first).height, 36);
      var pressed = 0;
      await _pump(
        t,
        FrostedButton('Save', onPressed: () => pressed++),
        theme: FrostedThemeData.opal().copyWith(
          density: FrostedDensity.compact,
        ),
      );
      final rect = t.getRect(face.first);
      await t.tapAt(Offset(rect.center.dx, rect.top - 3));
      expect(pressed, 1, reason: 'the slop answers round the shorter face');
    });
  });

  group('a filled segmented strip in a taller row', () {
    testWidgets('keeps its height, the chosen plate filling it edge to edge', (
      t,
    ) async {
      await _pump(
        t,
        SizedBox(
          width: 340,
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: FrostedSegmentedButton<String>(
                  segments: const [
                    FrostedButtonSegment('day', 'Day'),
                    FrostedButtonSegment('night', 'Night'),
                  ],
                  value: 'day',
                  onChanged: (_) {},
                  label: 'Appearance',
                  fill: true,
                ),
              ),
            ],
          ),
        ),
      );
      final faces = find.descendant(
        of: find.byType(FrostedSegmentedButton<String>),
        matching: find.byType(FrostedFace),
      );
      final strip = t.getRect(faces.first);
      final plate = t.getRect(
        find
            .ancestor(of: find.text('Day'), matching: find.byType(FrostedFace))
            .first,
      );
      const inset = 3.0;
      expect(strip.height, 36 + inset * 2);
      expect(plate.top - strip.top, inset);
      expect(strip.bottom - plate.bottom, inset);
      final row = t.getRect(find.byType(Expanded));
      expect(row.height, 80);
      expect(strip.center.dy, row.center.dy, reason: 'centred in the row');
    });
  });
}
