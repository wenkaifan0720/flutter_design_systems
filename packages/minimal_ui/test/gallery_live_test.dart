// ignore_for_file: avoid_relative_lib_imports
// The example is the package's live gallery: every page builds without an error at a phone's
// width and at a desktop's, and every widget the package exports is built by at least one page. A widget no page
// builds fails the last test by name, so the next one added can't slip through unseen.
// The export adds minimal_host.dart for MinimalHitTarget, named below as host-only.
// ignore_for_file: unused_import

import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import '../example/lib/kit_gallery/apps/app_frame.dart';
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/gallery.dart';
import 'flutter_test_config.dart' show longWalkLeakTesting;

/// Drip's host layer: its kit parts wrap a control in it to pass the tap
/// floor's margin through a box that stops taps; no gallery page needs it.
const _hostOnly = {'MinimalHitTarget'};

/// Every public widget class the package's library declares, outside its
/// internal helpers.
Set<String> _exportedWidgets() {
  final declared = RegExp(
    r'^class (Minimal\w+)(?:<[^>]*>)? extends '
    r'(?:StatelessWidget|StatefulWidget|SingleChildRenderObjectWidget)\b',
    multiLine: true,
  );
  return {
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.dart') &&
          !file.path.contains('${Platform.pathSeparator}internal'))
        for (final m in declared.allMatches(file.readAsStringSync()))
          m.group(1)!,
  };
}

void main() {
  final built = <String>{};

  // Each page and app at both widths. The everyday tier builds each once,
  // at 390 and 1440 in turn; the sweep tier the other width.
  for (final (i, page) in galleryPagesAll.indexed) {
    for (final (w, size) in const [Size(390, 844), Size(1440, 1000)].indexed) {
      testWidgets(
        '${page.name} builds at ${size.width.round()}',
        (tester) async {
          final semantics = tester.ensureSemantics();
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          kitEmbedded = true;
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MinimalHost(
                light: kitTheme(Brightness.light),
                dark: kitTheme(Brightness.dark),
                brightness: Brightness.light,
                child: child!,
              ),
              home: ExamplePageView(
                page: page,
                brightness: Brightness.light,
                onOpen: (_) {},
                bar: MinimalAppBar(title: page.name),
              ),
            ),
          );
          // Spinners and skeletons never settle: a few frames build every
          // demo and run its first animations.
          for (var i = 0; i < 4; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          for (final element in tester.allElements) {
            built.add('${element.widget.runtimeType}'.split('<').first);
          }
          // Every band's heading reaches a screen reader, the windows' too:
          // a demo's own app or navigator stands a route's modal barrier,
          // which hides whatever painted before it in its semantics
          // container (on the Navigation page, the shell window would take
          // the top bars and the menu bar above it out of the page's
          // semantics).
          final headings = [
            for (final screen in tester.widgetList<KitEmbeddedScreen>(
              find.byType(KitEmbeddedScreen),
            ))
              screen.title,
            for (final window in tester.widgetList<KitWindow>(
              find.byType(KitWindow),
            ))
              ?window.title,
          ];
          for (final heading in headings) {
            expect(
              find.bySemanticsLabel(heading),
              findsWidgets,
              reason: '${page.name}: "$heading" is out of the semantics',
            );
          }
          await tester.pumpWidget(const SizedBox());
          semantics.dispose();
        },
        tags: w == i % 2 ? null : 'sweep',
        experimentalLeakTesting: longWalkLeakTesting,
      );
    }
  }

  // A page builds its rows as they scroll into view, so the build above
  // meets only the first screen of a long one. The inventory, scrolled to its
  // end at a phone's width, builds every row without an error: an overflow
  // fails it at the offset it shows at.
  testWidgets('Inventory scrolled to its end builds every row at 390', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    kitEmbedded = true;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MinimalHost(
          light: kitTheme(Brightness.light),
          dark: kitTheme(Brightness.dark),
          brightness: Brightness.light,
          child: child!,
        ),
        home: ExamplePageView(
          page: inventoryPage,
          brightness: Brightness.light,
          onOpen: (_) {},
          bar: MinimalAppBar(title: inventoryPage.name),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // The page's own list: the vertical scrollable that runs longest.
    final position = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .map((s) => s.position)
        .where((p) => p.axis == Axis.vertical)
        .reduce((a, b) => a.maxScrollExtent >= b.maxScrollExtent ? a : b);
    expect(position.maxScrollExtent, greaterThan(position.viewportDimension));
    var steps = 0;
    while (position.pixels < position.maxScrollExtent) {
      position.jumpTo(
        (position.pixels + position.viewportDimension * 0.75).clamp(
          0,
          position.maxScrollExtent,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester.takeException(),
        isNull,
        reason: 'at ${position.pixels.round()} px down the inventory',
      );
      for (final element in tester.allElements) {
        built.add('${element.widget.runtimeType}'.split('<').first);
      }
      steps += 1;
    }
    expect(steps, greaterThan(1));
    await tester.pumpWidget(const SizedBox());
  }, experimentalLeakTesting: longWalkLeakTesting);

  // The apps build what no page does (the shell's parts, the tables, the
  // records): pumped at both widths, they count toward the last test. Their
  // own checks are apps_test.dart's.
  for (final (i, app) in exampleApps.indexed) {
    for (final (w, size) in const [Size(390, 844), Size(1440, 1000)].indexed) {
      testWidgets(
        '${app.name} builds at ${size.width.round()}',
        (tester) async {
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            GalleryApp.at(Uri.parse('http://localhost/?app=${app.slug}')),
          );
          for (var i = 0; i < 4; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(find.byType(KitApp), findsOneWidget);
          for (final element in tester.allElements) {
            built.add('${element.widget.runtimeType}'.split('<').first);
          }
          await tester.pumpWidget(const SizedBox());
        },
        tags: w == i % 2 ? null : 'sweep',
        experimentalLeakTesting: longWalkLeakTesting,
      );
    }
  }

  test('a link opens the page, the appearance and the knobs it names', () {
    final app = GalleryApp.at(
      Uri.parse(
        'http://localhost/?page=lists-and-tables&appearance=dark'
        '&radius=12&density=compact',
      ),
    );
    expect(galleryPagesAll[app.initialPage].name, 'Lists and tables');
    expect(app.initialApp, isNull);
    expect(app.initialBrightness, Brightness.dark);
    expect(app.initialKnobs.radius, 12);
    expect(app.initialKnobs.density, Density.compact);
    final ritual = GalleryApp.at(Uri.parse('http://localhost/?app=habits'));
    expect(exampleApps[ritual.initialApp!].name, 'Ritual');
    expect(ritual.initialScreen, isNull);
    final habit = GalleryApp.at(
      Uri.parse('http://localhost/?app=habits&screen=habit'),
    );
    expect(habit.initialScreen, 'habit');
    final inventory = GalleryApp.at(
      Uri.parse('http://localhost/?page=inventory'),
    );
    expect(galleryPagesAll[inventory.initialPage].name, 'Inventory');
    final plain = GalleryApp.at(Uri.parse('http://localhost/?page=nowhere'));
    expect(plain.initialPage, 0);
    expect(plain.initialApp, isNull);
    expect(plain.initialBrightness, Brightness.light);
    expect(plain.initialKnobs, const Knobs());
  });

  test('every exported widget is built by a live page', () {
    final exported = _exportedWidgets();
    expect(exported, isNotEmpty);
    expect(
      exported.difference(built).difference(_hostOnly).toList()..sort(),
      isEmpty,
      reason: 'each of these needs a live demo on one of the example pages',
    );
  });
}
