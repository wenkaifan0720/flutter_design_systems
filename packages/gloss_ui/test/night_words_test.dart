// Words in colour on a pearl part read at 4.5:1 by night as by day: a
// destructive key's danger words (about 2.6:1 on the night pearl) and a
// toast's jade action (about 3.1:1). Measured against the lightest of the
// face where the words stand, as painted.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

double _lum(Color c) => c.computeLuminance();
double _ratio(Color a, Color b) {
  final x = _lum(a), y = _lum(b);
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

final _shot = GlobalKey();

Widget _app({
  required Brightness brightness,
  required Widget home,
  TextDirection direction = TextDirection.ltr,
  double text = 1,
}) => RepaintBoundary(
  key: _shot,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, navigator) => Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(text)),
        child: GlossHost(
          theme: GlossThemeData.light(),
          darkTheme: GlossThemeData.dark(),
          brightness: brightness,
          child: GlossToaster(child: navigator!),
        ),
      ),
    ),
    home: home,
  ),
);

/// The screen as painted, read a logical pixel at a time.
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

/// The words' colour and the least contrast they make with the face round
/// them: sampled just past each end of the words, at their top and foot.
(Color, double) _reading(
  Color Function(Offset) at,
  WidgetTester tester,
  String words,
) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: find.text(words), matching: find.byType(RichText)),
  );
  final ink = paragraph.text.style!.color!;
  final box = tester.getRect(find.text(words));
  var least = double.infinity;
  for (final x in [box.left - 3, box.right + 3]) {
    for (final y in [box.top + 2, box.center.dy, box.bottom - 2]) {
      least = math.min(least, _ratio(ink, at(Offset(x, y))));
    }
  }
  return (ink, least);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      "a dialog's destructive key reads at 4.5:1 (${brightness.name})",
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final page = GlobalKey();
        await tester.pumpWidget(
          _app(
            brightness: brightness,
            home: GlossScaffold(body: SizedBox.expand(key: page)),
          ),
        );
        unawaited(
          showGlossDialog<void>(
            context: page.currentContext!,
            builder: (_) => GlossDialog(
              title: 'Remove this recipe?',
              content: const Text('It leaves Thursday and your shopping list.'),
              actions: [
                GlossDialogAction(label: 'Keep', onPressed: () {}),
                GlossDialogAction(
                  label: 'Remove recipe',
                  onPressed: () {},
                  isDestructiveAction: true,
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final (ink, least) = _reading(
          await _picture(tester),
          tester,
          'Remove recipe',
        );
        expect(least, greaterThanOrEqualTo(4.5), reason: '$ink');
      },
    );

    testWidgets("a toast's action reads at 4.5:1 (${brightness.name})", (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final page = GlobalKey();
      await tester.pumpWidget(
        _app(
          brightness: brightness,
          home: GlossScaffold(body: SizedBox.expand(key: page)),
        ),
      );
      showGlossToast(
        page.currentContext!,
        'Added to Thursday',
        actionLabel: 'Undo',
        onAction: () {},
      );
      await tester.pumpAndSettle();
      final (ink, least) = _reading(await _picture(tester), tester, 'Undo');
      expect(least, greaterThanOrEqualTo(4.5), reason: '$ink');
      // Let it go.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
    });
  }
}
