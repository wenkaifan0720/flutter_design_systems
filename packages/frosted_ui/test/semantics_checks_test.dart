// ui_core_test's semantics checks over Shelf, the example app, and every gallery page: each control keeps a node of its
// own, a field's label is read once, and the places stay in reach, each taking a tap, with a book's page pushed.
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import 'gallery_support.dart';

const _nodes = DesignControlNodesCheck(look: 'Frosted');
const _fields = DesignFieldSemanticsCheck(look: 'Frosted');

Future<void> _shelf(WidgetTester t, double width) async {
  t.view.physicalSize = Size(width, width < 600 ? 844 : 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(KeyedSubtree(key: UniqueKey(), child: ShelfApp()));
  await t.pumpAndSettle();
}

List<String> _read(WidgetTester t, String screen) {
  final at = t.element(find.byType(ShelfApp));
  return [
    for (final p in [
      ..._nodes.check(at).problems,
      ..._fields.check(at).problems,
    ])
      '$screen: $p',
  ];
}

// The fonts the package ships, so words take their real widths.
Future<void> _fonts() async {
  final manifest = (json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>).cast<Map<String, dynamic>>();
  for (final family in manifest) {
    final name = family['family'] as String;
    final fonts = (family['fonts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    for (final alias in [
      name,
      if (!name.startsWith('packages/')) 'packages/frosted_ui/$name',
    ]) {
      final loader = FontLoader(alias);
      for (final font in fonts) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  }
}

void main() {
  setUpAll(_fonts);
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'Shelf at ${width.round()}: a node for each control, labels read once',
      (t) async {
        final semantics = t.ensureSemantics();
        await _shelf(t, width);
        final problems = _read(t, 'Books');
        await t.tap(find.text('Middlemarch'));
        await t.pumpAndSettle();
        problems.addAll(_read(t, 'a book'));
        await t.tap(find.text('Delete'));
        await t.pumpAndSettle();
        problems.addAll(_read(t, 'the delete dialog'));
        await _shelf(t, width);
        await t.tap(find.bySemanticsLabel('Add a book'));
        await t.pumpAndSettle();
        await t.tap(find.text('Save'));
        await t.pumpAndSettle();
        problems.addAll(_read(t, 'the form, its title missing'));
        await _shelf(t, width);
        await t.tap(find.text('Settings').last);
        await t.pumpAndSettle();
        problems.addAll(_read(t, 'Settings'));
        expect(problems, isEmpty, reason: problems.join('\n'));
        semantics.dispose();
      },
    );
  }

  for (final width in [1024.0, 1440.0]) {
    testWidgets(
      'Shelf at ${width.round()}: the places stay in reach with a page pushed',
      (t) async {
        final semantics = t.ensureSemantics();
        await _shelf(t, width);
        await t.tap(find.text('Middlemarch'));
        await t.pumpAndSettle();
        const DesignNavigationCheck(look: 'Frosted')
            .check(
              t.element(find.byType(ShelfApp)),
              destinations: ['Books', 'Reading', 'Settings'],
            )
            .verify();
        semantics.dispose();
      },
    );
  }

  testWidgets('every gallery page: a node for each control, labels read once', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    final problems = <String>[];
    for (final page in galleryPages) {
      await pumpGalleryPage(t, page, 'opal', Brightness.light);
      if (t.takeException() case final e?) problems.add('${page.id}: $e');
      final at = t.element(find.byKey(ValueKey('${page.id}/opal/light')));
      problems.addAll([
        for (final p in [
          ..._nodes.check(at).problems,
          ..._fields.check(at).problems,
        ])
          '${page.id}: $p',
      ]);
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
    semantics.dispose();
  }, timeout: const Timeout(Duration(minutes: 20)));
}
