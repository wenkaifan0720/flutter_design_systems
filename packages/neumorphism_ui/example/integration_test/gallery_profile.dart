// Build this entry once with `flutter build web --profile --target
// integration_test/gallery_profile.dart`. Normally it opens the complete example;
// ?profile=scroll warms every page in both appearances, then measures a second
// traversal in the visible browser. First-use timings stay in warmUp; only
// measured pages determine the 16 ms performance result.
// The browser reads window.neumorphicPerformanceReport as JSON. This file belongs
// only to the example; no browser interop or profiling API enters the UI package.
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui_example/gallery_pages.dart';
import 'package:neumorphism_ui_example/kit_gallery/kit.dart';
import 'package:neumorphism_ui_example/kit_gallery/live.dart';
import 'package:neumorphism_ui_example/main.dart' as gallery;

@JS('neumorphicPerformanceReport')
external set _report(JSString value);

@JS('neumorphicReviewProbe')
external set _reviewProbe(JSFunction value);

@JS('neumorphicReviewScroll')
external set _reviewScroll(JSFunction value);

Future<void> _review(String id) async {
  WidgetsFlutterBinding.ensureInitialized();
  await neumorphicLoadFonts();
  final query = Uri.base.queryParameters;
  final preset = query['preset'] ?? 'porcelain';
  final mode = query['dark'] == '1' ? Brightness.dark : Brightness.light;
  final custom = switch (query['custom']) {
    'contrast' => const gallery.GalleryCustom(highContrast: true),
    'compact' => const gallery.GalleryCustom(
      density: gallery.GalleryDensity.compact,
    ),
    _ => const gallery.GalleryCustom(),
  };
  kitShownPreset = preset;
  kitShownTheme = (brightness) => custom.theme(preset, brightness);
  final design = id.startsWith('design-');
  runApp(
    design
        ? gallery.GalleryApp(
            initialPage: id.substring(7),
            initialBrightness: mode,
            initialCustom: custom,
          )
        : galleryPages.firstWhere((page) => page.id == id).build(mode),
  );
  await SchedulerBinding.instance.endOfFrame;
  _reviewProbe = (() {
    final scroll = _verticalScroll(WidgetsBinding.instance.rootElement!);
    final view = WidgetsBinding.instance.renderViews.first;
    final box = scroll?.context.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final anchors = <String, Object>{};
    void visit(Element element) {
      final key = element.widget.key;
      if (key is ValueKey<String> && key.value.startsWith('live-')) {
        final render = element.findRenderObject();
        if (render is RenderBox && render.hasSize) {
          final at = render.localToGlobal(Offset.zero);
          anchors[key.value] = {
            'x': at.dx,
            'y': at.dy,
            'width': render.size.width,
            'height': render.size.height,
          };
        }
      }
      element.visitChildElements(visit);
    }

    visit(WidgetsBinding.instance.rootElement!);
    return jsonEncode({
      'anchors': anchors,
      'page': id,
      'preset': preset,
      'mode': mode.name,
      'custom': query['custom'] ?? 'drawn',
      'width': view.child!.size.width,
      'height': view.child!.size.height,
      'viewport': scroll?.position.viewportDimension ?? 0,
      'extent': scroll?.position.maxScrollExtent ?? 0,
      'offset': scroll?.position.pixels ?? 0,
      'top': origin.dy,
      'bottom': box == null
          ? 0
          : view.child!.size.height - origin.dy - box.size.height,
    }).toJS;
  }).toJS;
  _reviewScroll = ((JSNumber value) {
    final scroll = _verticalScroll(WidgetsBinding.instance.rootElement!);
    if (scroll == null) return;
    scroll.position.jumpTo(
      value.toDartDouble.clamp(
        scroll.position.minScrollExtent,
        scroll.position.maxScrollExtent,
      ),
    );
  }).toJS;
}

Map<String, Object> _durations(Iterable<Duration> values) {
  final ms = values.map((v) => v.inMicroseconds / 1000).toList()..sort();
  return {
    'frames': ms.length,
    'averageMs': ms.isEmpty ? 0 : ms.reduce((a, b) => a + b) / ms.length,
    'worstMs': ms.isEmpty ? 0 : ms.last,
    'over16ms': ms.where((v) => v > 16).length,
    'samplesMs': ms,
  };
}

ScrollableState? _verticalScroll(Element root) {
  ScrollableState? found;
  void visit(Element element) {
    if (found != null) return;
    if (element is StatefulElement && element.state is ScrollableState) {
      final state = element.state as ScrollableState;
      if (state.position.axis == Axis.vertical) {
        found = state;
        return;
      }
    }
    element.visitChildElements(visit);
  }

  visit(root);
  return found;
}

Future<void> main() async {
  final review = Uri.base.queryParameters['review'];
  if (review != null) {
    await _review(review);
    return;
  }
  if (Uri.base.queryParameters['profile'] != 'scroll') {
    await gallery.main();
    return;
  }
  WidgetsFlutterBinding.ensureInitialized();
  final warmUp = <Map<String, Object>>[];
  final results = <Map<String, Object>>[];
  void publish(String status, {String? error}) {
    _report = jsonEncode({
      'status': status,
      'profileMode': kProfileMode,
      'viewport': {
        'width': WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .physicalSize
            .width,
        'height': WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .physicalSize
            .height,
      },
      'warmUp': warmUp,
      'pages': results,
      'error': ?error,
    }).toJS;
  }

  publish('running');
  try {
    if (!kProfileMode) throw StateError('Performance requires a profile build');
    await neumorphicLoadFonts();
    // Include the full component matrices as well as the seven live screens:
    // the short everyday pages alone cannot exercise every painted component.
    final pages = <({String id, Widget Function(Brightness) build})>[
      for (final page in galleryPages) (id: page.id, build: page.build),
      for (final page in liveGalleryPages)
        (
          id: 'design-${page.id}',
          build: (brightness) => gallery.GalleryApp(
            initialPage: page.id,
            initialBrightness: brightness,
          ),
        ),
    ];
    for (final measured in [false, true]) {
      for (final page in pages) {
        for (final brightness in Brightness.values) {
          runApp(
            KeyedSubtree(
              key: ValueKey('${page.id}/${brightness.name}'),
              child: page.build(brightness),
            ),
          );
          // Exclude mounting and font/shader startup from the scrolling interval.
          await Future<void>.delayed(const Duration(seconds: 2));
          final scroll = _verticalScroll(WidgetsBinding.instance.rootElement!);
          if (scroll == null) {
            throw StateError('${page.id} has no vertical scroll');
          }
          final position = scroll.position;
          final extent = position.maxScrollExtent;
          final duration = Duration(
            milliseconds: (extent / 2.4).ceil().clamp(300, 10000),
          );
          final timings = <FrameTiming>[];
          SchedulerBinding.instance.addTimingsCallback(timings.addAll);
          try {
            for (final target in [extent, 0.0]) {
              await position.animateTo(
                target,
                duration: duration,
                curve: Curves.linear,
              );
            }
            // The web engine batches its timing callbacks. Force two final frames
            // around that interval so the last scrolling frames are reported.
            for (var i = 0; i < 2; i++) {
              await Future<void>.delayed(const Duration(milliseconds: 150));
              SchedulerBinding.instance.scheduleFrame();
              await SchedulerBinding.instance.endOfFrame;
            }
          } finally {
            SchedulerBinding.instance.removeTimingsCallback(timings.addAll);
          }
          (measured ? results : warmUp).add({
            'page': page.id,
            'mode': brightness.name,
            'scrollExtent': extent,
            'build': _durations(timings.map((t) => t.buildDuration)),
            'raster': _durations(timings.map((t) => t.rasterDuration)),
            'passed':
                timings.isNotEmpty &&
                timings.every(
                  (t) =>
                      t.buildDuration.inMicroseconds <= 16000 &&
                      t.rasterDuration.inMicroseconds <= 16000,
                ),
          });
          publish('running');
        }
      }
    }
    publish(results.every((r) => r['passed'] == true) ? 'passed' : 'failed');
  } catch (error) {
    publish('failed', error: error.toString());
    rethrow;
  }
}
