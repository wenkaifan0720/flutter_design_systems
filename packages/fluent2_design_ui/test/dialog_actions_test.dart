// A dialog's buttons stand in one row at its end when they fit, else in one
// column of one width, the primary on top and the dismissive one at the
// foot: never two on a line and the third alone under them, never a stack
// of ragged widths. Phones from 320 to 390, at their text size and larger,
// and a desk; ui_core_test's DesignDialogActionsCheck reads each.
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'gallery_support.dart' show loadFluent2TestFonts;

Widget _app(
  Widget page, {
  double scale = 1,
  Brightness brightness = Brightness.light,
}) => WidgetsApp(
  color: const Color(0xFF000000),
  debugShowCheckedModeBanner: false,
  localizationsDelegates: const [
    RawWidgetsLocalizations.delegate,
    Fluent2Localizations.delegate,
  ],
  builder: (context, child) => MediaQuery.withClampedTextScaling(
    minScaleFactor: scale,
    maxScaleFactor: scale,
    child: Fluent2Host(brightness: brightness, child: child!),
  ),
  onGenerateRoute: (settings) => PageRouteBuilder<void>(
    settings: settings,
    pageBuilder: (context, _, _) => page,
  ),
);

const _keys = ['Cancel', "Don't save", 'Save changes'];

void main() {
  setUpAll(loadFluent2TestFonts);

  for (final (width, scale) in const [
    (320.0, 1.0),
    (320.0, 2.0),
    (360.0, 1.0),
    (390.0, 1.0),
    (390.0, 1.5),
    (390.0, 2.0),
    (520.0, 2.0),
    (1440.0, 1.0),
  ]) {
    testWidgets('at $width, text at ${scale}x: the buttons stand in one row '
        'or one column of one width, the primary on top', (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          Center(
            child: Fluent2Dialog(
              title: 'Save changes?',
              message: 'The form has edits that are not saved.',
              actions: [
                Fluent2Button(_keys[0], onPressed: () {}),
                Fluent2Button(_keys[1], onPressed: () {}),
                Fluent2Button(
                  _keys[2],
                  appearance: Fluent2ButtonAppearance.primary,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();

      final keys = [
        for (final words in _keys)
          tester.getRect(
            find.ancestor(
              of: find.text(words),
              matching: find.byType(Fluent2Button),
            ),
          ),
      ];
      final tops = {for (final k in keys) k.top.round()};
      final where = keys.map((k) => '$k').join(', ');
      if (tops.length == 1) {
        expect(
          {for (final k in keys) k.left}.length,
          3,
          reason: 'one row: $where',
        );
      } else {
        // One column, the primary on top, each as wide as the others.
        expect(tops, hasLength(3), reason: 'two on a line: $where');
        expect(keys[2].bottom, lessThanOrEqualTo(keys[1].top), reason: where);
        expect(keys[1].bottom, lessThanOrEqualTo(keys[0].top), reason: where);
        expect(
          {for (final k in keys) k.width.round()},
          hasLength(1),
          reason: 'one width: $where',
        );
      }
      if (width > 600 && scale == 1) {
        expect(tops, hasLength(1), reason: 'a desk has room: $where');
      }
      final report = const DesignDialogActionsCheck(
        look: 'fluent2',
        actions: _keys,
      ).check(tester.element(find.byType(Fluent2Dialog)));
      expect(report.problems, isEmpty);
      semantics.dispose();
    });
  }

  for (final (width, scale) in const [
    (390.0, 1.0),
    (390.0, 2.0),
    (768.0, 2.0),
  ]) {
    testWidgets("at $width, text at ${scale}x: a bottom sheet's buttons share "
        'its foot or stand in one column of one width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          Align(
            alignment: Alignment.bottomCenter,
            child: Fluent2BottomSheet(
              title: 'Unsaved changes',
              actions: [
                Fluent2Button(_keys[1], onPressed: () {}),
                Fluent2Button(
                  _keys[2],
                  appearance: Fluent2ButtonAppearance.primary,
                  onPressed: () {},
                ),
              ],
              child: const Text('The form has edits that are not saved.'),
            ),
          ),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();
      final keys = [
        for (final words in _keys.skip(1))
          tester.getRect(
            find.ancestor(
              of: find.text(words),
              matching: find.byType(Fluent2Button),
            ),
          ),
      ];
      final where = keys.map((k) => '$k').join(', ');
      if (keys[0].top.round() != keys[1].top.round()) {
        expect(keys[1].bottom, lessThanOrEqualTo(keys[0].top), reason: where);
        expect(keys[0].width, closeTo(keys[1].width, 0.5), reason: where);
      }
      for (final words in _keys.skip(1)) {
        final text = tester.renderObject<RenderParagraph>(find.text(words));
        expect(text.didExceedMaxLines, isFalse, reason: '$words cut');
      }
    });
  }
}
