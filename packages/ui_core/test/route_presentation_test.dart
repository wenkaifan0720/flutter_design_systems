// Where a screen stands (0.6.0): a full-screen dialog page and a popup
// (a sheet, a dialog) are sheets, as Material's AppBar takes them; a page
// pushed over another is pushed; a navigator's first page is a root; a
// published presentation wins over the route's.
import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

// What each screen read, by the screen: a page under another builds again
// as it is covered, so one record would hold the page under.
final _seen = <String, RoutePresentation>{};

Widget _reader([String screen = 'top']) => Builder(
  builder: (context) {
    _seen[screen] = RoutePresentation.of(context);
    return const SizedBox.expand();
  },
);

Future<NavigatorState> _app(WidgetTester tester) async {
  await tester.pumpWidget(harness(_reader('first')));
  return tester.state<NavigatorState>(find.byType(Navigator));
}

Future<RoutePresentation?> _in(WidgetTester tester, Route<void> route) async {
  final navigator = await _app(tester);
  _seen.remove('top');
  unawaited(navigator.push(route));
  await tester.pumpAndSettle();
  return _seen['top'];
}

void main() {
  testWidgets("a navigator's first page is a root", (tester) async {
    await _app(tester);
    expect(_seen['first'], RoutePresentation.root);
  });

  testWidgets('outside any route it is a root', (tester) async {
    await tester.pumpWidget(_reader());
    expect(_seen['top'], RoutePresentation.root);
  });

  testWidgets('a page pushed over another is pushed', (tester) async {
    final at = await _in(
      tester,
      PageRouteBuilder<void>(pageBuilder: (context, _, _) => _reader()),
    );
    expect(at, RoutePresentation.pushed);
  });

  testWidgets('a full-screen dialog page is a sheet', (tester) async {
    final at = await _in(
      tester,
      PageRouteBuilder<void>(
        fullscreenDialog: true,
        pageBuilder: (context, _, _) => _reader(),
      ),
    );
    expect(at, RoutePresentation.sheet);
  });

  testWidgets('a popup is a sheet: a dialog, a bottom sheet', (tester) async {
    expect(
      await _in(
        tester,
        RawDialogRoute<void>(pageBuilder: (context, _, _) => _reader()),
      ),
      RoutePresentation.sheet,
    );
    expect(
      await _in(
        tester,
        RawBottomSheetRoute<void>(builder: (context, details) => _reader()),
      ),
      RoutePresentation.sheet,
    );
  });

  testWidgets('a published presentation wins over the route', (tester) async {
    final at = await _in(
      tester,
      PageRouteBuilder<void>(
        fullscreenDialog: true,
        pageBuilder: (context, _, _) => RoutePresentationScope(
          presentation: RoutePresentation.pushed,
          child: _reader(),
        ),
      ),
    );
    expect(at, RoutePresentation.pushed);
  });
}
