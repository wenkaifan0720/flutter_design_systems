import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/host.dart';

Widget _app(Widget home) => MaterialApp(home: home);

void main() {
  group('RoutePresentation.of', () {
    testWidgets('is root outside any route', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('Alone'),
        ),
      );
      expect(
        RoutePresentation.of(tester.element(find.text('Alone'))),
        RoutePresentation.root,
      );
    });

    testWidgets('reads root for a first route and pushed for one pushed '
        'over another', (tester) async {
      await tester.pumpWidget(_app(const Text('Root')));
      final root = tester.element(find.text('Root'));
      expect(RoutePresentation.of(root), RoutePresentation.root);

      Navigator.of(root)
          .push(MaterialPageRoute<void>(builder: (_) => const Text('Pushed')));
      await tester.pumpAndSettle();
      expect(
        RoutePresentation.of(tester.element(find.text('Pushed'))),
        RoutePresentation.pushed,
      );
    });

    testWidgets('keeps a root a root under a sheet on the same navigator, '
        'though the navigator can pop', (tester) async {
      await tester.pumpWidget(_app(const Text('Root')));
      final root = tester.element(find.text('Root'));
      Navigator.of(root).push(
        RawDialogRoute<void>(
          pageBuilder: (_, _, _) => const RoutePresentationScope(
            presentation: RoutePresentation.sheet,
            child: Text('Sheet'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(Navigator.of(root).canPop(), isTrue);
      expect(RoutePresentation.of(root), RoutePresentation.root);
      expect(
        RoutePresentation.of(tester.element(find.text('Sheet'))),
        RoutePresentation.sheet,
      );
    });

    testWidgets('a published presentation wins over the route\'s position', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const RoutePresentationScope(
            presentation: RoutePresentation.pushed,
            child: Text('Published'),
          ),
        ),
      );
      expect(
        RoutePresentation.of(tester.element(find.text('Published'))),
        RoutePresentation.pushed,
      );
      expect(
        RoutePresentationScope.maybeOf(tester.element(find.text('Published'))),
        RoutePresentation.pushed,
      );
    });

    testWidgets('a reader rebuilds when the published presentation changes', (
      tester,
    ) async {
      final seen = <RoutePresentation>[];
      Widget scoped(RoutePresentation presentation) => Directionality(
        textDirection: TextDirection.ltr,
        child: RoutePresentationScope(
          presentation: presentation,
          child: Builder(
            builder: (context) {
              seen.add(RoutePresentation.of(context));
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(scoped(RoutePresentation.root));
      await tester.pumpWidget(scoped(RoutePresentation.sheet));
      expect(seen, <RoutePresentation>[
        RoutePresentation.root,
        RoutePresentation.sheet,
      ]);
    });
  });

  test('each preview presentation names its platform', () {
    expect(PreviewPlatform.values, <PreviewPlatform>[
      PreviewPlatform.android,
      PreviewPlatform.ios,
    ]);
    expect(PreviewPlatform.android.targetPlatform, TargetPlatform.android);
    expect(PreviewPlatform.ios.targetPlatform, TargetPlatform.iOS);
  });

  test('the shell\'s data defaults', () {
    const tab = NavTab(icon: Icons.home, label: 'Home', location: '/home');
    expect(tab.selectedIcon, isNull);
    expect(tab.key, isNull);
    final action = ShellAction(icon: Icons.add, onPressed: (_) {});
    expect(action.accent, isFalse);
    expect(action.label, isNull);
    expect(action.key, isNull);
  });
}
