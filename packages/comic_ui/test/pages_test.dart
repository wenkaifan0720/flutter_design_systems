// The example pages are what a unit copies, so they stand under the same law as the parts: every preset, both modes,
// a small phone, a phone and a desktop, no exception, no overflow, and no column crushed to a word's width.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/comic_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'pages/agenda_page.dart';
import 'pages/form_page.dart';
import 'pages/home_page.dart';
import 'pages/ledger_page.dart';
import 'pages/method_page.dart';
import 'pages/profile_page.dart';
import 'pages/thread_page.dart';
import 'pages/wall_page.dart';
import 'support.dart';

const _nav = [
  ComicNavItem(label: 'Today', short: 'Today', icon: LucideIcons.house),
  ComicNavItem(label: 'Places', short: 'Places', icon: LucideIcons.compass),
];
const _brand = ComicBrand(name: 'Your name');

final _pages = <String, Widget Function()>{
  'home': () => const HomePage(),
  'agenda': () => const AgendaPage(),
  'wall': () => const WallPage(),
  'thread': () => const ThreadPage(),
  'ledger': () => const LedgerPage(),
  'method': () => const MethodPage(),
  'form': () => const FormPage(),
  'profile': () => const ProfilePage(),
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
    await loadComicFonts();
  });

  Future<void> holds(
    WidgetTester tester,
    Widget Function() page,
    String preset,
    bool dark,
    double width,
  ) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      comicApp(
        ComicChromeScope(brand: _brand, nav: _nav, active: 0, child: page()),
        preset: preset,
        dark: dark,
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(_crushed(tester), isEmpty);
  }

  for (final page in _pages.entries) {
    testWidgets(
      '${page.key} on a small phone',
      (tester) => holds(tester, page.value, 'offset', false, 320),
    );
    for (final preset in ComicThemeData.presets) {
      for (final dark in const [false, true]) {
        for (final width in const [390.0, 1440.0]) {
          testWidgets(
            '${page.key} $preset ${dark ? 'dark' : 'light'} @$width',
            (tester) => holds(tester, page.value, preset, dark, width),
          );
        }
      }
    }
  }

  // A judge said the hero filled the phone's first screen on 4 of 5 first screens. Every page but the look's home shows
  // the page's job above the fold of a 390 x 844 phone, under a masthead and over a tab bar.
  const job = {
    'agenda': 'WAITING ON YOU',
    'wall': 'THIS MONTH',
    'thread': 'LAST NIGHT, A LITTLE AFTER NINE',
    'ledger': 'WHERE YOU STAND',
    'method': 'TIME',
    'form': 'THE BASICS',
    'profile': 'YOUR CARD',
  };
  for (final page in job.entries) {
    testWidgets('${page.key} shows its job on the first phone screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        comicApp(
          ComicChromeScope(
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
}
