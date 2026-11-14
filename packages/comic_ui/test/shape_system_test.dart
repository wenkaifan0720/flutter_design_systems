// The exported-component census and the actual rendered contours agree under
// every Customize choice. Adding an export without a rendered specimen fails.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_parts.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/design_review.dart';
import 'gallery_support.dart';
import 'support.dart';

Set<String> _publicWidgets() => publicComicWidgets();

/// The nearest named widgets above [element], for a failure's reason.
String _owners(Element element) {
  final names = <String>[];
  element.visitAncestorElements((a) {
    final name = a.widget.runtimeType.toString();
    if (!name.startsWith('_')) names.add(name);
    return names.length < 8;
  });
  return names.join(' < ');
}

void _contours(WidgetTester tester, ComicShapes shapes, Set<String> built) {
  final allowed = <OutlinedBorder>[
    shapes.small,
    shapes.medium,
    shapes.large,
    shapes.capsule,
    shapes.full,
    const CircleBorder(),
    // 7: a menu row or a grouped row (rim 3 + their 4 px inset).
    for (final inset in [1.0, 2.0, 2.5, 3.0, 4.0, 5.0, 7.0]) ...[
      comicInsetShape(shapes.small, inset),
      comicInsetShape(shapes.medium, inset),
      comicInsetShape(shapes.large, inset),
    ],
  ].map((s) => s.copyWith(side: BorderSide.none)).toSet();
  for (final element in find.byWidgetPredicate((_) => true).evaluate()) {
    built.add(element.widget.runtimeType.toString().split('<').first);
    final widget = element.widget;
    if (widget is DecoratedBox && widget.decoration is BoxDecoration) {
      final box = widget.decoration as BoxDecoration;
      var dataGeometry = false;
      element.visitAncestorElements((ancestor) {
        if (const {
          'ComicChart',
          'ComicUnits',
          'ComicShares',
          'ComicSegments',
          'ComicProgressCells',
          'ComicPieChart',
        }.contains(ancestor.widget.runtimeType.toString().split('<').first)) {
          dataGeometry = true;
        }
        return true;
      });
      expect(
        dataGeometry ||
            box.shape == BoxShape.circle ||
            box.border == null ||
            !box.border!.isUniform ||
            box.border!.dimensions.horizontal == 0 ||
            box.borderRadius != null,
        isTrue,
        reason:
            'A framed component still draws a hardcoded rectangle: $box in '
            '${_owners(element)}',
      );
    }
    if (widget is DecoratedBox && widget.decoration is ShapeDecoration) {
      final outline = (widget.decoration as ShapeDecoration).shape;
      if (outline is OutlinedBorder) {
        var barePhoto = false;
        element.visitAncestorElements((ancestor) {
          if (ancestor.widget case ComicMedia(bare: true)) barePhoto = true;
          return true;
        });
        expect(
          barePhoto ||
              allowed.contains(outline.copyWith(side: BorderSide.none)),
          isTrue,
          reason:
              '${widget.toStringShort()} ignored the corner theme: $outline',
        );
      }
    }
    if (widget is CustomPaint) {
      final dynamic painter = widget.painter;
      switch (painter?.runtimeType.toString()) {
        case '_SwitchPainter':
          expect(painter.shape, shapes.capsule);
        case '_SliderInk':
          expect(painter.shape, shapes.capsule);
          expect(painter.thumb, shapes.full);
        case '_BarPainter':
          expect(painter.shape, shapes.capsule);
      }
    }
  }
}

Widget _extras(ComicThemeData theme) => MaterialApp(
  home: ComicTheme(
    data: theme,
    child: AnimatedComicTheme(
      data: theme,
      duration: Duration.zero,
      child: SingleChildScrollView(
        child: ComicColumn(
          children: [
            const ComicBackButton(),
            const ComicAutoRow(children: [Text('One'), Text('Two')]),
            ComicBalancedText(
              'A readable line of text',
              style: theme.type.body,
            ),
            ComicSplit(start: const Text('Start'), end: const Text('End')),
            ComicDotsScope(
              child: ComicLetteringScope(
                theme.colors.text,
                child: const Text('Print'),
              ),
            ),
            AnimatedComicShape(
              shape: theme.shapes.small,
              builder: (_, _) => const SizedBox(),
            ),
            const ComicToneMark(ComicTone.success),
            SizedBox(
              height: 200,
              child: ComicTextContextMenu(
                anchors: const TextSelectionToolbarAnchors(
                  primaryAnchor: Offset(100, 100),
                ),
                buttonItems: [
                  ContextMenuButtonItem(label: 'Copy', onPressed: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });
  for (final corners in GalleryCorners.values) {
    for (final mode in Brightness.values) {
      final custom = GalleryCustom(corners: corners);
      final theme = custom.theme('offset', mode);
      final built = <String>{};
      for (final page in galleryPages) {
        testWidgets(
          '${corners.name}/${mode.name}: ${page.id} follows the shape system',
          (tester) async {
            kitShownTheme = (b) => custom.theme('offset', b);
            addTearDown(() => kitShownTheme = null);
            await pumpGalleryPage(tester, page, 'offset', mode);
            expect(tester.takeException(), isNull);
            _contours(tester, theme.shapes, built);
          },
        );
      }
      testWidgets('${corners.name}/${mode.name}: wrappers and editing menu', (
        tester,
      ) async {
        await tester.pumpWidget(_extras(theme));
        await settle(tester);
        _contours(tester, theme.shapes, built);
        await tester.pumpWidget(
          ComicPreview(
            light: theme,
            dark: theme,
            brightness: mode,
            child: const ComicScaffold(body: Text('Preview')),
          ),
        );
        await settle(tester);
        _contours(tester, theme.shapes, built);
        expect(tester.takeException(), isNull);
      });
      test(
        '${corners.name}/${mode.name}: no exported component is missing',
        () {
          final expected = _publicWidgets();
          expect(expected.length, greaterThan(120));
          expect(
            expected.difference(built),
            isEmpty,
            reason:
                'Every new public component needs a rendered shape specimen',
          );
        },
      );
      testWidgets(
        '${corners.name}/${mode.name}: review sheet',
        (tester) async {
          kitShownTheme = (b) => custom.theme('offset', b);
          addTearDown(() => kitShownTheme = null);
          await pumpGalleryPage(
            tester,
            (id: 'review-corners', title: 'Corners', build: reviewCorners),
            'offset',
            mode,
            width: 1000,
          );
          expect(tester.takeException(), isNull);
          // The gallery's app is the package's own MaterialApp (material_ui), which builds a WidgetsApp.
          await expectLater(
            find.byType(WidgetsApp).first,
            matchesGoldenFile(
              'goldens/shapes/${corners.name}_${mode.name}.png',
            ),
          );
        },
        tags: const ['goldens'],
        skip:
            !autoUpdateGoldenFiles &&
            !Directory('test/goldens/shapes').existsSync(),
      );
    }
  }
  test('nested corners subtract the actual inset and stop at zero', () {
    final outer = ComicShapes.rounded(12).medium;
    for (final inset in [0.0, 3.0, 5.0, 20.0]) {
      final inner = comicInsetShape(outer, inset) as RoundedRectangleBorder;
      expect(
        inner.borderRadius.resolve(TextDirection.ltr).topLeft.x,
        (12 - inset).clamp(0, 12),
      );
    }
  });
  testWidgets('the slider paints a circular thumb in both corner families', (
    tester,
  ) async {
    for (final shapes in [const ComicShapes(), ComicShapes.rounded(8)]) {
      final theme = ComicThemeData.offset().copyWith(shapes: shapes);
      const shot = ValueKey('thumb-pixels');
      await tester.pumpWidget(
        MaterialApp(
          home: ComicTheme(
            data: theme,
            child: Center(
              child: RepaintBoundary(
                key: shot,
                child: ColoredBox(
                  color: theme.colors.background,
                  child: SizedBox(
                    width: 240,
                    height: 48,
                    child: ComicSlider(
                      label: 'Volume',
                      quiet: true,
                      value: .5,
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await settle(tester);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(shot),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        Color pixel(int x, int y) {
          final at = (y * image.width + x) * 4;
          return Color.fromARGB(
            bytes.getUint8(at + 3),
            bytes.getUint8(at),
            bytes.getUint8(at + 1),
            bytes.getUint8(at + 2),
          );
        }

        expect(pixel(120, 24), theme.colors.caption);
        expect(
          pixel(110, 14),
          theme.colors.background,
          reason: 'A rectangular thumb fills this corner; a circular thumb leaves it clear',
        );
        image.dispose();
      });
    }
    // Drawn pixels: the rasterizer's, as a golden's (Linux CI leaves it to macOS).
  }, tags: 'goldens');
}
