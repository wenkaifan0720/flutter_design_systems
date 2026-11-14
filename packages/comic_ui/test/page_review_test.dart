// What the coordinator saw in the release web build in a browser (11-12, on 562f34f5f7), each held on the live
// example's own page, by day and by night:
// 1. a toggle group's chosen fill covers its whole cell, as the segmented control's does;
// 2. from 600 up a stepper and one-line choices keep to their content, never their column;
// 3. chips in one row stand one height, a chip with its remove cross among them;
// 4. a link starts on its column's edge;
// 5. (the select field's list carries the check: shared_checks_test's openers)
// 6. a dialog's actions stand at its trailing end, the confirming act last, inline and raised;
// 7. a floating action button's print is in its rim's ink, as the raised plate is (light by night).
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/comic_host.dart';
import 'package:comic_ui/src/comic/internal/track.dart'
    show ComicTrack, ComicTrackFace;

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart' show kitShownPreset, kitShownTheme;
import '../example/lib/kit_gallery/live_pages.dart';
import '../example/lib/main.dart' show GalleryCustom;
import 'gallery_support.dart';
import 'support.dart';

/// Pumps the live page [id] at [width] by [brightness], the view grown to the page's whole height.
Future<void> _pumpLive(
  WidgetTester tester,
  String id,
  double width,
  Brightness brightness,
) async {
  final custom = GalleryCustom(), preset = kitShownPreset;
  kitShownTheme = (b) => custom.theme(preset, b);
  addTearDown(() => kitShownTheme = null);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
  final page = livePages.firstWhere((p) => p.id == id);
  await tester.pumpWidget(
    MaterialApp(
      key: ValueKey('$id/$width/${brightness.name}'),
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
}

/// The gallery section labelled [label].
Finder _section(String label) => find.byKey(ValueKey('kit-section/$label'));

/// A chip's drawn face: its largest filled outline.
Rect _chipFace(WidgetTester tester, Element chip) {
  Rect? face;
  for (final box
      in find
          .descendant(
            of: find.byElementPredicate((e) => e == chip),
            matching: find.byType(DecoratedBox),
          )
          .evaluate()) {
    final decoration = (box.widget as DecoratedBox).decoration;
    if (decoration is! ShapeDecoration || decoration.color == null) continue;
    final rect = tester.getRect(find.byElementPredicate((e) => e == box));
    if (face == null || rect.height * rect.width > face.height * face.width) {
      face = rect;
    }
  }
  return face!;
}

String _px(Rect r) =>
    '${r.left.toStringAsFixed(1)},${r.top.toStringAsFixed(1)} '
    '${r.width.toStringAsFixed(1)}x${r.height.toStringAsFixed(1)}';

/// The dialog [dialog]'s actions: at its trailing end (the act's end on its content's), the quiet one before the act.
List<String> _actionsAtEnd(WidgetTester tester, Finder dialog, String what) {
  final found = <String>[];
  final acts = find.descendant(
    of: dialog,
    matching: find.byWidgetPredicate((w) => '${w.runtimeType}' == '_Filled'),
  );
  if (acts.evaluate().length != 1) {
    return [
      '$what: ${acts.evaluate().length} act buttons, not one (the confirming action is the act)',
    ];
  }
  final act = tester.getRect(acts);
  final content = tester.getRect(
    find.descendant(of: dialog, matching: find.byType(ComicColumn)).first,
  );
  if ((act.right - content.right).abs() > 1) {
    found.add(
      "$what: the act ends at ${act.right.toStringAsFixed(1)}, not the content's end ${content.right.toStringAsFixed(1)}",
    );
  }
  for (final e
      in find
          .descendant(
            of: dialog,
            matching: find.byWidgetPredicate(
              (w) => '${w.runtimeType}' == '_Action',
            ),
          )
          .evaluate()) {
    final quiet = tester.getRect(find.byElementPredicate((x) => x == e));
    if (quiet.right > act.left + .5) {
      found.add(
        '$what: a quiet action (${_px(quiet)}) stands after the act (${_px(act)})',
      );
    }
  }
  return found;
}

/// Where each example on the pumped page first draws, against its section's leading edge: the section's own picture
/// (each is a repaint boundary, transparent where nothing is drawn) read below its label, at twice the size. A section
/// whose example starts more than [tolerance] in (a glyph's side bearing) is named with where it starts, and so is
/// each press laid out at the column's start (a loose tick, a radio's row, a rating's first star, a pager's first dot,
/// quiet words, a trail's first step) whose face starts in from it: a least target pads outward, never moving the
/// face (11-12 item 1).
// Examples that start in from their column by design, each with the reason; everything else starts on it.
const _insetByDesign = {
  'An error': 'a state stands centred in its room',
  'Empty': 'a state stands centred in its room',
  'Loading': 'a state stands centred in its room',
  'A mark': "the art's own margin inside its box",
  'A portrait': "the art's own margin inside its box",
  'A pop': "the burst's points inside its box",
  'The burst, one a screen': "the burst's points inside its box",
  'A donut': "the ring keeps room for its pulled-out slice, its figure in the ring's middle",
};

// On a phone the quiet button spans the column, its words centred, as every stacked action.
const _insetOnPhone = {'Quiet'};

Future<List<String>> _offEdge(
  WidgetTester tester,
  String at, {
  double tolerance = 2.5,
}) async {
  final problems = <String>[];
  final sections = find
      .byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('kit-section/'),
      )
      .evaluate()
      .toList();
  for (final e in sections) {
    final name = (e.widget.key! as ValueKey<String>).value.substring(12);
    final phone =
        tester.view.physicalSize.width / tester.view.devicePixelRatio < 600;
    final boundary = e.renderObject! as RenderRepaintBoundary;
    final section = tester.getRect(find.byElementPredicate((x) => x == e));
    final label = tester.getRect(
      find
          .descendant(
            of: find.byElementPredicate((x) => x == e),
            matching: find.byType(ComicLabel),
          )
          .first,
    );
    const scale = 2.0;
    final pixels = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: scale);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final w = image.width, h = image.height;
      image.dispose();
      return (data!, w, h);
    });
    final (data, w, h) = pixels!;
    final from = ((label.bottom - section.top + 1) * scale).ceil();
    var first = w;
    // A rule's ink is translucent (16 % of the ink): read anything an eighth opaque.
    for (var y = from; y < h; y++) {
      for (var x = 0; x < first; x++) {
        if (data.getUint8((y * w + x) * 4 + 3) > 32) {
          first = x;
          break;
        }
      }
    }
    final presses = find
        .descendant(
          of: find.byElementPredicate((x) => x == e),
          matching: find.byType(ComicPressable),
        )
        .evaluate();
    for (final press in presses) {
      final box = press.renderObject;
      if (box is! RenderBox || !box.hasSize || !box.attached) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      // A press across the whole column (a phone's stacked actions) centres its words by design, and a month's day
      // keeps its number centred in the grid's cell.
      if (rect.width >= section.width - 1 ||
          find
              .ancestor(
                of: find.byElementPredicate((x) => x == press),
                matching: find.byType(ComicDatePicker),
              )
              .evaluate()
              .isNotEmpty) {
        continue;
      }
      if (rect.left > section.left + 0.5 ||
          rect.right <= section.left ||
          rect.top >= section.bottom ||
          rect.bottom <= section.top + label.bottom - section.top + 1) {
        continue;
      }
      final top = math.max(from, ((rect.top - section.top) * scale).ceil());
      final bottom = math.min(h, ((rect.bottom - section.top) * scale).floor());
      final right = math.min(w, ((rect.right - section.left) * scale).floor());
      var own = right;
      for (var y = top; y < bottom; y++) {
        for (var x = 0; x < own; x++) {
          if (data.getUint8((y * w + x) * 4 + 3) > 128) {
            own = x;
            break;
          }
        }
      }
      if (own == right) continue;
      if (own / scale > tolerance) {
        problems.add(
          '$name at $at: "${(press.widget as ComicPressable).label}" is laid out at its column\'s start and draws '
          '${(own / scale).toStringAsFixed(1)} px in',
        );
      }
    }
    if (first == w ||
        _insetByDesign.containsKey(name) ||
        (phone && _insetOnPhone.contains(name))) {
      continue;
    }
    final inset = first / scale;
    if (inset > tolerance) {
      problems.add(
        '$name at $at: its example starts ${inset.toStringAsFixed(1)} px in from its column\'s edge '
        '(${section.left.toStringAsFixed(1)})',
      );
    }
  }
  return problems;
}

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });

  for (final width in [390.0, 600.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      final at = '${width.toInt()}, ${brightness.name}';

      testWidgets('a toggle group fills its chosen cell at $at', (
        tester,
      ) async {
        await _pumpLive(tester, 'buttons', width, brightness);
        final lit = find.descendant(
          of: find.byWidgetPredicate((w) => w is ComicToggleGroup),
          matching: find.byWidgetPredicate(
            (w) => w is ComicTrackFace && w.fill != null,
          ),
        );
        expect(lit, findsWidgets);
        for (final e in lit.evaluate()) {
          final face = e.widget as ComicTrackFace;
          final cell = tester.getRect(find.byElementPredicate((x) => x == e));
          final fill = tester.getRect(
            find
                .descendant(
                  of: find.byElementPredicate((x) => x == e),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          // The fill stands the trough's gap in from the cell's sides and the rim and the gap in from its top and
          // bottom, as the segmented control's thumb does.
          final inset = face.gap + 3;
          expect(
            fill.width >= cell.width - 2 * face.gap - .5 &&
                fill.height >= cell.height - 2 * inset - .5,
            isTrue,
            reason: 'the chosen fill ${_px(fill)} in its cell ${_px(cell)}',
          );
        }
      });

      testWidgets('chips stand one height at $at', (tester) async {
        await _pumpLive(tester, 'selection', width, brightness);
        final chips = find.descendant(
          of: _section('Chips'),
          matching: find.byType(ComicChip),
        );
        final faces = [for (final e in chips.evaluate()) _chipFace(tester, e)];
        expect(faces.length, greaterThanOrEqualTo(4));
        final heights = {for (final f in faces) f.height.toStringAsFixed(1)};
        expect(heights, hasLength(1), reason: 'chip faces ${faces.map(_px)}');
        // The remove cross's glyph stands inside its chip's face, and its press is centred on the face.
        final removable = find.byWidgetPredicate(
          (w) => w is ComicChip && w.onDeleted != null,
        );
        final glyph = tester.getRect(
          find.descendant(of: removable, matching: find.byIcon(ComicGlyphs.x)),
        );
        final press = tester.getRect(
          find.descendant(of: removable, matching: find.byType(ComicPressable)),
        );
        final face = faces.firstWhere(
          (f) => f.inflate(.5).contains(glyph.center),
          orElse: () => Rect.zero,
        );
        expect(
          face.inflate(.5).contains(glyph.topLeft) &&
              face.inflate(.5).contains(glyph.bottomRight) &&
              (press.center.dy - face.center.dy).abs() < .5,
          isTrue,
          reason:
              'the cross ${_px(glyph)}, its press ${_px(press)}, among ${faces.map(_px)}',
        );
      });

      testWidgets('a link starts on its column at $at', (tester) async {
        await _pumpLive(tester, 'buttons', width, brightness);
        final column = tester.getRect(_section('A link'));
        final words = tester.getRect(find.text('Read this issue'));
        expect(
          (words.left - column.left).abs(),
          lessThan(.5),
          reason: 'the link ${_px(words)} in its column ${_px(column)}',
        );
      });

      testWidgets("a dialog's actions stand at its end at $at", (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpLive(tester, 'dialogs', width, brightness);
        final problems = _actionsAtEnd(
          tester,
          find.byType(ComicDialog).first,
          'the page\'s dialog',
        );
        final open = find.bySemanticsLabel(RegExp(r'^Dialog$')).first;
        await tester.ensureVisible(open);
        await settle(tester);
        await tester.tap(open);
        await settle(tester);
        expect(find.byType(ComicDialog), findsNWidgets(2));
        problems.addAll(
          _actionsAtEnd(
            tester,
            find.byType(ComicDialog).last,
            'the raised dialog',
          ),
        );
        semantics.dispose();
        expect(problems, isEmpty);
      });

      // The coordinator, 11-12 (design6 P): an example starts on its column's edge with its drawn face; a least target
      // pads outward, hit-tested only, and never moves the face.
      if (width == 1440 || brightness == Brightness.light) {
        for (final page in livePages) {
          testWidgets('${page.id}: every example starts on its column at $at', (
            tester,
          ) async {
            await _pumpLive(tester, page.id, width, brightness);
            final problems = await _offEdge(tester, at);
            for (final problem in problems) {
              debugPrint(problem);
            }
            expect(problems, isEmpty);
            // The drawn face is read from pixels: the rasterizer's, as a golden's (Linux CI leaves it to macOS).
          }, tags: 'goldens');
        }
      }

      if (width >= 600) {
        testWidgets('a stepper and choices keep to their content at $at', (
          tester,
        ) async {
          await _pumpLive(tester, 'selection', width, brightness);
          final problems = <String>[];
          final column = tester.getRect(_section('A count'));
          final track = tester.getRect(
            find
                .descendant(
                  of: find.byType(ComicNumberField).first,
                  matching: find.byType(ComicTrack),
                )
                .first,
          );
          // Less and more at most a touch target square each, the count at most 140 between them, the rim round.
          if (track.width > 2 * 48 + 140 + 6) {
            problems.add(
              'the stepper ${_px(track)} spans its column ${_px(column)}',
            );
          }
          for (final e
              in find
                  .descendant(
                    of: find.byType(ComicChoices),
                    matching: find.byType(ComicChoiceBox),
                  )
                  .evaluate()) {
            final box = tester.getRect(find.byElementPredicate((x) => x == e));
            final words = tester.getRect(
              find
                  .descendant(
                    of: find.byElementPredicate((x) => x == e),
                    matching: find.byType(Text),
                  )
                  .first,
            );
            // Its words, on a text field's keyline either side.
            if (box.width > words.width + 2 * 18.5 + 6) {
              problems.add(
                'a choice ${_px(box)} is wider than its words ${_px(words)}',
              );
            }
          }
          for (final problem in problems) {
            debugPrint(problem);
          }
          expect(problems, isEmpty);
        });
      }
    }
  }
}
