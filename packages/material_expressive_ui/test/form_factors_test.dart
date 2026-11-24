/// Platforms (0.2.0's form-factor check): under [ExpressiveHost], whose
/// theme gives a `MaterialPageRoute` the look's own transitions, the iOS
/// edge swipe still pops a page, and Android's back closes what is open over
/// a page (a menu, a dialog) before it pops the page. The look's own page's
/// swipe and predictive back are page_test's; a sheet's back is sheet_test's.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

/// An app on [ExpressiveHost] whose home pushes the detail page.
Widget _app() => MaterialApp(
  builder: (context, app) => ExpressiveHost(child: app!),
  home: Builder(
    builder: (context) => Center(
      child: ExpressiveFilledButton(
        'Open',
        onPressed: () =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const _Detail())),
      ),
    ),
  ),
);

/// An inner page: a menu and a dialog it can open.
class _Detail extends StatelessWidget {
  const _Detail();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.expressiveTheme.colors.surface,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Detail'),
          ExpressiveMenu(
            label: 'More',
            entries: [ExpressiveMenuItem('Rename', onPressed: () {})],
            child: const SizedBox(width: 48, height: 48),
          ),
          Builder(
            builder: (context) => ExpressiveTextButton(
              'Delete',
              onPressed: () => showExpressiveDialog<void>(
                context: context,
                builder: (_) =>
                    const ExpressiveDialog(title: 'Delete the trip?'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(_app());
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  expect(find.text('Detail'), findsOneWidget);
}

/// The system's back, as Android sends it.
Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    "iOS: the edge swipe pops a page pushed with the look's transitions",
    (tester) async {
      await _open(tester);
      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final gesture = await tester.startGesture(const Offset(4, 300));
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      await gesture.moveBy(Offset(width * 0.6, 0));
      await tester.pump();
      // The page follows the finger.
      expect(tester.getTopLeft(find.text('Detail')).dx, greaterThan(width / 2));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Android: back closes a dialog, then a menu, before it pops the page',
    (tester) async {
      await _open(tester);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete the trip?'), findsOneWidget);
      await _back(tester);
      expect(find.text('Delete the trip?'), findsNothing);
      expect(find.text('Detail'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('More'));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsOneWidget);
      await _back(tester);
      expect(find.text('Rename'), findsNothing);
      expect(find.text('Detail'), findsOneWidget);

      await _back(tester);
      expect(find.text('Detail'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
