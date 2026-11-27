// By night a toast reads as its own surface over the page: the top bar's
// band it stands on by day is as dark as the night page (about 1.04:1), so
// by night it stands on the raised band inside a hairline that reads at 3:1
// against the page, its face and the card it may float over. By day it
// stays the ink band.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';

double _contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

Future<void> _show(WidgetTester tester, Brightness brightness) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final page = GlobalKey();
  await tester.pumpWidget(
    kitApp(
      brightness: brightness,
      home: CivicScaffold(body: SizedBox.expand(key: page)),
    ),
  );
  CivicToast.show(
    page.currentContext!,
    'Your settings have been saved',
    actionLabel: 'Undo',
    onActionPressed: () {},
  );
  await tester.pumpAndSettle();
}

/// The toast's own surface: the box its words stand in.
_Face _band(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.ancestor(
        of: find.text('Your settings have been saved'),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((b) => _face(b.decoration))
    .nonNulls
    .firstWhere((d) => d.color != null);

/// A box's face, from a box or a shape decoration: its fill, its edge, its
/// top-left corner and its shadows.
typedef _Face = ({
  Color? color,
  BorderSide? edge,
  double corner,
  List<BoxShadow> shadows,
});

_Face? _face(Decoration d) => switch (d) {
  BoxDecoration(
    :final color,
    :final border,
    :final borderRadius,
    :final boxShadow,
  ) =>
    (
      color: color,
      edge: border is Border ? border.top : null,
      corner: borderRadius?.resolve(TextDirection.ltr).topLeft.x ?? 0,
      shadows: boxShadow ?? const [],
    ),
  ShapeDecoration(:final color, :final shape, :final shadows) => (
    color: color,
    edge: shape is OutlinedBorder && shape.side != BorderSide.none
        ? shape.side
        : null,
    corner: shape is RawCornerBorder
        ? shape.borderRadius.resolve(TextDirection.ltr).topLeft.x
        : 0,
    shadows: shadows ?? const [],
  ),
  _ => null,
};

Future<void> _expire(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 7));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('by night a toast stands inside an edge that reads at 3:1', (
    tester,
  ) async {
    await _show(tester, Brightness.dark);
    final t = CivicTheme.of(tester.element(find.text('Undo')));
    final band = _band(tester);
    final edge = band.edge?.color;
    expect(edge, isNotNull, reason: 'the night toast has no edge');
    for (final (name, under) in [
      ('page', t.ground),
      ('card', t.background),
      ('band', band.color!),
    ]) {
      expect(
        _contrast(edge!, under),
        greaterThanOrEqualTo(3),
        reason: 'edge against the $name',
      );
    }
    // Its words keep 7:1 on the band.
    final words = tester.widget<Text>(
      find.text('Your settings have been saved'),
    );
    expect(
      _contrast(words.style!.color!, band.color!),
      greaterThanOrEqualTo(7),
    );
    await _expire(tester);
  });

  testWidgets('by day a toast stays the ink band, edgeless', (tester) async {
    await _show(tester, Brightness.light);
    final t = CivicTheme.of(tester.element(find.text('Undo')));
    final band = _band(tester);
    expect(band.color, CivicTopBar.bandOf(t));
    expect(band.edge, isNull);
    expect(_contrast(band.color!, t.ground), greaterThanOrEqualTo(7));
    await _expire(tester);
  });
}
