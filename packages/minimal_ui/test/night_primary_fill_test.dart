// By night the standard preset's solid accent is a crisp fill under light
// words, as it is by day: the filled button and a dialog's main action read
// as the act to take, never as a pastel that looks switched off.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

final MinimalThemeData _night = MinimalThemeData.preset(
  'standard',
  Brightness.dark,
);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Widget _host(Widget child) => MaterialApp(
  builder: (context, navigator) =>
      MinimalTheme(data: _night, child: navigator!),
  home: Scaffold(body: Center(child: child)),
);

/// The fill of the nearest painted box behind [label]: the face it sits on.
Color? _face(WidgetTester tester, String label) {
  final boxes = tester.widgetList<DecoratedBox>(
    find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate(
        (w) => w is DecoratedBox && w.position == DecorationPosition.background,
      ),
    ),
  );
  for (final box in boxes) {
    final fill = switch (box.decoration) {
      BoxDecoration(:final color) => color,
      ShapeDecoration(:final color) => color,
      _ => null,
    };
    if (fill != null && fill.a > 0) return fill;
  }
  return null;
}

/// The colour [label]'s words print in.
Color? _words(WidgetTester tester, String label) =>
    tester.renderObject<RenderParagraph>(find.text(label)).text.style?.color;

void _expectSolidAccent(WidgetTester tester, String label) {
  final colors = _night.colors;
  final face = _face(tester, label);
  final words = _words(tester, label);
  expect(face, colors.primary, reason: '$label stands on the solid accent');
  expect(words, colors.primaryForeground, reason: "$label's words");
  expect(
    words!.computeLuminance(),
    closeTo(1, 0.001),
    reason: "$label's words are white",
  );
  expect(
    _contrast(words, face!),
    greaterThanOrEqualTo(4.5),
    reason: "$label's words read on its face",
  );
  expect(
    face.computeLuminance(),
    lessThan(0.3),
    reason: '$label stands in a crisp accent, not a pastel',
  );
}

void main() {
  testWidgets('by night a filled button stands in the accent with white '
      'words', (tester) async {
    await tester.pumpWidget(_host(MinimalButton('Stop', onPressed: () {})));
    await tester.pumpAndSettle();
    _expectSolidAccent(tester, 'Stop');
  });

  testWidgets("by night a dialog's main action stands in the accent with "
      'white words', (tester) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => MinimalButton(
            'Open',
            variant: MinimalButtonVariant.secondary,
            onPressed: () => showMinimalDialog<bool>(
              context,
              builder: (context) => const MinimalDialog(
                title: 'Unsaved changes',
                message: 'Save your changes before leaving this task?',
                confirmLabel: 'Save changes',
                cancelLabel: 'Cancel',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    _expectSolidAccent(tester, 'Save changes');
  });
}
