// ui_core's shared checks (088701304f) over every gallery page and app
// screen: DesignRowCheck (controls sharing a row, by their drawn outline)
// under each density, day and night; DesignWidthCheck at 600, 1024, 1440
// and 1920; checkList on each field that opens a list, at 390 and 1440.
// ignore_for_file: avoid_relative_lib_imports, avoid_print
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:minimal_ui/minimal_ui.dart';

import '../example/lib/main.dart';
import 'keylines_test.dart'
    show keylineScreens, loadKeylineFonts, precacheShownImages;

/// Why the Pickers page cannot be read: its time wheels keep their
/// off-screen rows laid out and never painted.
const String _unpaintedWheels =
    'the time wheels keep their off-screen rows (100 by 32, each under a '
    'RepaintBoundary of a SliverFixedExtentList) laid out in the scroll '
    "view's cache area and never painted, and DrawnPixels.read refuses a "
    'screen holding an unpainted boundary (probe 11-11: 72 of them); the '
    'selects on this page are held by p_classes_test (d); 0.2.0: ui_core '
    "reads a screen past an unpainted boundary (the 0.2.0 list's wheels)";

/// Where a check cannot read Minimal, by `check: screen at width`, with
/// the reason named.
final Map<String, String> _misreadings = {
  for (final width in ['600', '1024', '1440', '1920'])
    'widths: Pickers at $width': _unpaintedWheels,
};

/// Problems a check names that Minimal means, each held by its words with
/// the reason, and taken to ui_core's owner as a misreading (11-11). Every
/// other problem fails.
final Map<RegExp, String> _held = {
  RegExp(
    r'a button "(Today|Habits|Settings|Trends|Orders|Products|My issues|'
    r'Inbox|New habit)" beside a button "(Today|Habits|Settings|Trends|'
    r'Orders|Products|My issues|Inbox)"',
  ): "a navigation bar's destinations stack each glyph over its label and "
      'only the chosen one draws a face, so their words stand under the '
      "bar's middle and their outlines differ by design (the rail's New "
      'habit square stands in the rail, not in a row of buttons)',
  RegExp(
    r'a button "(outline|ghost|tonal|solid) small" beside a button "outline"'
    r'|a button "Control (sm|md)" beside a button "Control lg"',
  ): 'the sizes specimen sets the small, medium and large faces side by '
      'side so they can be compared',
  RegExp(
    r'a button "(Previous slide|Next slide|Page \d of \d)" beside a button',
  ): "a carousel's page dots are marks between its arrows, not faces of "
      "the arrows' size",
  RegExp(r'^a switch "[^"]+" beside a button'):
      "a switch's track keeps its "
      "own height beside a dialog footer's buttons: it is not a button",
  RegExp(
    r'a button "(Customize|Light|Dark)" beside a button "(Customize|Light|Dark)"',
  ): "a segmented control's segments sit inside its track and the track is "
      'its outline (32, level with the square beside it)',
  RegExp(
    r'a button "(Filters, active|Search issues)" beside a button '
    r'"(Search issues|Filters, active)"',
  ): "the filter square stands inside "
      "the search entry's face, and the entry holds two lines (its label "
      'over its detail)',
  RegExp(r'^a button "(Archive habit|Export as CSV)": \d+ px wide'):
      'a form row that is itself the act (its icon, its label, its '
      'chevron) is a list row and spans its form',
  RegExp(r'^a button "(Share|Save to files)": \d+ px wide'):
      "an action sheet's actions are its rows and span the sheet",
  RegExp(r'^a button "Search (orders|archive|issues)": \d+ px wide'):
      'a search entry is a search field and spans its column',
  RegExp(
    r'^a list opened from a button "[^"]+": its words are \d+ px in from '
    r"the field's words",
  ): "a select is a hairline row whose words stand on the page's gutter; "
      'its list starts on that edge (the measure ruled 11-11) and its words '
      "stand in by the card's own inset",
  RegExp(r'^a row of a button "Monday" and a button "Sunday": its sides'):
      "a segmented control's segments sit inside its track and the track is "
      'its outline; only the chosen segment draws a hairline, so read by its '
      "drawn faces the row ends at the chosen one's rim and the other's "
      'words (the habits settings, 11-12)',
  RegExp(r'^a segmented control "OPEN": \d+ px wide'):
      'a KPI strip (its '
      'cells filter what shows under it) spans the card it heads',
  RegExp(
    r'^a (button|checkbox) "Large" beside a (button|checkbox) '
    r'"(Off|On|Disabled|Disabled on)"|^a (button|checkbox) "(Off|On|'
    r'Disabled|Disabled on)" beside a (button|checkbox) "Large"',
  ): "the checkbox states strip sets the large check (20) beside the "
      '16 px ones, each centred in its 44 px slot, so the sizes compare',
  RegExp(r'^a segmented control "Today": 390 px wide'):
      "the Overview page draws a 390 px phone's Today screen, and the "
      "segmented control spans that phone's column",
  RegExp(
    r'^a button "(Send message|Stop response)" beside a button '
    r'"Send message": its (top|bottom)',
  ): "the Text fields page sets its composer specimens side by side: a "
      "message composer's send square and the comment box's are each sized "
      'to their own composer and stand on its line, not one row',
  RegExp(
    r'^a button "(Delete|Create habit|New habit)" beside a button '
    r'"(Cancel|Search)": its (top|bottom) is level with theirs as laid out, '
    r'0\.5 device px',
  ): "level as laid out; as drawn a filled face's anti-aliased edge reads "
      "half a device pixel inside the outlined face's hairline beside it, "
      'and the two read level in the pictures (dialogs, day and night, '
      '11-11)',
  RegExp(
    r'^a button "\w+day,? \d+ [^"]+" beside a button '
    r'"\w+day,? \d+ [^"]+": '
    r'the capitals of "\d+" are [^,]+ centre line as laid out, [\d.]+ '
    r'device px below as drawn',
  ): "laid out, every day's figure is within 0.2 px of the week's centre "
      'line; most days draw no face for the check to take the middle from, '
      "and Geist Mono's figures stand on its capitals' height (0 to 710 of "
      '1000, measured 11-11)',
};

DesignAlignmentReport _unheld(DesignAlignmentReport report) =>
    DesignAlignmentReport(report.look, [
      for (final p in report.problems)
        if (!_held.keys.any((r) => r.hasMatch(p))) p,
    ]);

typedef _Screen = ({
  String name,
  String query,
  Future<void> Function(WidgetTester tester)? open,
  bool page,
});

final List<_Screen> _screens = [
  for (final page in examplePages)
    (
      name: page.name,
      query: 'page=${GalleryApp.pageSlug(page.name)}',
      open: null,
      page: true,
    ),
  for (final screen in keylineScreens)
    (
      name: screen.name,
      query: 'app=${screen.app}',
      open: screen.open,
      page: false,
    ),
];

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _show(
  WidgetTester tester,
  _Screen screen,
  Size size, {
  String extra = '',
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    GalleryApp.at(Uri.parse('http://localhost/?${screen.query}$extra')),
  );
  await _settle(tester);
  await screen.open?.call(tester);
  await precacheShownImages(tester);
}

void _verify(String at, DesignAlignmentReport report) {
  final unheld = _unheld(report);
  print(
    '$at: ${unheld.problems.length} named, '
    '${report.problems.length - unheld.problems.length} held',
  );
  for (final p in unheld.problems) {
    print('  $p');
  }
  unheld.verify();
}

Element _root(WidgetTester tester) =>
    tester.element(find.byType(WidgetsApp).first);

String _kind(Widget w) => w.runtimeType.toString().split('<').first;

void main() {
  setUpAll(loadKeylineFonts);

  group('rows by drawn outline', () {
    for (final density in const ['standard', 'compact']) {
      for (final appearance in const ['light', 'dark']) {
        for (final screen in _screens) {
          for (final size
              in screen.page
                  ? const [Size(1440, 900)]
                  : const [Size(390, 844), Size(1440, 900)]) {
            final where = '${screen.name} at ${size.width.round()}';
            final at = '$density · $appearance · $where';
            testWidgets(at, skip: _misreadings.containsKey('rows: $where'), (
              tester,
            ) async {
              await _show(
                tester,
                screen,
                size,
                extra: '&density=$density&appearance=$appearance',
              );
              _verify(
                at,
                await const DesignRowCheck(look: 'Minimal')
                    .check(_root(tester), runAsync: tester.runAsync),
              );
            }, tags: 'goldens');
          }
        }
      }
    }
  });

  group('widths', () {
    for (final width in const [600.0, 1024.0, 1440.0, 1920.0]) {
      for (final screen in _screens) {
        final where = '${screen.name} at ${width.round()}';
        testWidgets(where, skip: _misreadings.containsKey('widths: $where'), (
          tester,
        ) async {
          await _show(tester, screen, Size(width, 1000));
          _verify(
            where,
            await const DesignWidthCheck(look: 'Minimal')
                .check(_root(tester), runAsync: tester.runAsync),
          );
        }, tags: 'goldens');
      }
    }
  });

  group('a list opened from a field', () {
    for (final width in const [390.0, 1440.0]) {
      for (final screen in _screens) {
        final where = '${screen.name} at ${width.round()}';
        testWidgets(where, skip: _misreadings.containsKey('list: $where'), (
          tester,
        ) async {
          await _show(tester, screen, Size(width, 1000));
          // The first select on the screen that opens a menu in place.
          final field = find.byWidgetPredicate((w) {
            if (_kind(w) != 'MinimalSelect') return false;
            return (w as MinimalSelect).presentation ==
                MinimalSelectPresentation.menu;
          });
          final shown = [
            for (final e in field.evaluate())
              if (tester
                      .getRect(find.byElementPredicate((x) => x == e))
                      .bottom <
                  950)
                e,
          ];
          if (shown.isEmpty) return;
          final face = find
              .descendant(
                of: find.byElementPredicate((x) => x == shown.first),
                matching: find.byType(MinimalPressable),
              )
              .first;
          final press = tester.widget<MinimalPressable>(face);
          if (!press.enabled || press.onPressed == null) return;
          await tester.tap(face);
          await _settle(tester);
          _verify(
            where,
            await const DesignWidthCheck(look: 'Minimal')
                .checkList(tester.element(face), runAsync: tester.runAsync),
          );
        }, tags: 'goldens');
      }
    }
  });
}
