// By night a destructive fill is the danger tone at 60% over the ground
// (deeper where white words need it for 4.5:1): a red that reads as an act
// to take, never a pastel that looks switched off, and quieter than the main
// action beside it, so Discard is not as loud as Save. Danger words keep the
// lighter red ink.
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

Widget _host(Widget child, {MinimalThemeData? theme}) => MaterialApp(
  builder: (context, navigator) =>
      MinimalTheme(data: theme ?? _night, child: navigator!),
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

void _expectQuietDanger(
  WidgetTester tester,
  String label, {
  MinimalThemeData? theme,
}) {
  final t = theme ?? _night;
  final face = _face(tester, label)!;
  final words = _words(tester, label)!;
  expect(face.r, greaterThan(face.g), reason: '$label stands on a red');
  expect(face.r, greaterThan(face.b), reason: '$label stands on a red');
  expect(
    _contrast(face, t.background),
    lessThan(_contrast(t.colors.destructive, t.background)),
    reason: '$label stands quieter than the full danger tone',
  );
  expect(
    _contrast(face, t.background),
    lessThan(_contrast(t.primary, t.background)),
    reason: '$label stands off the ground less than the main action',
  );
  expect(
    words.computeLuminance(),
    closeTo(1, 0.001),
    reason: "$label's words are white",
  );
  expect(
    _contrast(words, face),
    greaterThanOrEqualTo(4.5),
    reason: "$label's words read on its face",
  );
}

Widget _opener(Widget Function(BuildContext context) dialog) => Builder(
  builder: (context) => MinimalButton(
    'Open',
    variant: MinimalButtonVariant.secondary,
    onPressed: () => showMinimalDialog<Object>(context, builder: dialog),
  ),
);

void main() {
  group('by night a destructive fill', () {
    testWidgets('a destructive button stands in a quieter red with white '
        'words', (tester) async {
      await tester.pumpWidget(
        _host(
          MinimalButton(
            'Delete habit',
            variant: MinimalButtonVariant.destructive,
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      _expectQuietDanger(tester, 'Delete habit');
    });

    testWidgets("a destructive dialog's confirm stands in a quieter red with "
        'white words', (tester) async {
      await tester.pumpWidget(
        _host(
          _opener(
            (context) => const MinimalDialog(
              title: 'Delete habit?',
              message: 'Its history goes too.',
              confirmLabel: 'Delete',
              cancelLabel: 'Keep',
              destructive: true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      _expectQuietDanger(tester, 'Delete');
    });
  });

  group('by night in every preset', () {
    for (final preset in MinimalThemeData.presets) {
      testWidgets('in $preset a destructive button stands quieter than the '
          'main one beside it, its words white', (tester) async {
        final t = MinimalThemeData.preset(preset, Brightness.dark);
        await tester.pumpWidget(
          _host(
            theme: t,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MinimalButton(
                  'Discard',
                  variant: MinimalButtonVariant.destructive,
                  onPressed: () {},
                ),
                MinimalButton('Save', onPressed: () {}),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        _expectQuietDanger(tester, 'Discard', theme: t);
      });
    }
  });

  group('by night among several actions', () {
    testWidgets("a dialog's destructive action stands in a quieter red with "
        'white words beside the main one', (tester) async {
      await tester.pumpWidget(
        _host(
          _opener(
            (context) => MinimalDialog(
              title: 'Unsaved changes',
              message: 'Save your changes before leaving this task?',
              actions: [
                RawDialogAction(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                RawDialogAction(
                  label: 'Discard',
                  isDestructiveAction: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                RawDialogAction(
                  label: 'Save changes',
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      _expectQuietDanger(tester, 'Discard');
      expect(_face(tester, 'Save changes'), _night.primary);
    });

    testWidgets("a menu bar's destructive command keeps the lighter red ink", (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MinimalMenuBar(
            menus: [
              MinimalMenuEntry(
                'Edit',
                children: [
                  MinimalMenuEntry('Rename', onPressed: () {}),
                  MinimalMenuEntry(
                    'Delete',
                    isDestructiveAction: true,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      final words = _words(tester, 'Delete');
      expect(words, _night.destructiveInk);
      expect(
        _contrast(words!, _night.background),
        greaterThanOrEqualTo(4.5),
        reason: 'the danger words read on the ground',
      );
    });
  });
}
