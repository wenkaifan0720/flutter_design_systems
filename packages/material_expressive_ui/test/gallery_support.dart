// What the gallery tests share: a gallery page pumped in a preset and an appearance, on a phone as wide as the gallery
// device and as tall as the page, so every section is on screen at once.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

// The gallery is the example app; a test reads its pages from there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/theme.dart';

export '../example/lib/gallery_pages.dart';

/// Loads the bundled faces under the names the components ask for (the package's, once it is one), so words are
/// measured and drawn as on a device.
Future<void> loadExpressiveFonts() async {
  for (final (family, files) in const [
    ('RobotoFlex', ['RobotoFlex.ttf']),
    ('Jost', ['Jost-400.ttf', 'Jost-500.ttf', 'Jost-600.ttf']),
    ('MaterialSymbolsRounded', ['MaterialSymbolsRounded.ttf']),
  ]) {
    final loader = FontLoader(expressiveFontFamily(family));
    for (final file in files) {
      final bytes = ByteData.sublistView(
        File('assets/fonts/$file').readAsBytesSync(),
      );
      loader.addFont(Future.value(bytes));
    }
    await loader.load();
  }
}

/// Every font the test bundle carries (the icons' among them), under the family names the manifest gives.
Future<void> loadBundledFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    for (final font
        in (family['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// The gallery's phone width.
const galleryWidth = 390.0;

/// Pumps [page] in [preset] and [brightness] at [width] ([galleryWidth] unless given), then grows the view to the
/// page's whole height; in [direction] when given (the page's previews and overlays read it).
Future<void> pumpGalleryPage(
  WidgetTester tester,
  GalleryPage page,
  String preset,
  Brightness brightness, {
  double devicePixelRatio = 1,
  TextDirection? direction,
  double width = galleryWidth,
}) async {
  kitShownPreset = preset;
  addTearDown(() => kitShownPreset = kitPreset);
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = Size(width, 844) * devicePixelRatio;
  addTearDown(tester.view.reset);
  final built = page.build(brightness);
  await tester.pumpWidget(
    KeyedSubtree(
      // The page's key (sectionsOrPage finds a page without sections by
      // it), with the direction only when one is given.
      key: ValueKey(
        '${page.id}/$preset/${brightness.name}'
        '${direction == null ? '' : '/${direction.name}'}',
      ),
      child: direction == null
          ? built
          : Directionality(textDirection: direction, child: built),
    ),
  );
  await settle(tester);
  final scrollables = tester
      .stateList<ScrollableState>(find.byType(Scrollable))
      .where((s) => s.position.axis == Axis.vertical);
  final extent = scrollables.isEmpty
      ? 0.0
      : scrollables.first.position.maxScrollExtent;
  if (extent > 0) {
    tester.view.physicalSize = Size(width, 844 + extent) * devicePixelRatio;
    await settle(tester);
  }
}

/// A second of frames: what an entrance takes, without waiting on a spinner that never stops.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 34));
  }
}

/// Every preset by day and by night.
Iterable<(String, Brightness)> get presetsAndModes sync* {
  for (final preset in ExpressiveThemeData.presets) {
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

/// Text contrast as the words are inked: every paragraph the semantics tree reads but a disabled control's, its own
/// colours against the colour most of its box is painted, leaving out pixels within 1.25:1 of the ink (the ink and its
/// anti-aliased edge).
/// 4.5:1, or 3:1 for large text (18 px, or 14 px bold). Each failure is a line: the words, the ratio, the colours.
///
/// Flutter's `textContrastGuideline` reads both colours from a capture at one pixel per logical pixel, where thin
/// strokes at 11 to 13 px never fill a pixel: it takes an anti-aliased grey for the ink. This reads the ink from the
/// paragraph itself, and only the ground from the pixels.
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
    if (words.isEmpty || !_readAloud(p) || _disabled(p)) continue;
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

/// Whether [p] is the words of a disabled control. WCAG leaves an inactive component out of the contrast rule, and
/// Flutter's guideline skips it; Material draws its words at 38%.
bool _disabled(RenderParagraph p) {
  RenderObject? node = p;
  while (node != null) {
    final s = node.debugSemantics;
    if (s != null && !s.isMergedIntoParent) {
      return s.getSemanticsData().flagsCollection.isEnabled ==
          ui.Tristate.isFalse;
    }
    node = node.parent;
  }
  return false;
}

/// Whether a screen reader reads [p]: it is not hidden, nor spoken by a label in its place, and the node it falls in
/// (or the node that one merges into) says its words — not so for words under a modal barrier, which blocks them.
bool _readAloud(RenderParagraph p) {
  RenderObject? node = p;
  while (node != null) {
    if (node is RenderExcludeSemantics && node.excluding) return false;
    if (node is RenderSemanticsAnnotations && node.excludeSemantics) {
      return false;
    }
    if (node is RenderOffstage && node.offstage) return false;
    if (node is RenderOpacity && node.opacity == 0) return false;
    if (node is RenderAnimatedOpacity && node.opacity.value == 0) return false;
    node = node.parent;
  }
  String flat(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
  final words = flat(p.text.toPlainText());
  node = p;
  while (node != null) {
    var s = node.debugSemantics;
    if (s != null && s.attached) {
      while (s!.isMergedIntoParent && s.parent != null) {
        s = s.parent;
      }
      final d = s.getSemanticsData();
      return flat('${d.label} ${d.value} ${d.hint} ${d.tooltip}')
          .contains(words);
    }
    node = node.parent;
  }
  return false;
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
