// The label sweep (ui_core's DesignLabelCheck): every gallery page under each density Frosted ships by name, standard
// and compact, each labelled control's label and icon read off the middle of its face, as laid out and as drawn. A
// control centred under one density and not the other fails under that one's name. Harbor's screens are swept in
// harbor_test.dart.
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:ui_core/alignment.dart';

import 'gallery_support.dart';

// The gallery is the example app; a test sets the theme it shows.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';

const _densities = {
  'standard': FrostedDensity.standard,
  'compact': FrostedDensity.compact,
};

const _screen = ValueKey('label-sweep');

/// Pages whose sweep still misreads on macOS on ui_core 0.2.0, skipped: it
/// reads a label 0.5-0.9 device px off its face's middle, which ui_core's own
/// sweep of the gallery does not report.
const _misread = {
  'command': 'ui_core misread, 0.2.0 design-sweep reads: label middles',
  'menu': 'ui_core misread, 0.2.0 design-sweep reads: label middles',
  'preview': 'ui_core misread, 0.2.0 design-sweep reads: label middles',
  'structure': 'ui_core misread, 0.2.0 design-sweep reads: label middles',
};

/// Readings set aside on a page, each proven to one control in one state,
/// while ui_core's DesignLabelCheck misreads it: the line the check gives,
/// the words of the filter chips it reads them in, and the chips' state.
///
/// ui_core 0.2.0 reads the live filter chips' "Money in" capitals 30.1
/// device px high where their DesignCapCenter gives 25.2 (the chips checked
/// on their own give it; the turned-off ones beside them do not). They are
/// drawn as the turned-off chips' and "Money out"'s are (the M's top on the
/// same pixel row), and the reading follows the chip's x alone: with the
/// chips' least width at 46, 47, 47.5 or 48.5 it reads true, at 48, 49, 50
/// or 52 it does not.
const _setAside = {
  'selection': (
    line:
        'a button "Money in": the capitals of "Money in" are drawn 30.1 '
        'device px high; its DesignCapCenter\'s capHeightFactor gives 25.2',
    words: 'Money in',
    frozen: false,
  ),
};

/// [problems] less each line in [_setAside] for [page], as many times as
/// the chips it names give it when checked on their own in that state; a
/// chip in the other state that gives it keeps it. (The gallery's filter
/// chips choose strings; a generic match would read `onChanged` through a
/// covariant type.)
Future<List<String>> _lessSetAside(
  WidgetTester tester,
  String page,
  List<String> problems,
) async {
  final aside = _setAside[page];
  if (aside == null || !problems.contains(aside.line)) return problems;
  var times = 0;
  for (final chips
      in find
          .byWidgetPredicate(
            (w) =>
                w is FrostedFilterChipGroup<String> &&
                (w.onChanged == null) == aside.frozen &&
                w.options.any((o) => o.label == aside.words),
          )
          .evaluate()) {
    final own = await const DesignLabelCheck(
      look: 'Frosted',
      drawnTolerance: 0.5,
    ).check(chips, runAsync: tester.runAsync);
    times += own.problems.where((p) => p == aside.line).length;
  }
  final left = [...problems];
  for (var i = 0; i < times; i++) {
    left.remove(aside.line);
  }
  return left;
}

/// Lets images decode (they load in real time), then paints the frame they
/// mark, so a check that reads pixels finds every boundary painted.
Future<void> _painted(WidgetTester tester) async {
  await tester.runAsync(
    () => Future.wait([
      for (final e in find.byType(Image).evaluate())
        precacheImage((e.widget as Image).image, e),
    ]),
  );
  await tester.pump();
}

/// Every family the package's FontManifest.json lists (its faces and the
/// glyphs' Lucide), under the manifest's name and the package's: a check
/// fails, by name, on a control drawn in the test's own font.
Future<void> _fonts() async {
  final manifest = (json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>).cast<Map<String, dynamic>>();
  for (final family in manifest) {
    final name = family['family'] as String;
    final fonts = (family['fonts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    for (final alias in [
      name,
      if (!name.startsWith('packages/')) 'packages/frosted_ui/$name',
    ]) {
      final loader = FontLoader(alias);
      for (final font in fonts) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  }
}

void main() {
  setUpAll(_fonts);

  for (final page in galleryPages) {
    testWidgets(
      '${page.id}: every label on its face\'s middle, standard '
      'and compact',
      (tester) async {
        addTearDown(() => kitShownTheme = null);
        addTearDown(tester.view.reset);
        tester.view.devicePixelRatio = 1;
        final problems = <String>[];
        for (final MapEntry(key: name, value: density) in _densities.entries) {
          kitShownTheme = (b) => FrostedThemeData.preset(
            kitShownPreset,
            b,
          ).copyWith(density: density);
          tester.view.physicalSize = const Size(galleryWidth, 844);
          await tester.pumpWidget(
            RepaintBoundary(
              key: _screen,
              child: KeyedSubtree(
                key: ValueKey('${page.id}/$name'),
                child: page.build(Brightness.light),
              ),
            ),
          );
          await settle(tester);
          // The whole page on screen at once, as the gallery tests grow it.
          final scrollables = tester
              .stateList<ScrollableState>(find.byType(Scrollable))
              .where((s) => s.position.axis == Axis.vertical);
          final extent = scrollables.isEmpty
              ? 0.0
              : scrollables.first.position.maxScrollExtent;
          if (extent > 0) {
            tester.view.physicalSize = Size(galleryWidth, 844 + extent);
            await settle(tester);
          }
          await _painted(tester);
          final report =
              await const DesignLabelCheck(
                look: 'Frosted',
                drawnTolerance: 0.5,
              ).check(
                tester.element(find.byKey(_screen)),
                runAsync: tester.runAsync,
              );
          final read = await _lessSetAside(tester, page.id, report.problems);
          problems.addAll([for (final p in read) '$name · $p']);
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
      },
      // The check reads drawn pixels, which depend on the rasterizer as a
      // golden does.
      tags: const ['goldens'],
      skip: _misread.containsKey(page.id),
    );
  }
}
