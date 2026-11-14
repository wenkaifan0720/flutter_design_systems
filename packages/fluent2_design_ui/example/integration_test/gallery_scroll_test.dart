// Frame times while every gallery page scrolls to its foot and back, for `flutter drive --profile --no-dds` on a
// desktop: each page's build and raster times land in the timeline summary the driver writes.
//
// The test asks for each frame itself, 16 ms apart, and moves the page 40 px a frame (2,400 px a second). It doesn't
// wait for the display: a window the display isn't showing (behind another app, on another Space) gets no vsync, and
// a test that pumps through vsync would wait for ever. Each frame is a warm-up frame, the one kind the engine renders
// without a vsync, so its raster time is real.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui_example/gallery_pages.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmark;

  /// Draws one frame now, then gives the raster thread a frame's time.
  Future<void> frame() async {
    binding.scheduleWarmUpFrame();
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }

  testWidgets('every gallery page scrolls', (tester) async {
    for (final pass in ['warmup', 'measured']) {
      for (final brightness in Brightness.values) {
        for (final page in galleryPages) {
          double scrollExtent = 0;
          Future<void> mount() async {
            binding.attachRootWidget(
              binding.wrapWithDefaultView(page.build(brightness)),
            );
            for (var i = 0; i < 30; i++) {
              await frame();
            }
          }

          // The warm-up records the first mount; the measured trace records scrolling.
          if (pass == 'measured') await mount();
          await binding.traceAction(
            () async {
              if (pass == 'warmup') await mount();
              final positions = tester
                  .stateList<ScrollableState>(find.byType(Scrollable))
                  .where((state) => state.position.axis == Axis.vertical);
              if (positions.isEmpty) return;
              final position = positions.first.position;
              scrollExtent = position.maxScrollExtent;
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
            },
            streams: const ['Dart', 'Embedder', 'GC'],
            reportKey: '${pass}_${page.id}_${brightness.name}',
          );
          debugPrint(
            '$pass ${page.id} ${brightness.name}: ${scrollExtent.round()} px',
          );
        }
      }
    }
  });
}
