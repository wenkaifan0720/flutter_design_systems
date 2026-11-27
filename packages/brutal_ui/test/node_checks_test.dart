// ui_core_test 0.6.0's node checks on Brutal, the round's proof: every control a screen shows keeps a node a screen
// reader reaches, and each field's controls take their own taps and its label is read once. On every gallery page by
// day and by night.
// ignore_for_file: avoid_relative_lib_imports
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/admit/admit.dart';

List<String> _failed(BuildContext context) => [
  for (final p in const DesignControlNodesCheck(
    look: 'Brutal',
  ).check(context).problems)
    p.toString(),
  for (final p in const DesignFieldSemanticsCheck(
    look: 'Brutal',
  ).check(context).problems)
    p.toString(),
];

void main() {
  setUpAll(brutalLoadFonts);

  for (final (i, page) in galleryPages.indexed) {
    for (final appearance in const [
      AdmitAppearance.light,
      AdmitAppearance.dark,
    ]) {
      testWidgets(
        'the ${page.id} page by ${appearance == AdmitAppearance.light ? 'day' : 'night'}: its controls and fields',
        (tester) async {
          tester.view.physicalSize = const Size(1440, 4000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final semantics = tester.ensureSemantics();
          try {
            await tester.pumpWidget(
              AdmitApp(
                parts: [
                  for (final p in galleryPages)
                    (title: p.title, build: p.build),
                ],
                initialPart: i,
                initialAppearance: appearance,
              ),
            );
            for (var s = 0; s < 3; s++) {
              await tester.pump(const Duration(seconds: 1));
            }
            final failed = _failed(tester.element(find.byType(AdmitApp)));
            expect(failed, isEmpty, reason: failed.join('\n'));
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}
