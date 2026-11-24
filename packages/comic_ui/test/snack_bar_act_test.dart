// A snack bar's action is the act and its dismiss a plain key, as a Material SnackBarAction takes the accent and its
// close icon does not: Undo stands on the act's fill, the dismiss on a plain key's, by day and by night, either way
// round.
import 'package:comic_ui/comic_host.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

final _page = GlobalKey();
final _shot = GlobalKey();

Finder _in(Type type) => find.descendant(
  of: find.byType(ComicSnackBar),
  matching: find.byType(type),
);

void main() {
  for (final brightness in Brightness.values) {
    for (final direction in TextDirection.values) {
      testWidgets('${brightness.name}, ${direction.name}: Undo is the act, the '
          'dismiss a plain key', (tester) async {
        await tester.runAsync(comicLoadFonts);
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          RepaintBoundary(
            key: _shot,
            child: MaterialApp(
              builder: (context, child) => Directionality(
                textDirection: direction,
                child: ComicHost(
                  light: ComicThemeData.offset(),
                  dark: ComicThemeData.offset(Brightness.dark),
                  brightness: brightness,
                  child: child!,
                ),
              ),
              home: SizedBox.expand(key: _page),
            ),
          ),
        );
        await tester.pumpAndSettle();
        showComicSnackBar(
          _page.currentContext!,
          'Tasks deleted',
          actionLabel: 'Undo',
          onAction: () {},
        );
        await tester.pumpAndSettle();
        final c = ComicTheme.of(tester.element(find.byType(ComicSnackBar)))
            .colors;
        final boundary =
            _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final pixels = (await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = await image.toByteData();
          image.dispose();
          return data!.buffer.asUint8List();
        }))!;
        // A face's colour: a point inside its rim, beside its words or glyph.
        Color face(Finder part) {
          final r = tester.getRect(part);
          final x = (r.left + 6).round(), y = r.center.dy.round();
          final i = (y * 390 + x) * 4;
          return Color.fromARGB(255, pixels[i], pixels[i + 1], pixels[i + 2]);
        }

        void same(Color a, Color b, String what) {
          for (final (p, q) in [(a.r, b.r), (a.g, b.g), (a.b, b.b)]) {
            expect(
              (p - q).abs() * 255,
              lessThan(3),
              reason: '$what: $a, not $b',
            );
          }
        }

        same(face(_in(ComicButton)), c.primary, 'Undo');
        same(
          face(_in(ComicIconButton)),
          brightness == Brightness.dark ? c.card : c.control,
          'the dismiss',
        );
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
      });
    }
  }
}
