// Profile the example on the web using engine FrameTiming data. watchPerformance
// works without a VM timeline connection and preserves the web-only build scope.
// Use engine-scheduled frames: web warm-up frames bypass the engine's build-start
// timestamp. Traverse every page in both modes before the measured pass. Keep
// warm-up timings as first-use evidence; measured build/raster work must fit16ms.
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui_example/gallery_pages.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  // Match the example's startup: load its fonts once before visiting pages.
  setUpAll(retroDesktopLoadFonts);

  /// Waits for an engine frame, then gives the raster thread a frame's time.
  Future<void> frame() async {
    binding.scheduleFrame();
    await binding.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }

  testWidgets('foreground bevels leave their child pixels visible on the web', (
    tester,
  ) async {
    const markKey = ValueKey('web-visible-mark');
    const boundaryKey = ValueKey('web-face-boundary');
    const marker = Color(0xff00cc88);
    for (final brightness in Brightness.values) {
      for (final appearance in RetroDesktopAppearance.values) {
        binding.attachRootWidget(
          binding.wrapWithDefaultView(
            WidgetsApp(
              color: const Color(0xff000000),
              builder: (context, child) => RetroDesktopTheme(
                data: RetroDesktopThemeData.slate(brightness)
                    .copyWith(appearance: appearance),
                child: Center(
                  child: RepaintBoundary(
                    key: boundaryKey,
                    child: SizedBox(
                      width: 320,
                      child: RetroDesktopAlert(
                        title: 'Visible content',
                        body:
                            'The foreground rim must leave this content alone.',
                        mark: const SizedBox(
                          key: markKey,
                          width: 24,
                          height: 24,
                          child: ColoredBox(color: marker),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        for (var i = 0; i < 10; i++) {
          await frame();
        }
        final box = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(boundaryKey),
        );
        final point = box.globalToLocal(tester.getCenter(find.byKey(markKey)));
        await tester.runAsync(() async {
          final image = await box.toImage();
          try {
            final bytes = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            final offset =
                (point.dy.floor() * image.width + point.dx.floor()) * 4;
            expect(
              [
                for (var channel = 0; channel < 4; channel++)
                  bytes.getUint8(offset + channel),
              ],
              [0, 204, 136, 255],
              reason: '${brightness.name} / ${appearance.name}',
            );
          } finally {
            image.dispose();
          }
        });
      }
    }
  });

  for (final phase in ['warmup', 'measured']) {
    for (final brightness in Brightness.values) {
      for (final page in galleryPages) {
        final key = '${phase}_${brightness.name}_${page.id}';
        testWidgets('$key scroll timing', (tester) async {
          binding.attachRootWidget(
            binding.wrapWithDefaultView(page.build(brightness)),
          );
          for (var i = 0; i < 30; i++) {
            await frame();
          }
          // A page can contain a horizontal navigation scroll before its body.
          // Measure the longest vertical scroll, not whichever was built first.
          final positions =
              tester
                  .stateList<ScrollableState>(find.byType(Scrollable))
                  .map((state) => state.position)
                  .where((position) => position.axis == Axis.vertical)
                  .toList()
                ..sort(
                  (a, b) => b.maxScrollExtent.compareTo(a.maxScrollExtent),
                );
          expect(positions, isNotEmpty);
          final position = positions.first;
          Future<void> scroll() async {
            for (final step in [40.0, -40.0]) {
              do {
                position.jumpTo(
                  (position.pixels + step).clamp(
                    position.minScrollExtent,
                    position.maxScrollExtent,
                  ),
                );
                await frame();
              } while (step > 0
                  ? position.pixels < position.maxScrollExtent
                  : position.pixels > position.minScrollExtent);
            }
          }

          // The first phase reaches every glyph and shader across all pages and
          // modes. Both phases retain all frames; only measured timings block.
          await binding
              .watchPerformance(scroll, reportKey: key)
              .timeout(const Duration(seconds: 45));
          debugPrint('scrolled $key: ${position.maxScrollExtent.round()} px');
          final timing = binding.reportData![key] as Map<String, dynamic>;
          expect(timing['frame_count'], greaterThan(0), reason: key);
          if (phase == 'measured') {
            expect(
              timing['worst_frame_build_time_millis'],
              lessThanOrEqualTo(16),
              reason: key,
            );
            expect(
              timing['worst_frame_rasterizer_time_millis'],
              lessThanOrEqualTo(16),
              reason: key,
            );
          }
        });
      }
    }
  }
}
