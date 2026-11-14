// Frame times while every gallery page scrolls to its foot and back, for `flutter drive --profile --no-dds` on a
// desktop: each page's build and raster times land in the timeline summary the driver writes.
//
// The test asks for each frame itself, 16 ms apart, and moves the page 40 px a frame (2,400 px a second). It doesn't
// wait for the display: a window the display isn't showing (behind another app, on another Space) gets no vsync, and
// a test that pumps through vsync would wait for ever. Each frame is a warm-up frame, the one kind the engine renders
// without a vsync, so its raster time is real.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui_example/main.dart'
    show galleryBuildPage, galleryExamplePages;
import 'package:material_expressive_ui/material_expressive_ui.dart'
    show expressiveLoadFonts;
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmark;
  setUpAll(expressiveLoadFonts);

  /// Draws one frame now, then gives the raster thread a frame's time.
  Future<void> frame() async {
    binding.scheduleWarmUpFrame();
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }

  testWidgets('warm up every page in both modes before measuring the gallery', (
    tester,
  ) async {
    // Each pass traverses the entire gallery. A page does not get a second
    // chance inside the measured pass; first-use work stays in warmup_*.
    for (final phase in ['warmup', 'measured']) {
      for (final mode in Brightness.values) {
        for (final page in galleryExamplePages) {
          ScrollPosition? position;
          await binding.traceAction(
            () async {
              binding.attachRootWidget(
                binding.wrapWithDefaultView(galleryBuildPage(page, mode)),
              );
              for (var i = 0; i < 30; i++) {
                await frame();
              }
              final positions = tester
                  .stateList<ScrollableState>(find.byType(Scrollable))
                  .where((state) => state.position.axis == Axis.vertical);
              position = positions.firstOrNull?.position;
              for (final step in [40.0, -40.0]) {
                do {
                  final current = position;
                  if (current != null) {
                    current.jumpTo(
                      (current.pixels + step).clamp(
                        current.minScrollExtent,
                        current.maxScrollExtent,
                      ),
                    );
                  }
                  await frame();
                } while (position != null &&
                    (step > 0
                        ? position!.pixels < position!.maxScrollExtent
                        : position!.pixels > position!.minScrollExtent));
              }
            },
            streams: const ['Dart', 'Embedder', 'GC'],
            reportKey: '${phase}_${page.id}_${mode.name}',
          );
          debugPrint(
            '$phase ${page.id}/${mode.name}: ${position?.maxScrollExtent.round() ?? 0} px',
          );
        }
      }
    }
  });
}
