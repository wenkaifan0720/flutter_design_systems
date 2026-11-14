// ui_core's shared checks for the two faults the user caught on 11-11 (buttons in one row showing different heights,
// dropdowns spanning a wide page), over every page of the example app, in Platinum and Chisel:
// - DesignRowCheck: controls sharing a row show one top and one bottom by their drawn outlines, at 390 and 1440, under
//   each density, by day and by night;
// - DesignWidthCheck: from 600 up a select, a button, a stepper and a segmented control keep to their content and
//   padding, at most 320, at 600, 1024, 1440 and 1920;
// - checkList: every select opened at 390 and 1440, its list at least its field's width, on its leading edge, its words
//   on the field's.
// What a check misreads on these screens is named by kind, with its reason, in misreads.dart; the rest must be empty.
// ignore_for_file: avoid_relative_lib_imports
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:ui_core/alignment.dart';

import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'misreads.dart';
import 'support.dart';

const _look = 'Retro Desktop';

/// The view's device pixel ratio: the checks' own.
const _ratio = 3.0;

/// Pumps [page] [width] wide in [appearance] (and [density], else the one the
/// width ships), as the example app shows it (no sample menu bar), grows the
/// view to the page's height (at most [tallest]), decodes its images and,
/// when [still], stops its tickers (a spinner would repaint while its pixels
/// are read).
Future<void> _show(
  WidgetTester tester,
  ExamplePage page, {
  required double width,
  required RetroDesktopAppearance appearance,
  required Brightness brightness,
  RetroDesktopDensity? density,
  double tallest = 16000,
  bool still = true,
}) async {
  final ticking = ValueNotifier(true);
  addTearDown(ticking.dispose);
  kitShownChrome = false;
  kitShownTheme = (b) => RetroDesktopThemeData.preset(
    kitShownPreset,
    b,
  ).copyWith(appearance: appearance, density: density);
  // At the checks' own pixel ratio, 3: the look's painters draw their faces
  // on the view's device pixels, and at 1 a face standing on a fractional
  // logical y moved up to a whole pixel against its words, which the checks
  // read on a grid three times as fine.
  tester.view.devicePixelRatio = _ratio;
  tester.view.physicalSize = Size(width, 900) * _ratio;
  await tester.pumpWidget(
    KeyedSubtree(
      key: ValueKey(
        '${page.name}/$width/${appearance.name}/${brightness.name}/'
        '${density?.name}',
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: ticking,
        builder: (context, on, child) => TickerMode(enabled: on, child: child!),
        child: page.build(brightness),
      ),
    ),
  );
  await settle(tester);
  // The whole page on screen (a lazy list's length firms up as it lays more
  // out): a part laid out past the screen's foot is never painted, and the
  // checks refuse a picture that was never painted ("All components" ran past
  // 3200 and could not be read).
  for (var i = 0; i < 6; i++) {
    final scrollables = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .where((s) => s.position.axis == Axis.vertical);
    final extent = scrollables.isEmpty
        ? 0.0
        : scrollables.first.position.maxScrollExtent;
    final height = tester.view.physicalSize.height / _ratio;
    if (extent <= 0 || height >= tallest) {
      if (extent > 0) {
        debugPrint('SHOWN ${page.name} at $width: $extent past $tallest');
      }
      break;
    }
    tester.view.physicalSize =
        Size(width, (height + extent).clamp(900, tallest)) * _ratio;
    await settle(tester);
  }
  // Every image the page draws, decoded before it is read: an Image's, and a
  // decoration's (an avatar's, a card's cover), which decode on their own.
  await tester.runAsync(() async {
    final pending = <Future<void>>[];
    void take(ImageProvider provider, Element e) =>
        pending.add(precacheImage(provider, e, onError: (_, _) {}));
    void decorated(Decoration? d, Element e) {
      final image = switch (d) {
        BoxDecoration(:final image) => image,
        ShapeDecoration(:final image) => image,
        _ => null,
      };
      if (image != null) take(image.image, e);
    }

    for (final e in find.byType(Image).evaluate()) {
      take((e.widget as Image).image, e);
    }
    for (final e in find.byType(DecoratedBox).evaluate()) {
      decorated((e.widget as DecoratedBox).decoration, e);
    }
    for (final e in find.byType(Container).evaluate()) {
      decorated((e.widget as Container).decoration, e);
    }
    await Future.wait(pending);
  });
  await tester.pump();
  if (still) {
    ticking.value = false;
    await tester.pump();
    await tester.pump();
  }
}

/// [check]'s problems; read again, up to four times, if the screen changed
/// while it was read: an image still decoding (a decoration's, an avatar's,
/// which the page's Image precache does not reach) is given real time to
/// finish, then a frame.
Future<List<String>> _read(
  WidgetTester tester,
  Future<DesignAlignmentReport> Function() check,
) async {
  for (var attempt = 0; ; attempt++) {
    try {
      return (await check()).problems;
    } on StateError catch (e) {
      if (attempt == 4) {
        return ['could not be read: ${e.message.split('\n').first}'];
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
    }
  }
}

void main() {
  setUpAll(() async {
    await loadRetroDesktopFonts();
    await loadRetroDesktopGlyphFace();
    await loadRetroDesktopManifestFonts();
  });
  tearDown(() {
    kitShownTheme = null;
    kitShownChrome = true;
  });

  for (final appearance in RetroDesktopAppearance.values) {
    for (final brightness in Brightness.values) {
      testWidgets('rows: ${appearance.name} ${brightness.name}, every page '
          'shows one top and one bottom across each row', (tester) async {
        addTearDown(tester.view.reset);
        final problems = <String>[];
        for (final width in const [390.0, 1440.0]) {
          for (final density in RetroDesktopDensity.values) {
            var count = 0;
            for (final page in examplePages) {
              await _show(
                tester,
                page,
                width: width,
                appearance: appearance,
                brightness: brightness,
                density: density,
              );
              final found = await _read(
                tester,
                () => const DesignRowCheck(
                  look: _look,
                ).check(tester.binding.rootElement!, runAsync: tester.runAsync),
              );
              for (final p in found) {
                count++;
                final line = '$width ${density.name} ${page.name}: $p';
                debugPrint('ROWP ${appearance.name} ${brightness.name} $line');
                problems.add(line);
              }
            }
            debugPrint(
              'ROWCHECK ${appearance.name} ${brightness.name} $width '
              '${density.name}: $count',
            );
          }
        }
        final real = withoutMisreads('rows', problems, [
          ...rowMisreads,
          if (appearance == RetroDesktopAppearance.chisel) ...chiselRowMisreads,
        ]);
        expect(real, isEmpty, reason: real.join('\n'));
      }, tags: const ['goldens']);
    }

    testWidgets('widths: ${appearance.name}, from 600 up every select, button, '
        'stepper and segmented control keeps to its content', (tester) async {
      addTearDown(tester.view.reset);
      final problems = <String>[];
      for (final width in const [600.0, 1024.0, 1440.0, 1920.0]) {
        var count = 0;
        for (final page in examplePages) {
          await _show(
            tester,
            page,
            width: width,
            appearance: appearance,
            brightness: Brightness.light,
          );
          final found = await _read(
            tester,
            () => const DesignWidthCheck(look: _look)
                .check(tester.binding.rootElement!, runAsync: tester.runAsync),
          );
          for (final p in found) {
            count++;
            final line = '$width ${page.name}: $p';
            debugPrint('WIDP ${appearance.name} $line');
            problems.add(line);
          }
        }
        debugPrint('WIDTHS ${appearance.name} $width: $count');
      }
      final real = withoutMisreads('widths', problems, widthMisreads);
      expect(real, isEmpty, reason: real.join('\n'));
    }, tags: const ['goldens']);

    testWidgets('lists: ${appearance.name}, every select\'s list is at least '
        'its field, on its leading edge', (tester) async {
      addTearDown(tester.view.reset);
      final problems = <String>[];
      final selects = find.byWidgetPredicate(
        (w) => w.runtimeType.toString().startsWith('RetroDesktopSelect<'),
      );
      for (final width in const [390.0, 1440.0]) {
        var count = 0, opened = 0;
        for (final page in examplePages) {
          await _show(
            tester,
            page,
            width: width,
            appearance: appearance,
            brightness: Brightness.light,
            still: false,
            // A screen's height: each select is scrolled into view and
            // opened there (a page shown whole, 16000 tall, scrolled under
            // an open list and asserted).
            tallest: 3200,
          );
          final n = selects.evaluate().length;
          for (var i = 0; i < n; i++) {
            final field = selects.at(i);
            final press = find
                .descendant(
                  of: field,
                  matching: find.byType(RetroDesktopPressable),
                )
                .first;
            if (press.evaluate().isEmpty) continue;
            await tester.ensureVisible(press);
            await settle(tester);
            await tester.tap(press, warnIfMissed: false);
            await settle(tester);
            opened++;
            final report = await const DesignWidthCheck(look: _look)
                .checkList(tester.element(field), runAsync: tester.runAsync);
            // What opened, when the check finds no list: a menu or none.
            final menus = find.byWidgetPredicate(
              (w) => w.runtimeType.toString().startsWith('RetroDesktopMenu<'),
            );
            final shown = menus.evaluate().isEmpty
                ? 'no menu on screen'
                : 'a menu at ${tester.getRect(menus.first)}, the field at '
                      '${tester.getRect(field)}';
            for (final p in report.problems) {
              count++;
              final line =
                  '$width ${page.name} select ${i + 1}: $p'
                  '${p.startsWith('no list') ? ' ($shown)' : ''}';
              debugPrint('LISTP ${appearance.name} $line');
              problems.add(line);
            }
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await settle(tester);
          }
        }
        debugPrint('LISTS ${appearance.name} $width: $count of $opened');
      }
      final real = withoutMisreads(
        'lists',
        problems,
        appearance == RetroDesktopAppearance.chisel ? chiselListMisreads : [],
      );
      expect(real, isEmpty, reason: real.join('\n'));
    }, tags: const ['goldens']);
  }
}
