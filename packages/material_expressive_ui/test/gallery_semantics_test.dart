// A demo app nested in a gallery page (a stack of pages, a router, a
// register's preview, the trip planner, the shell's tab stacks) raises a
// first route whose barrier hides, from assistive technology, everything
// painted before it in its semantics container. On material_ui's
// MaterialApp, which keeps no container of its own round its navigator, that
// was the gallery round the demo: its rail, its bar and its tabs. Each nested
// app and navigator stands in a container of its own, so on every page, at a
// desktop's width and at a phone's, every text in view reaches the semantics
// tree.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

// The gallery is the example app; a test reads its pages from there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import 'flutter_test_config.dart' show pageWalkLeakTesting;
import 'gallery_support.dart';

final List<String> _pages = <String>[
  for (final page in galleryPages) page.id,
  'everyday-dialog',
  'everyday-tabs',
  'everyday-cards',
  galleryOverview,
];

void main() {
  LeakTesting.settings = pageWalkLeakTesting;
  for (final size in const <Size>[Size(1440, 1600), Size(390, 900)]) {
    for (final id in _pages) {
      testWidgets('$id at ${size.width.round()}: every text in view is in the '
          'semantics tree', (tester) async {
        final semantics = tester.ensureSemantics();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        try {
          await tester.pumpWidget(
            GalleryApp(key: ValueKey<String>(id), initialPage: id),
          );
          await settle(tester);
          expect(_unspoken(Offset.zero & size), isEmpty);
        } finally {
          semantics.dispose();
          PaintingBinding.instance.imageCache
            ..clear()
            ..clearLiveImages();
          await tester.pump();
        }
      });
    }
  }
}

/// The first line of each text in [view] that no node of the semantics tree
/// says, in its label or its value.
List<String> _unspoken(Rect view) {
  final unspoken = <String>{};
  for (final element in find.byType(RichText).evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    final line = paragraph.text.toPlainText().split('\n').first.trim();
    // An icon is a glyph of the private use area; one letter says little.
    if (line.length < 2 ||
        line.runes.every((rune) => rune >= 0xE000 && rune <= 0xF8FF)) {
      continue;
    }
    if (!paragraph.hasSize || _excluded(element)) continue;
    final origin = paragraph.localToGlobal(Offset.zero);
    if (!view.contains(origin) ||
        !view.contains(origin + paragraph.size.bottomRight(Offset.zero))) {
      continue;
    }
    final said = RegExp(RegExp.escape(line));
    if (find.semantics.byLabel(said).evaluate().isEmpty &&
        find.semantics.byValue(said).evaluate().isEmpty) {
      unspoken.add(line);
    }
  }
  return unspoken.toList();
}

/// Whether [element] stands under a widget that keeps it from assistive
/// technology on purpose.
bool _excluded(Element element) {
  var excluded = false;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    excluded =
        (widget is ExcludeSemantics && widget.excluding) ||
        (widget is Semantics && widget.excludeSemantics);
    return !excluded;
  });
  return excluded;
}
