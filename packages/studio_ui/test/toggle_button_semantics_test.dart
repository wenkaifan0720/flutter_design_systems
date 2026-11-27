// A key that latches reads as Flutter's IconButton(isSelected:) does: a
// button, selected while it is latched, not a switch. The record key is one:
// selected while it records.
import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart'
    show IconButton, MaterialApp, Scaffold;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

void main() {
  setUpAll(studioLoadFonts);

  for (final recording in [true, false]) {
    testWidgets('the record key, ${recording ? '' : 'not '}recording, reads '
        'as IconButton(isSelected: $recording) does', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) =>
              StudioHost(brightness: Brightness.light, child: app!),
          home: Scaffold(
            body: Column(
              children: [
                MergeSemantics(
                  child: Semantics(
                    label: 'Flutter toggle',
                    child: IconButton(
                      isSelected: recording,
                      onPressed: () {},
                      icon: const Icon(LucideIcons.circle),
                    ),
                  ),
                ),
                StudioTransportKey(
                  icon: const Icon(LucideIcons.circle),
                  tooltip: 'Record',
                  record: true,
                  lit: recording,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final flutter = tester
          .getSemantics(find.bySemanticsLabel('Flutter toggle'))
          .getSemanticsData()
          .flagsCollection;
      final studio = tester
          .getSemantics(find.bySemanticsLabel('Record'))
          .getSemanticsData()
          .flagsCollection;
      expect(studio.isButton, isTrue);
      expect(studio.isButton, flutter.isButton);
      expect(studio.isSelected, recording ? Tristate.isTrue : Tristate.isFalse);
      expect(studio.isSelected, flutter.isSelected);
      expect(studio.isToggled, Tristate.none, reason: 'not a switch');
      expect(studio.isToggled, flutter.isToggled);
      semantics.dispose();
    });
  }

  testWidgets('the play key, which does not latch, says no selected state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            StudioHost(brightness: Brightness.light, child: app!),
        home: Scaffold(
          body: StudioTransportKey(
            icon: const Icon(LucideIcons.play),
            tooltip: 'Play',
            lit: true,
            onPressed: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final flags = tester
        .getSemantics(find.bySemanticsLabel('Play'))
        .getSemanticsData()
        .flagsCollection;
    expect(flags.isButton, isTrue);
    expect(flags.isSelected, Tristate.none);
    expect(flags.isToggled, Tristate.none);
    semantics.dispose();
  });
}
