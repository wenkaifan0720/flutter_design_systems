// What the gallery tests share: a gallery page pumped in a preset and an appearance, on a phone as wide as the gallery
// device and as tall as the page, so every section is on screen at once; the bundled faces; and text contrast read
// with each word's own ink.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

// The gallery is the example app; a test reads its pages from there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/theme.dart';

export '../example/lib/gallery_pages.dart';

/// The gallery's phone width.
const galleryWidth = 390.0;

/// Loads the faces the pubspec bundles (Selawik and the two glyph sets) and every family in the FontManifest, so
/// words are measured and inked as they would be on a device.
Future<void> loadFluent2TestFonts() async {
  final faces = <String, List<String>>{};
  String? family;
  for (final line in File('pubspec.yaml').readAsLinesSync()) {
    final found = RegExp(r'^\s*- family:\s*(.+)$').firstMatch(line);
    final asset = RegExp(r'^\s*- asset:\s*(.+)$').firstMatch(line);
    if (found != null) family = found[1]!.trim();
    if (asset != null && family != null) {
      (faces[family] ??= []).add(asset[1]!.trim());
    }
  }
  for (final MapEntry(key: name, value: files) in faces.entries) {
    final loader = FontLoader(fluent2FontFamily(name));
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await loader.load();
  }
  // Then every family the package's FontManifest.json names, under its own
  // name, so no word or glyph falls back to the test's own font.
  final manifest =
      jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final entry in manifest.cast<Map<String, Object?>>()) {
    final loader = FontLoader(entry['family']! as String);
    for (final f in (entry['fonts']! as List).cast<Map<String, Object?>>()) {
      loader.addFont(rootBundle.load(f['asset']! as String));
    }
    await loader.load();
  }
}

/// Pumps [page] in [preset] and [brightness] at [galleryWidth], then grows the view to the page's whole height.
Future<void> pumpGalleryPage(
  WidgetTester tester,
  GalleryPage page,
  String preset,
  Brightness brightness, {
  double devicePixelRatio = 1,
}) async {
  kitShownPreset = preset;
  addTearDown(() => kitShownPreset = kitPreset);
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = const Size(galleryWidth, 844) * devicePixelRatio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    KeyedSubtree(
      key: ValueKey('${page.id}/$preset/${brightness.name}'),
      child: page.build(brightness),
    ),
  );
  await settle(tester);
  // A lazy list knows its height only as it builds its rows, so its extent is an estimate until all are built: grow
  // until nothing is left to scroll, or a row would stand cut at the capture's edge.
  var height = 844.0;
  for (var i = 0; i < 8; i++) {
    final scrollables = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .where((s) => s.position.axis == Axis.vertical);
    final extent = scrollables.isEmpty
        ? 0.0
        : scrollables.first.position.maxScrollExtent;
    if (extent <= 0) break;
    height += extent;
    tester.view.physicalSize = Size(galleryWidth, height) * devicePixelRatio;
    await settle(tester);
  }
  // A photograph decodes off the frame: wait for every image, so a capture never catches one half loaded.
  await tester.runAsync(
    () => Future.wait([
      for (final e in find.byType(Image).evaluate())
        precacheImage((e.widget as Image).image, e),
    ]),
  );
  await tester.pump();
}

/// Pumps [page] at [width] in the shown preset, [brightness] and [density], grows the view to the page's whole height,
/// then holds it still to be read: what runs for ever (a spinner, a shimmer) stops where it is, the page's images
/// decode, and the frame they land in is drawn.
Future<void> pumpWhole(
  WidgetTester t,
  GalleryPage page,
  double width, {
  Brightness brightness = Brightness.light,
  Fluent2Density density = Fluent2Density.standard,
}) async {
  kitShownTheme = (b) =>
      Fluent2ThemeData.preset(kitShownPreset, b).copyWith(density: density);
  addTearDown(() => kitShownTheme = null);
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(width, 900);
  addTearDown(t.view.reset);
  Widget shown({required bool ticking}) => TickerMode(
    enabled: ticking,
    child: KeyedSubtree(
      key: ValueKey(('${page.id}/$width/${brightness.name}', density)),
      child: page.build(brightness),
    ),
  );
  // The page before goes first: a demo's scroll controller is one object
  // and serves one scroll view at a time.
  await t.pumpWidget(const SizedBox());
  await t.pump();
  await t.pumpWidget(shown(ticking: true));
  await settle(t);
  var height = 900.0;
  for (var i = 0; i < 8; i++) {
    final scrollables = t
        .stateList<ScrollableState>(find.byType(Scrollable))
        .where((s) => s.position.axis == Axis.vertical);
    final extent = scrollables.isEmpty
        ? 0.0
        : scrollables.first.position.maxScrollExtent;
    if (extent <= 0) break;
    height += extent;
    t.view.physicalSize = Size(width, height);
    await settle(t);
  }
  await t.pumpWidget(shown(ticking: false));
  await t.runAsync(
    () => Future.wait([
      for (final e in find.byType(Image).evaluate())
        precacheImage((e.widget as Image).image, e),
    ]),
  );
  await t.pump();
}

/// The screen on show: a Northwind root's scaffold (the others wait off stage) or the page's own, else the whole
/// page.
Element shownScreen(WidgetTester t) {
  final scaffold = find.byType(Fluent2Scaffold).hitTestable();
  return t.element(
    scaffold.evaluate().isEmpty
        ? find.byType(KeyedSubtree).first
        : scaffold.first,
  );
}

/// A second of frames: what an entrance takes, without waiting on a spinner that never stops.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 34));
  }
}

/// Every preset, light and dark.
Iterable<(String, Brightness)> get presetsAndModes sync* {
  for (final preset in Fluent2ThemeData.presets) {
    for (final b in Brightness.values) {
      yield (preset, b);
    }
  }
}

/// WCAG's relative luminance of [c].
double luminance(Color c) {
  double channel(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG's contrast ratio between [a] and [b], from 1 to 21.
double contrastRatio(Color a, Color b) {
  final x = luminance(a), y = luminance(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

/// Text contrast as the words are inked: every paragraph the semantics tree reads, its own colours against the colour
/// most of its box is painted, leaving out pixels within 1.25:1 of the ink (the ink and its anti-aliased edge).
/// 4.5:1, or 3:1 for large text (18 px, or 14 px bold). Each failure is a line: the words, the ratio, the colours.
///
/// Flutter's `textContrastGuideline` reads both colours from a capture at one pixel per logical pixel, where
/// Selawik's strokes at 10 to 12 px never fill a pixel: it takes an anti-aliased grey for the ink. This reads the ink
/// from the paragraph itself, and only the ground from the pixels.
///
/// Words of a control that announces itself disabled are left out, as WCAG 1.4.3 leaves out "part of an inactive user
/// interface component" and Flutter's guideline skips a disabled node.
Future<List<String>> inkedContrastFailures(WidgetTester tester) async {
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  late final ui.Image image;
  late final ByteData bytes;
  await tester.runAsync(() async {
    image = await layer.toImage(view.paintBounds, pixelRatio: 1);
    bytes = (await image.toByteData())!;
  });
  final failures = <String>[];
  for (final element in find.byType(RichText).evaluate()) {
    final p = element.renderObject! as RenderParagraph;
    if (!p.attached || !p.hasSize || p.size.isEmpty) continue;
    final words = p.text.toPlainText().trim();
    if (words.isEmpty || !_readAloud(p) || _inactive(p)) continue;
    final inks = <Color>[];
    p.text.visitChildren((span) {
      final style = span.style;
      if (style?.foreground != null) {
        inks.add(style!.foreground!.color);
      } else if (style?.color != null) {
        inks.add(style!.color!);
      }
      return true;
    });
    if (inks.isEmpty) continue;
    final box =
        MatrixUtils.transformRect(
          p.getTransformTo(null),
          Offset.zero & p.size,
        ).intersect(
          Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
        );
    if (box.isEmpty) continue;
    final counts = <int, int>{};
    for (var y = box.top.floor(); y < box.bottom.ceil(); y++) {
      for (var x = box.left.floor(); x < box.right.ceil(); x++) {
        final v = bytes.getUint32((y * image.width + x) * 4) >> 8;
        counts[v] = (counts[v] ?? 0) + 1;
      }
    }
    final ranked = counts.entries.toList()..sort((a, b) => b.value - a.value);
    final style = p.text.style;
    final size = style?.fontSize ?? 14;
    final bold = (style?.fontWeight?.value ?? 400) >= 700;
    final need = size >= 18 || (size >= 14 && bold) ? 3.0 : 4.5;
    for (final ink in inks) {
      Color? ground;
      for (final e in ranked) {
        final c = Color(0xFF000000 | e.key);
        if (contrastRatio(c, Color.alphaBlend(ink, c)) >= 1.25) {
          ground = c;
          break;
        }
      }
      if (ground == null) continue;
      final ratio = contrastRatio(Color.alphaBlend(ink, ground), ground);
      if (ratio < need) {
        failures.add(
          '"$words" ${ratio.toStringAsFixed(2)}:1 (needs $need) '
          'ink ${_hex(ink)} on ${_hex(ground)}',
        );
      }
    }
  }
  return failures;
}

/// Whether [p] belongs to a control that announces itself disabled: the nearest semantics node over it is not enabled.
bool _inactive(RenderParagraph p) {
  RenderObject? node = p;
  while (node != null) {
    final owned = node.debugSemantics;
    if (owned != null) {
      return owned.getSemanticsData().flagsCollection.isEnabled ==
          ui.Tristate.isFalse;
    }
    node = node.parent;
  }
  return false;
}

/// Whether a screen reader reads [p]: it is in the semantics tree, not hidden from it.
bool _readAloud(RenderParagraph p) {
  RenderObject? node = p;
  while (node != null) {
    if (node is RenderExcludeSemantics && node.excluding) return false;
    if (node is RenderOffstage && node.offstage) return false;
    if (node is RenderOpacity && node.opacity == 0) return false;
    if (node is RenderAnimatedOpacity && node.opacity.value == 0) return false;
    node = node.parent;
  }
  return true;
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// The gallery's sections on screen, by their labels, in the page's order.
List<(String, Finder)> sections() {
  final found = find.byWidgetPredicate(
    (w) =>
        w is RepaintBoundary &&
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('kit-section/'),
  );
  final seen = <String, int>{};
  return [
    for (var i = 0; i < found.evaluate().length; i++)
      () {
        final label =
            ((found.at(i).evaluate().single.widget.key!) as ValueKey<String>)
                .value
                .substring('kit-section/'.length);
        final n = seen[label] = (seen[label] ?? 0) + 1;
        return (n == 1 ? label : '$label $n', found.at(i));
      }(),
  ];
}

/// [label] as a file name.
String slug(String label) => label
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');
