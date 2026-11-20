// ignore_for_file: avoid_relative_lib_imports
// On the gallery pages that show them, every checkbox, switch and radio reads
// as that control, with its state, and never as a button, each control
// named, at a phone's width.
import 'dart:ui' show CheckedState, Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/main.dart';

/// Each page, the least number of checkables it shows and some of their
/// names (a name starts with these words).
const _pages = {
  'inventory': (4, ['Agree to the guidelines', 'Free', 'Pro', 'Reminders']),
  'pickers': (4, ['Morning', 'Afternoon', 'Evening', 'Any time']),
  'selection': (
    26,
    ['Reminders', 'Weekly digest', 'Meditate', 'Journal', 'Free', 'Standard'],
  ),
};

void main() {
  for (final MapEntry(key: slug, value: (least, names)) in _pages.entries) {
    testWidgets('$slug: its checkboxes, switches and radios are no buttons', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      // Tall enough that the whole page is built, every control in the tree.
      tester.view
        ..physicalSize = const Size(390, 9000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      kitEmbedded = true;
      final page = galleryPagesAll.singleWhere(
        (p) => GalleryApp.pageSlug(p.name) == slug,
      );
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
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      var root = tester.getSemantics(find.byType(ExamplePageView));
      while (root.parent != null) {
        root = root.parent!;
      }
      final checkables = <SemanticsNode>[];
      bool visit(SemanticsNode node) {
        final flags = node.getSemanticsData().flagsCollection;
        if (flags.isChecked != CheckedState.none ||
            flags.isToggled != Tristate.none) {
          checkables.add(node);
        }
        node.visitChildren(visit);
        return true;
      }

      visit(root);
      expect(checkables.length, greaterThanOrEqualTo(least));
      for (final node in checkables) {
        final data = node.getSemanticsData();
        expect(data.flagsCollection.isButton, isFalse, reason: data.label);
      }
      for (final name in names) {
        expect(
          checkables.where((n) => n.getSemanticsData().label.startsWith(name)),
          isNotEmpty,
          reason: name,
        );
      }
      semantics.dispose();
    });
  }
}
