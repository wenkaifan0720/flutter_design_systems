// The look's raised windows on ui_core 0.3.0's routes: a dialog (DesignDialogRoute) is a screen reader's dialog, keeps
// Tab inside, gives the focus back to the button that opened it, and Escape closes it only when escapeDismissible
// says so; a sheet page on a phone (DesignBottomSheetRoute) follows a finger that drags it closed; each stands at once
// under the look's default motion.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

import 'support.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadRetroDesktopFonts();
  });

  for (final escapes in [true, false]) {
    testWidgets('a dialog: at once, a dialog to a screen reader, focus back; '
        'Escape ${escapes ? 'closes' : 'is refused'}', (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        retroDesktopApp(
          Builder(
            builder: (context) => Center(
              child: RetroDesktopButton(
                'Open',
                onPressed: () => showRetroDesktopDialog<void>(
                  context,
                  barrierDismissible: false,
                  escapeDismissible: escapes,
                  builder: (context) => RetroDesktopDialog(
                    title: 'Save changes?',
                    actions: [
                      RetroDesktopButton(
                        'Cancel',
                        onPressed: () => Navigator.pop(context),
                      ),
                      RetroDesktopButton('Save', onPressed: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final open = find.text('Open');
      Focus.of(tester.element(open)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('Save changes?'), findsOneWidget, reason: 'at once');
      expect(tester.hasRunningAnimations, isFalse);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.role == SemanticsRole.dialog,
        ),
        findsOneWidget,
        reason: "ui_core's dialog role",
      );

      // Tab stays inside the dialog.
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focused = FocusManager.instance.primaryFocus!.context!;
        expect(
          find
              .ancestor(
                of: find.byWidget(focused.widget),
                matching: find.byType(RetroDesktopDialog),
              )
              .evaluate(),
          isNotEmpty,
          reason: 'Tab $i kept inside',
        );
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(
        find.text('Save changes?'),
        escapes ? findsNothing : findsOneWidget,
      );
      if (!escapes) {
        await tester.tap(find.text('Cancel'));
        await tester.pump();
        expect(find.text('Save changes?'), findsNothing);
      }
      await tester.pump();
      expect(
        Focus.of(tester.element(open)).hasFocus,
        isTrue,
        reason: 'focus back to the button that opened it',
      );
      semantics.dispose();
    });
  }

  testWidgets('a sheet page on a phone stands at once and a finger drags it '
      'closed', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var opened = true;
    late StateSetter update;
    await tester.pumpWidget(
      retroDesktopApp(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Navigator(
              onDidRemovePage: (_) => update(() => opened = false),
              pages: [
                const RetroDesktopPage<void>(
                  key: ValueKey('root'),
                  child: Center(child: Text('Parent page')),
                ),
                if (opened)
                  const RetroDesktopSheetPage<void>(
                    key: ValueKey('sheet'),
                    drawer: true,
                    child: SizedBox(
                      height: 200,
                      child: Center(child: Text('Sheet content')),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Sheet content'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse, reason: 'at once');
    await tester.fling(find.text('Sheet content'), const Offset(0, 300), 2000);
    await tester.pumpAndSettle();
    expect(find.text('Sheet content'), findsNothing);
    expect(opened, isFalse);
  });
}
