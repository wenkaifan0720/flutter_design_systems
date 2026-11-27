// ui_core_test's semantics checks over every gallery page: each control keeps a node of its own and a field's label
// is read once.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'gallery_support.dart';

const _nodes = DesignControlNodesCheck(look: 'Neumorphism');
const _fields = DesignFieldSemanticsCheck(look: 'Neumorphism');

void main() {
  testWidgets('every gallery page: a node for each control, labels read once', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    final problems = <String>[];
    for (final page in galleryPages) {
      await pumpGalleryPage(t, page, 'porcelain', Brightness.light);
      if (t.takeException() case final e?) problems.add('${page.id}: $e');
      final at = t.element(find.byKey(ValueKey('${page.id}/porcelain/light')));
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
