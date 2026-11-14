// The example is the package's living reference: every exported widget is
// built on a live page reached through the example's own navigation, or in
// an overlay a live page raises, and every page stands in the navigation;
// no icon or character on a live page falls back to the missing-glyph box.
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'overlay_fixtures.dart';
import 'shape_support.dart';
import 'support/font_glyphs.dart';

String _name(Widget widget) => widget.runtimeType.toString().split('<').first;

void main() {
  setUpAll(loadExpressiveFonts);

  testWidgets('every exported widget is live in the example', (tester) async {
    final seen = <String>{};
    void see() {
      for (final element
          in find
              .byWidgetPredicate((_) => true, skipOffstage: false)
              .evaluate()) {
        seen.add(_name(element.widget));
      }
    }

    final tofu = <String>{};
    // Every character a live page sets in a text face is drawn by both
    // bundled text faces (Customize can set any page in Jost); one neither
    // carries is the browser's missing-glyph box on the web build, or a
    // network fallback font.
    final faces = [
      for (final file in ['RobotoFlex.ttf', 'Jost-400.ttf'])
        outlinedGlyphs(await loadBundledFont(file)).keys.toSet(),
    ];
    final drawn = faces.reduce((a, b) => a.intersection(b));
    final strays = <String>{};
    void read(String where) {
      void check(String text) {
        for (final rune in text.runes) {
          final char = String.fromCharCode(rune);
          if (rune < 0x20 || rune == 0xfffc || char.trim().isEmpty) continue;
          // Format characters (zero-width space and joiners, direction
          // marks and isolates) are never drawn: the shaper drops them, so
          // no face needs a glyph (the Shape page breaks labels at ZWSP).
          if ((rune >= 0x200b && rune <= 0x200f) ||
              (rune >= 0x202a && rune <= 0x202e) ||
              (rune >= 0x2060 && rune <= 0x2069) ||
              rune == 0xfeff) {
            continue;
          }
          if (!drawn.contains(rune)) {
            strays.add('$where: "$char" U+${rune.toRadixString(16)}');
          }
        }
      }

      // The Type page's other scripts are set in the platform's fallback
      // fonts on purpose (Noto on the web): the one place they may be.
      final scripts = find.byWidgetPredicate(
        (w) => _name(w) == '_ScriptsSection',
        skipOffstage: false,
      );
      final fallback = <RenderParagraph>{
        ...tester.renderObjectList<RenderParagraph>(
          find.descendant(
            of: scripts,
            matching: find.byType(RichText, skipOffstage: false),
            skipOffstage: false,
          ),
        ),
      };
      final typed = <EditableText>{
        ...tester.widgetList<EditableText>(
          find.descendant(
            of: scripts,
            matching: find.byType(EditableText, skipOffstage: false),
            skipOffstage: false,
          ),
        ),
      };
      for (final paragraph in tester.renderObjectList<RenderParagraph>(
        find.byType(RichText, skipOffstage: false),
      )) {
        if (fallback.contains(paragraph)) continue;
        final family = paragraph.text.style?.fontFamily ?? '';
        if (family.endsWith(ExpressiveSymbolsFont.family)) continue;
        check(paragraph.text.toPlainText());
      }
      for (final field in tester.widgetList<EditableText>(
        find.byType(EditableText, skipOffstage: false),
      )) {
        if (typed.contains(field)) continue;
        check(field.controller.text);
      }
    }

    final bundled = {
      for (final icon in ExpressiveSymbols.byName.values) icon.codePoint,
    };
    // A window tall enough that every lazily built section is built.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 24000);
    addTearDown(tester.view.reset);
    // Every page a link reaches: the destinations' and the plain routes
    // (the inventory), which stand outside the navigation.
    for (final pages in [
      for (final destination in galleryDestinations) destination.pages,
      galleryPlainRoutes,
    ]) {
      for (final page in pages) {
        await tester.pumpWidget(
          GalleryApp(key: ValueKey(page), initialPage: page),
        );
        await settle(tester);
        expect(tester.takeException(), isNull, reason: page);
        see();
        read(page);
        // No icon falls back to the missing-glyph box: each names a glyph
        // of the bundled Symbols subset.
        for (final icon in tester.widgetList<Icon>(
          find.byType(Icon, skipOffstage: false),
        )) {
          final data = icon.icon;
          if (data == null) continue;
          if (data.fontFamily != ExpressiveSymbolsFont.family ||
              data.fontPackage != expressiveFontPackage ||
              !bundled.contains(data.codePoint)) {
            tofu.add(
              '$page: ${data.fontFamily} '
              'U+${data.codePoint.toRadixString(16)}',
            );
          }
        }
      }
    }
    // The overlays, each raised by a call some live page makes.
    final sources = [
      for (final file in Directory(
        'example/lib',
      ).listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart')) file.readAsStringSync(),
    ].join('\n');
    for (final call in {
      'showExpressiveDialog',
      'showExpressiveBottomSheet',
      'showExpressiveMenu',
      'showExpressivePopover',
      'showExpressiveSnackBar',
      'showExpressiveDatePicker',
      'showExpressiveDateRangePicker',
      'showExpressiveTimePicker',
      'showExpressiveNavigationDrawer',
    }) {
      expect(
        sources,
        contains(RegExp('$call(<[^(]*>)?\\(')),
        reason: 'no live page calls $call',
      );
    }
    await forEachOverlay(
      tester,
      ExpressiveThemeData.preset('baseline', Brightness.light),
      (name) {
        see();
        read(name);
      },
    );

    expect(tofu, isEmpty, reason: 'icons outside the bundled subset');
    expect(
      strays,
      isEmpty,
      reason: 'characters neither bundled text face draws',
    );
    final missing = exportedWidgets()
        .difference(seen)
        .difference(paintNothingWidgets.keys.toSet());
    expect(
      missing,
      isEmpty,
      reason:
          'Build each exported widget on a live page of the example: '
          '${missing.toList()..sort()}',
    );
  });
}
