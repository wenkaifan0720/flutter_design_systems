// A toast on a phone stands as far over a screen's footer (its pinned
// buttons) as it stands over the screen's foot where there is no footer:
// the screen keeps its footer clear, and the toaster adds no bar's height. A
// page pushed over the screen covers the footer, and the toast stands over
// the foot until it goes.
import 'dart:async' show unawaited;

import 'package:fluent2_design_ui/fluent2_design_parts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gallery_support.dart' show loadFluent2TestFonts;

Widget _app(
  Widget page, {
  double scale = 1,
  Brightness brightness = Brightness.light,
}) => WidgetsApp(
  color: const Color(0xFF000000),
  debugShowCheckedModeBanner: false,
  localizationsDelegates: const [
    RawWidgetsLocalizations.delegate,
    Fluent2Localizations.delegate,
  ],
  builder: (context, child) => MediaQuery.withClampedTextScaling(
    minScaleFactor: scale,
    maxScaleFactor: scale,
    child: Fluent2Host(
      brightness: brightness,
      child: Fluent2Toaster(child: child!),
    ),
  ),
  onGenerateRoute: (settings) => PageRouteBuilder<void>(
    settings: settings,
    pageBuilder: (context, _, _) => page,
  ),
);

Future<Rect> _toast(WidgetTester tester, {required bool footer}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    KeyedSubtree(
      key: ValueKey(footer),
      child: _app(
        Fluent2Scaffold(
          footer: footer
              ? Fluent2Button(
                  'Submit',
                  appearance: Fluent2ButtonAppearance.primary,
                  expand: true,
                  onPressed: () {},
                )
              : null,
          body: Builder(
            builder: (context) => Center(
              child: Fluent2Button(
                'Save',
                onPressed: () => showFluent2Toast(context, 'Changes saved'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
  return _shown(tester);
}

Rect _shown(WidgetTester tester) => tester.getRect(find.byType(Fluent2Toast));

void main() {
  setUpAll(loadFluent2TestFonts);

  testWidgets("a toast stands over a screen's footer as over its foot", (
    tester,
  ) async {
    final bare = await _toast(tester, footer: false);
    final gap = 844 - bare.bottom;
    final over = await _toast(tester, footer: true);
    final band = tester.getRect(find.byType(Fluent2BottomStand));
    expect(over.bottom, lessThanOrEqualTo(band.top), reason: 'clear: $over');
    expect(band.top - over.bottom, closeTo(gap, 0.5));
  });

  testWidgets(
    'a page pushed over the screen covers its footer: the toast stands '
    'over the foot, and over the footer again as the page goes',
    (tester) async {
      final bare = await _toast(tester, footer: false);
      final gap = 844 - bare.bottom;
      await _toast(tester, footer: true);
      final floor = tester.getRect(find.byType(Fluent2BottomStand)).top;
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      unawaited(
        navigator.push(
          PageRouteBuilder<void>(
            pageBuilder: (context, _, _) => const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(844 - _shown(tester).bottom, closeTo(gap, 0.5));
      navigator.pop();
      await tester.pumpAndSettle();
      expect(floor - _shown(tester).bottom, closeTo(gap, 0.5));
    },
  );
}
