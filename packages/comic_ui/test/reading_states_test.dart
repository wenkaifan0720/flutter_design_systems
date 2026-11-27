// The gallery's actual navigation specimens and the ink above a live control.
import 'dart:ui' as ui;

import 'package:comic_ui/comic_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// The example exports live specimens only from its own app.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/demos/charts.dart';
import '../example/lib/kit_gallery/demos/chrome.dart';
import '../example/lib/kit_gallery/demos/complete.dart';
import '../example/lib/kit_gallery/demos/inventory.dart';
import '../example/lib/kit_gallery/demos/raised.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'gallery_support.dart';
import 'support.dart';

void main() {
  setUpAll(loadComicFonts);
  for (final dark in [false, true]) {
    testWidgets(
      'Hover and press keep a single ground behind words in ${dark ? 'dark' : 'light'} mode',
      (t) async {
        const key = ValueKey('face');
        await t.pumpWidget(
          comicApp(
            Center(
              child: RepaintBoundary(
                key: key,
                child: ComicButton('Open', onPressed: () {}),
              ),
            ),
            dark: dark,
          ),
        );
        await t.pumpAndSettle();
        final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(key));
        final word = t
            .getRect(find.text('OPEN'))
            .shift(-t.getTopLeft(find.byKey(key)));
        Future<int> ground() async {
          final colors = await t.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final data = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            final pixels = <int>{};
            for (
              var y = (word.center.dy * 2).floor() - 5;
              y < word.center.dy * 2 + 5;
              y++
            ) {
              for (var x = 14; x < 25; x++) {
                pixels.add(data.getUint32((y * image.width + x) * 4));
              }
            }
            image.dispose();
            return pixels;
          });
          return colors!.single;
        }

        final rest = await ground();
        final pointer = await t.createGesture(kind: PointerDeviceKind.mouse);
        await pointer.addPointer(location: Offset.zero);
        addTearDown(pointer.removePointer);
        final center = t.getCenter(find.byType(ComicButton));
        await pointer.moveTo(center);
        await t.pumpAndSettle();
        final hover = await ground();
        expect(hover, isNot(rest));
        await pointer.down(center);
        await t.pump(const Duration(milliseconds: 250));
        await t.pumpAndSettle();
        expect(await ground(), isNot(hover));
        await pointer.up();
      },
      tags: 'goldens',
    );
  }

  const spaced = 'I      I';
  for (final width in [390.0, 1440.0]) {
    for (final (name, specimen, groundOf, fillOf)
        in <
          (
            String,
            Widget,
            Color Function(ComicColors),
            Color Function(ComicColors),
          )
        >[
          (
            'Cover lettering',
            const SizedBox(
              width: 240,
              height: 160,
              child: ComicCoverPrint(
                child: Center(child: ComicLettering(spaced, size: 36)),
              ),
            ),
            (c) => c.cover,
            (c) => c.paper,
          ),
          (
            'Splash title over illustrated art',
            const ComicSplash(title: spaced, art: ComicArtBand(ground: 2)),
            (c) => c.sky,
            (c) => c.paper,
          ),
          if (width == 390)
            (
              'Compact splash title over illustrated art',
              const ComicSplash(
                title: spaced,
                compact: true,
                art: ComicArtBand(ground: 2),
              ),
              (c) => c.sky,
              (c) => c.paper,
            ),
          (
            'Text supplied as an art-band illustration',
            const SizedBox(
              width: 240,
              height: 160,
              child: ComicArtBand(
                ground: 2,
                leading: Text(
                  spaced,
                  style: TextStyle(fontSize: 24, color: Color(0xff080808)),
                ),
              ),
            ),
            (c) => c.artGround(2),
            (c) => const Color(0xff080808),
          ),
          (
            'Step panel sound effect',
            const ComicStepPanel(
              number: '1',
              words: 'First step',
              ground: 2,
              sfx: spaced,
            ),
            (c) => c.artGround(2),
            (c) => c.sfxOn(2),
          ),
        ]) {
      testWidgets('$name keeps the space between the letters plain at $width', (
        t,
      ) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = Size(width, 900);
        addTearDown(t.view.reset);
        const key = ValueKey('illustration');
        await t.pumpWidget(
          comicApp(
            Center(
              child: RepaintBoundary(key: key, child: specimen),
            ),
          ),
        );
        await t.pumpAndSettle();
        final lettering = find.byWidgetPredicate(
          (w) =>
              (w is ComicLettering && w.text == spaced) ||
              (w is Text && w.data == spaced),
        );
        final colors = ComicTheme.of(t.element(lettering)).colors;
        final letter = t.renderObject<RenderBox>(lettering);
        final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(key));
        final bounds = MatrixUtils.transformRect(
          letter.getTransformTo(boundary),
          Offset.zero & letter.size,
        );
        final sample = await t.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final y = (bounds.center.dy * 2).floor();
          final xs = <int>[];
          int pixel(int x, int y) {
            final i = 4 * (image.width * y + x);
            return (data.getUint8(i + 3) << 24) |
                (data.getUint8(i) << 16) |
                (data.getUint8(i + 1) << 8) |
                data.getUint8(i + 2);
          }

          for (var x = (bounds.left * 2).ceil(); x < bounds.right * 2; x++) {
            if (pixel(x, y) == fillOf(colors).toARGB32()) xs.add(x);
          }
          // Sample the artwork between the two painted I glyphs.
          expect(xs, isNotEmpty);
          final middle = (xs.first + xs.last) ~/ 2;
          final result = {
            for (var x = middle - 7; x <= middle + 7; x++)
              for (var row = y - 5; row <= y + 5; row++) pixel(x, row),
          };
          image.dispose();
          return result;
        });
        expect(sample, {groundOf(colors).toARGB32()});
      }, tags: 'goldens');
    }
  }

  testWidgets('Wordless illustrations retain the dots in transparent areas', (
    t,
  ) async {
    const frame = ValueKey('illustrated band');
    const graphic = ValueKey('transparent graphic');
    await t.pumpWidget(
      comicApp(
        const Center(
          child: RepaintBoundary(
            key: frame,
            child: SizedBox(
              width: 240,
              height: 140,
              child: ComicArtBand(
                ground: 2,
                markSize: 80,
                leading: SizedBox(
                  key: graphic,
                  width: 80,
                  height: 80,
                  child: Center(
                    child: SizedBox.square(
                      dimension: 14,
                      child: ColoredBox(color: Color(0xff000000)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(frame));
    final mark = t.renderObject<RenderBox>(find.byKey(graphic));
    final start = mark.localToGlobal(const Offset(4, 4), ancestor: boundary);
    final shades = await t.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final colors = {
        for (var x = start.dx.ceil() * 2; x < start.dx * 2 + 40; x++)
          for (var y = start.dy.ceil() * 2; y < start.dy * 2 + 40; y++)
            data.getUint32(4 * (y * image.width + x)),
      };
      image.dispose();
      return colors;
    });
    expect(shades!.length, greaterThan(1));
  }, tags: 'goldens');

  testWidgets(
    'A pressable tile names its current subtitle unless the caller overrides it',
    (t) async {
      var read = false;
      await t.pumpWidget(
        comicApp(
          StatefulBuilder(
            builder: (context, update) => ComicListTile(
              title: 'Route change',
              subtitle: read ? 'Read' : 'Unread',
              note: 'Platform 2',
              onPressed: () => update(() => read = !read),
            ),
          ),
        ),
      );
      final initial = find.bySemanticsLabel('Route change, Unread');
      expect(t.getSemantics(initial).hint, isEmpty);
      expect(t.getSemantics(initial).value, 'Platform 2');
      await t.tap(find.text('Route change'));
      await t.pumpAndSettle();
      expect(initial, findsNothing);
      expect(find.bySemanticsLabel('Route change, Read'), findsOneWidget);
      await t.pumpWidget(
        comicApp(
          ComicListTile(
            title: 'Route change',
            subtitle: 'Read',
            semanticLabel: 'Open route details',
            onPressed: () {},
          ),
        ),
      );
      expect(find.bySemanticsLabel('Open route details'), findsOneWidget);
    },
  );

  testWidgets('The lower price precedes the upper price at double-size RTL', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(390, 844);
    addTearDown(t.view.reset);
    await t.pumpWidget(
      comicApp(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(2),
          ),
          child: Center(
            child: ComicRangeSlider(
              label: 'Price',
              values: const RawRangeValues(20, 60),
              max: 100,
              valueLabel: (value) => '\$${value.round()}',
              onChanged: (_) {},
            ),
          ),
        ),
        direction: TextDirection.rtl,
      ),
    );
    const caption = r'$20 – $60';
    final paragraph = t.renderObject<RenderParagraph>(
      find.descendant(of: find.text(caption), matching: find.byType(RichText)),
    );
    Rect word(int start, int end) => paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: end),
        )
        .single
        .toRect();
    final lower = word(0, 3), upper = word(6, 9);
    expect(lower.right, lessThan(upper.left));
    expect(lower.top, closeTo(upper.top, .5));
  });

  testWidgets('Wrapped dialog buttons leave room for a keyboard focus ring', (
    t,
  ) async {
    for (final direction in TextDirection.values) {
      await t.pumpWidget(
        comicApp(
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 300, child: kitTryRaised()),
          ),
          direction: direction,
        ),
      );
      await t.pumpAndSettle();
      final faces = find
          .byType(ComicButton)
          .evaluate()
          .map(
            (element) => t.getRect(
              find.byElementPredicate((candidate) => candidate == element),
            ),
          )
          .toList();
      final first = faces.first;
      final next = faces.firstWhere((face) => face.top >= first.bottom);
      expect(next.top - first.bottom, greaterThanOrEqualTo(16));
    }
  });
  testWidgets(
    'Arabic changes visible samples and command names at two times text size',
    (t) async {
      final samples = <(Widget, String)>[
        (kitSpecimenTabs(), 'مقروء'),
        (kitSpecimenLogo(), 'مرحى!'),
        (kitSpecimenMenuBar(), 'ملف'),
        (kitSpecimenCommand(), 'ابحث في الأعداد'),
        (kitSpecimenTally(), 'أيّها تختار؟'),
      ];
      for (final (widget, label) in samples) {
        await t.pumpWidget(
          comicApp(
            KitWords(
              arabic: true,
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(390, 844),
                  textScaler: TextScaler.linear(2),
                ),
                child: SingleChildScrollView(child: widget),
              ),
            ),
            direction: TextDirection.rtl,
          ),
        );
        await t.pumpAndSettle();
        expect(
          find.text(label, findRichText: true).evaluate().isNotEmpty ||
              find
                  .bySemanticsLabel(RegExp(RegExp.escape(label)))
                  .evaluate()
                  .isNotEmpty,
          isTrue,
          reason: label,
        );
      }
    },
  );

  testWidgets(
    'Arabic headers and actions retain display weight in an otherwise English app',
    (t) async {
      await t.pumpWidget(
        comicApp(
          Column(
            children: [
              const ComicAppBar(title: 'المكتبة'),
              const ComicDialog(
                title: 'تفاصيل العدد',
                message: 'احفظ هذا العدد.',
              ),
              ComicButton('حفظ', onPressed: () {}),
              ComicButton('Save', onPressed: () {}),
            ],
          ),
        ),
      );
      for (final word in ['المكتبة', 'تفاصيل العدد', 'حفظ']) {
        expect(
          t.widget<Text>(find.text(word)).style?.fontWeight,
          FontWeight.w700,
          reason: word,
        );
      }
      expect(
        t.widget<Text>(find.text('SAVE')).style?.fontWeight,
        FontWeight.w400,
      );
      // A card, a sheet and a menu bar head in the lettering face too.
      for (final (word, part) in <(String, Widget)>[
        ('الأعداد', const ComicCard(title: 'الأعداد', children: [])),
        ('المرشحات', const ComicSheet(title: 'المرشحات', child: SizedBox())),
        (
          'ملف',
          ComicMenuBar(
            menus: [
              RawMenuEntry(
                label: 'ملف',
                children: [RawMenuEntry(label: 'جديد', onPressed: () {})],
              ),
            ],
          ),
        ),
      ]) {
        await t.pumpWidget(comicApp(Center(child: part)));
        expect(
          t.widget<Text>(find.text(word)).style?.fontWeight,
          FontWeight.w700,
          reason: word,
        );
      }
    },
  );

  // The pointer's tint darkens a page by day; a link's words keep 4.5:1 on it, hovered and pressed, on the page, a
  // card and an inset, in every preset by day and by night (the resting blue fell to 4.0:1 under the tint).
  for (final (preset, b) in presetsAndModes) {
    testWidgets(
      'A hovered or pressed link stays readable in $preset ${b.name}',
      (t) async {
        final c = ComicTheme.preset(preset, b).colors;
        for (final (name, ground) in [
          ('page', c.background),
          ('card', c.card),
          ('inset', c.inset),
        ]) {
          await t.pumpWidget(
            comicApp(
              ColoredBox(
                color: ground,
                child: Center(
                  child: ComicLink('Read this issue', onPressed: () {}),
                ),
              ),
              preset: preset,
              dark: b == Brightness.dark,
            ),
          );
          final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
          await mouse.addPointer(location: Offset.zero);
          await mouse.moveTo(t.getCenter(find.byType(ComicLink)));
          await t.pump(const Duration(milliseconds: 600));
          final link = find.byType(ComicLink);
          expect(
            await inkedContrastFailures(t, within: link),
            isEmpty,
            reason: 'hovered on the $name',
          );
          await mouse.down(t.getCenter(link));
          await t.pump(const Duration(milliseconds: 600));
          expect(
            await inkedContrastFailures(t, within: link),
            isEmpty,
            reason: 'pressed on the $name',
          );
          await mouse.up();
          await mouse.removePointer();
          await t.pump(const Duration(milliseconds: 600));
        }
      },
    );
  }
}
