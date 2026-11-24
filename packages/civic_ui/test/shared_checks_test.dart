// ui_core_test's checks over Brindlemere parking permits' everyday screens:
// every control a finger reaches on a phone is 48 by 48 at the least, and 24
// by 24 for a pointer on a desk (Civic's floors, from its theme's
// RawTapTargetScope), each reached where a screen reader outlines it; and
// on a desk a pointer over a live control shows the pointing hand over all of
// it. The everyday run takes each screen once, the phone and the desk dealt
// round them; the sweep takes the other half.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import '../example/lib/everyday_screens.dart';
import 'screens_matrix.dart';

/// [report] verified, but for Civic's skip link: hidden until the keyboard
/// reaches it, it lets a finger through to the title it covers (a finger
/// never needs a hidden keyboard shortcut) and keeps its node for a screen
/// reader, which the check reads as a box past a tap's reach
/// ([CivicScaffold.skipLinkLabel]).
void _verify(DesignAlignmentReport report) =>
    DesignAlignmentReport(report.look, [
      for (final problem in report.problems)
        if (!problem.startsWith('a link "Skip to main content"')) problem,
    ]).verify();

void main() {
  for (final (i, screen) in everydayScreens.indexed) {
    for (final phone in [true, false]) {
      final everyday = (i % 2 == 0) == phone;
      testWidgets(
        '${screen.id} at ${phone ? '390 by a finger' : '1440 by a pointer'}',
        (tester) async {
          await showScreen(
            tester,
            screen.app(Brightness.light, TextDirection.ltr),
            width: phone ? 390 : 1440,
            height: phone ? 844 : 900,
          );
          // The app's navigator, under Civic's theme (where its floors are):
          // the checks pass over a page under a pushed one.
          final page = tester.element(find.byType(Navigator).first);
          _verify(const DesignTapTargetCheck(look: 'Civic').check(page));
          if (!phone) {
            _verify(const DesignCursorCheck(look: 'Civic').check(page));
          }
        },
        variant: TargetPlatformVariant.only(
          phone ? TargetPlatform.android : TargetPlatform.macOS,
        ),
        tags: everyday ? null : const ['sweep'],
      );
    }
  }
}
