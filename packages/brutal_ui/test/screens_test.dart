// Admit's everyday screens at a phone's, a tablet's and a desktop's width, by day and by night: each lays out with
// nothing overflowing and nothing thrown. And to a screen reader: every node is named once (never a name and then
// the same words again), and on a desk the side list's places are there beside whatever the body holds.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';

import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/everyday_screens.dart';
import 'tiers.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : brutalRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);
  // Each screen every run at one width, by day or by night, turning over the
  // screens so every width meets both; the rest in the sweep.
  for (final (i, screen) in everydayScreens.indexed) {
    for (final (w, width) in const [390.0, 768.0, 1440.0].indexed) {
      for (final brightness in Brightness.values) {
        testWidgets(
          '${screen.id} at ${width.toInt()} by ${brightness.name}',
          tags: sweepUnless(w == i % 3 && brightness.index == (i ~/ 3) % 2),
          (tester) async {
            tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(screen.app(brightness, TextDirection.ltr));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
  // Each screen every run at a phone's or a desk's width, in turn.
  for (final (i, screen) in everydayScreens.indexed) {
    for (final (w, width) in const [390.0, 1440.0].indexed) {
      testWidgets(
        '${screen.id} at ${width.toInt()} names each control once',
        tags: sweepUnless(w == i % 2),
        (tester) async {
          tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            screen.app(Brightness.light, TextDirection.ltr),
          );
          await tester.pumpAndSettle();
          final twice = <String>[];
          final buttons = <String>{};
          void visit(SemanticsNode node) {
            final data = node.getSemanticsData();
            final lines = data.label
                .split('\n')
                .map((l) => l.trim().toLowerCase())
                .where((l) => l.isNotEmpty)
                .toList();
            if (lines.toSet().length < lines.length) twice.add(data.label);
            if (data.flagsCollection.isButton) buttons.add(data.label);
            node.visitChildren((child) {
              visit(child);
              return true;
            });
          }

          visit(
            tester
                .binding
                .renderViews
                .first
                .owner!
                .semanticsOwner!
                .rootSemanticsNode!,
          );
          expect(twice, isEmpty, reason: 'a name, then the same words again');
          // Under a sheet or a dialog the page, its places with it, is rightly
          // hidden from a screen reader.
          if (width >= 1024 &&
              !const {'filter', 'cancel'}.contains(screen.id)) {
            expect(
              buttons,
              containsAll(const ['Home', 'Events', 'Tickets', 'Settings']),
              reason: "the side list's places, beside the body's navigator",
            );
          }
          semantics.dispose();
        },
      );
    }
  }
}
