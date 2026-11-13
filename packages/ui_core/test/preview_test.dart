import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/host.dart';

/// A previewed page with its own exit, as a system's derived back or
/// Cancel is: it asks its route to pop.
class _Page extends StatelessWidget {
  const _Page(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(title),
      TextButton(
        onPressed: () => Navigator.maybePop(context),
        child: const Text('Exit'),
      ),
    ],
  );
}

Widget _stage({
  required Route<void> Function(BuildContext, Widget) route,
  Widget child = const _Page('Detail'),
  Widget? under,
}) => MaterialApp(
  home: PreviewStage(route: route, under: under, child: child),
);

Route<void> _pushed(BuildContext context, Widget page) =>
    MaterialPageRoute<void>(builder: (_) => page);

Route<void> _sheet(BuildContext context, Widget page) =>
    ModalBottomSheetRoute<void>(
      isScrollControlled: false,
      builder: (_) => RoutePresentationScope(
        presentation: RoutePresentation.sheet,
        child: SizedBox(height: 300, child: page),
      ),
    );

void main() {
  group('PreviewDevice', () {
    test('the Android reference phone is 411.43 × 914.29 dp at 2.625', () {
      final android = PreviewDevice.android;
      expect(android.size.width, closeTo(411.43, 0.005));
      expect(android.size.height, closeTo(914.29, 0.005));
      expect(android.devicePixelRatio, 2.625);
      expect(android.physicalSize.width, closeTo(1080, 1e-9));
      expect(android.physicalSize.height, closeTo(2400, 1e-9));
    });

    test('the iPhone reference phone is 390 × 844 pt at 3', () {
      expect(PreviewDevice.ios.size, const Size(390, 844));
      expect(PreviewDevice.ios.devicePixelRatio, 3);
      expect(PreviewDevice.ios.physicalSize, const Size(1170, 2532));
    });

    test('each presentation names its device', () {
      expect(PreviewDevice.of(PreviewPlatform.android), PreviewDevice.android);
      expect(PreviewPlatform.ios.device, PreviewDevice.ios);
    });
  });

  group('PreviewFrame', () {
    testWidgets('publishes its presentation and brightness inside, and nothing '
        'outside', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: <Widget>[
              Text('Outside'),
              Expanded(
                child: PreviewFrame(
                  platform: PreviewPlatform.ios,
                  brightness: Brightness.dark,
                  child: Text('Inside'),
                ),
              ),
            ],
          ),
        ),
      );
      final inside = tester.element(find.text('Inside'));
      expect(
        PreviewFrame.maybeOf(inside),
        const PreviewFrameData(
          platform: PreviewPlatform.ios,
          brightness: Brightness.dark,
        ),
      );
      expect(PreviewFrame.targetPlatformOf(inside), TargetPlatform.iOS);
      expect(MediaQuery.platformBrightnessOf(inside), Brightness.dark);
      expect(
        ScrollConfiguration.of(inside).getPlatform(inside),
        TargetPlatform.iOS,
      );

      final outside = tester.element(find.text('Outside'));
      expect(PreviewFrame.maybeOf(outside), isNull);
      expect(PreviewFrame.targetPlatformOf(outside), defaultTargetPlatform);
      expect(MediaQuery.platformBrightnessOf(outside), Brightness.light);
    });

    testWidgets('frames side by side each keep their own presentation', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: <Widget>[
              Expanded(
                child: PreviewFrame(
                  platform: PreviewPlatform.android,
                  child: Text('Android'),
                ),
              ),
              Expanded(
                child: PreviewFrame(
                  platform: PreviewPlatform.ios,
                  child: Text('iOS'),
                ),
              ),
            ],
          ),
        ),
      );
      expect(
        PreviewFrame.targetPlatformOf(tester.element(find.text('Android'))),
        TargetPlatform.android,
      );
      expect(
        PreviewFrame.targetPlatformOf(tester.element(find.text('iOS'))),
        TargetPlatform.iOS,
      );
    });

    testWidgets('a host that reads the frame gives its scrolls the '
        'presentation\'s physics', (tester) async {
      Future<ScrollPhysics> physicsIn(PreviewPlatform platform) async {
        await tester.pumpWidget(
          PreviewFrame(
            platform: platform,
            child: Builder(
              builder: (context) => MaterialApp(
                theme: ThemeData(
                  platform: PreviewFrame.targetPlatformOf(context),
                ),
                home: ListView(children: const <Widget>[Text('Row')]),
              ),
            ),
          ),
        );
        // The app's theme animates to the new platform.
        await tester.pumpAndSettle();
        return tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position
            .physics;
      }

      // The physics chain a scroll view resolves (its own, then its
      // ambient behaviour's).
      List<Type> chain(ScrollPhysics? physics) => <Type>[
        for (var link = physics; link != null; link = link.parent)
          link.runtimeType,
      ];

      final ios = chain(await physicsIn(PreviewPlatform.ios));
      expect(ios, contains(BouncingScrollPhysics));
      expect(ios, isNot(contains(ClampingScrollPhysics)));
      final android = chain(await physicsIn(PreviewPlatform.android));
      expect(
        android,
        isNot(contains(BouncingScrollPhysics)),
        reason: '$android',
      );
      expect(android, contains(ClampingScrollPhysics), reason: '$android');
    });

    testWidgets('its box is the phone: a smaller box stands without the '
        'view\'s insets', (tester) async {
      const padding = EdgeInsets.only(top: 47, bottom: 34);
      Widget framed(Size? box) {
        const frame = PreviewFrame(child: Text('Page'));
        return MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 600),
            padding: padding,
            viewPadding: padding,
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: box == null
                ? frame
                : Center(
                    child: SizedBox.fromSize(size: box, child: frame),
                  ),
          ),
        );
      }

      await tester.pumpWidget(framed(null));
      var page = tester.element(find.text('Page'));
      expect(MediaQuery.sizeOf(page), const Size(800, 600));
      expect(MediaQuery.paddingOf(page), padding);

      await tester.pumpWidget(framed(const Size(300, 500)));
      page = tester.element(find.text('Page'));
      expect(MediaQuery.sizeOf(page), const Size(300, 500));
      expect(MediaQuery.paddingOf(page), EdgeInsets.zero);
    });

    testWidgets(
      'in device mode lays the page out at the presentation\'s device '
      'and scales it to fit',
      (tester) async {
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: PreviewFrame(
              platform: PreviewPlatform.ios,
              device: true,
              child: SizedBox.expand(child: Text('Page')),
            ),
          ),
        );
        final page = tester.element(find.text('Page'));
        expect(MediaQuery.sizeOf(page), PreviewDevice.ios.size);
        expect(MediaQuery.paddingOf(page), EdgeInsets.zero);
        // 390 × 844 fitted into the 800 × 600 test view: scaled by 600 / 844.
        final box = tester.getRect(find.byType(SizedBox).first);
        expect(box.height, closeTo(600, 0.01));
        expect(box.width, closeTo(390 * 600 / 844, 0.01));
      },
    );
  });

  group('PreviewStage', () {
    testWidgets('a pushed page previewed alone never pops onto the blank '
        'stage', (tester) async {
      await tester.pumpWidget(_stage(route: _pushed));
      await tester.pumpAndSettle();
      final page = find.text('Detail');
      expect(page, findsOneWidget);
      expect(
        RoutePresentation.of(tester.element(page)),
        RoutePresentation.pushed,
      );

      // The exit still renders as it does live, and tapping it is a no-op.
      await tester.tap(find.text('Exit'));
      await tester.pumpAndSettle();
      expect(page, findsOneWidget);

      // So is the system back.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(page, findsOneWidget);

      // A route raised over the page still closes.
      showDialog<void>(
        context: tester.element(page),
        builder: (_) => const Text('Dialog'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dialog'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Dialog'), findsNothing);
      expect(page, findsOneWidget);

      // A pop that takes the page anyway raises it again, and popUntil ends.
      Navigator.of(tester.element(page)).pop();
      await tester.pumpAndSettle();
      expect(page, findsOneWidget);
      Navigator.of(tester.element(page)).popUntil((route) => route.isFirst);
      await tester.pumpAndSettle();
      expect(page, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a sheet page previewed alone keeps standing on its exit and '
        'its barrier', (tester) async {
      await tester.pumpWidget(_stage(route: _sheet));
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsOneWidget);
      expect(
        RoutePresentation.of(tester.element(find.text('Detail'))),
        RoutePresentation.sheet,
      );

      await tester.tap(find.text('Exit'));
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsOneWidget);

      // The barrier above the sheet.
      await tester.tapAt(const Offset(400, 20));
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a hot reload\'s new child reaches the page already '
        'standing', (tester) async {
      await tester.pumpWidget(_stage(route: _pushed));
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsOneWidget);

      // The preview's source changes; a hot reload rebuilds the stage.
      await tester.pumpWidget(
        _stage(route: _pushed, child: const _Page('Edited')),
      );
      final reassembled = tester.binding.reassembleApplication();
      await tester.pump();
      await reassembled;
      await tester.pump();
      expect(find.text('Edited'), findsOneWidget);
      expect(find.text('Detail'), findsNothing);
      expect(
        RoutePresentation.of(tester.element(find.text('Edited'))),
        RoutePresentation.pushed,
      );
    });

    testWidgets('stands the page over what lies under it', (tester) async {
      await tester.pumpWidget(_stage(route: _sheet, under: const Text('Root')));
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsOneWidget);
      expect(find.text('Root'), findsOneWidget);
    });
  });
}
