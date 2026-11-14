// ignore_for_file: avoid_relative_lib_imports
// No unstyled text: under a bare WidgetsApp, with nothing but the package's
// theme above it (no Material, no host text style), every paragraph and every
// editable line in every specimen, and in every overlay a part opens (menus,
// dialogs, sheets, pickers, snack bars, tooltips), is set in one of the
// look's faces with a colour, never Flutter's fallback (the yellow double
// underline).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../example/lib/kit_gallery/demos/raised.dart';
import '../example/lib/kit_gallery/kit.dart';

import 'shape_fit_test.dart' show shapeSpecimens;
import 'support.dart';

Set<String> faces(RetroDesktopThemeData theme) => {
  for (final family in [
    theme.typeface.chromeFamily,
    theme.typeface.bodyFamily,
    theme.typeface.monoFamily,
    'Jersey15',
  ])
    retroDesktopFontFamily(family),
};

// The words a render object draws and the style they are set in.
Iterable<(String, TextStyle?)> lines(RenderObject root) sync* {
  final found = <(String, TextStyle?)>[];
  void visit(RenderObject node) {
    if (node is RenderParagraph) {
      found.add((node.text.toPlainText(), node.text.style));
    } else if (node is RenderEditable) {
      found.add((node.text?.toPlainText() ?? '', node.text?.style));
    }
    node.visitChildren(visit);
  }

  visit(root);
  yield* found;
}

void checkStyled(WidgetTester tester, Set<String> allowed, String why) {
  for (final view in tester.binding.renderViews) {
    for (final (words, style) in lines(view)) {
      if (words.trim().isEmpty) continue;
      final family = style?.fontFamily ?? '';
      // Glyph fonts draw icons, not words.
      final glyphs =
          family.toLowerCase().contains('lucide') ||
          family.toLowerCase().contains('icons');
      if (glyphs) continue;
      final reason = '$why: "$words" is set in "$family" ($style)';
      expect(style, isNotNull, reason: reason);
      expect(allowed, contains(family), reason: reason);
      expect(
        style!.color ?? style.foreground?.color,
        isNotNull,
        reason: reason,
      );
      expect(
        style.decorationStyle == TextDecorationStyle.double &&
            style.decorationColor == const Color(0xFFFFFF00),
        isFalse,
        reason: reason,
      );
      expect(
        style.debugLabel ?? '',
        isNot(contains('fallback')),
        reason: reason,
      );
    }
  }
}

void main() {
  setUpAll(loadRetroDesktopFonts);
  for (final brightness in Brightness.values) {
    testWidgets('$brightness: every line wears the look, overlays too', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final theme = RetroDesktopThemeData.classic(brightness);
      kitShownTheme = (b) => RetroDesktopThemeData.classic(b);
      addTearDown(() => kitShownTheme = null);
      final allowed = faces(theme);
      final specimens = <String, Widget Function()>{
        ...shapeSpecimens,
        'kitRaiseLaunchers': kitRaiseLaunchers,
      };
      Future<void> host(String name) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF000000),
            pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, _, _) => builder(context),
            ),
            builder: (context, child) =>
                RetroDesktopTheme(data: theme, child: child!),
            home: name == 'kitSpecimenScreen'
                ? specimens[name]!()
                : SingleChildScrollView(
                    child: KeyedSubtree(
                      key: ValueKey(name),
                      child: specimens[name]!(),
                    ),
                  ),
          ),
        );
        await tester.pump();
      }

      var opened = 0;
      for (final name in specimens.keys) {
        await host(name);
        checkStyled(tester, allowed, name);
        final count = find.byType(RetroDesktopPressable).evaluate().length;
        for (var i = 0; i < count; i++) {
          final press = find.byType(RetroDesktopPressable).at(i);
          if (!tester.any(press)) break;
          final widget = tester.widget<RetroDesktopPressable>(press);
          if (widget.onPressed == null && widget.onLongPress == null) continue;
          final box = tester.getRect(press);
          if (box.isEmpty || box.bottom < 0 || box.top > 1600) continue;
          await tester.tapAt(box.center);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          checkStyled(tester, allowed, '$name after press $i');
          opened++;
          // Start the next press from the specimen as built, overlays shut.
          await host(name);
        }
        expect(tester.takeException(), isNull, reason: name);
      }
      expect(opened, greaterThan(60));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
