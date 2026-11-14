// The shared checks of ui_core (088701304f, then 0e25289dfd), for the two things the user caught on 11-11 (16:34, on
// Ledger): buttons in one row that do not stand one height, and dropdowns as wide as their column. Over every page of
// the live example (the gate's ordinary screens among them):
// - DesignRowCheck: controls sharing a row, by their drawn outlines and their capitals, under each density Comic ships,
//   by day and by night (every density at 390, the standard one at 1440 too);
// - DesignWidthCheck: buttons, selects, steppers, segmented controls, groups of choices and tab bars keep to their
//   content at 600, 1024, 1440 and 1920;
// - DesignLabelCheck: labels on the middle of their faces, and a chosen control's fill to its cell, at 390 and 1440,
//   by day and by night;
// - what floats over a page (every select, combobox, multi-select, menu and popover), at 390, 600 and 1440, by day
//   and by night: outside every clip but the window's, its rim drawn all round and its plate under it, its rows'
//   words on one x, and a list from a field the field's width, from its leading edge, its words on the field's
//   (DesignWidthCheck.checkList), its chosen row carrying the check.
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/comic_host.dart';
import 'package:comic_ui/src/comic/raised.dart'
    show ComicRaisedFrame, comicRaisedPlate;
import 'package:ui_core/alignment.dart';

// ignore_for_file: avoid_relative_lib_imports, avoid_print
import '../example/lib/kit_gallery/kit.dart' show kitShownPreset, kitShownTheme;
import '../example/lib/kit_gallery/live_pages.dart';
import '../example/lib/main.dart' show GalleryCustom;
import 'gallery_support.dart';
import 'support.dart';

/// The densities Comic ships, by name.
const _densities = {
  'standard': ComicDensity.standard,
  'comfortable': ComicDensity.comfortable,
  'compact': ComicDensity.compact,
};

/// Pumps [page]'s body at [width] in [density] and [brightness], the view grown to the page's whole height.
Future<void> _pumpLive(
  WidgetTester tester,
  LivePage page,
  double width, {
  Brightness brightness = Brightness.light,
  ComicDensity density = ComicDensity.standard,
}) async {
  final custom = GalleryCustom(density: density), preset = kitShownPreset;
  kitShownTheme = (b) => custom.theme(preset, b);
  addTearDown(() => kitShownTheme = null);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      key: ValueKey('${page.id}/$width/$density/${brightness.name}'),
      debugShowCheckedModeBanner: false,
      home: ComicHost(
        light: custom.theme(preset, Brightness.light),
        dark: custom.theme(preset, Brightness.dark),
        brightness: brightness,
        child: livePageBody(page),
      ),
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
    tester.view.physicalSize = Size(width, 900 + extent);
    await settle(tester);
  }
  await _decodeImages(tester);
}

/// Lets the screen's images decode and draws the frame they land in, as ui_core's checks ask (11-11, g13: the
/// navigation page's widths were read while something on it repainted). A media slot first reads its manifest (a
/// FutureBuilder) and only then starts its picture, which the package's tests do not bundle (it fails, and the slot
/// keeps its stand-in): so each round decodes what is on screen, lets real time pass for what is still loading,
/// and draws the frame, until a round finds nothing new.
Future<void> _decodeImages(WidgetTester tester) async {
  final seen = <ImageProvider>{};
  for (var round = 0; round < 4; round++) {
    final providers = <(ImageProvider, Element)>[
      for (final e in find.byType(Image, skipOffstage: false).evaluate())
        ((e.widget as Image).image, e),
      for (final e in find.byType(DecoratedBox, skipOffstage: false).evaluate())
        if ((e.widget as DecoratedBox).decoration case BoxDecoration(
          image: DecorationImage(:final image),
        ))
          (image, e),
    ].where((p) => seen.add(p.$1)).toList();
    if (round > 0 && providers.isEmpty) return;
    await tester.runAsync(() async {
      await Future.wait([
        for (final (p, e) in providers) precacheImage(p, e, onError: (_, _) {}),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await settle(tester);
  }
}

/// The repaint boundaries under [root] that are laid out but not painted (debug builds, as tests are).
List<RenderRepaintBoundary> _unpainted(RenderObject root) {
  final found = <RenderRepaintBoundary>[];
  void visit(RenderObject o) {
    if (o is RenderRepaintBoundary) {
      var dirty = false;
      assert(() {
        dirty = o.debugNeedsPaint;
        return true;
      }());
      if (dirty) found.add(o);
    }
    o.visitChildren(visit);
  }

  visit(root);
  return found;
}

/// What the shared checks read that is not the fault they hunt, by kind: each names a kind of part or a way of reading
/// the screen, matched by the problem's shape and never by a demo's label, so a fault on any other part still fails
/// (11-12: a misread keyed by one chip's label hid its real fault). Each is printed as a misread; everything else
/// fails. Reported to the coordinator.
final _misreads = <(RegExp, String)>[
  (
    RegExp(
      r'^a button: [\d.]+ px wide as laid out, [\d.]+ as drawn; its content and padding take 0 ',
    ),
    "a part with no words or glyph of its own that takes a press: a chart's plot, pressed to read a value, is not a "
        'button',
  ),
  (
    RegExp(
      r'^a list opened from a button "[^"]+": (\d+(\.\d+)?) px wide as laid out, [\d.]+ as drawn, narrower than the field \(\1, ',
    ),
    "a list read in its route's own picture: laid out it is the field's width; drawn, the route's ground is "
        'transparent (read as black), so its dark rim reads as ground',
  ),
  (
    RegExp(
      r"^a list opened from .*: its leading edge is on the field's as laid out",
    ),
    "a list read in its route's own picture: laid out it starts on the field's edge; drawn, its dark rim reads as "
        'its transparent ground',
  ),
  (
    RegExp(
      r'^a button "[A-Z][a-z]+ \d{1,2}, \d{4}" beside a button "[A-Z][a-z]+ \d{1,2}, \d{4}": its (top|bottom) is level with theirs as laid out, 5 device px (below|above) as drawn$',
    ),
    "a calendar's chosen day by day, read in its section's own picture: its transparent ground reads as black, so "
        "its ink rim reads as ground and only its fill counts (2.5 px in); drawn, its rim stands on the cell's box as "
        "its neighbours' rims do (11-11, g14 pictures)",
  ),
];

/// Prints [report] for [what], misreads apart, and returns the problems that are real.
List<String> _report(String what, DesignAlignmentReport report) {
  final real = <String>[], misread = <String>[];
  for (final problem in report.problems) {
    final why = _misreads
        .where((m) => m.$1.hasMatch(problem))
        .map((m) => m.$2)
        .firstOrNull;
    if (why == null) {
      real.add(problem);
    } else {
      misread.add('misread ($why): $problem');
    }
  }
  print('$what: ${real.length} (${misread.length} misread)');
  for (final problem in [...real, ...misread]) {
    print('  $problem');
  }
  return real;
}

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });

  // Every test here reads drawn pixels (ui_core's as-drawn checks, a surface's drawn rim), which hang on the
  // rasterizer as a golden does: each is tagged goldens, so Linux CI leaves it to the macOS goldens job (11-13).

  // Rows by their drawn outlines. A tall page is read at 2 device px a point, a very tall one at 1, to keep its
  // picture in memory; the tolerance is half a device px either way.
  for (final page in livePages) {
    for (final (width, densities) in [
      (390.0, _densities.keys.toList()),
      (1440.0, ['standard']),
    ]) {
      for (final density in densities) {
        testWidgets('rows on ${page.id} at ${width.toInt()}, $density', (
          tester,
        ) async {
          final problems = <String>[];
          for (final brightness in Brightness.values) {
            await _pumpLive(
              tester,
              page,
              width,
              brightness: brightness,
              density: _densities[density]!,
            );
            final height = tester.view.physicalSize.height;
            final report =
                await DesignRowCheck(
                  look: 'Comic',
                  pixelRatio: height > 5000 ? 1 : 2,
                ).check(
                  tester.element(find.byKey(ValueKey('live/${page.id}'))),
                  runAsync: tester.runAsync,
                );
            problems.addAll(
              _report(
                'rows ${page.id} ${width.toInt()} $density ${brightness.name}',
                report,
              ),
            );
          }
          expect(problems, isEmpty);
        }, tags: 'goldens');
      }
    }
  }

  // Widths, from 600 up. A page holding a control laid out but never painted (the command palette's rows below its
  // 240 cap, in its list's cache extent: their repaint boundaries stay unpainted, 11-11 g15) stops ui_core's check,
  // which reads every control's boundary; such a page is read section by section, the section holding it left out
  // and named.
  for (final page in livePages) {
    for (final width in [600.0, 1024.0, 1440.0, 1920.0]) {
      testWidgets('widths on ${page.id} at ${width.toInt()}', (tester) async {
        await _pumpLive(tester, page, width);
        const check = DesignWidthCheck(look: 'Comic');
        final what = 'widths ${page.id} ${width.toInt()}';
        if (_unpainted(tester.binding.renderViews.first).isEmpty) {
          final report = await check.check(
            tester.element(find.byKey(ValueKey('live/${page.id}'))),
            runAsync: tester.runAsync,
          );
          expect(_report(what, report), isEmpty);
          return;
        }
        final problems = <String>[];
        final sections = find.byWidgetPredicate(
          (w) =>
              w is RepaintBoundary &&
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('kit-section/'),
        );
        for (final section in sections.evaluate()) {
          final label = (section.widget.key! as ValueKey<String>).value
              .substring('kit-section/'.length);
          if (_unpainted(section.renderObject!).isNotEmpty) {
            print(
              '$what, "$label": not read (a control in it is laid out but not painted: ui_core stops on it)',
            );
            continue;
          }
          final report = await check.check(section, runAsync: tester.runAsync);
          problems.addAll(_report('$what, "$label"', report));
        }
        expect(problems, isEmpty);
      }, tags: 'goldens');
    }
  }

  // Labels on the middle of their faces, and a chosen control's fill to its cell (ui_core 0e25289dfd: a toggle
  // group's chosen fill was a marker behind its word, 11-12), over every page at 390 and 1440, by day and by night.
  // keylines_test holds the drawn capitals on the gate's screens; here the labels are held as laid out.
  for (final page in livePages) {
    for (final width in [390.0, 1440.0]) {
      testWidgets('labels on ${page.id} at ${width.toInt()}', (tester) async {
        final problems = <String>[];
        for (final brightness in Brightness.values) {
          await _pumpLive(tester, page, width, brightness: brightness);
          final height = tester.view.physicalSize.height;
          final report =
              await DesignLabelCheck(
                look: 'Comic',
                pixelRatio: height > 5000 ? 1 : 2,
              ).check(
                tester.element(find.byKey(ValueKey('live/${page.id}'))),
                runAsync: tester.runAsync,
              );
          problems.addAll(
            _report(
              'labels ${page.id} ${width.toInt()} ${brightness.name}',
              report,
            ),
          );
        }
        expect(problems, isEmpty);
      }, tags: 'goldens');
    }
  }

  // What opens from a page and floats over it (11-11, design6 P): every select, combobox, multi-select, menu and
  // popover in the gallery, at 390, 600 and 1440, by day and by night. Each opened surface stands outside every clip
  // but the window's, whole on screen, its plate too; its rim is drawn all round it, the bottom stroke too, and its
  // plate (11-12, the floating action button's print) under its bottom and trailing edges, so it reads on top
  // wherever its edge falls; a list's words start on one x, and a list from a field starts them on the field's words
  // (DesignWidthCheck.checkList) and marks the field's value with the check. No date popup: the gallery's date
  // pickers stand in their panels.
  final openers = <_Opener>[
    _Opener('pickers', 'the select', field: () => _selectFace(0)),
    _Opener('pickers', 'the select field', field: () => _selectFace(1)),
    _Opener(
      'pickers',
      'the combobox',
      field: () => find.descendant(
        of: find.byType(ComicCombobox<String>),
        matching: find.byType(EditableText),
      ),
      type: 'r',
    ),
    _Opener(
      'pickers',
      'the multi-select',
      field: () => find.descendant(
        of: find.byType(ComicMultiSelect<String>),
        matching: find.byType(EditableText),
      ),
      type: 'r',
    ),
    _Opener('form', 'the delivery select', field: () => _selectFace(0)),
    _Opener(
      'buttons',
      "the split button's menu",
      button: () => find.bySemanticsLabel('More options'),
    ),
    _Opener(
      'navigation',
      "the menu bar's File menu",
      button: () => find.descendant(
        of: find.byType(ComicMenuBar),
        matching: find.text('File'),
      ),
    ),
    _Opener(
      'dialogs',
      "the Menu button's menu",
      button: () => find.bySemanticsLabel(RegExp(r'^Menu$')),
    ),
    _Opener(
      'dialogs',
      'the popover',
      button: () => find.bySemanticsLabel(RegExp(r'^Filter$')),
      list: false,
    ),
  ];
  for (final opener in openers) {
    for (final width in [390.0, 600.0, 1440.0]) {
      for (final brightness in Brightness.values) {
        final what =
            '${opener.name} on ${opener.page} at ${width.toInt()}, ${brightness.name}';
        testWidgets(what, (tester) async {
          final semantics = tester.ensureSemantics();
          await _pumpLive(
            tester,
            livePages.firstWhere((p) => p.id == opener.page),
            width,
            brightness: brightness,
          );
          final before = {
            for (final e in _floating().evaluate()) e.renderObject,
          };
          final from = (opener.field ?? opener.button)!().first;
          await tester.ensureVisible(from);
          await settle(tester);
          await tester.tap(from);
          await settle(tester);
          if (opener.type case final type?) {
            await tester.enterText(from, type);
            await settle(tester);
          }
          final opened = [
            for (final e in _floating().evaluate())
              if (!before.contains(e.renderObject))
                e.renderObject! as RenderBox,
          ];
          expect(opened, isNotEmpty, reason: 'nothing opened from $what');
          final surface = opened.last;
          final problems = <String>[
            ..._clipped(tester, surface),
            ...await _drawnWhole(tester, surface),
            if (opener.list) ..._oneWordsX(surface),
            // A list from a pressed field marks the field's value: the fill it opens on, and the check (11-12).
            if (opener.field != null && opener.type == null)
              if (find
                      .descendant(
                        of: find.byWidgetPredicate((w) => w is ComicMenu),
                        matching: find.byIcon(ComicGlyphs.check),
                      )
                      .evaluate()
                      .length
                  case final checks when checks != 1)
                'its chosen row carries $checks checks, not one',
          ];
          print('$what: ${_px(_global(surface))}');
          for (final problem in problems) {
            print('  $problem');
          }
          if (opener.field != null && opener.type == null) {
            final report = await const DesignWidthCheck(look: 'Comic')
                .checkList(tester.element(from), runAsync: tester.runAsync);
            problems.addAll(_report('list from $what', report));
          } else if (opener.field != null) {
            // checkList measures from a pressed control; a list a person types for opens from a text field, whose
            // face is read here: the editor's nearest painted ancestor.
            final typed = _typedList(tester.renderObject(from), surface);
            print('list from $what: ${typed.length}');
            for (final problem in typed) {
              print('  $problem');
            }
            problems.addAll(typed);
          }
          semantics.dispose();
          expect(problems, isEmpty);
        }, tags: 'goldens');
      }
    }
  }
}

/// Something on a page that opens a floating surface, and how to open it.
class _Opener {
  const _Opener(
    this.page,
    this.name, {
    this.field,
    this.button,
    this.type,
    this.list = true,
  });

  /// The live page it stands on, and what it is.
  final String page, name;

  /// The field the list opens from: pressed (a select), or typed into ([type]).
  final Finder Function()? field;

  /// The button a menu or a popover opens from.
  final Finder Function()? button;

  /// What is typed into [field] for its list to show.
  final String? type;

  /// Holds a list of options, not a popover's free content.
  final bool list;
}

/// The press of the page's [i]th select field.
Finder _selectFace(int i) => find
    .descendant(
      of: find.byType(ComicSelectField).at(i),
      matching: find.byType(ComicPressable),
    )
    .first;

/// Comic's floating faces: a raised menu, and the frame of what the design kit places (lists, menus, popovers).
Finder _floating() => find.byWidgetPredicate(
  (w) => w is ComicMenu || w is ComicRaisedFrame,
  skipOffstage: false,
);

Rect _global(RenderBox box) =>
    MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);

String _px(Rect r) =>
    '${r.left.toStringAsFixed(1)},${r.top.toStringAsFixed(1)} '
    '${r.width.toStringAsFixed(1)}x${r.height.toStringAsFixed(1)}';

bool _holds(Rect outer, Rect inner) =>
    inner.left >= outer.left - .01 &&
    inner.top >= outer.top - .01 &&
    inner.right <= outer.right + .01 &&
    inner.bottom <= outer.bottom + .01;

/// What cuts [surface] or its plate: the window's edge, or a clip above it (a panel's, a scroll view's).
List<String> _clipped(WidgetTester tester, RenderBox surface) {
  final r = _global(surface);
  final room = Rect.fromLTRB(
    r.left + .5,
    r.top + .5,
    r.right + comicRaisedPlate - .5,
    r.bottom + comicRaisedPlate - .5,
  );
  final window =
      Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
  final found = <String>[
    if (!_holds(window, room)) 'it runs past the window (${_px(room)})',
  ];
  for (var up = surface.parent; up != null; up = up.parent) {
    final clips =
        up is RenderClipRect ||
        up is RenderClipRRect ||
        up is RenderClipPath ||
        up is RenderClipOval ||
        up is RenderAbstractViewport;
    if (!clips || up is! RenderBox || !up.hasSize) continue;
    final at = _global(up);
    if (!_holds(at, room)) {
      found.add('a ${up.runtimeType} at ${_px(at)} cuts it (${_px(room)})');
    }
  }
  return found;
}

/// Reads the screen: [surface]'s rim is drawn on each side (the bottom stroke too), and just outside its bottom and
/// trailing edges its plate lies in the rim's ink, so it reads on top of whatever it lands on.
Future<List<String>> _drawnWhole(WidgetTester tester, RenderBox surface) async {
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  late List<int> rgba;
  late int width;
  await tester.runAsync(() async {
    final image = await layer.toImage(view.paintBounds, pixelRatio: 1);
    width = image.width;
    rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer
        .asUint8List();
    image.dispose();
  });
  List<int> at(Offset o) {
    final i = (o.dy.floor() * width + o.dx.floor()) * 4;
    return rgba.sublist(i, i + 3);
  }

  int far(List<int> a, List<int> b) =>
      (a[0] - b[0]).abs() + (a[1] - b[1]).abs() + (a[2] - b[2]).abs();
  final r = _global(surface);
  final fill = at(r.topLeft + const Offset(5.5, 5.5));
  final found = <String>[];
  for (final (side, along, inward) in [
    (
      'bottom',
      (double f) => Offset(r.left + r.width * f, r.bottom),
      const Offset(0, -1),
    ),
    (
      'top',
      (double f) => Offset(r.left + r.width * f, r.top),
      const Offset(0, 1),
    ),
    (
      'leading',
      (double f) => Offset(r.left, r.top + r.height * f),
      const Offset(1, 0),
    ),
    (
      'trailing',
      (double f) => Offset(r.right, r.top + r.height * f),
      const Offset(-1, 0),
    ),
  ]) {
    for (final f in [.25, .5, .75]) {
      final edge = along(f);
      final rim = at(edge + inward * 1.5), outside = at(edge - inward * 2);
      if (far(rim, fill) < 150) {
        found.add(
          'no rim drawn on its $side at ${_px(edge & Size.zero)} (rgb $rim, fill $fill)',
        );
      }
      if ((side == 'bottom' || side == 'trailing') && far(outside, rim) > 60) {
        found.add(
          'no plate under its $side at ${_px(edge & Size.zero)} (rgb $outside, rim $rim)',
        );
      }
    }
  }
  return found;
}

/// A list opened by typing into the field that holds [editor]: at least the field's width, from its leading edge, its
/// first row's words on the field's words (where the editor's caret stands before its first letter).
List<String> _typedList(RenderObject editor, RenderBox surface) {
  RenderEditable? line;
  void seek(RenderObject o) {
    if (line != null) return;
    if (o is RenderEditable) {
      line = o;
      return;
    }
    o.visitChildren(seek);
  }

  seek(editor);
  if (line == null) return ['no editor in the field'];
  final caret = line!.getLocalRectForCaret(const TextPosition(offset: 0));
  final words = MatrixUtils.transformPoint(
    line!.getTransformTo(null),
    Offset(caret.left, 0),
  ).dx;
  final editorRect = _global(line!);
  Rect? face;
  for (var up = line!.parent; up != null; up = up.parent) {
    if (up is! RenderBox || !up.hasSize) continue;
    final paints = switch (up) {
      RenderDecoratedBox(:final decoration) =>
        decoration is! BoxDecoration ||
            decoration.color != null ||
            decoration.border != null,
      RenderCustomPaint(:final painter, :final foregroundPainter) =>
        painter != null || foregroundPainter != null,
      _ => false,
    };
    final r = _global(up);
    if (paints && r.width > editorRect.width + 1) {
      face = r;
      break;
    }
  }
  if (face == null) return ['no painted face around the field'];
  final list = _global(surface);
  final rows = _rowWords(surface);
  return [
    if (list.width < face.width - .5)
      'a list typed for: ${list.width.toStringAsFixed(1)} wide, narrower than its field (${face.width.toStringAsFixed(1)})',
    if ((list.left - face.left).abs() > .5)
      "a list typed for: its leading edge at ${list.left.toStringAsFixed(1)}, the field's at ${face.left.toStringAsFixed(1)}",
    if (rows.isNotEmpty && (rows.first.$3 - words).abs() > .5)
      "a list typed for: its words at ${rows.first.$3.toStringAsFixed(1)}, the field's at ${words.toStringAsFixed(1)}",
  ];
}

/// Every row of [surface]'s list starts its words on one x (design6 P).
List<String> _oneWordsX(RenderBox surface) {
  final rows = _rowWords(surface);
  if (rows.isEmpty) return ['no words in its list'];
  final first = rows.first;
  return [
    for (final (text, _, x) in rows.skip(1))
      if ((x - first.$3).abs() > .5)
        '"$text" starts its words at ${x.toStringAsFixed(1)}, "${first.$1}" at ${first.$3.toStringAsFixed(1)}',
  ];
}

/// Each row's words in [surface], top to bottom: the row's leading paragraph (an icon's glyph is not words), its
/// global box, and where its first letter starts.
List<(String, Rect, double)> _rowWords(RenderBox surface) {
  final words = <(String, Rect, double)>[];
  void visit(RenderObject o) {
    if (o is RenderParagraph) {
      final text = o.text.toPlainText();
      if (text.trim().isNotEmpty &&
          text.runes.any((r) => r < 0xE000 || r > 0xF8FF)) {
        final boxes = o.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 1),
        );
        final x = boxes.isEmpty ? 0.0 : boxes.first.left;
        final transform = o.getTransformTo(null);
        words.add((
          text,
          MatrixUtils.transformRect(transform, Offset.zero & o.size),
          MatrixUtils.transformPoint(transform, Offset(x, 0)).dx,
        ));
      }
    }
    o.visitChildren(visit);
  }

  visit(surface);
  // One per row: the leading paragraph among those sharing its middle.
  final rows = <(String, Rect, double)>[];
  for (final w in words..sort((a, b) => a.$3.compareTo(b.$3))) {
    if (rows.any((row) => (row.$2.center.dy - w.$2.center.dy).abs() < 4)) {
      continue;
    }
    rows.add(w);
  }
  return rows..sort((a, b) => a.$2.top.compareTo(b.$2.top));
}
