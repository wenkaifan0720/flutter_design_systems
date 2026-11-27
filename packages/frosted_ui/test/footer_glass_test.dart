// A screen's footer and a docked action bar stand on the bar's glass, edged on
// top by the lit hairline: the page passes under them, blurred, with no opaque
// band and no fade over it, and rests where it did, a margin over the band.
// From 600 wide a footer's acts, each at most a button's measure, stand at the
// column's end, as the action bar's one act does; on a phone they span the
// line, and a row in the page's body keeps the line's start.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';
import 'package:frosted_ui/src/frosted/internal/footer_band.dart';
import 'package:frosted_ui/src/frosted/internal/measure.dart';

void _size(WidgetTester t, Size size) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> _pump(
  WidgetTester t,
  Widget home, {
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
}) async {
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => Directionality(
        textDirection: direction,
        child: FrostedHost(brightness: brightness, child: page!),
      ),
      home: home,
    ),
  );
  await t.pumpAndSettle();
  expect(t.takeException(), isNull);
}

/// The bar's glass round [of].
Finder _glass(Finder of) => find.ancestor(
  of: of,
  matching: find.byWidgetPredicate(
    (w) => w is FrostedFace && w.material == FrostedMaterial.bar,
  ),
);

Finder _save() => find.widgetWithText(FrostedButton, 'Save');

/// The canvas's paint round [of] that is not the whole window: an opaque
/// band, which hides the page passing under it.
List<Rect> _bands(WidgetTester t, Finder of, Size window) {
  final canvas = t.element(of).frostedTheme.colorScheme.background;
  return [
    for (final e
        in find
            .ancestor(
              of: of,
              matching: find.byWidgetPredicate(
                (w) => w is ColoredBox && w.color == canvas,
              ),
            )
            .evaluate())
      t.getRect(find.byElementPredicate((x) => x == e)),
  ].where((r) => r != Offset.zero & window).toList();
}

/// A fade into the canvas: a gradient ending in it.
Finder _fades(Color canvas) => find.byWidgetPredicate(
  (w) =>
      w is DecoratedBox &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).gradient is LinearGradient &&
      ((w.decoration as BoxDecoration).gradient! as LinearGradient)
              .colors
              .last ==
          canvas,
);

Widget _form({Widget? footer}) => FrostedScaffold(
  topBar: const FrostedAppBar(title: 'New book'),
  body: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const FrostedTextField(labelText: 'Title'),
      for (var i = 0; i < 24; i++)
        SizedBox(key: ValueKey('row $i'), height: 60),
    ],
  ),
  footer:
      footer ??
      FrostedButtonRow(children: [FrostedButton('Save', onPressed: () {})]),
);

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      "a screen's footer is the bar's glass over the page (${brightness.name})",
      (t) async {
        const window = Size(390, 844);
        _size(t, window);
        await _pump(t, _form(), brightness: brightness);
        expect(_glass(_save()), findsOneWidget);
        final face = t.widget<FrostedFace>(_glass(_save()));
        // Edged on top only, by the lit hairline, as the phone's bar is at
        // its foot.
        expect(face.edges, const EdgeInsets.only(top: FrostedStrokes.regular));
        expect(_bands(t, _save(), window), isEmpty);
        final canvas = t.element(_save()).frostedTheme.colorScheme.background;
        expect(_fades(canvas), findsNothing);
        // The page runs on under the band to the window's foot.
        final band = t.getRect(_glass(_save()));
        final view = t.getRect(find.byType(Scrollable).first);
        expect(view.bottom, moreOrLessEquals(window.height));
        expect(band.bottom, moreOrLessEquals(window.height));
      },
    );
  }

  testWidgets('the page rests a margin over the band, scrolled to its end', (
    t,
  ) async {
    const window = Size(390, 844);
    _size(t, window);
    await _pump(t, _form());
    await t.drag(find.byType(Scrollable).first, const Offset(0, -4000));
    await t.pumpAndSettle();
    final band = t.getRect(
      find.ancestor(of: _save(), matching: find.byType(FrostedBottomStand)),
    );
    final last = t.getRect(find.byKey(const ValueKey('row 23')));
    expect(
      last.bottom,
      moreOrLessEquals(band.top - FrostedInsets.screen.bottom, epsilon: .5),
    );
  });

  testWidgets('a docked action bar is the bar\'s glass', (t) async {
    const window = Size(390, 844);
    _size(t, window);
    await _pump(
      t,
      Column(
        children: [
          const Expanded(child: SizedBox.expand()),
          FrostedActionBar(label: 'Save', onPressed: () {}),
        ],
      ),
    );
    expect(_glass(_save()), findsOneWidget);
    expect(_bands(t, _save(), window), isEmpty);
  });

  for (final direction in TextDirection.values) {
    final ltr = direction == TextDirection.ltr;
    testWidgets(
      "from 600 wide a footer's acts stand at the column's end (${direction.name})",
      (t) async {
        _size(t, const Size(1440, 900));
        await _pump(t, _form(), direction: direction);
        final field = t.getRect(find.byType(FrostedTextField));
        final save = t.getRect(_save());
        expect(save.width, moreOrLessEquals(frostedControlMeasure));
        // At desktop width the footer floats on its slab, the column's
        // width: the acts stand its inset in from the column's end.
        const inset = FrostedChromeMetrics.footSlabInset;
        if (ltr) {
          expect(
            save.right,
            moreOrLessEquals(field.right - inset, epsilon: .5),
          );
        } else {
          expect(save.left, moreOrLessEquals(field.left + inset, epsilon: .5));
        }
        // A pair keeps its order, the gap between, the last at the end.
        await _pump(
          t,
          _form(
            footer: FrostedButtonRow(
              children: [
                FrostedButton.glass('Cancel', onPressed: () {}),
                FrostedButton('Save', onPressed: () {}),
              ],
            ),
          ),
          direction: direction,
        );
        final pair = t.getRect(_save());
        final cancel = t.getRect(find.widgetWithText(FrostedButton, 'Cancel'));
        if (ltr) {
          expect(
            pair.right,
            moreOrLessEquals(field.right - inset, epsilon: .5),
          );
          expect(cancel.right, lessThan(pair.left));
        } else {
          expect(pair.left, moreOrLessEquals(field.left + inset, epsilon: .5));
          expect(cancel.left, greaterThan(pair.right));
        }
      },
    );

    testWidgets(
      "a row in the page's body keeps the line's start (${direction.name})",
      (t) async {
        _size(t, const Size(1440, 900));
        await _pump(
          t,
          FrostedScaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FrostedTextField(labelText: 'Title'),
                FrostedButtonRow(
                  children: [FrostedButton('Save', onPressed: () {})],
                ),
              ],
            ),
          ),
          direction: direction,
        );
        final field = t.getRect(find.byType(FrostedTextField));
        final save = t.getRect(_save());
        if (ltr) {
          expect(save.left, moreOrLessEquals(field.left, epsilon: .5));
        } else {
          expect(save.right, moreOrLessEquals(field.right, epsilon: .5));
        }
      },
    );
  }

  testWidgets("on a phone a footer's act spans the line", (t) async {
    _size(t, const Size(390, 844));
    await _pump(t, _form());
    final field = t.getRect(find.byType(FrostedTextField));
    final save = t.getRect(_save());
    expect(save.left, moreOrLessEquals(field.left, epsilon: .5));
    expect(save.right, moreOrLessEquals(field.right, epsilon: .5));
  });
}
