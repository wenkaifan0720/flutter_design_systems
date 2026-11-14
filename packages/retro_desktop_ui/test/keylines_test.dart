// Keylines (design6 P), by ui_core's shared check: every window, group box, card and list section is a
// DesignKeylineRegion, and in each the words, icons, fields and controls that start a row sit on one leading keyline and
// what ends one on one trailing keyline; a row of controls has one height and one centre line. Over Papers' windows and
// the ordinary screens at 390 and 1440, in Platinum and Chisel. papers_test's own keyline check stays for what this does
// not cover: a row of buttons ending on the window's trailing keyline.
// The package emitter carries the example's own app into example/lib.
// ignore_for_file: avoid_relative_lib_imports
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../example/lib/kit_gallery/demos/ordinary.dart';
import '../example/lib/kit_gallery/demos/papers.dart';
import '../example/lib/kit_gallery/kit.dart';

import 'support.dart';

Future<List<String>> _problems(WidgetTester tester, String screen) async {
  final report = await const DesignKeylineCheck(look: 'Retro Desktop')
      .check(tester.binding.rootElement!, runAsync: tester.runAsync);
  return [for (final p in report.problems) '$screen: $p'];
}

void main() {
  setUpAll(loadRetroDesktopFonts);
  tearDown(() => kitShownTheme = null);
  for (final width in [390.0, 1440.0]) {
    for (final appearance in [
      RetroDesktopAppearance.platinum,
      RetroDesktopAppearance.chisel,
    ]) {
      testWidgets('keylines at $width in ${appearance.name}', (tester) async {
        tester.view.physicalSize = Size(width, width > 600 ? 900 : 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final base = RetroDesktopThemeData.preset(
          'classic',
          Brightness.light,
        ).copyWith(appearance: appearance);
        Widget app(String key, Widget home) => MaterialApp(
          key: ValueKey('$key/$width/$appearance'),
          debugShowCheckedModeBanner: false,
          builder: (context, child) => RetroDesktopTheme(
            data: base.atWidth(MediaQuery.sizeOf(context).width),
            child: child!,
          ),
          home: home,
        );
        final problems = <String>[];
        for (final front in [
          KitPapersWindow.documents,
          KitPapersWindow.details,
          KitPapersWindow.settings,
          KitPapersWindow.prints,
        ]) {
          await tester.pumpWidget(
            app('papers/${front.name}', KitPapers(front: front)),
          );
          await tester.pumpAndSettle();
          problems.addAll(await _problems(tester, 'Papers ${front.name}'));
        }
        // The gallery's ordinary screens bring their own app, wearing the
        // gallery's shown theme.
        kitShownTheme = (b) => RetroDesktopThemeData.preset(
          'classic',
          b,
        ).copyWith(appearance: appearance);
        for (final screen in kitOrdinaryScreens) {
          await tester.pumpWidget(
            KeyedSubtree(
              key: ValueKey('ordinary/$screen/$width/$appearance'),
              child: kitOrdinaryScreen(screen, Brightness.light),
            ),
          );
          await tester.pumpAndSettle();
          problems.addAll(await _problems(tester, screen));
        }
        debugPrint('KEYLINES $width ${appearance.name}: ${problems.length}');
        expect(problems, isEmpty, reason: problems.join('\n'));
      }, tags: const ['goldens']);
    }
  }
}
