// The row the keys are on in an open list (a combobox's, a select's) stands
// out from the rows beside it, by day as by night: a pale glaze plate under
// it, as a lit row's plate is drawn. By day the row stood clear, its only
// mark the glaze's white reflection on white porcelain, about 3/255 from its
// neighbours.
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

const _venues = ['Hall 1', 'Hall 2', 'Kino Arsenal', 'Main stage'];

/// A row's plate colour, sampled clear of its words.
Color _plate(
  Color Function(Offset) at,
  WidgetTester tester,
  String words,
  TextDirection direction,
) {
  final plate = tester.getRect(
    find
        .ancestor(
          of: find.text(words),
          matching: find.byType(AnimatedGlossSurface),
        )
        .first,
  );
  final x = direction == TextDirection.ltr ? .72 : .28;
  return at(Offset(plate.left + plate.width * x, plate.center.dy));
}

Future<void> _page(
  WidgetTester tester,
  Widget child,
  Brightness brightness,
  TextDirection direction,
) async {
  tester.view.physicalSize = const Size(600, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(
      brightness: brightness,
      direction: direction,
      home: GlossScaffold(
        body: Align(
          alignment: AlignmentDirectional.topStart,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(width: 360, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    for (final direction in TextDirection.values) {
      final at = '${brightness.name}, ${direction.name}';
      testWidgets("a combobox's keyed row stands out from the next, $at", (
        tester,
      ) async {
        await _page(
          tester,
          GlossCombobox<String>(
            labelText: 'Venue',
            options: _venues,
            displayStringForOption: (s) => s,
            onSelected: (_) {},
          ),
          brightness,
          direction,
        );
        await tester.tap(find.byType(EditableText));
        await tester.enterText(find.byType(EditableText), 'a');
        await tester.pumpAndSettle();
        final picture = await _picture(tester);
        final lit = _plate(picture, tester, 'Hall 1', direction);
        final next = _plate(picture, tester, 'Hall 2', direction);
        expect(
          _ratio(lit, next),
          greaterThanOrEqualTo(1.2),
          reason: 'keyed $lit beside $next',
        );
      });

      testWidgets("a select's keyed row stands out from the next, $at", (
        tester,
      ) async {
        await _page(
          tester,
          GlossSelect<String>(
            labelText: 'Due',
            items: const [
              GlossSelectItem(value: 'today', label: 'Today'),
              GlossSelectItem(value: 'week', label: 'This week'),
              GlossSelectItem(value: 'later', label: 'Later'),
            ],
            value: 'today',
            onChanged: (_) {},
          ),
          brightness,
          direction,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        // The keys open it on its value and move on a row.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        final picture = await _picture(tester);
        final lit = _plate(picture, tester, 'This week', direction);
        final next = _plate(picture, tester, 'Later', direction);
        expect(
          _ratio(lit, next),
          greaterThanOrEqualTo(1.2),
          reason: 'keyed $lit beside $next',
        );
      });
    }
  }
}
