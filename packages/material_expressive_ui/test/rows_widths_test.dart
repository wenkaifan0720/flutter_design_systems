// ui_core's shared checks for the two faults the user met on 11-11 (a
// dialog's buttons of two drawn heights; a dropdown spanning a wide page):
// every row of controls by its drawn outlines (DesignRowCheck), by day and
// by night under each density the look ships; every select, button, stepper
// and segmented control at a control's width from 600 (DesignWidthCheck) at
// 600, 1024, 1440 and 1920, each select's chosen value whole; and every list
// opened from a field at the field's width, on its leading edge, its words on
// the field's (checkList; every option's words where the field's value
// starts) at 390, 600 and 1440. Over every gallery page and every
// trip planner screen.
//
// Both checks read the drawn pixels, the rasterizer's as a golden's are:
// tagged `goldens`, so macOS runs it and Linux CI leaves it out.
@Tags(['goldens'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import '../example/lib/kit_gallery/trip.dart';
import 'gallery_support.dart';

const _look = 'Material Expressive';
const _rows = DesignRowCheck(look: _look);
const _widths = DesignWidthCheck(look: _look);

/// The density the platform under test gets (the look's
/// `adaptivePlatformDensity`).
String get _density =>
    defaultTargetPlatform == TargetPlatform.macOS ? 'compact' : 'standard';

/// The gallery's rows that span their list or section, read as buttons or
/// selects by the width check: one-line action rows (KitAction, a list tile
/// with a chevron), list tiles, disclosure rows and article rows; and the
/// collapsed search bar, which is search.
const _spanningRows = <String>{
  'Search Lisbon',
  'Log 7 pages',
  'Next step',
  'Show last week',
  'Between both edges',
  'Enabled',
  'Middle inset',
  'Can I return an item?',
  'Do you ship abroad?',
  'How long does shipping …',
  'Spring across',
  'Open as a modal drawer',
  'First frost on the allo…',
  'The night train north',
  'Tide pools at low water',
  'Actions for a note',
  'New observation',
  'Open the tinted sheet',
  'Open the trail log',
  'Share this note',
  'The route, from code',
  'New playlist (the sheet…',
  'Open “Morning focus”',
};

/// The gallery's size ladders: one control per size (or shape) side by
/// side on purpose.
const _ladders = <String>{'buttons', 'icon-buttons', 'fab', 'split-button'};

/// What a check reads that is not a fault, with why; null for anything else
/// (the coordinator's rulings, msg_39c6dabff58b; ui_core is asked to classify
/// each itself).
String? _misread(String where, String problem) {
  final page = where.split(' ').first;
  final width = RegExp(r'^a (button|select) "([^"]*)": [\d.]+ px wide')
      .firstMatch(problem);
  if (width != null && _spanningRows.contains(width.group(2))) {
    return 'a row spans its list or section (list rows, disclosure rows, the '
        'collapsed search bar)';
  }
  if (problem.startsWith('a control beside a control') ||
      RegExp(r'^a row of \d+ controls from a control').hasMatch(problem)) {
    return 'controls with no face of their own (a bare glyph, a '
        "destination's indicator, a badge) read by their outline";
  }
  if (_ladders.contains(page) &&
      !problem.contains('"Queue"') &&
      RegExp(r'^a (button|switch) "[^"]*" beside a button').hasMatch(problem)) {
    return "a size ladder: one control per size, side by side on purpose";
  }
  if (page == 'buttons' &&
      RegExp(
        r'^a button "Queue" beside a button "Play": its (top|bottom) is level '
        r'with theirs as laid out',
      ).hasMatch(problem)) {
    return 'an extra-small outlined pill under compact density: its label\'s '
        'box, read with 2dp around it, covers the whole 24dp face, so its '
        '1dp outline is read only in its rounded ends; drawn level with '
        'Play, 24dp each (probe p26, rendered at 4x)';
  }
  if (page == 'toolbar' &&
      RegExp(
        r'^a button "(Write a message|Play|New note)" beside a button '
        r'"[^"]*": its (top|bottom) is 4 px (below|above) theirs as laid out',
      ).hasMatch(problem)) {
    return "a floating toolbar's FAB beside it: Compose's 56dp FAB centred "
        "on the 64dp toolbar, two faces (ui_core 0e25289dfd reads the "
        "toolbar's actions by its pill; the oracle's toolbar scenes)";
  }
  if ((page == 'cards' || page == 'everyday-cards') &&
      problem.contains('the capitals of')) {
    return "a card's title sits at its top or foot by design, not on the "
        "row's centre line";
  }
  if (page == 'states' && problem.contains('"Directions"')) {
    return "the states page's bare-pressable demo: the page's own content";
  }
  if (page == 'chips' &&
      (problem.contains('its sides are') ||
          RegExp(
            r'its (top|bottom) is 0\.[0-4] px (below|above) theirs as laid out',
          ).hasMatch(problem) ||
          RegExp(
            r'its (top|bottom) is level with theirs as laid out, 0\.\d device',
          ).hasMatch(problem))) {
    return "a scrolling chip row's clipped end, and chips under half a "
        'pixel apart (a 1dp stroke beside a fill, 0.3 px as laid out)';
  }
  if (page == 'app-bar' &&
      problem.startsWith('a text field beside a button "Cancel search"')) {
    return "the search field is read by its one-line entry, not by its bar";
  }
  if (page == 'pickers' &&
      problem.startsWith('a text field beside a checkbox "Select hour')) {
    return "the time input's chosen field is read by its one-line entry, not "
        'by its 72dp plate (marked, DesignKeylineFace), the selector beside '
        "it's height";
  }
  if (page == 'select' &&
      problem.contains(
        'a list opened from a button "Standard delivery": its words are',
      )) {
    return "the page's own in-place menu (the Open section, under the "
        'delivery field, its words 16 in) read as the list the field '
        "opened, which overlaps it: that list's words stand at 68.1, the "
        "field's value at 68.3 (probe, ui_core 0e25289dfd)";
  }
  if (RegExp(
    r"^a tab bar: [\d.]+ px wide as laid out, [\d.]+ as drawn; its \d+ "
    r"tabs' content and padding take 0,",
  ).hasMatch(problem)) {
    return "a navigation bar's destinations (Compose's Role.Tab) read by "
        'their hit layers: each pressable is the pill-sized layer under its '
        'icon and label, which holds none of them, so the bar reads as tabs '
        'with no content';
  }
  if (problem.contains('no list open from')) {
    return "checkList finds no face in the look's own surface paint "
        '(sent to ui_core: _listFrom reads only stock painters)';
  }
  return null;
}

void _report(String what, String where, List<String> problems) {
  final faults = [
    for (final p in problems)
      if (_misread(where, p) == null) p,
  ];
  // ignore: avoid_print
  print(
    [
      '$what $where: ${problems.length} read, ${faults.length} faults',
      for (final p in problems)
        '  ${_misread(where, p) == null ? '!' : '~ ${_misread(where, p)}:'} $p',
    ].join('\n'),
  );
  expect(faults, isEmpty, reason: faults.join('\n'));
}

Future<void> _app(
  WidgetTester tester,
  String page,
  double width, {
  double height = 1100,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GalleryApp(initialPage: page, initialBrightness: brightness),
  );
  await settle(tester);
}

bool _opensList(Widget w) => w is ExpressiveSelect || w is ExpressiveCombobox;

/// In the list opened from [held] (a select, a combobox), every option's
/// words where the field's value starts, within a pixel: one edge for a
/// list's words, the field's.
List<String> _wordsEdge(
  WidgetTester tester,
  Element held,
  Set<Element> before,
) {
  final (name, labels) = switch (held.widget) {
    ExpressiveSelect(:final label, :final options) => (
      label,
      [for (final o in options) o.label],
    ),
    ExpressiveCombobox(:final label, :final options) => (
      label,
      [for (final o in options) o.label],
    ),
    _ => (null, const <String>[]),
  };
  // The list this field opened: a surface that was not on the page before
  // the tap (a page may show a list in place, as the select page does).
  final menus = find.byElementPredicate(
    (e) => e.widget is ExpressiveMenuSurface && !before.contains(e),
  );
  final value = find.descendant(
    of: find.byElementPredicate((e) => identical(e, held)),
    matching: find.byType(EditableText),
  );
  if (labels.isEmpty || menus.evaluate().isEmpty || value.evaluate().isEmpty) {
    return const [];
  }
  final valueX = tester.getRect(value.first).left;
  return [
    for (final label in labels.toSet())
      if (find
              .descendant(of: menus.last, matching: find.text(label))
              .evaluate()
              .firstOrNull
              ?.renderObject
          case final RenderBox words)
        if ((words.localToGlobal(Offset.zero).dx - valueX).abs() > 1)
          'a list from "${name ?? ''}": "$label" starts '
              '${(words.localToGlobal(Offset.zero).dx - valueX).toStringAsFixed(1)}'
              " px from where the field's value starts",
  ];
}

/// Every select's and combobox's chosen value its entry cuts: the value
/// wider than the entry's line (the caret's gap and width end it).
List<String> _cutValues(WidgetTester tester) {
  final cut = <String>[];
  for (final field in find.byWidgetPredicate(_opensList).evaluate()) {
    final label = switch (field.widget) {
      ExpressiveSelect(:final label) => label,
      ExpressiveCombobox(:final label) => label,
      _ => null,
    };
    void visit(RenderObject node) {
      if (node is! RenderEditable) {
        node.visitChildren(visit);
        return;
      }
      final painter = TextPainter(
        text: node.text,
        textDirection: node.textDirection,
        textScaler: node.textScaler,
        maxLines: 1,
      )..layout();
      final room = node.size.width - node.cursorWidth - 1;
      if (painter.width > room + 0.5) {
        cut.add(
          'a select "${label ?? ''}": its chosen value '
          '"${node.text?.toPlainText()}" is cut, '
          '${painter.width.toStringAsFixed(1)} px in '
          '${room.toStringAsFixed(1)} px',
        );
      }
      painter.dispose();
    }

    final box = field.renderObject;
    if (box != null) visit(box);
  }
  return cut;
}

void main() {
  setUpAll(() async {
    await loadExpressiveFonts();
    await loadBundledFonts();
  });
  final densities = TargetPlatformVariant(const {
    TargetPlatform.android,
    TargetPlatform.macOS,
  });

  group('rows by their drawn outlines', () {
    for (final page in galleryExamplePages) {
      for (final mode in Brightness.values) {
        testWidgets('${page.id} ${mode.name}', (tester) async {
          await pumpGalleryPage(tester, page, 'baseline', mode);
          final report = await _rows.check(
            tester.binding.rootElement!,
            runAsync: tester.runAsync,
          );
          _report('ROWS', '${page.id} $_density ${mode.name}', report.problems);
        }, variant: densities);
      }
    }
    for (final screen in TripScreens.all) {
      for (final width in [390.0, 1440.0]) {
        for (final mode in Brightness.values) {
          testWidgets('trip $screen ${width.round()} ${mode.name}', (
            tester,
          ) async {
            await _app(
              tester,
              screen,
              width,
              height: width < 600 ? 1700 : 1100,
              brightness: mode,
            );
            final report = await _rows.check(
              tester.binding.rootElement!,
              runAsync: tester.runAsync,
            );
            _report(
              'ROWS',
              'trip $screen ${width.round()} $_density ${mode.name}',
              report.problems,
            );
          }, variant: densities);
        }
      }
    }
  });

  group('controls at their width from 600', () {
    for (final width in [600.0, 1024.0, 1440.0, 1920.0]) {
      for (final page in [
        for (final p in galleryExamplePages) p.id,
        ...TripScreens.all,
      ]) {
        testWidgets('$page ${width.round()}', (tester) async {
          await _app(tester, page, width, height: 4000);
          final report = await _widths.check(
            tester.binding.rootElement!,
            runAsync: tester.runAsync,
          );
          _report('WIDTHS', '$page ${width.round()}', [
            ...report.problems,
            ..._cutValues(tester),
          ]);
        });
      }
    }
  });

  group('a list opened from a field', () {
    for (final width in [390.0, 600.0, 1440.0]) {
      for (final page in [
        for (final p in galleryExamplePages) p.id,
        ...TripScreens.all,
      ]) {
        testWidgets('$page ${width.round()}', (tester) async {
          await _app(tester, page, width, height: 4000);
          final problems = <String>[];
          for (var i = 0; ; i++) {
            final fields = find.byWidgetPredicate(_opensList).evaluate();
            if (i >= fields.length) break;
            // This field's element, held: choosing in a list can change how
            // many fields the screen shows.
            final held = fields.elementAt(i);
            final field = find.descendant(
              of: find.byElementPredicate((e) => identical(e, held)),
              matching: find.byType(ExpressiveMenu),
            );
            if (field.evaluate().isEmpty) continue;
            await tester.ensureVisible(field.first);
            await settle(tester);
            final face = tester.getRect(field.first);
            final before = find
                .byType(ExpressiveMenuSurface)
                .evaluate()
                .toSet();
            await tester.tapAt(face.centerLeft + const Offset(24, 0));
            await settle(tester);
            final report = await _widths.checkList(
              tester.element(field.first),
              runAsync: tester.runAsync,
            );
            problems.addAll([
              for (final p in [
                ...report.problems,
                ..._wordsEdge(tester, held, before),
              ])
                'field $i: $p',
            ]);
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await settle(tester);
          }
          _report('LISTS', '$page ${width.round()}', problems);
        });
      }
    }
  });
}
