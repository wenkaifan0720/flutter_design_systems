// Page dots are found at a glance: a page not shown is an empty socket
// whose floor reads at 3:1 on the page, by day and by night, in every gel
// (they were about 1.1:1, nearly invisible by night).
// GlossScaffold is deprecated (GlossAppShell replaces it); tested until 0.7.0 removes it.
// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

final _shot = GlobalKey();

Future<void> _show(
  WidgetTester tester,
  Widget part, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  double width = 390,
  GlossThemeData? theme,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _shot,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, app) => GlossHost(
          theme: theme ?? GlossThemeData.light(),
          darkTheme: theme ?? GlossThemeData.dark(),
          brightness: brightness,
          child: Directionality(textDirection: direction, child: app!),
        ),
        home: GlossScaffold(
          body: Align(
            alignment: AlignmentDirectional.topStart,
            child: Padding(padding: const EdgeInsets.all(24), child: part),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<Color Function(Offset)> _picture(WidgetTester tester) async {
  final boundary =
      _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final (width, data) = (await tester.runAsync<(int, ByteData)>(() async {
    final image = await boundary.toImage();
    final bytes = (await image.toByteData())!;
    final width = image.width;
    image.dispose();
    return (width, bytes);
  }))!;
  return (Offset at) {
    final i = 4 * (at.dy.floor() * width + at.dx.floor());
    return Color.fromARGB(
      data.getUint8(i + 3),
      data.getUint8(i),
      data.getUint8(i + 1),
      data.getUint8(i + 2),
    );
  };
}

double _ratio(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

void main() {
  setUpAll(glossLoadFonts);

  for (final brightness in Brightness.values) {
    for (final gel in [for (final p in GlossThemeData.palettes) p.id]) {
      testWidgets('the dots read on the page, $gel, $brightness', (
        tester,
      ) async {
        final theme = GlossThemeData.preset(gel, brightness);
        await _show(
          tester,
          const GlossPageDots(pageCount: 4, page: 0),
          brightness: brightness,
          theme: theme,
        );
        final dots = find.descendant(
          of: find.byType(GlossPageDots),
          matching: find.byType(AnimatedContainer),
        );
        expect(dots, findsNWidgets(4));
        final at = await _picture(tester);
        final page = at(tester.getRect(find.byType(GlossPageDots)).topLeft);
        for (var i = 1; i < 4; i++) {
          final dot = at(tester.getRect(dots.at(i)).center);
          expect(
            _ratio(dot, page),
            greaterThanOrEqualTo(2.9),
            reason: 'dot $i $dot on the page $page',
          );
        }
      });
    }
  }
}
