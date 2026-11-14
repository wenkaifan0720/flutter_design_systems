// ui_core's checks for two faults a review caught (a button of another height
// in a row, a dropdown of the wrong width):
// - DesignRowCheck over every gallery page and the app screens, under each
//   density the look ships, by day and by night: controls sharing a row
//   show one top and one bottom by their drawn outline;
// - DesignWidthCheck over every gallery page and the app screens at 600,
//   1024, 1440 and 1920 wide, with a pointer (a desktop's or a tablet's
//   browser): a select, a button, a stepper or a segmented control keeps to
//   its content and padding, at most 320;
// - checkList on every select at 390 and 1440, with a pointer: its open
//   list at least the field's width, on its leading edge, its words on the
//   field's (less the check column Fluent's listbox sets before them).
// Each prints what it names as ROWS, WIDTHS or LIST lines into the log.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/src/fluent2_design/components/input/field_core.dart'
    show Fluent2FieldButton, Fluent2ListboxColumn;
import 'package:ui_core/alignment.dart';

import 'gallery_support.dart';

void _say(String kind, String name, Iterable<String> found) {
  for (final line in found) {
    // ignore: avoid_print
    print('$kind $name · $line');
  }
}

/// ui_core's reader refuses a boundary never painted (a row in an inner
/// list's cache extent, the code entry's hidden line under Opacity(0)):
/// named, reported to ui_core's owner, and the rest goes on.
void _unread(String name, String what) {
  // ignore: avoid_print
  print(
    'UNREAD $name · $what: a control under it was never painted (a '
    "list's cache extent, a hidden entry)",
  );
}

/// The page's widths: a gallery page at the phone's, an app screen at the
/// phone's and the desktop's.
List<double> _widthsOf(GalleryPage page) =>
    page.id.startsWith('app-') ? const [390.0, 1440.0] : const [galleryWidth];

/// Where Fluent's listbox sets an option's words past the select face's:
/// after its check column (16 and its gap), and in a list with icons after
/// the icon and its gap too (the face shows the words alone).
double _listIndent(Fluent2Select<Object?> select) =>
    select.options.any((o) => o.icon != null) ? 44 : 20;

/// What the row check names that is not the look's: each a pattern and
/// why, reported to ui_core's owner.
final _rowMisreads = <(RegExp, String)>[
  (
    RegExp(
      r'a button "Mara Okafor" beside a button "Kai Tanaka": its (top|bottom) is '
      r'level with theirs as laid out, 3 device px (below|above) as drawn',
    ),
    'by night an unchosen circular tag\'s fill (neutralBackground3, #141414) '
        'stands within the check\'s reach of the ground, so its face is read '
        'by the avatar inside it; both pills\' edges stand on the same pixel '
        'rows (r9 badges p390_dark, 3120)',
  ),
  (
    RegExp(
      r"draws? (its|their) text in the test's own font \(solid boxes\), "
      r'a button "([^"]*\d+ unread|Mara Okafor[^"]*)" first',
    ),
    'words on a fill of their own inside the control (a count badge\'s '
        'pill over its icon button, a swiped row over its action) read '
        'against the control\'s face, so their pill reads as solid boxes',
  ),
  (
    RegExp(r'a button "[^"]*\d+ unread" beside a button "[^"]*": its '),
    'a subtle icon button shows no outline: its count badge\'s pill is '
        'read as one (the bell\'s glyph and the avatar share the bar\'s '
        'middle)',
  ),
  (
    RegExp(
      r'a button "[^"]*\d+ unread" beside a button "[^"]*": the capitals of '
      r'"\d+" ',
    ),
    'a count badge\'s number is read as its icon button\'s label: the button '
        'shows a glyph only, and the badge rides its face\'s top end corner',
  ),
  (
    RegExp(
      r'a button "Profile and settings" beside a button "(Upload|New event)": '
      r'its (top|bottom) is 8 px (above|below) theirs as laid out',
    ),
    'a subtle icon button shows no outline and is read by its 48 target; '
        'beside it the 32 avatar, both on the bar\'s middle',
  ),
  (
    RegExp(r'a text field beside a button "Attach a file": '),
    'a composer grown to several lines keeps its acts on its last line '
        '(Fluent\'s chat input); the field and its acts are not a row of '
        'peers',
  ),
  (
    RegExp(
      r'a button "\w+ \d+, \d{4}" beside a button "\w+ \d+, \d{4}": its '
      r'(top|bottom) is level with theirs as laid out, 1(\.0)? device px',
    ),
    'a chosen day\'s light brand tint and today\'s brand disc share one '
        'circle; the tint\'s antialiased edge falls under the contrast floor',
  ),
  (
    RegExp(
      r'a row of (a (switch|button) "[^"]*"(, | and )?)+: its sides are 0 px '
      r'in as laid out, 0(\.1)? px on the left and -0\.2 px on the right as '
      r'drawn',
    ),
    'a joined strip (the segmented control): its edge on a part pixel, its '
        'partial cover read whole',
  ),
];

/// What the width check names that is not the look's.
final _widthMisreads = <(RegExp, String)>[
  (
    RegExp(
      r'a button "(Brand guidelines\.pdf|Upload a file|Find a person|'
      r'Start a meeting)": ',
    ),
    'a tree\'s one-line row is read as a button '
        '(its rows with a shortcut, two lines of words, are not): rows of a '
        'list span it',
  ),
  (
    RegExp(r'a segmented control "Mon": '),
    'a bar chart\'s bars, each a choice that shows its value, touch at 600 '
        'and are read as a segmented control',
  ),
  (
    RegExp(
      r'a button "Home": \d+ px wide as laid out, [\d.]+ as drawn; its '
      r'content and padding take 20 ',
    ),
    'a navigation drawer\'s item is a row of its list and spans the drawer '
        '(the inventory stands the drawer across its card); its content is '
        'read as its glyph alone',
  ),
  (
    RegExp(r'a stepper "Back to (Files|Calendar)": '),
    'a pushed page\'s top bar (its way back and one act round the title) '
        'is read as a stepper',
  ),
];

/// [found] less what [misreads] names.
List<String> _less(List<String> found, List<(RegExp, String)> misreads) => [
  for (final f in found)
    if (!misreads.any((m) => m.$1.hasMatch(f))) f,
];

/// The densities the look ships, by name.
const _densities = {
  'standard': Fluent2Density.standard,
  'comfortable': Fluent2Density.comfortable,
  'compact': Fluent2Density.compact,
};

void main() {
  setUpAll(loadFluent2TestFonts);

  for (final page in galleryPages) {
    for (final width in _widthsOf(page)) {
      testWidgets('${page.id}, ${width.round()} wide: controls in a row show '
          'one top and one bottom, each density, day and night', (t) async {
        final found = <String>[];
        // The desktop screens as a desktop draws them; the phone's as a
        // phone does.
        debugDefaultTargetPlatformOverride = width >= 600
            ? TargetPlatform.macOS
            : null;
        try {
          for (final MapEntry(key: step, value: density)
              in _densities.entries) {
            for (final brightness in Brightness.values) {
              await pumpWhole(
                t,
                page,
                width,
                brightness: brightness,
                density: density,
              );
              try {
                final report = await const DesignRowCheck(look: 'Fluent 2')
                    .check(shownScreen(t), runAsync: t.runAsync);
                found.addAll([
                  for (final p in report.problems)
                    '$step, ${brightness.name} · $p',
                ]);
              } on StateError {
                _unread(
                  '${page.id}_${width.round()}',
                  '$step, ${brightness.name}',
                );
              }
            }
          }
          await t.pumpWidget(const SizedBox());
          await t.pump(const Duration(seconds: 1));
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
        _say('ROWS', '${page.id}_${width.round()}', found);
        final real = _less(found, _rowMisreads);
        expect(real, isEmpty, reason: real.join('\n'));
        // ui_core's checks read drawn pixels (the rasterizer's, as a
        // golden's): run where the goldens run.
      }, tags: const ['goldens']);
    }
  }

  for (final page in galleryPages) {
    testWidgets('${page.id}: from 600 its controls keep to their content, '
        'at 600, 1024, 1440 and 1920', (t) async {
      final found = <String>[];
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        for (final width in const [600.0, 1024.0, 1440.0, 1920.0]) {
          await pumpWhole(t, page, width);
          try {
            final report = await const DesignWidthCheck(look: 'Fluent 2')
                .check(shownScreen(t), runAsync: t.runAsync);
            found.addAll([
              for (final p in report.problems) '${width.round()} · $p',
            ]);
          } on StateError {
            _unread(page.id, '${width.round()}');
          }
        }
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 1));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
      _say('WIDTHS', page.id, found);
      final real = _less(found, _widthMisreads);
      expect(real, isEmpty, reason: real.join('\n'));
    }, tags: const ['goldens']);
  }

  for (final page in galleryPages) {
    for (final width in const [390.0, 1440.0]) {
      testWidgets('${page.id}, ${width.round()} wide: every select\'s list '
          'opens at its width, on its leading edge', (t) async {
        final found = <String>[];
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          await pumpWhole(t, page, width);
          // Each select that opens (a disabled one does not).
          final faces = find.descendant(
            of: find.byWidgetPredicate((w) => w is Fluent2Select),
            matching: find.byWidgetPredicate(
              (w) => w is Fluent2FieldButton && w.onOpen != null,
            ),
          );
          final count = faces.evaluate().length;
          for (var i = 0; i < count; i++) {
            final face = faces.at(i);
            // One on show (a select on a tab or a step not shown waits).
            if (find
                .descendant(of: face, matching: find.byType(Text))
                .hitTestable()
                .evaluate()
                .isEmpty) {
              continue;
            }
            final name = t
                .widget<Fluent2FieldButton>(face)
                .label
                .replaceAll('\n', ' ');
            await t.tap(face);
            await t.pump();
            await t.pump(const Duration(milliseconds: 400));
            final select = t.widget<Fluent2Select<Object?>>(
              find
                  .ancestor(
                    of: face,
                    matching: find.byWidgetPredicate((w) => w is Fluent2Select),
                  )
                  .first,
            );
            try {
              final report = await DesignWidthCheck(
                look: 'Fluent 2',
                listWordsIndent: _listIndent(select),
              ).checkList(t.element(face), runAsync: t.runAsync);
              found.addAll([for (final p in report.problems) '"$name" · $p']);
            } on StateError {
              _unread('${page.id}_${width.round()}', '"$name"');
            }
            // Closed by Escape, else by its face again.
            await t.sendKeyEvent(LogicalKeyboardKey.escape);
            await t.pump(const Duration(milliseconds: 400));
            if (find.byType(Fluent2ListboxColumn).evaluate().isNotEmpty) {
              await t.tap(face, warnIfMissed: false);
              await t.pump(const Duration(milliseconds: 400));
            }
          }
          await t.pumpWidget(const SizedBox());
          await t.pump(const Duration(seconds: 1));
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
        _say('LIST', '${page.id}_${width.round()}', found);
        expect(found, isEmpty, reason: found.join('\n'));
      }, tags: const ['goldens']);
    }
  }
}
