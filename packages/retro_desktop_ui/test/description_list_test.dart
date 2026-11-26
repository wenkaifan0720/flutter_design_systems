// A description list's label and its value share a baseline, though the label
// is set smaller: the words of a fact read as one line.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

import 'support.dart';

/// Where [words]' first line stands: its paragraph's top and the baseline of
/// the same text laid out at the paragraph's width.
double _baseline(WidgetTester tester, String words) {
  final p = tester.renderObject<RenderParagraph>(find.text(words));
  final painter = TextPainter(
    text: p.text,
    textDirection: p.textDirection,
    textScaler: p.textScaler,
    strutStyle: p.strutStyle,
    textHeightBehavior: p.textHeightBehavior,
    textWidthBasis: p.textWidthBasis,
  )..layout(maxWidth: p.size.width);
  final baseline = painter.computeDistanceToActualBaseline(
    TextBaseline.alphabetic,
  );
  painter.dispose();
  return p.localToGlobal(Offset.zero).dy + baseline;
}

void main() {
  setUpAll(loadRetroDesktopFonts);
  for (final figures in [false, true]) {
    testWidgets('a label and its value stand on one baseline '
        '(${figures ? 'figures' : 'words'})', (tester) async {
      tester.view.physicalSize = const Size(390, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, app) =>
              RetroDesktopHost(brightness: Brightness.light, child: app!),
          home: Padding(
            padding: const EdgeInsets.all(16),
            child: RetroDesktopDescriptionList([
              RetroDesktopFact('Holds', '1.4 GB', figures: figures),
              RetroDesktopFact('Free', '3.6 GB', figures: figures),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final (label, value) in const [
        ('Holds', '1.4 GB'),
        ('Free', '3.6 GB'),
      ]) {
        expect(
          _baseline(tester, value),
          moreOrLessEquals(_baseline(tester, label), epsilon: .5),
          reason: '"$label" and "$value"',
        );
      }
    });
  }
}
