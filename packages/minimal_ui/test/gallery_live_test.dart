// ignore_for_file: avoid_relative_lib_imports
// The example is the package's live gallery (polish round 3, §4): every page builds without an error at a phone's
// width and at a desktop's, and every widget the package exports is built by at least one page. A widget no page
// builds fails the last test by name, so the next one added can't slip through unseen.
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import '../example/lib/kit_gallery/apps/app_frame.dart';
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/main.dart';

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

  for (final page in galleryPagesAll) {
    for (final size in const [Size(390, 844), Size(1440, 1000)]) {
      testWidgets('${page.name} builds at ${size.width.round()}', (
        tester,
      ) async {
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
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  // The apps build what no page does (the shell's parts, the tables, the
  // records): pumped at both widths, they count toward the last test. Their
  // own checks are apps_test.dart's.
  for (final app in exampleApps) {
    for (final size in const [Size(390, 844), Size(1440, 1000)]) {
      testWidgets('${app.name} builds at ${size.width.round()}', (
        tester,
      ) async {
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
      });
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
      exported.difference(built).toList()..sort(),
      isEmpty,
      reason: 'each of these needs a live demo on one of the example pages',
    );
  });
}
