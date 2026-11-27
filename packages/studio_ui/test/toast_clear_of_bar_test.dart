// A toast on a phone stands as far over a screen's navigation bar as it
// stands over the screen's foot where there is no bar: the shell keeps its
// bar clear, and the toaster adds no bar's height. A page pushed over the
// screen covers the bar, and the toast stands over the foot until it goes.
import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

// The gallery's app frame; a test reads it from the example.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart' show kitApp;

const _message = 'Marker added at 12:04';

Future<Rect> _toast(WidgetTester tester, {required bool bar}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    KeyedSubtree(
      key: ValueKey(bar),
      child: kitApp(
        brightness: Brightness.light,
        home: StudioScaffold(
          destinations: bar
              ? const [
                  StudioDestination(
                    icon: Icon(LucideIcons.house),
                    label: 'Home',
                  ),
                  StudioDestination(
                    icon: Icon(LucideIcons.libraryBig),
                    label: 'Library',
                  ),
                  StudioDestination(
                    icon: Icon(LucideIcons.mic),
                    label: 'Record',
                  ),
                ]
              : const [],
          onDestinationSelected: (_) {},
          body: Builder(
            builder: (context) => Center(
              child: StudioButton(
                'Mark',
                onPressed: () => showStudioToast(context, _message),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Mark'));
  await tester.pumpAndSettle();
  return _shown(tester);
}

Rect _shown(WidgetTester tester) => tester.getRect(find.text(_message));

void main() {
  setUpAll(studioLoadFonts);

  testWidgets("a toast stands over a phone's navigation bar as over its foot", (
    tester,
  ) async {
    final bare = await _toast(tester, bar: false);
    final gap = 844 - bare.bottom;
    final over = await _toast(tester, bar: true);
    final bar = tester.getRect(find.byType(StudioNavigationBar));
    expect(over.bottom, lessThanOrEqualTo(bar.top), reason: 'clear: $over');
    expect(bar.top - over.bottom, closeTo(gap, 0.5));
  });

  testWidgets(
    'a page pushed over the screen covers its navigation bar: the toast stands '
    'over the foot, and over the navigation bar again as the page goes',
    (tester) async {
      final bare = await _toast(tester, bar: false);
      final gap = 844 - bare.bottom;
      await _toast(tester, bar: true);
      final floor = tester.getRect(find.byType(StudioNavigationBar)).top;
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
