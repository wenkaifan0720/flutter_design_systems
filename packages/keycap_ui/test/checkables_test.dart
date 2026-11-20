// Every checkbox, radio and switch on every gallery page and every Jotter
// screen says what it is, as Flutter's do: a checkable that is not also a
// button, and a radio that says whether it is the checked one (ui_core_test's
// DesignCheckableCheck). Each page is laid out tall enough to show it whole.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import '../example/lib/everyday_screens.dart';
import '../example/lib/gallery_pages.dart';

Future<void> _check(WidgetTester tester, Widget app, double width) async {
  tester.view.physicalSize = Size(width, 9000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final semantics = tester.ensureSemantics();
  await tester.pumpWidget(app);
  await tester.pump(const Duration(milliseconds: 600));
  const DesignCheckableCheck(look: 'Keycap')
      .check(tester.element(find.byWidget(app)))
      .verify();
  semantics.dispose();
  // Let springs and loops come to rest before the tree goes.
  await tester.pumpWidget(const SizedBox());
}

void main() {
  for (final width in const [390.0, 1440.0]) {
    for (final page in galleryPages) {
      testWidgets('the ${page.id} page says what each checkable is, at '
          '${width.toInt()}', (tester) async {
        await _check(tester, page.build(Brightness.light), width);
      });
    }
    for (final screen in everydayScreens) {
      testWidgets('${screen.id} says what each checkable is, at '
          '${width.toInt()}', (tester) async {
        await _check(
          tester,
          screen.app(Brightness.light, TextDirection.ltr),
          width,
        );
      });
    }
  }
}
