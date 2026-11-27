// By day a dialog's rim is its glass's lit hairline (law 2: no edge is a dark line): round a dialog and a date
// picker's card no edge pixel is darker than the face just inside it, and along the top the sheen lies under the lit
// rim. Its Cancel, a glass act on the dialog's glass, catches the light from above: brighter along its top than at its
// foot, its glass reaching its foot as the ink act's does, and quieter than the ink act beside it. By night the rim
// stays light.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';

const _stage = ValueKey('stage');
const _ratio = 3.0;
const _size = Size(390, 844);

double _lum(Color c) => c.computeLuminance();

typedef _Read = Color Function(double x, double y);

Future<_Read> _shot(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_stage),
  );
  final width = (_size.width * _ratio).round();
  final px = (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _ratio);
    try {
      return (await image.toByteData())!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
  return (double x, double y) {
    final i = ((y * _ratio).floor() * width + (x * _ratio).floor()) * 4;
    return Color.fromARGB(px[i + 3], px[i], px[i + 1], px[i + 2]);
  };
}

Future<void> _open(
  WidgetTester tester,
  bool dark,
  Future<void> Function(BuildContext context) open,
) async {
  tester.view.devicePixelRatio = _ratio;
  tester.view.physicalSize = _size * _ratio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => FrostedHost(
        brightness: dark ? Brightness.dark : Brightness.light,
        child: RepaintBoundary(key: _stage, child: page!),
      ),
      home: Center(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => open(context),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

final _cards = <(String, String, Future<void> Function(BuildContext))>[
  (
    'a dialog',
    'Freeze this card?',
    (context) => FrostedDialog.show(
      context,
      title: 'Freeze this card?',
      message: 'Payments stop until you unfreeze it.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Freeze',
    ),
  ),
  (
    "a date picker's card",
    'Select a date',
    (context) => showFrostedDatePicker(
      context,
      initialDate: DateTime(2026, 11, 20),
      first: DateTime(2026),
      last: DateTime(2027),
      currentDate: DateTime(2026, 11, 18),
    ),
  ),
];

Rect _face(WidgetTester tester, String title) => tester.getRect(
  find.ancestor(of: find.text(title), matching: find.byType(FrostedFace)).last,
);

void main() {
  for (final (name, title, open) in _cards) {
    testWidgets('by day $name has no dark edge, its top lit', (tester) async {
      await _open(tester, false, open);
      final r = _face(tester, title);
      final at = await _shot(tester);
      // The four sides, clear of the corners: the outermost two pixels of
      // each against the face 6 in.
      final sides = <String, List<(Offset, Offset)>>{
        'top': [
          for (final k in [.3, .5, .7])
            (
              Offset(r.left + r.width * k, r.top + .2),
              Offset(r.left + r.width * k, r.top + 6),
            ),
        ],
        'bottom': [
          for (final k in [.3, .5, .7])
            (
              Offset(r.left + r.width * k, r.bottom - .2),
              Offset(r.left + r.width * k, r.bottom - 6),
            ),
        ],
        'start': [
          for (final k in [.4, .6])
            (
              Offset(r.left + .2, r.top + r.height * k),
              Offset(r.left + 6, r.top + r.height * k),
            ),
        ],
        'end': [
          for (final k in [.4, .6])
            (
              Offset(r.right - .2, r.top + r.height * k),
              Offset(r.right - 6, r.top + r.height * k),
            ),
        ],
      };
      for (final MapEntry(key: side, value: points) in sides.entries) {
        for (final (edge, inside) in points) {
          for (final step in [0.0, 1 / _ratio, 2 / _ratio]) {
            final d = side == 'top'
                ? Offset(0, step)
                : side == 'bottom'
                ? Offset(0, -step)
                : side == 'start'
                ? Offset(step, 0)
                : Offset(-step, 0);
            final e = at(edge.dx + d.dx, edge.dy + d.dy);
            final f = at(inside.dx, inside.dy);
            expect(
              _lum(e),
              greaterThanOrEqualTo(_lum(f) - .004),
              reason: '$side edge $e at ${edge + d} is darker than the face $f',
            );
          }
        }
      }
      // Under the lit rim along the top, the sheen: brighter than the face.
      final x = r.center.dx;
      final sheen = at(x, r.top + 1.5);
      final face = at(x, r.top + 6);
      expect(_lum(sheen), greaterThan(_lum(face)));
    });

    testWidgets('by night $name keeps its light rim', (tester) async {
      await _open(tester, true, open);
      final r = _face(tester, title);
      final at = await _shot(tester);
      final x = r.center.dx;
      expect(_lum(at(x, r.top + .2)), greaterThan(_lum(at(x, r.top + 6))));
      expect(
        _lum(at(r.left + .2, r.center.dy)),
        greaterThan(_lum(at(r.left + 6, r.center.dy))),
      );
    });
  }

  testWidgets("by day a dialog's Cancel is glass catching the light, quieter "
      'than its ink act', (tester) async {
    await _open(tester, false, _cards.first.$3);
    final cancel = tester.getRect(
      find
          .ancestor(of: find.text('Cancel'), matching: find.byType(FrostedFace))
          .first,
    );
    final act = tester.getRect(
      find
          .ancestor(of: find.text('Freeze'), matching: find.byType(FrostedFace))
          .first,
    );
    final dialog = _face(tester, 'Freeze this card?');
    final at = await _shot(tester);
    // Along a column in its round end, clear of the word: brighter at its
    // top than its foot.
    final x = cancel.left + 14;
    final top = at(x, cancel.top + cancel.height * .2);
    final foot = at(x, cancel.bottom - cancel.height * .2);
    expect(
      _lum(top) - _lum(foot),
      greaterThanOrEqualTo(.02),
      reason: 'top $top, foot $foot',
    );
    // Quieter than the ink act: nearer the dialog's face.
    final ground = at(dialog.center.dx, dialog.top + 12);
    final glass = at(x, cancel.center.dy);
    final ink = at(act.left + 14, act.center.dy);
    double contrast(Color a, Color b) {
      final (hi, lo) = _lum(a) > _lum(b) ? (a, b) : (b, a);
      return (_lum(hi) + .05) / (_lum(lo) + .05);
    }

    expect(contrast(glass, ground), lessThan(contrast(ink, ground)));
  });

  testWidgets("by day a dialog's Cancel stands as tall as its ink act: its "
      'glass reaches its foot', (tester) async {
    await _open(tester, false, _cards.first.$3);
    final cancel = tester.getRect(
      find
          .ancestor(of: find.text('Cancel'), matching: find.byType(FrostedFace))
          .first,
    );
    final act = tester.getRect(
      find
          .ancestor(of: find.text('Freeze'), matching: find.byType(FrostedFace))
          .first,
    );
    expect(cancel.top, act.top);
    expect(cancel.bottom, act.bottom);
    final dialog = _face(tester, 'Freeze this card?');
    final at = await _shot(tester);
    final ground = at(dialog.center.dx, dialog.top + 12);
    // Its last row of pixels, and the row above it, along its middle and its
    // round ends: the glass, a step darker than the dialog's face. A light
    // ring there would melt into the white face and the pill would read a
    // size smaller than the act beside it.
    for (final x in [cancel.left + 20, cancel.center.dx, cancel.right - 20]) {
      for (final y in [cancel.bottom - .2, cancel.bottom - 1 / _ratio - .2]) {
        expect(
          _lum(ground) - _lum(at(x, y)),
          greaterThanOrEqualTo(.04),
          reason: 'foot ${at(x, y)} at ($x, $y) against the face $ground',
        );
      }
    }
  });
}
