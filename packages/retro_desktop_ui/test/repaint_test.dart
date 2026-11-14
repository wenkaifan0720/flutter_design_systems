import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/src/retro_desktop/pixels.dart'
    show RenderRetroDesktopPixelPaint, RetroDesktopDeskPainter;

import 'support.dart';

class _RedPainter extends RetroDesktopPixelPainter {
  const _RedPainter();

  @override
  void paint(RetroDesktopPixelGrid px, Size size) =>
      px.fill(Offset.zero & size, const Color(0xffff0000));

  @override
  bool shouldRepaint(_RedPainter old) => false;
}

void main() {
  for (final ratio in [1.0, 2.0]) {
    testWidgets(
      'cached desktop keeps pixels through resize and theme changes at $ratio',
      (tester) async {
        tester.view.devicePixelRatio = ratio;
        tester.view.physicalSize = Size(600 * ratio, 400 * ratio);
        addTearDown(tester.view.reset);
        Future<List<int>> draw(RetroDesktopThemeData theme, Size size) async {
          await tester.pumpWidget(
            retroDesktopApp(
              Center(
                child: SizedBox.fromSize(
                  size: size,
                  child: RetroDesktopTheme(
                    data: theme,
                    child: const RetroDesktopScaffold(
                      fullBleed: true,
                      body: SizedBox(height: 400),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          return (await tester.runAsync(() async {
            final desk = find.byWidgetPredicate(
              (widget) =>
                  widget is CustomPaint &&
                  widget.painter is RetroDesktopDeskPainter,
            );
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find
                  .ancestor(of: desk, matching: find.byType(RepaintBoundary))
                  .first,
            );
            final image = await boundary.toImage(pixelRatio: ratio);
            final data = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            final bytes = data!.buffer.asUint8List().toList();
            image.dispose();
            return bytes;
          }))!;
        }

        for (final (size, mode) in [
          (const Size(320, 180), Brightness.light),
          (const Size(448, 240), Brightness.light),
          (const Size(448, 240), Brightness.dark),
        ]) {
          final theme = RetroDesktopThemeData.classic(mode);
          final colors = theme.colors;
          final cached = await draw(theme, size);
          final reference = (await tester.runAsync(() async {
            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder)..scale(ratio);
            RetroDesktopDeskPainter(colors).paint(canvas, size);
            final picture = recorder.endRecording();
            final image = await picture.toImage(
              (size.width * ratio).round(),
              (size.height * ratio).round(),
            );
            picture.dispose();
            final data = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            final bytes = data!.buffer.asUint8List().toList();
            image.dispose();
            return bytes;
          }))!;
          expect(cached.length, reference.length);
          var differences = 0;
          for (var i = 0; i < cached.length; i++) {
            if (cached[i] != reference[i]) differences++;
          }
          expect(
            differences,
            0,
            reason: '$size $mode preserves the original desktop pixels',
          );
        }
      },
      tags: const ['goldens'],
    );
  }

  for (final width in [390.0, 1440.0]) {
    testWidgets('scrolling retains the desktop picture at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        retroDesktopApp(
          RetroDesktopScaffold(
            scrollController: controller,
            body: const SizedBox(height: 3000, child: Text('Scrollable body')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final desk = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is RetroDesktopDeskPainter,
      );
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.ancestor(of: desk, matching: find.byType(RepaintBoundary)).first,
      );
      final picture = boundary.debugLayer!.firstChild;
      expect(picture, isNotNull);
      expect(controller.position.maxScrollExtent, greaterThan(120));
      controller.jumpTo(120);
      await tester.pump();
      expect(identical(boundary.debugLayer!.firstChild, picture), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('foreground changes repaint an otherwise unchanged layer', (
    tester,
  ) async {
    const key = ValueKey('paint-layer');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 20,
              height: 20,
              child: RetroDesktopPixelPaint(
                painter: _RedPainter(),
                child: ColoredBox(color: Color(0xff0000ff)),
              ),
            ),
          ),
        ),
      ),
    );
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    Future<List<int>> pixel() async => (await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final rgba = bytes!.buffer.asUint8List().sublist(
        (10 * 20 + 10) * 4,
        (10 * 20 + 10) * 4 + 4,
      );
      image.dispose();
      return rgba;
    }))!;
    final paint = tester.renderObject<RenderRetroDesktopPixelPaint>(
      find.byType(RetroDesktopPixelPaint),
    );
    expect(await pixel(), [0, 0, 255, 255]);
    paint.foreground = true;
    await tester.pump();
    expect(await pixel(), [255, 0, 0, 255]);
    paint.foreground = false;
    await tester.pump();
    expect(await pixel(), [0, 0, 255, 255]);
  }, tags: const ['goldens']);

  testWidgets('sky painters snapshot caller data before it changes', (
    tester,
  ) async {
    final kinds = [RetroDesktopSkyCondition.sun];
    final shares = [.1];
    Future<RetroDesktopPixelPainter> build() async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RetroDesktopTheme(
            data: RetroDesktopThemeData.classic(),
            child: RetroDesktopPixelSky(kinds: kinds, shares: shares),
          ),
        ),
      );
      return tester
          .widget<RetroDesktopPixelPaint>(find.byType(RetroDesktopPixelPaint))
          .painter;
    }

    final first = await build();
    expect((await build()).shouldRepaint(first), isFalse);
    kinds[0] = RetroDesktopSkyCondition.rain;
    final second = await build();
    expect(second.shouldRepaint(first), isTrue);
    shares[0] = .9;
    expect((await build()).shouldRepaint(second), isTrue);
  });
}
