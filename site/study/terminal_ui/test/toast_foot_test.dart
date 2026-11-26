// The saved notice stands above the phone's Save foot, which stands on the
// status line and the window list: ui_core 0.6.1 stacks the kept bands.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_terminal/stint_terminal.dart';
import 'package:terminal_ui/terminal_ui.dart';

void main() {
  for (final ar in [false, true]) {
    for (final night in [false, true]) {
      testWidgets(
        'at 390, ${ar ? "Arabic" : "English"} ${night ? "night" : "day"}: '
        'Changes saved stands above the Save foot',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(390, 844);
          addTearDown(tester.view.reset);
          final words = StintWords(ar ? StintLanguage.ar : StintLanguage.en);
          await tester.pumpWidget(
            StintTerminal(
              launch: StintLaunch.fromUri(
                Uri.parse(
                  'https://stint.example/?page=detail'
                  '&theme=${night ? "night" : "day"}&dir=${ar ? "rtl" : "ltr"}',
                ),
              ),
              repository: StintRepository(),
            ),
          );
          await tester.pumpAndSettle();
          final title = find.byType(EditableText).first;
          await tester.enterText(
            title,
            '${tester.widget<EditableText>(title).controller.text} x',
          );
          await tester.pumpAndSettle();
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await tester.pumpAndSettle();
          final foot = tester.getRect(
            find
                .ancestor(
                  of: find.textContaining(words.save).first,
                  matching: find.byType(RawToasterKeepClear),
                )
                .first,
          );
          final toast = tester.getRect(
            find
                .ancestor(
                  of: find
                      .textContaining(words.saved, findRichText: true)
                      .first,
                  matching: find.byType(TermToast),
                )
                .first,
          );
          expect(
            toast.bottom,
            lessThanOrEqualTo(foot.top),
            reason: 'toast $toast, foot $foot',
          );
        },
      );
    }
  }
}
