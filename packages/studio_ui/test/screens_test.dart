// Roomtone's everyday screens at a phone's, a tablet's and a desktop's width, by day and by night: each lays out with
// nothing overflowing and nothing thrown. And to a screen reader: every node is named once (never a name and then
// the same words again), every button is named, and on a desk the side panel's places are there beside whatever the body holds.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';

import 'package:studio_ui/studio_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/everyday_screens.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : studioRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

// The screens that open on a dialog or a sheet over the page.
const _modal = {'discard', 'export'};

void main() {
  setUpAll(_loadFonts);
  for (final screen in everydayScreens) {
    for (final width in const [390.0, 768.0, 1440.0]) {
      for (final brightness in Brightness.values) {
        testWidgets('${screen.id} at ${width.toInt()} by ${brightness.name}', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(screen.app(brightness, TextDirection.ltr));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  for (final screen in everydayScreens) {
    for (final width in const [390.0, 1440.0]) {
      testWidgets('${screen.id} at ${width.toInt()} names each control once', (
        tester,
      ) async {
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
        // A place is a tab on ui_core's shell: "Home", then its place
        // ("Tab 1 of 4").
        final places = <String>{};
        void visit(SemanticsNode node) {
          // A node merged into its parent is read as part of it, never on
          // its own.
          if (node.isMergedIntoParent) return;
          final data = node.getSemanticsData();
          final lines = data.label
              .split('\n')
              .map((l) => l.trim().toLowerCase())
              .where((l) => l.isNotEmpty)
              .toList();
          if (lines.toSet().length < lines.length) twice.add(data.label);
          if (data.flagsCollection.isButton) buttons.add(data.label);
          if (data.flagsCollection.isButton || data.role == SemanticsRole.tab) {
            places.add(lines.isEmpty ? '' : data.label.split('\n').first);
          }
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
        expect(
          buttons.where((label) => label.trim().isEmpty),
          isEmpty,
          reason: 'every button is named',
        );
        // Under a sheet or a dialog the page, its places with it, is rightly
        // hidden from a screen reader.
        if (width >= 1024 && !_modal.contains(screen.id)) {
          expect(
            places,
            containsAll(const ['Home', 'Library', 'Record', 'Settings']),
            reason: "the side panel's places, beside the body's navigator",
          );
        }
        semantics.dispose();
      });
    }
  }
}
