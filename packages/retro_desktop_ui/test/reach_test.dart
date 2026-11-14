// Every control reaches at least 48 by 48 to a finger on a phone, and no two controls reach over each other unless one
// holds the other. The drawings stay the look's 28 lp; the reach around them grows (`RetroDesktopReach`). Every part that takes
// a callback is enumerated from the source, so a new one fails here until it is named in the table; then every example
// page is held to the same at 390.
import 'dart:io';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'pages/account_page.dart';
import 'pages/agenda_page.dart';
import 'pages/document_page.dart';
import 'pages/home_page.dart';
import 'pages/month_page.dart';
import 'pages/readings_page.dart';
import 'pages/shelf_page.dart';
import 'pages/table_page.dart';
import 'support.dart';
import 'interactive_samples.dart';

void _tap() {}

final _parts = {
  for (final sample in retroDesktopInteractiveSamples.entries)
    sample.key: () => sample.value(_tap),
};

/// The parts a finger drives through ui_core's detectors, not a press; and the list table, one focus stop whose rows
/// take a finger as the period's lists did.
const _byPointer = {
  'RetroDesktopRangeSlider',
  'RetroDesktopResizable',
  'RetroDesktopTreeView',
  'RetroDesktopListTable',
};

/// Public parts that take a callback, read from the library.
Set<String> _interactive() {
  final found = <String>{};
  final cls = RegExp(
    r'^class (RetroDesktop\w+)[^{]*\{(.*?)^\}',
    multiLine: true,
    dotAll: true,
  );
  final cb = RegExp(
    r'final (?:VoidCallback|ValueChanged<[^>]+>|void Function\([^)]*\))\? \w+',
  );
  for (final file in Directory(
    'lib/src/retro_desktop',
  ).listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    for (final m in cls.allMatches(file.readAsStringSync())) {
      if (m[1] != 'AnimatedRetroDesktopTheme' &&
          (cb.hasMatch(m[2]!) || m[2]!.contains('EditableText('))) {
        found.add(m[1]!);
      }
    }
  }
  return found;
}

/// Every place a finger lands in the part: what takes a tap, and every text field's press (its bare editor if it has none).
/// With [off], a press with nothing wired yet counts too: an example page leaves its callbacks to the app.
/// With [gestures], so does a bare detector: the parts ui_core drives by pointer (a thumb, a handle, a wheel, a row).
List<(String, Rect)> _reaches(
  Element part, {
  bool off = false,
  bool gestures = false,
}) {
  final out = <(String, Rect)>[];
  for (final e in collectAllElementsFrom(part, skipOffstage: true)) {
    final w = e.widget;
    bool held() =>
        e.findAncestorWidgetOfExactType<RetroDesktopPressable>() != null ||
        e.findAncestorWidgetOfExactType<DesignPressable>() != null;
    final takes = switch (w) {
      RetroDesktopPressable(:final onPressed, :final onLongPress) =>
        off || onPressed != null || onLongPress != null,
      // ui_core's own presses: a split button's halves, a table's headers.
      DesignPressable(:final onPressed, :final onLongPress) =>
        e.findAncestorWidgetOfExactType<RetroDesktopPressable>() == null &&
            (off || onPressed != null || onLongPress != null),
      GestureDetector() when gestures =>
        !held() &&
            (w.onTap != null ||
                w.onPanStart != null ||
                w.onHorizontalDragStart != null ||
                w.onVerticalDragStart != null),
      TextSelectionGestureDetector() => true,
      EditableText() =>
        e.findAncestorWidgetOfExactType<TextSelectionGestureDetector>() == null,
      _ => false,
    };
    if (!takes) continue;
    final box = e.renderObject;
    if (box is! RenderBox || !box.hasSize) continue;
    final rect = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
    out.add(('${w.runtimeType} ${e.toStringShort()}'.split('(').first, rect));
  }
  return out;
}

bool _inside(Rect a, Rect b) =>
    a.left >= b.left - .5 &&
    a.top >= b.top - .5 &&
    a.right <= b.right + .5 &&
    a.bottom <= b.bottom + .5;

List<String> _problems(List<(String, Rect)> reaches) {
  final problems = <String>[];
  for (final (what, r) in reaches) {
    if (r.width < 48 - .01 || r.height < 48 - .01) {
      problems.add(
        '$what at ${r.topLeft} reaches ${r.width.toStringAsFixed(1)} by ${r.height.toStringAsFixed(1)}',
      );
    }
  }
  for (var i = 0; i < reaches.length; i++) {
    for (var j = i + 1; j < reaches.length; j++) {
      final (a, ra) = reaches[i];
      final (b, rb) = reaches[j];
      if (_inside(ra, rb) || _inside(rb, ra)) continue;
      final o = ra.intersect(rb);
      if (o.width > .5 && o.height > .5) {
        problems.add(
          '$a at ${ra.topLeft} and $b at ${rb.topLeft} overlap by ${o.size}',
        );
      }
    }
  }
  return problems;
}

const _nav = [
  RetroDesktopNavItem(
    label: 'Today',
    short: 'Today',
    icon: LucideIcons.house,
    onPressed: _tap,
  ),
  RetroDesktopNavItem(
    label: 'Places',
    short: 'Places',
    icon: LucideIcons.compass,
    onPressed: _tap,
  ),
  RetroDesktopNavItem(
    label: 'You',
    short: 'You',
    icon: LucideIcons.user,
    onPressed: _tap,
  ),
];

/// The example pages, wired as an app wires them.
final _pages = <String, Widget Function()>{
  'home': () => const HomePage(onOpen: _tap),
  'agenda': () => const AgendaPage(onOpen: _tap),
  'document': () => const DocumentPage(onOpen: _tap),
  'readings': () => const ReadingsPage(onOpen: _tap),
  'shelf': () => const ShelfPage(onOpen: _tap),
  'table': () => const TablePage(),
  'account': () => const AccountPage(onSave: _tap),
  'month': () => const MonthPage(onOpen: _tap),
};

void main() {
  setUpAll(loadRetroDesktopFonts);

  test('every part that takes a callback is named in the table', () {
    final found = _interactive();
    // A sample may show one class another way ('RetroDesktopButton (wide)', 'RetroDesktopButton.text'): its class
    // is the name before the first space or dot.
    final named = {
      for (final key in _parts.keys) key.split(' ').first.split('.').first,
    };
    expect(
      found.difference(named),
      isEmpty,
      reason: 'a new control: add it to the table',
    );
    expect(
      named.difference(found),
      isEmpty,
      reason: 'gone from the library: take it out',
    );
  });

  for (final MapEntry(key: name, value: build) in _parts.entries) {
    for (final dark in const [false, true]) {
      testWidgets('$name reaches 48 by 48 at 390 ${dark ? 'dark' : 'light'}', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const key = ValueKey('part');
        await tester.pumpWidget(
          retroDesktopApp(
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [KeyedSubtree(key: key, child: build())],
                ),
              ),
            ),
            dark: dark,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final reaches = _reaches(
          find.byKey(key).evaluate().single,
          gestures: _byPointer.contains(name),
        );
        expect(reaches, isNotEmpty, reason: 'nothing in $name takes a tap');
        expect(_problems(reaches), isEmpty);
      });
    }
  }

  // On this touch host, a close action keeps a 48px target at either layout
  // width. A display-only title bar fits the larger chrome type in 30px.
  for (final (width, closes, bar) in const [
    (390.0, true, 48.0),
    (390.0, false, 30.0),
    (1440.0, true, 48.0),
    (1440.0, false, 30.0),
  ]) {
    testWidgets(
      'a window ${closes ? 'that closes' : 'that does not close'} at $width: its bar is $bar tall',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var closed = 0;
        await tester.pumpWidget(
          retroDesktopApp(
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: RetroDesktopWindow(
                  title: 'A window',
                  onClose: closes ? () => closed++ : null,
                  child: const Text('Inside'),
                ),
              ),
            ),
            width: width,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final bars = find.descendant(
          of: find.byType(RetroDesktopWindow),
          matching: find.byType(CustomMultiChildLayout),
        );
        expect(tester.getSize(bars.first).height, bar);
        if (!closes) return;
        final reaches = _reaches(
          find.byType(RetroDesktopWindow).evaluate().single,
        );
        expect(reaches, hasLength(1));
        final (_, press) = reaches.single;
        if (width < retroDesktopDeskWidth) {
          expect(_problems(reaches), isEmpty);
          expect(press.top, tester.getTopLeft(bars.first).dy);
        }
        await tester.tapAt(press.center);
        expect(closed, 1);
      },
    );
  }

  for (final MapEntry(key: name, value: page) in _pages.entries) {
    testWidgets('the $name page: every press reaches 48 by 48 at 390', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        retroDesktopApp(
          RetroDesktopChromeScope(
            brand: 'Your name',
            nav: _nav,
            active: 0,
            child: page(),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        _problems(_reaches(tester.binding.rootElement!, off: true)),
        isEmpty,
      );
    });
  }
}
