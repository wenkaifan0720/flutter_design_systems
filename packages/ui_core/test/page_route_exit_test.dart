// RawPageRoute and RawPage over a Material or Cupertino page: the page under
// plays the look's exit as the look's page comes in, and back as it goes.
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

// A look's transition: in from the right; out a third to the left.
class _Slide extends PageTransitionsBuilder {
  const _Slide();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => SlideTransition(
    position: Tween(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(animation),
    child: SlideTransition(
      position: Tween(
        begin: Offset.zero,
        end: const Offset(-0.3, 0),
      ).animate(secondaryAnimation),
      child: child,
    ),
  );
}

// A look's transition that hands the page under its own exit.
class _Handing extends _Slide {
  const _Handing();

  static Widget? exit(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) => child;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => exit;
}

Route<void> _look(String name, {PageTransitionsBuilder by = const _Slide()}) =>
    RawPageRoute<void>(transitionsBuilder: by, builder: (_) => Text(name));

// Where the page under stands halfway through the look's page coming in,
// and halfway through it going.
Future<(double, double)> _under(
  WidgetTester tester, {
  required Route<void>? home,
  Route<void>? over,
  bool reduceMotion = false,
}) async {
  final nav = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: const Size(800, 600),
        disableAnimations: reduceMotion,
      ),
      child: MaterialApp(
        navigatorKey: nav,
        home: home == null ? const Text('A') : null,
        onGenerateRoute: home == null ? null : (_) => home,
      ),
    ),
  );
  if (over != null) {
    nav.currentState!.push(over);
    await tester.pumpAndSettle();
  }
  final under = over == null ? 'A' : 'M';
  nav.currentState!.push(_look('B'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
  final coming = tester.getTopLeft(find.text(under)).dx;
  await tester.pumpAndSettle();
  nav.currentState!.pop();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
  final going = tester.getTopLeft(find.text(under)).dx;
  await tester.pumpAndSettle();
  return (coming, going);
}

void main() {
  testWidgets("over MaterialApp(home:), the page under plays the look's exit", (
    tester,
  ) async {
    // Halfway: the look's page halfway in, the page under 0.3 x 0.5 of 800
    // to the left.
    expect(await _under(tester, home: null), (-120.0, -120.0));
  });

  testWidgets("over a Material and a Cupertino page, the page under plays it", (
    tester,
  ) async {
    expect(
      await _under(
        tester,
        home: null,
        over: MaterialPageRoute<void>(builder: (_) => const Text('M')),
      ),
      (-120.0, -120.0),
    );
    expect(
      await _under(
        tester,
        home: null,
        over: CupertinoPageRoute<void>(builder: (_) => const Text('M')),
      ),
      (-120.0, -120.0),
    );
  });

  testWidgets('over a page of the same transition, its own exit, once', (
    tester,
  ) async {
    expect(await _under(tester, home: _look('A')), (-120.0, -120.0));
  });

  testWidgets('under Reduce Motion, the page under stays', (tester) async {
    expect(await _under(tester, home: null, reduceMotion: true), (0.0, 0.0));
  });

  test("a transition's own handing is kept; one per transition", () {
    final handing = _look('A', by: const _Handing()) as RawPageRoute<void>;
    final a = _look('A') as RawPageRoute<void>;
    final b = _look('B') as RawPageRoute<void>;
    addTearDown(handing.dispose);
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    expect(handing.delegatedTransition, same(_Handing.exit));
    expect(a.delegatedTransition, isNotNull);
    expect(b.delegatedTransition, same(a.delegatedTransition));
  });

  testWidgets("RawPage's route hands the same exit", (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );
    final page = const RawPage<void>(
      transitionsBuilder: _Slide(),
      child: Text('C'),
    ).createRoute(context);
    final look = _look('A') as RawPageRoute<void>;
    // A route made outside a navigator is disposed by the test that made it.
    // ignore: invalid_use_of_protected_member
    addTearDown(page.dispose);
    addTearDown(look.dispose);
    expect(
      (page as PageRoute<void>).delegatedTransition,
      same(look.delegatedTransition),
    );
  });
}
