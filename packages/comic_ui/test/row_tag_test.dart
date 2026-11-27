// A list row that shows a status in a widget of the app's own: the tag is read with the row's
// name, in its own case, and the row's hover and press wash reach it; an app's own control at the row's end still keeps
// its node and its press. A tag alone reads its word as written. The day's screen behind a dialog is a quiet tone, as
// the night's is: its dots stand at most 2:1 off the page's ground.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

// An app's own status tag, as an adopter writes one.
class _Status extends StatelessWidget {
  const _Status(this.word);
  final String word;
  @override
  Widget build(BuildContext context) =>
      ComicTag(word, tone: ComicSpeaker.narrator);
}

// An app's own control.
class _More extends StatelessWidget {
  const _More({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => ComicIconButton(
    ComicGlyphs.more,
    semanticLabel: 'Actions for Dune',
    onPressed: onPressed,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    comicApp(
      SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
      width: width,
    ),
  );
  await tester.pump();
  await tester.pump();
  expect(tester.takeException(), isNull);
}

double _contrast(Color a, Color b) {
  final (la, lb) = (a.computeLuminance(), b.computeLuminance());
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'an app\'s own status tag is read with the row, in its own case / $width',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _pump(
          tester,
          ComicListSection(
            children: [
              ComicListTile(
                isFirst: true,
                title: 'Dune',
                subtitle: 'Frank Herbert',
                trailing: const _Status('To read'),
                onPressed: () {},
              ),
            ],
          ),
          width: width,
        );
        expect(
          find.bySemanticsLabel(RegExp(r'^Dune, Frank Herbert\s+To read$')),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel(RegExp('TO READ')), findsNothing);
        // The row's press, and so its hover and press wash, covers the tag.
        final press = find.ancestor(
          of: find.byType(ComicTag),
          matching: find.byType(ComicPressable),
        );
        expect(press, findsOneWidget);
        final face = tester.getRect(press);
        final tag = tester.getRect(find.byType(ComicTag));
        expect(
          face.contains(tag.topLeft) &&
              face.contains(tag.bottomRight - const Offset(.1, .1)),
          isTrue,
        );
        semantics.dispose();
      },
    );

    testWidgets(
      'an app\'s own control at a row\'s end keeps its node and press / $width',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var opened = 0, menus = 0;
        await _pump(
          tester,
          ComicListTile(
            title: 'Dune',
            subtitle: 'Frank Herbert',
            trailing: _More(onPressed: () => menus++),
            onPressed: () => opened++,
          ),
          width: width,
        );
        expect(find.bySemanticsLabel('Dune, Frank Herbert'), findsOneWidget);
        tester.semantics.tap(find.semantics.byLabel('Actions for Dune'));
        await tester.pump();
        expect((menus, opened), (1, 0));
        // Its own press only: it stands beside the row's.
        expect(
          find.ancestor(
            of: find.byType(ComicIconButton),
            matching: find.byType(ComicPressable),
          ),
          findsNothing,
        );
        semantics.dispose();
      },
    );
  }

  testWidgets('a tag alone reads its word as written', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, const ComicTag('To read'));
    expect(find.bySemanticsLabel('To read'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('TO READ')), findsNothing);
    semantics.dispose();
  });

  for (final preset in ComicThemeData.presets) {
    testWidgets('the day\'s screen behind a dialog is a quiet tone / $preset', (
      tester,
    ) async {
      final colors = ComicTheme.preset(preset, Brightness.light).colors;
      const boundary = ValueKey('screen');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 60,
              height: 60,
              child: RepaintBoundary(
                key: boundary,
                child: ComicScreenScrim(
                  animation: kAlwaysCompleteAnimation,
                  ink: colors.scrim,
                ),
              ),
            ),
          ),
        ),
      );
      final render = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(boundary),
      );
      final bytes = await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 4);
        final data = await image.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        image.dispose();
        return data!;
      });
      // The darkest opaque pixel: the dots' ink.
      Color? ink;
      for (var i = 0; i < bytes!.lengthInBytes; i += 4) {
        if (bytes.getUint8(i + 3) < 250) continue;
        final c = Color.fromARGB(
          255,
          bytes.getUint8(i),
          bytes.getUint8(i + 1),
          bytes.getUint8(i + 2),
        );
        if (ink == null || c.computeLuminance() < ink.computeLuminance()) {
          ink = c;
        }
      }
      expect(ink, isNotNull);
      final ratio = _contrast(ink!, colors.background);
      expect(ratio, inInclusiveRange(1.2, 2.0));
    });
  }
}
