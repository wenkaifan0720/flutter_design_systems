// Jotter's everyday screens at a phone's, a tablet's and a desktop's width,
// by day and by night: each lays out with nothing overflowing and nothing
// thrown. And to a screen reader: every node is named once, and on a desk
// the side column's places are there beside whatever the body holds. At
// 200% text, nothing overflows and no words are cut short.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';

import '../example/lib/everyday_screens.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : keycapRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// Every run of words laid out shorter than its lines need.
List<String> _cut(WidgetTester tester) => [
  for (final p in tester.allRenderObjects.whereType<RenderParagraph>())
    if (p.attached && p.hasSize && p.firstChild == null)
      if (p.getDryLayout(BoxConstraints(maxWidth: p.size.width))
          case final natural when p.size.height + 0.5 < natural.height)
        '"${p.text.toPlainText()}": ${p.size.height} of ${natural.height}',
];

void main() {
  setUpAll(_loadFonts);
  for (final screen in everydayScreens) {
    for (final width in const [390.0, 1440.0]) {
      testWidgets('${screen.id} at ${width.toInt()} with 200% text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          screen.app(Brightness.light, TextDirection.ltr),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(_cut(tester), isEmpty);
      });
    }
  }
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
        void visit(SemanticsNode node) {
          final data = node.getSemanticsData();
          final lines = data.label
              .split('\n')
              .map((l) => l.trim().toLowerCase())
              .where((l) => l.isNotEmpty)
              .toList();
          if (lines.toSet().length < lines.length) twice.add(data.label);
          if (data.flagsCollection.isButton || data.role == SemanticsRole.tab) {
            buttons.add(data.label.split('\n').first);
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
        // Under a sheet or a dialog the page, its places with it, is rightly
        // hidden from a screen reader.
        if (width >= 1024 &&
            !const {'delete', 'move', 'share'}.contains(screen.id)) {
          expect(
            buttons,
            containsAll(const ['Home', 'Notes', 'Settings']),
            reason: "the side column's places, beside the body's navigator",
          );
        }
        semantics.dispose();
      });
    }
  }
}
