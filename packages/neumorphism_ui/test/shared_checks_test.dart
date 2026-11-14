// ui_core's shared checks (design6 P, 11-11 afternoon) over every screen the look shows:
// - DesignRowCheck: controls sharing a row show one top and one bottom as drawn, under each density the gallery
//   offers (standard and compact), by day and by night. Hearth's screens and the Overview at a phone's and a desk's
//   width; the gallery's pages at the gallery's phone width, as tall as their sections.
// - DesignWidthCheck: from 600 wide up, a select's closed face, a button, a stepper and a segmented control keep to
//   what their content takes (at most 320), at 600, 1024, 1440 and 1920.
// - DesignWidthCheck.checkList: a list opened from a select, a combobox or a multi-select is at least as wide as the
//   field and starts on its leading edge, at 390 and 1440.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/internal/panel.dart'
    show NeumorphicPanel, NeumorphicPanelRow;
import 'package:ui_core/alignment.dart'
    show
        DesignAlignmentReport,
        DesignRowCheck,
        DesignWidthCheck,
        DesignWidthKind,
        DesignWidthLimit;

// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/hearth.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/live.dart';
import 'gallery_support.dart' show fitPage, loadBundledFonts, settle;
import 'support.dart' show loadNeumorphicFonts;

const _look = 'Neumorphism';

/// From 600 wide a control keeps to what its content takes (at most 320); a card's one act spans its card while the
/// card is at most 1.5 times that cap (neumorphicWideRoom): Pay under the order, 430 to 472 wide.
const _widths = DesignWidthCheck(
  look: _look,
  limits: {
    DesignWidthKind.button: DesignWidthLimit(
      480,
      "a card's one act spans its card while the card is at most 1.5 times a key's 320 cap (Pay under the order)",
    ),
  },
);

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });
  final app = ['overview', for (final s in hearthScreens) s.id];
  final pages = [
    ...app,
    for (final p in liveGalleryPages)
      if (!app.contains(p.id)) p.id,
  ];
  double tall(String screen, double width) =>
      app.contains(screen) ? (width < 600 ? 1400 : 1100) : 2600;

  Future<void> show(
    WidgetTester tester,
    String screen,
    double width, {
    GalleryDensity density = GalleryDensity.standard,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, tall(screen, width));
    await tester.pumpWidget(
      GalleryApp(
        key: ValueKey((screen, width, density, brightness)),
        initialPage: screen,
        initialBrightness: brightness,
        initialCustom: GalleryCustom(density: density),
      ),
    );
    await settle(tester);
    // Every picture decoded before the screen is read (a picture finishing mid-read repaints it).
    await tester.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await settle(tester);
  }

  Future<DesignAlignmentReport> read(
    WidgetTester tester,
    Future<DesignAlignmentReport> Function() check,
  ) async {
    // A picture finishing its decoding while the screen is read repaints it: let it land and read again, at most
    // three times. A lazy list's rows built past the view are never painted: the view grows to hold the page.
    for (var attempt = 1; ; attempt++) {
      try {
        return await check();
      } on StateError {
        if (attempt == 3) {
          // What is still waiting to paint, by the widgets that made it.
          final waiting = <String>[];
          void visit(RenderObject n) {
            if (n is RenderRepaintBoundary && n.debugNeedsPaint) {
              final creator = n.debugCreator;
              waiting.add(
                creator is DebugCreator
                    ? creator.element.debugGetCreatorChain(6)
                    : '$n',
              );
            }
            n.visitChildren(visit);
          }

          visit(tester.renderObject(find.byType(GalleryApp)));
          // ignore: avoid_print
          print('UNPAINTED ${waiting.length}\n  ${waiting.join('\n  ')}');
          rethrow;
        }
        await fitPage(tester);
        await tester.runAsync(
          () => Future<void>.delayed(Duration(milliseconds: 400 * attempt)),
        );
        await settle(tester);
      }
    }
  }

  void verdict(String tag, List<String> found) {
    final named = <String>[];
    final left = <String>[];
    for (final p in found) {
      final why = _named(p);
      (why == null ? left : named).add(why == null ? p : '$p  [$why]');
    }
    // ignore: avoid_print
    print(
      '$tag: ${left.length} (named ${named.length})'
      '${found.isEmpty ? '' : '\n  ${[...left, ...named].join('\n  ')}'}',
    );
    expect(left, isEmpty, reason: left.join('\n'));
  }

  final rowRuns = <(String, double)>[
    for (final s in app)
      for (final width in [390.0, 1440.0]) (s, width),
    for (final p in pages)
      if (!app.contains(p)) (p, 390.0),
  ];
  for (final (screen, width) in rowRuns) {
    testWidgets('rows level as drawn $screen $width', (tester) async {
      addTearDown(tester.view.reset);
      final found = <String>[];
      for (final density in [GalleryDensity.standard, GalleryDensity.compact]) {
        for (final brightness in Brightness.values) {
          await show(
            tester,
            screen,
            width,
            density: density,
            brightness: brightness,
          );
          final report = await read(
            tester,
            () => const DesignRowCheck(look: _look).check(
              tester.element(find.byType(GalleryApp)),
              runAsync: tester.runAsync,
            ),
          );
          found.addAll([
            for (final p in report.problems)
              '${density.name} ${brightness.name} · $p',
          ]);
        }
      }
      verdict('ROWS $screen ${width.toInt()}', found);
    }, tags: ['goldens']);
  }

  for (final screen in pages) {
    testWidgets('controls keep their width $screen', (tester) async {
      addTearDown(tester.view.reset);
      final found = <String>[];
      for (final width in [600.0, 1024.0, 1440.0, 1920.0]) {
        await show(tester, screen, width);
        final report = await read(
          tester,
          () => _widths.check(
            tester.element(find.byType(GalleryApp)),
            runAsync: tester.runAsync,
          ),
        );
        found.addAll([
          for (final p in report.problems) '${width.toInt()} · $p',
        ]);
      }
      verdict('WIDTHS $screen', found);
    });
  }

  // A field's open list: a select's menu, a combobox's or a multi-select's panel.
  final lists = find.byWidgetPredicate(
    (w) => w is NeumorphicMenu || w is NeumorphicPanel,
  );
  final fields = find.byWidgetPredicate(
    (w) =>
        w is NeumorphicSelect ||
        w is NeumorphicCombobox ||
        w is NeumorphicMultiSelect,
  );
  for (final screen in pages) {
    for (final width in [390.0, 1440.0]) {
      testWidgets('lists open to their field $screen $width', (tester) async {
        addTearDown(tester.view.reset);
        await show(tester, screen, width);
        final count = fields.evaluate().length;
        final found = <String>[];
        for (var i = 0; i < count; i++) {
          final field = fields.at(i);
          await tester.ensureVisible(field);
          await settle(tester);
          final shut = lists.evaluate().toSet();
          final entry = find.descendant(
            of: field,
            matching: find.byType(EditableText),
          );
          await tester.tap(
            entry.evaluate().isNotEmpty
                ? entry.first
                : find
                      .descendant(
                        of: field,
                        matching: find.byType(DesignKeylineFace),
                      )
                      .first,
            warnIfMissed: false,
          );
          await settle(tester);
          if (entry.evaluate().isNotEmpty) {
            // A combobox opens its list on the arrow key, as on typing.
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
            await settle(tester);
          }
          // The list's options start their words on the field's value, the chosen one's check at its end
          // (internal/panel.dart, neumorphicFieldListInsets).
          Future<DesignAlignmentReport> list() => read(
            tester,
            () => const DesignWidthCheck(look: _look).checkList(
              // An entry's field is its editable's well; a select's, the select.
              tester.element(entry.evaluate().isNotEmpty ? entry.first : field),
              runAsync: tester.runAsync,
            ),
          );
          var report = await list();
          if (entry.evaluate().isNotEmpty &&
              report.problems.any((p) => p.startsWith('no list open'))) {
            // An entry that suggests as it is typed in: a letter most of its options hold.
            await tester.enterText(entry.first, 'e');
            await settle(tester);
            report = await list();
          }
          found.addAll([for (final p in report.problems) '#$i · $p']);
          found.addAll([
            for (final p in _openList(tester, lists, shut)) '#$i · $p',
          ]);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await settle(tester);
          FocusManager.instance.primaryFocus?.unfocus();
          await settle(tester);
        }
        verdict('LISTS $screen ${width.toInt()} ($count fields)', found);
      }, tags: ['goldens']);
    }
  }
}

/// The list opened since [shut] (design6 P, 11-11 night): every option's words start on one x, and its whole frame
/// paints, clipped by nothing it stands in (a card, a panel, a scroll), within the window.
List<String> _openList(WidgetTester tester, Finder lists, Set<Element> shut) {
  final opened = lists.evaluate().where((e) => !shut.contains(e)).toList();
  if (opened.isEmpty) return const [];
  final list = opened.last;
  final problems = <String>[];
  final rows = find.descendant(
    of: find.byElementPredicate((e) => identical(e, list)),
    matching: find.byWidgetPredicate(
      (w) => w is NeumorphicPanelRow || w is NeumorphicTap,
    ),
  );
  final starts = <double>[];
  for (var k = 0; k < rows.evaluate().length; k++) {
    final words = find.descendant(of: rows.at(k), matching: find.byType(Text));
    if (words.evaluate().isEmpty) continue;
    starts.add(tester.getTopLeft(words.first).dx);
  }
  if (starts.length > 1) {
    final least = starts.reduce(math.min), most = starts.reduce(math.max);
    if (most - least > .5) {
      problems.add(
        "the open list's options start their words on ${starts.toSet().length} "
        'x, ${least.toStringAsFixed(1)} to ${most.toStringAsFixed(1)}',
      );
    }
  }
  final box = list.renderObject! as RenderBox;
  final frame = MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  ).deflate(.5);
  RenderObject child = box;
  for (var up = box.parent; up != null; up = up.parent) {
    final clip = up.describeApproximatePaintClip(child);
    if (clip != null) {
      final global = MatrixUtils.transformRect(up.getTransformTo(null), clip);
      if (!global.contains(frame.topLeft) ||
          !global.contains(frame.bottomRight)) {
        problems.add(
          "the open list's frame is cut by ${up.runtimeType} "
          '(${global.toString()} round ${frame.toString()})',
        );
        break;
      }
    }
    child = up;
  }
  final view = tester.view.physicalSize / tester.view.devicePixelRatio;
  if (!(Offset.zero & view).inflate(.5).contains(frame.bottomRight) ||
      frame.top < -.5) {
    problems.add("the open list's frame runs past the window ($frame)");
  }
  return problems;
}

/// Why a problem a check reports is not a fault of the look, or null: a fault. Each class is named, and each is held
/// to its own reading so a new fault of the same look never hides in it.
String? _named(String problem) {
  // An act's face is the pigment in a 145° gradient with a sheen (controls.dart, _ActPainter): read against one face
  // colour its rows count as ink, the words as solid boxes. Every family in FontManifest.json is loaded; the same
  // labels on flat faces read true (the label sweep names the same class).
  if (RegExp(
    r"draws its text in the test's own font \(solid boxes\), a button "
    r'"(Small|Start now|Open Hearth, a home app)" first',
  ).hasMatch(problem)) {
    return "an act's gradient face read as solid ink";
  }
  // A field's key (show password, send) stands inside its groove, a part of the field: the check takes the field's
  // face to be the bare editable, the groove holding another control, and reads the key as a control beside it.
  if (RegExp(
    r'a text field(?: "[^"]*")? beside a button "(Show password|Hide password|Send)": its (top|bottom) is',
  ).hasMatch(problem)) {
    return "a field's own key inside its groove";
  }
  // A choice card stands its title over its note: its capitals are the first line's, above the card's middle.
  if (RegExp(
    r'a button "(Basic|Home)" beside a button "(Basic|Home)": the capitals of "(Basic|Home)" are [\d.]+ px above',
  ).hasMatch(problem)) {
    return "a choice card: title over note";
  }
  // Two keys round a figure with no face of their own, standing alone in a card or a list row: the number field (its
  // keys at most 200 from its start, NeumorphicNumberField) and the fluted dial between its keys (its stage the plate
  // and a key each side, centred: the hero object, whose scale reads "10"). The face the check finds round the keys is
  // the card's or the row's, the column's width, and what it takes for their content is whatever lies between them
  // (the dial's readout, the field's figure); wide_walk_test holds each to its own width.
  if (RegExp(
    r'^\d+ · a stepper "(Less|10)": \d+ px wide as laid out, [\d.]+ as drawn'
    r'(; its content and padding take [\d.]+)? \(at most 320',
  ).hasMatch(problem)) {
    return "two keys round a figure, no face: the card or row they stand in read";
  }
  // Two fields side by side in a form's grid (Town and Postcode, first and last name), each its label over its groove:
  // they lay out alike (grooves 314 to 362, words centred at 337.8 on both; shapes/log/probe-field.out), yet the
  // reading flips from 2.9 px above by night to 5 px below by day, its "as laid out" taken from the grooves' inset
  // shading. wide_walk_test holds the pair's grooves and words level as laid out.
  if (RegExp(
    r'^(standard|compact) (dark|light) · a text field beside a text field: '
    r'(the capitals of "(Bristol|BS1 4DJ|Alex|Morgan)" are (2\.9 px above|5 px below) the row|its bottom is 1\.3 px above theirs)',
  ).hasMatch(problem)) {
    return "a field pair's grooves read by their inset shading";
  }
  // The same specimen's latches under NeumorphicFlatScope: a shadowless bank is the ground's colour, so its drawn sides
  // read as its chosen cell's fill alone (53.8 and 155 px in on a 390 column). Laid out its sides are on the row's.
  if (RegExp(
    r'^(standard|compact) (dark|light) · a row of a button "Auto" and a button "Off": its sides are 0 px in as laid out',
  ).hasMatch(problem)) {
    return 'a shadowless bank read by its chosen cell';
  }
  // A bank by night (segmented buttons, latches, toggle groups, a button group, the hour and minute banks, a tab
  // strip): its unchosen cells' faces are the wall's own colour, so by night its trailing end shows by its rim and its
  // cast alone (design_review_test holds that edge at 1.2 or more by night), and the check reads the bank to its last
  // seam: right side in by one trailing cell (86.5 to 175 at 390), left side on the row's. By day the same banks read
  // true.
  if (RegExp(
    r'^(standard|compact) dark · a row of .+: its sides are 0 px in as laid out, 0 px on the left and '
    r'(86\.5|102\.3|103|115\.7|175) px on the right as drawn$',
  ).hasMatch(problem)) {
    return 'a bank by night read to its last seam';
  }
  // The buttons page's sizes stand side by side on one centre line so the three read as a scale: their tops and
  // bottoms differ by half the difference in height each way.
  if (RegExp(
    r'^(standard|compact) (dark|light) · a button "(Small|Medium)" beside a button "Large": its (top|bottom) is '
    r'(4|7|10) px (below|above) theirs as laid out',
  ).hasMatch(problem)) {
    return 'a sizes specimen: three heights on one centre line';
  }
  // A split button's two halves are its body's two ends: read against the body itself (its pigment face, the surface
  // round them), the toggle's rounded end lands a fifth of a pixel out.
  if (RegExp(
    r'^(standard|compact) (dark|light) · a row of a button "Start now" and a button "More options": its sides are '
    r'0 px in as laid out, 0 px on the left and -0\.2 px on the right as drawn$',
  ).hasMatch(problem)) {
    return "a split button's halves read against its own body";
  }
  // A carousel's arrows stand either side of its slides: two keys round what they turn, read as a stepper whose face
  // is the slides' frame. in_motion_test holds the frame and its slides.
  if (RegExp(
    r'^\d+ · a stepper "Previous": \d+ px wide as laid out, [\d.]+ as drawn; its content and padding take [\d.]+ '
    r'\(at most 320',
  ).hasMatch(problem)) {
    return "a carousel's arrows round its slides";
  }
  // A combobox's groove holds its key and a multi-select's its chips, so the check takes the field to be the bare words
  // line inside it (14 in from the groove: the field's 14 inset; the multi-select's 10 and its groove's own). The list
  // opens from the groove's leading edge at its width (row_contract_test holds that at 600 to 1920); its words stand
  // on the field's words (neumorphicFieldListInsets).
  if (RegExp(
    r'^#\d+ · a list opened from a button: its leading edge is 14(\.1)? px out past the field.s as laid out, 14(\.1)? '
    r'px out past as drawn$',
  ).hasMatch(problem)) {
    return "a text entry's field read as its words line";
  }
  // A bay of the house stands its window over its words (its figure, name and note at its foot): the bay's face is
  // its whole wall (DesignKeylineFace), and its words are at the foot by design.
  if (RegExp(
    r'a button "(Living room|Kitchen|Hall|Bedroom|Study)" beside a button "(Living room|Kitchen|Hall|Bedroom|Study)": '
    r'the capitals of "[\d.]+°" are [\d.]+ px below',
  ).hasMatch(problem)) {
    return "a bay of the house: window over words";
  }
  return null;
}
