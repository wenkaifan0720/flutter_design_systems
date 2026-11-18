// The gallery as a screen reader reads it: on every page, at a desktop's width and a phone's, each section heading and
// each of the app's destinations stand in the semantics tree. A route's barrier hides what was painted before it in
// its semantics container, and Quill's frame paints its side bar and top bar before its in-place navigator, so that
// navigator (and every app the gallery nests) stands in a container of its own; material_ui's MaterialApp adds none.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart' show ledgerLoadFonts;
import 'package:ledger_ui_example/gallery_pages.dart';
import 'package:ledger_ui_example/kit_gallery/quill/quill.dart';

const _sizes = [Size(1440, 900), Size(390, 844)];

// Quill keeps a few things moving (a caret, a ticker), so the frames are counted, not settled.
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 250));
  }
}

/// What each heading on the page says: its label, or the words under it.
List<String> _headings(WidgetTester t) => [
  for (final e
      in find
          .byWidgetPredicate(
            (w) => w is Semantics && w.properties.header == true,
          )
          .evaluate())
    if ((e.widget as Semantics).properties.label case final label?
        when label.trim().isNotEmpty)
      label
    else if (find
            .descendant(
              of: find.byWidget(e.widget),
              matching: find.byType(Text),
            )
            .evaluate()
            .firstOrNull
        case final text?)
      (text.widget as Text).data ??
          (text.widget as Text).textSpan!.toPlainText(),
];

void _expectRead(WidgetTester t, String page) {
  // A heading's words as drawn: a placeholder for an inline mark left out, and in any case (a sortable column's
  // heading reads its label, "Entry", where Ledger draws "ENTRY").
  for (final drawn in {..._headings(t), 'Home', 'Register', 'Settings'}) {
    final words = drawn.replaceAll('\uFFFC', '').trim();
    if (words.isEmpty) continue;
    expect(
      find.semantics.byLabel(
        RegExp(RegExp.escape(words), caseSensitive: false),
      ),
      findsAny,
      reason: '"$words" on $page is not in the semantics tree',
    );
  }
}

Future<void> _open(WidgetTester t, Size size, Widget app) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(app);
  await _settle(t);
}

void main() {
  // Ledger's own faces, as the gallery draws them (a part laid out in the test face overflows its slot).
  setUpAll(ledgerLoadFonts);
  final parts = [
    for (final page in galleryPages) (title: page.title, build: page.build),
  ];
  for (final size in _sizes) {
    final width = size.width.round();
    for (final page in QuillPage.values) {
      testWidgets(
        '${page.name} at $width: its headings and destinations are read',
        (t) async {
          final semantics = t.ensureSemantics();
          await _open(t, size, QuillApp(initialPage: page, parts: parts));
          _expectRead(t, page.name);
          semantics.dispose();
        },
      );
    }
  }
  for (final (i, part) in galleryPages.indexed) {
    testWidgets(
      'the part page ${part.id} at 1440: its headings and destinations are read',
      (t) async {
        final semantics = t.ensureSemantics();
        await _open(t, _sizes.first, QuillApp(parts: parts, initialPart: i));
        _expectRead(t, part.id);
        semantics.dispose();
      },
    );
  }
}
