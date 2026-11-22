// The pigment can't spread: it's out of the barrel, a part takes no colour of the page's, and a page has one act.
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/theme.dart'
    show NeumorphicPigment;

import 'flat_stage.dart';
import 'support.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadNeumorphicFonts();
  });

  group('the pigment cannot spread', () {
    test('the barrel keeps raw pigment and paint helpers out', () {
      final file = File('lib/src/neumorphism.dart');
      final barrel = file.readAsStringSync();
      // The exporter rewrites this path and its directives to the package stem.
      final stem = file.uri.pathSegments.last.replaceFirst('.dart', '');
      for (final hidden in [
        'NeumorphicPigment',
        'neumorphicPaintRaised',
        'neumorphicPaintPressed',
      ]) {
        expect(barrel, contains(hidden), reason: 'hide $hidden');
      }
      // The theme's export hides the pigment first; the rule and edge widths it hides beside it are paint helpers too.
      expect(
        barrel,
        matches(
          RegExp("export '$stem/theme\\.dart'\\s+hide NeumorphicPigment\\b"),
        ),
      );
    });

    test('no example page reaches for a pigment or a colour', () {
      final found = <String>[];
      for (final f in examplePages()) {
        final s = f.readAsStringSync();
        for (final bad in [
          '.pigment',
          'pigmentInk',
          'pigmentHi',
          'onPigment',
          'colors.',
          'Color(',
          'Colors.',
          "plaster/theme.dart",
        ]) {
          if (s.contains(bad)) found.add('${f.path}: $bad');
        }
      }
      expect(found, isEmpty);
    });

    test('colour overrides stay confined to documented primitives', () {
      final field = RegExp(r'^\s*final Color\??\s+\w+', multiLine: true);
      final found = <String>[];
      for (final f in lookLibrary()) {
        if (f.path.endsWith('/theme.dart') ||
            f.path.endsWith('/geometry.dart')) {
          continue;
        }
        final s = f.readAsStringSync();
        for (final c in RegExp(
          r'^class (\w+)[^\n{]*\{',
          multiLine: true,
        ).allMatches(s)) {
          final name = c[1]!;
          if (name.startsWith('_') || !name.startsWith('Neumorphic')) continue;
          final end = s.indexOf(RegExp(r'^class ', multiLine: true), c.end);
          final body = s.substring(c.start, end < 0 ? s.length : end);
          if (field.hasMatch(body)) found.add(name);
        }
      }
      // A spine is a rule in a column, its colour a token passed inside the library.
      found.remove('NeumorphicColumn');
      // A busy button supplies its on-face ink to its spinner. The package's
      // styling contract permits this primitive override; pages still use
      // the preset defaults, checked independently above.
      found.remove('NeumorphicCircularProgressIndicator');
      // The parts library's cell bank and panel-row painters: internal helpers, each handed its colour by the part
      // that draws it.
      found.remove('NeumorphicCellBank');
      found.remove('NeumorphicPanelRowRelief');
      found.remove('NeumorphicPanelRowRaise');
      expect(found, isEmpty);
    });

    test('an example page has one act', () {
      final found = <String>[];
      for (final f in examplePages()) {
        final acts = 'NeumorphicButton.filled('
            .allMatches(f.readAsStringSync())
            .length;
        // A page may place its act twice by width: the rail's on a desktop and the top's on a phone, or a footer's. Never two on one screen: agenda and form hold one.
        if (acts > 1) found.add('${f.path}: $acts');
      }
      expect(found, isEmpty);
    });

    for (final b in Brightness.values) {
      testWidgets('the pigment is a small share of a page, ${b.name}', (
        tester,
      ) async {
        final t = NeumorphicThemeData.preset('porcelain', b);
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: NeumorphicTheme(
                data: t,
                child: RepaintBoundary(
                  key: flatStage,
                  child: ColoredBox(
                    color: t.colors.ground,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const NeumorphicPageHead(
                          title: 'A page',
                          subtitle: 'A line',
                        ),
                        const NeumorphicLatchGroup(
                          options: [
                            NeumorphicLatch('One', icon: NeumorphicGlyphs.sun),
                            NeumorphicLatch('Two'),
                          ],
                          value: 'One',
                        ),
                        const NeumorphicDial(
                          compact: true,
                          value: 40,
                          figure: '40',
                          label: 'A word',
                        ),
                        NeumorphicButton.filled('Do it', onPressed: () {}),
                        const NeumorphicLiveText('A state'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final (w, h, px) = await stagePixels(tester);
        final share = pigmentPixels(px, t.colors.pigment) / (w * h);
        expect(share, lessThan(.04));
      }, tags: ['goldens']);
    }
  });
}
