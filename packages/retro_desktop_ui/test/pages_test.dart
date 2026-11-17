// The example pages are what a unit copies, so they stand under the same law as the parts: every preset, both modes,
// a small phone, a phone and a desktop, no exception, no overflow, and no column crushed to a word's width.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
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

const _nav = [
  RetroDesktopNavItem(label: 'Today', short: 'Today', icon: LucideIcons.house),
  RetroDesktopNavItem(
    label: 'Places',
    short: 'Places',
    icon: LucideIcons.compass,
  ),
  RetroDesktopNavItem(label: 'You', short: 'You', icon: LucideIcons.user),
];
const _brand = 'Your name';

final _pages = <String, Widget Function()>{
  'home': () => const HomePage(),
  'agenda': () => const AgendaPage(),
  'document': () => const DocumentPage(),
  'readings': () => const ReadingsPage(),
  'shelf': () => const ShelfPage(),
  'table': () => const TablePage(),
  'account': () => const AccountPage(),
  'month': () => const MonthPage(),
};

/// A word's column: narrow and tall, a word a letter per line. The fault the test found most of.
List<String> _crushed(WidgetTester tester) {
  final out = <String>[];
  for (final p in tester.renderObjectList<RenderParagraph>(
    find.byType(RichText, skipOffstage: false),
  )) {
    final words = p.text.toPlainText().trim();
    if (words.length < 8) continue;
    final s = p.size;
    if (s.width < 72 && s.height > 3 * s.width) {
      out.add(
        '"$words" ${s.width.toStringAsFixed(0)}x${s.height.toStringAsFixed(0)}',
      );
    }
  }
  return out;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadRetroDesktopFonts();
  });

  Future<void> holds(
    WidgetTester tester,
    Widget Function() page,
    String preset,
    bool dark,
    double width, {
    double scale = 1,
    TextDirection direction = TextDirection.ltr,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      debugPrint(details.toString());
      previousErrorHandler?.call(details);
    };
    try {
      await tester.pumpWidget(
        retroDesktopApp(
          RetroDesktopChromeScope(
            brand: _brand,
            nav: _nav,
            active: 0,
            child: page(),
          ),
          preset: preset,
          dark: dark,
          scale: scale,
          direction: direction,
        ),
      );
      await tester.pump();
    } finally {
      FlutterError.onError = previousErrorHandler;
    }
    expect(tester.takeException(), isNull);
    expect(_crushed(tester), isEmpty);
  }

  // Every day each page runs on a small phone, in two presets (light on a phone, dark on a desk: the presets turn round
  // the pages, so each is seen both ways) and at 2x text once (the pages turn round the widths and directions, so each
  // width is seen both ways); the rest of the matrix in the sweep.
  final presets = RetroDesktopThemeData.presets.toList();
  for (final (i, page) in _pages.entries.indexed) {
    testWidgets(
      '${page.key} on a small phone',
      (tester) => holds(tester, page.value, 'classic', false, 320),
    );
    for (final (p, preset) in presets.indexed) {
      for (final dark in const [false, true]) {
        for (final width in const [390.0, 1440.0]) {
          final everyday = dark
              ? width == 1440 && p == (i + 2) % presets.length
              : width == 390 && p == i % presets.length;
          testWidgets(
            '${page.key} $preset ${dark ? 'dark' : 'light'} @$width',
            tags: sweepUnless(everyday),
            (tester) => holds(tester, page.value, preset, dark, width),
          );
        }
      }
    }
  }

  const widths = [390.0, 768.0, 1024.0, 1440.0];
  for (final (i, page) in _pages.entries.indexed) {
    for (final (w, width) in widths.indexed) {
      for (final (d, direction) in TextDirection.values.indexed) {
        testWidgets(
          '${page.key} at 2x text, $width, $direction',
          tags: sweepUnless(i % (widths.length * 2) == w * 2 + d),
          (tester) => holds(
            tester,
            page.value,
            'classic',
            false,
            width,
            scale: 2,
            direction: direction,
          ),
        );
      }
    }
  }

  // A judge said the hero filled the phone's first screen on 4 of 5 first screens. Every page but the look's home shows
  // the page's job above the fold of a 390 x 844 phone, under the menu bar and over the strip.
  const job = {
    'agenda': 'Confirm the first thing',
    'document': 'A plan worth keeping',
    'readings': 'Showers',
    'shelf': 'The first thing',
    'table': '640',
    'account': 'Your name',
    'month': 'March 2026',
  };
  for (final page in job.entries) {
    testWidgets('${page.key} shows its job on the first phone screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        retroDesktopApp(
          RetroDesktopChromeScope(
            brand: _brand,
            nav: _nav,
            active: 0,
            child: _pages[page.key]!(),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final top = tester.getTopLeft(find.text(page.value).first).dy;
      expect(
        top,
        lessThan(844 - 84 - 40),
        reason: '"${page.value}" starts at $top',
      );
    });
  }

  // Tiled, a short window takes the slack of its column, so the last of a column can stand empty. No example does: a third of
  // a window with nothing in it, under its words, is a page written for another page's height.
  for (final page in _pages.entries) {
    testWidgets('${page.key} has no blank third in a window', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        retroDesktopApp(
          RetroDesktopChromeScope(
            brand: _brand,
            nav: _nav,
            active: 0,
            child: page.value(),
          ),
        ),
      );
      await tester.pump();
      final blank = <String>[];
      for (final window in find.byType(RetroDesktopWindow).evaluate()) {
        final box = window.renderObject! as RenderBox;
        final rect = box.localToGlobal(Offset.zero) & box.size;
        var deepest = rect.top;
        void walk(Element e) {
          final r = e.renderObject;
          if (e.widget is RichText && r is RenderParagraph) {
            final at = r.localToGlobal(Offset.zero).dy + r.size.height;
            // The status line stands at the foot: it doesn't fill what's above it.
            if (at < rect.bottom - 30 && at > deepest) deepest = at;
          }
          e.visitChildren(walk);
        }

        window.visitChildren(walk);
        final empty = rect.bottom - 30 - deepest;
        if (empty > rect.height / 3) {
          final title = (window.widget as RetroDesktopWindow).title;
          blank.add('$title: $empty of ${rect.height}');
        }
      }
      expect(blank, isEmpty);
    });
  }
}
