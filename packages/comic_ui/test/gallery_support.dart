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
import 'package:comic_ui/comic_ui.dart';

// The gallery is the example app; a test reads its pages from there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/theme.dart';

export '../example/lib/gallery_pages.dart';

/// The gallery's phone width.
const galleryWidth = 390.0;

/// Pumps [page] in [preset] and [brightness] at [width], then grows the view to the page's whole height.
Future<void> pumpGalleryPage(
  WidgetTester tester,
  GalleryPage page,
  String preset,
  Brightness brightness, {
  double devicePixelRatio = 1,
  double width = galleryWidth,
}) async {
  kitShownPreset = preset;
  addTearDown(() => kitShownPreset = kitPreset);
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = Size(width, 844) * devicePixelRatio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    KeyedSubtree(
      key: ValueKey('${page.id}/$preset/${brightness.name}'),
      child: page.build(brightness),
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
  for (final preset in ComicThemeData.presets) {
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

/// Text contrast as the words are inked: every visible non-icon paragraph in an enabled subtree, its own colours against the colour
/// most of its box is painted, leaving out pixels within 1.25:1 of the ink (the ink and its anti-aliased edge).
/// 4.5:1, or 3:1 for large text (18 px, or 14 px bold). Each failure is a line: the words, the ratio, the colours.
///
/// Flutter's `textContrastGuideline` reads both colours from a capture at one pixel per logical pixel, where Shantell Sans's
/// strokes at 11 to 13 px never fill a pixel: it takes an anti-aliased grey for the ink. This reads the ink from the
/// paragraph itself, and only the ground from the pixels.
Future<List<String>> inkedContrastFailures(
  WidgetTester tester, {
  String? diagnosticPath,
  Finder? within,
}) async {
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  late final ui.Image image;
  late final ByteData bytes;
  await tester.runAsync(() async {
    image = await layer.toImage(view.paintBounds, pixelRatio: 1);
    bytes = (await image.toByteData())!;
  });
  final failures = <String>[];
  final paragraphs = within == null
      ? find.byType(RichText)
      : find.descendant(of: within, matching: find.byType(RichText));
  for (final element in paragraphs.evaluate()) {
    var icon = false;
    element.visitAncestorElements((ancestor) {
      if (ancestor.widget is Icon) icon = true;
      return !icon;
    });
    if (icon) continue;
    final p = element.renderObject! as RenderParagraph;
    if (!p.attached || !p.hasSize || p.size.isEmpty) continue;
    final words = p.text.toPlainText().trim();
    if (words.isEmpty || !_contrastRequired(p)) continue;
    final inks = <(Color, double)>[];
    final transform = p.getTransformTo(null).storage;
    final scale = math.max(
      math.sqrt(transform[0] * transform[0] + transform[1] * transform[1]),
      math.sqrt(transform[4] * transform[4] + transform[5] * transform[5]),
    );
    void readSpans(InlineSpan span, TextStyle inherited) {
      final style = inherited.merge(span.style);
      if (span is TextSpan) {
        final ink = style.foreground?.color ?? style.color;
        if (ink != null && (span.text?.trim().isNotEmpty ?? false)) {
          final size = p.textScaler.scale(style.fontSize ?? 14) * scale;
          final bold = (style.fontWeight?.value ?? 400) >= 700;
          inks.add((ink, size >= 18 || (size >= 14 && bold) ? 3.0 : 4.5));
        }
        for (final child in span.children ?? const <InlineSpan>[]) {
          readSpans(child, style);
        }
      }
    }

    readSpans(p.text, const TextStyle());
    if (inks.isEmpty) continue;
    final box =
        MatrixUtils.transformRect(
          p.getTransformTo(view),
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
    for (final (ink, need) in inks) {
      Color? ground;
      for (final e in ranked) {
        final c = Color(0xFF000000 | e.key);
        if (contrastRatio(c, Color.alphaBlend(ink, c)) >= 1.25) {
          ground = c;
          break;
        }
      }
      // If every pixel is close to the ink, the text still has to fail;
      // an unreadable ink/background pair must not disappear from the audit.
      ground ??= ranked.isEmpty ? null : Color(0xFF000000 | ranked.first.key);
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
  if (failures.isNotEmpty && diagnosticPath != null) {
    await tester.runAsync(() async {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(diagnosticPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(png!.buffer.asUint8List());
    });
  }
  image.dispose();
  return failures;
}

/// Whether visible text is subject to contrast checks, matching Flutter's
/// exclusion of hidden and disabled semantic subtrees. Text remains visible
/// when a parent owns its spoken label through ExcludeSemantics.
bool _contrastRequired(RenderParagraph p) {
  RenderObject? node = p;
  while (node != null) {
    if (node is RenderSemanticsAnnotations &&
        node.properties.enabled == false) {
      return false;
    }
    if (node is RenderOffstage && node.offstage) return false;
    if (node is RenderOpacity && node.opacity == 0) return false;
    if (node is RenderAnimatedOpacity && node.opacity.value == 0) return false;
    node = node.parent;
  }
  return true;
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

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

/// Every widget class the package's barrel exports, read from its source: the census the gallery tests hold the
/// gallery and the live example to.
Set<String> publicComicWidgets() {
  final barrel = File('lib/src/comic.dart');
  final widgets = <String>{};
  for (final directive in RegExp(
    r"export '([^']+)'([^;]*);",
  ).allMatches(barrel.readAsStringSync())) {
    final path = File('${barrel.parent.path}/${directive[1]}');
    if (!path.existsSync()) continue;
    final hidden = directive[2]!.contains('hide')
        ? RegExp(r'\b\w+\b').allMatches(directive[2]!).map((m) => m[0]!).toSet()
        : <String>{};
    for (final type in RegExp(
      r'class (\w+)(?:<[^\n]+?>)?\s+extends (\w+)',
    ).allMatches(path.readAsStringSync())) {
      if (type[1]!.startsWith('_') || hidden.contains(type[1])) continue;
      if (const {
        'StatelessWidget',
        'StatefulWidget',
        'InheritedWidget',
        'InheritedTheme',
        'ImplicitlyAnimatedWidget',
        'MultiChildRenderObjectWidget',
        'LeafRenderObjectWidget',
        'ParentDataWidget',
        'SingleChildRenderObjectWidget',
      }.contains(type[2])) {
        widgets.add(type[1]!);
      }
    }
  }
  return widgets;
}
