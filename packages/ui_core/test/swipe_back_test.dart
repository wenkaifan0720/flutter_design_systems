// iOS's swipe back on a page that paints nothing at its leading edge (a
// look with no page background, Retro's): the route's barrier is hit there
// too and holds the gesture until the drag passes its slop; the page still
// follows the finger from where it went down. And the focus a swipe takes
// from the page (a navigator lets none into a route while a user gesture
// runs) comes back when it ends.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

// A look's push: none, the page as it is.
class _Plain extends PageTransitionsBuilder {
  const _Plain();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

// A page route that plays the swipe back round the look's push.
class _Page extends PageRoute<void> {
  _Page(this.page);

  final Widget page;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => page;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => const SwipeBackPageTransitionsBuilder(_Plain())
      .buildTransitions(this, context, animation, secondaryAnimation, child);
}

void main() {
  for (final background in [false, true]) {
    testWidgets('a page ${background ? 'with' : 'with no'} background '
        'follows the finger from where it went down', (tester) async {
      await tester.pumpWidget(
        harness(
          Builder(
            builder: (context) => Center(
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  _Page(
                    background
                        ? const ColoredBox(
                            color: Color(0xFFFFFFFF),
                            child: Center(child: Text('Second')),
                          )
                        : const Center(child: Text('Second')),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final at = tester.getTopLeft(find.text('Second')).dx;
      // Ten moves of 10: the slop (18) is passed on the second.
      final gesture = await tester.startGesture(const Offset(4, 300));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(10, 0));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(
        tester.getTopLeft(find.text('Second')).dx - at,
        moreOrLessEquals(100, epsilon: 1),
        reason: 'the page is as far over as the finger',
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget, reason: 'short: back');
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }

  testWidgets('a swipe that leaves the page keeps the focus in it; one that '
      'pops it gives the focus back to the page under', (tester) async {
    final opener = FocusNode(debugLabel: 'opener');
    final inner = FocusNode(debugLabel: 'inner');
    addTearDown(opener.dispose);
    addTearDown(inner.dispose);
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) => Center(
            child: Focus(
              focusNode: opener,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  _Page(
                    ColoredBox(
                      color: const Color(0xFFFFFFFF),
                      child: Center(
                        child: Focus(
                          focusNode: inner,
                          child: const Text('Second'),
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    opener.requestFocus();
    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    inner.requestFocus();
    await tester.pump();

    Future<void> swipe(double by) async {
      final gesture = await tester.startGesture(const Offset(4, 300));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(by / 10, 0));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    await swipe(100);
    expect(find.text('Second'), findsOneWidget, reason: 'short: back');
    expect(inner.hasPrimaryFocus, isTrue, reason: 'kept through the swipe');

    await swipe(600);
    expect(find.text('Second'), findsNothing, reason: 'past half: popped');
    expect(opener.hasPrimaryFocus, isTrue, reason: 'the page under has it');
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
