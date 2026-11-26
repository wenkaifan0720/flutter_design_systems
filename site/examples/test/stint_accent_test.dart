import 'dart:convert';
import 'dart:io';

import 'package:appliance_ui/appliance_ui.dart' show ApplianceThemeData;
import 'package:brutal_ui/brutal_ui.dart' show BrutalThemeData;
import 'package:civic_ui/civic_ui.dart' show CivicThemeData;
import 'package:clay_ui/clay_ui.dart' show ClayThemeData;
import 'package:comic_ui/comic_ui.dart' show ComicThemeData;
import 'package:design_system_examples/generated/studies.dart' as studies;
import 'package:fluent2_design_ui/fluent2_design_ui.dart' show Fluent2ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart' show FrostedThemeData;
import 'package:gloss_ui/gloss_ui.dart' show GlossThemeData;
import 'package:keycap_ui/keycap_ui.dart' show KeycapThemeData;
import 'package:ledger_ui/ledger_ui.dart' show LedgerThemeData;
import 'package:material_expressive_ui/material_expressive_ui.dart'
    show ExpressiveThemeData;
import 'package:minimal_ui/minimal_ui.dart' show MinimalThemeData;
import 'package:neumorphism_ui/neumorphism_ui.dart' show NeumorphicThemeData;
import 'package:retro_desktop_ui/retro_desktop_ui.dart'
    show RetroDesktopThemeData;
import 'package:stint_core/stint_core.dart';
import 'package:studio_ui/studio_ui.dart' show StudioThemeData;
import 'package:terminal_ui/terminal_ui.dart' show TermThemeData;

/// Each look's palettes as its package names them, its default first.
final presets = <String, List<String>>{
  'appliance': ApplianceThemeData.presets,
  'brutal': BrutalThemeData.presets,
  'civic': CivicThemeData.presets,
  'clay': ClayThemeData.presets,
  'comic': ComicThemeData.presets,
  'fluent2': Fluent2ThemeData.presets,
  'frosted': FrostedThemeData.presets,
  'gloss': GlossThemeData.presets,
  'keycap': KeycapThemeData.presets,
  'ledger': LedgerThemeData.presets,
  'material_expressive': [
    ExpressiveThemeData.defaultPreset,
    ...ExpressiveThemeData.presets.where(
      (id) => id != ExpressiveThemeData.defaultPreset,
    ),
  ],
  'minimal': MinimalThemeData.presets,
  'neumorphism': NeumorphicThemeData.presets,
  'retro_desktop': RetroDesktopThemeData.presets,
  'studio': StudioThemeData.presets,
  'terminal': TermThemeData.presets,
  // The reference editions: their own colours, then Stint's five seeds.
  'material': ['look', for (final a in StintAccent.values) a.name],
  'cupertino': ['look', for (final a in StintAccent.values) a.name],
};

/// Every edition offers the Stint page's accent menu its look's six named
/// palettes, the look's own first, and nothing else; and opens in each of
/// them, by day and by night, at phone and desktop width, with nothing
/// thrown (an assert included) and nothing overflowing.
void main() {
  final looks = (jsonDecode(File('../looks.json').readAsStringSync()) as Map)
      .keys
      .cast<String>();
  test('every edition has its look\'s palettes listed here', () {
    expect(presets.keys.toSet(), looks.toSet());
  });
  for (final look in looks) {
    testWidgets('$look offers its look\'s six palettes, its own first', (
      tester,
    ) async {
      final settings = StintSettings(const StintLaunch());
      addTearDown(settings.dispose);
      final app = await tester.runAsync(
        () => studies.openStudy(look, const StintLaunch().sharing(settings)),
      );
      await tester.pumpWidget(app!);
      await tester.pump(const Duration(milliseconds: 400));
      final offered = settings.palettes;
      expect(offered.map((p) => p.id), presets[look]);
      expect(offered, hasLength(6));
      expect(offered.map((p) => p.name).toSet(), hasLength(6));
      expect(settings.palette, offered.first, reason: 'the look\'s own');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
    for (final size in [const Size(390, 844), const Size(1440, 960)]) {
      testWidgets('$look in every palette at ${size.width.round()}', (
        tester,
      ) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final accent in presets[look]!) {
          for (final appearance in [Appearance.day, Appearance.night]) {
            final settings = StintSettings(
              StintLaunch(accent: accent, appearance: appearance),
            );
            // Opening loads the look's fonts, real I/O the test's fake
            // clock would never finish.
            final app = await tester.runAsync(
              () => studies.openStudy(
                look,
                StintLaunch(
                  accent: accent,
                  appearance: appearance,
                ).sharing(settings),
              ),
            );
            await tester.pumpWidget(app!);
            for (var i = 0; i < 4; i++) {
              await tester.pump(const Duration(milliseconds: 400));
            }
            expect(
              tester.takeException(),
              isNull,
              reason: '$look, $accent, ${appearance.name}',
            );
            expect(settings.palette?.id, accent);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump(const Duration(seconds: 1));
            settings.dispose();
          }
        }
      });
    }
  }
}
