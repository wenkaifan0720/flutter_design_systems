// The saved notice stands above the phone's Save foot, as a Scaffold keeps a
// snackbar above its persistent footer buttons.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_retro_desktop/stint_retro_desktop.dart';

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
            StintRetroDesktop(
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
                  of: find.text(words.saved, findRichText: true).first,
                  matching: find.byType(RetroDesktopSnackBar),
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
