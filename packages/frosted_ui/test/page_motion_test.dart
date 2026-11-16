// Frosted's page motion (coordinator msg_9718a2a2a077: page changes must not
// fly in): a drill-in settles in a small way over the page under it, which
// stands still, a pop is the reverse, on every platform the theme hands a
// page route to. The shell's top-level switch, in place: chrome_test.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

const _under = Key('under');
const _page = Key('page');

/// An app under FrostedHost whose home pushes an ordinary MaterialPageRoute,
/// as an app's own route would.
Widget _app({
  TextDirection direction = TextDirection.ltr,
  bool still = false,
  bool fullscreen = false,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: still),
    child: Directionality(
      textDirection: direction,
      child: FrostedHost(child: child!),
    ),
  ),
  home: Builder(
    builder: (context) => ColoredBox(
      key: _under,
      color: const Color(0xFFFFFFFF),
      child: Center(
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              fullscreenDialog: fullscreen,
              builder: (_) => const ColoredBox(
                key: _page,
                color: Color(0xFFEEEEEE),
                child: Center(child: Text('Detail')),
              ),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

Offset _at(WidgetTester tester, Key key) => tester.getTopLeft(find.byKey(key));

double _opacity(WidgetTester tester) {
  final fade = find.ancestor(
    of: find.byKey(_page),
    matching: find.byType(Opacity),
  );
  return fade.evaluate().isEmpty
      ? 1
      : tester.widget<Opacity>(fade.first).opacity;
}

/// The push's first frames: the route stands offstage on its first (the
/// hero controller measures it there), then its animation begins at 0.
Future<void> _entered(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// The page's offsets, frame by frame, from the push to [until].
Future<List<Offset>> _frames(
  WidgetTester tester, {
  Duration until = const Duration(milliseconds: 350),
}) async {
  final seen = <Offset>[];
  for (var ms = 0; ms <= until.inMilliseconds; ms += 25) {
    await tester.pump(
      ms == 0 ? Duration.zero : const Duration(milliseconds: 25),
    );
    if (find.byKey(_page).evaluate().isEmpty) break;
    seen.add(_at(tester, _page));
    // The page under it stands still and whole while the page above moves
    // (once it settles, the page under goes offstage).
    if (seen.last != Offset.zero || _opacity(tester) < 1) {
      expect(find.byKey(_under), findsOneWidget);
      expect(_at(tester, _under), Offset.zero);
    }
  }
  return seen;
}

void main() {
  testWidgets(
    'every platform: a pushed page settles 24 px toward the end as it clears, the page under it still',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Open'));
      await _entered(tester);
      expect(_at(tester, _page).dx, closeTo(FrostedPageMotion.travel, 1));
      expect(_opacity(tester), lessThan(.1));
      final seen = await _frames(tester);
      for (final at in seen) {
        expect(at.dy, 0);
        expect(at.dx, inInclusiveRange(0, FrostedPageMotion.travel));
      }
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i].dx, lessThanOrEqualTo(seen[i - 1].dx));
      }
      expect(_at(tester, _page), Offset.zero);
      expect(_opacity(tester), 1);
      final route = ModalRoute.of(tester.element(find.byKey(_page)))!;
      expect(route.transitionDuration, FrostedPageMotion.duration);
      expect(
        route.reverseTransitionDuration,
        FrostedPageMotion.reverseDuration,
      );
      expect(
        Theme.of(tester.element(find.byKey(_page)))
            .pageTransitionsTheme
            .builders,
        same(frostedPageTransitions),
      );

      // The pop is the reverse: the pane lifts off the way it came.
      Navigator.of(tester.element(find.byKey(_page))).pop();
      final back = await _frames(tester);
      for (final at in back) {
        expect(at.dx, inInclusiveRange(0, FrostedPageMotion.travel));
      }
      await tester.pumpAndSettle();
      expect(find.byKey(_page), findsNothing);
      expect(_at(tester, _under), Offset.zero);
    },
    variant: TargetPlatformVariant.all(),
  );

  test('the map hands every platform Frosted\'s page motion, iOS inside '
      "ui_core's swipe back", () {
    for (final platform in TargetPlatform.values) {
      final builder = frostedPageTransitions[platform];
      expect(
        builder is DesignSwipeBackPageTransitionsBuilder
            ? builder.builder
            : builder,
        isA<FrostedPageMotion>(),
        reason: '$platform',
      );
      expect(
        builder is DesignSwipeBackPageTransitionsBuilder,
        platform == TargetPlatform.iOS,
        reason: '$platform',
      );
    }
  });

  testWidgets(
    'an app theme Frosted cannot reach takes the motion from frostedPageTransitions',
    (tester) async {
      // No FrostedHost above the navigator: the route reads the app's own
      // theme, as an app on another Material than Frosted's own does.
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: frostedPageTransitions,
            ),
          ),
          home: Builder(
            builder: (context) => GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const ColoredBox(key: _page, color: Color(0xFFEEEEEE)),
                ),
              ),
              child: const ColoredBox(
                key: _under,
                color: Color(0xFFFFFFFF),
                child: Center(child: Text('Open')),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await _entered(tester);
      expect(_at(tester, _page).dx, closeTo(FrostedPageMotion.travel, 1));
      expect(_opacity(tester), lessThan(.1));
      for (final at in await _frames(tester)) {
        expect(at.dx, inInclusiveRange(0, FrostedPageMotion.travel));
      }
      expect(_at(tester, _page), Offset.zero);
      expect(
        ModalRoute.of(tester.element(find.byKey(_page)))!.transitionDuration,
        FrostedPageMotion.duration,
      );
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('right to left the page settles from the left', (tester) async {
    await tester.pumpWidget(_app(direction: TextDirection.rtl));
    await tester.tap(find.text('Open'));
    await _entered(tester);
    for (final at in await _frames(tester)) {
      expect(at.dx, inInclusiveRange(-FrostedPageMotion.travel, 0));
    }
    expect(_at(tester, _page), Offset.zero);
  });

  testWidgets('a full-screen dialog settles 24 px up from below', (
    tester,
  ) async {
    await tester.pumpWidget(_app(fullscreen: true));
    await tester.tap(find.text('Open'));
    await _entered(tester);
    expect(_at(tester, _page).dy, closeTo(FrostedPageMotion.travel, 1));
    for (final at in await _frames(tester)) {
      expect(at.dx, 0);
      expect(at.dy, inInclusiveRange(0, FrostedPageMotion.travel));
    }
  });

  testWidgets('under Reduce Motion a page comes as a cut', (tester) async {
    await tester.pumpWidget(_app(still: true));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(FrostedMotion.of(tester.element(find.byKey(_page))).moves, isFalse);
    expect(_at(tester, _page), Offset.zero);
    expect(_opacity(tester), 1);
  });

  testWidgets(
    'on iOS a drag from the start edge pulls the page under the finger; past half it goes back',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      Future<void> drag(double by) async {
        final g = await tester.startGesture(const Offset(4, 400));
        var ms = 0;
        for (var moved = 0.0; moved < by; moved += 20) {
          ms += 100;
          await g.moveBy(
            const Offset(20, 0),
            timeStamp: Duration(milliseconds: ms),
          );
          await tester.pump();
        }
        // Held under the finger, whole, as far as it was pulled.
        expect(_at(tester, _page).dx, inInclusiveRange(by - 40, by + 1));
        expect(_opacity(tester), 1);
        await g.up(timeStamp: Duration(milliseconds: ms + 100));
        await tester.pumpAndSettle();
      }

      await drag(160);
      expect(_at(tester, _page), Offset.zero, reason: 'short of half: stays');
      await drag(260);
      expect(find.byKey(_page), findsNothing, reason: 'past half: back');
      expect(_at(tester, _under), Offset.zero);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
