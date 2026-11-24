// RawPage and RawPageRoute (0.6.0): a look's page in a navigator's page
// list or pushed. Its route plays the look's transition with iOS's swipe
// back round it on iOS only, and once; fades under Reduce Motion; reads the
// page it holds now; transitions to a page but not to a full-screen dialog;
// and scopes its screen for a screen reader.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

var _plays = 0;

// A look's push, counted: the page slides in from the end.
class _Slide extends PageTransitionsBuilder {
  const _Slide();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    _plays++;
    return SlideTransition(
      position: Tween(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }
}

final _swipes = find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString().startsWith('_SwipeBack<'),
);

Widget _navigator(
  List<Page<void>> pages, {
  bool reduceMotion = false,
  void Function(Page<Object?> page)? removed,
}) => harness(
  Navigator(pages: pages, onDidRemovePage: removed ?? (page) {}),
  reduceMotion: reduceMotion,
);

// A screen with state of its own, to see it kept.
class _Note extends StatefulWidget {
  const _Note(this.text);

  final String text;

  @override
  State<_Note> createState() => _NoteState();
}

class _NoteState extends State<_Note> {
  @override
  Widget build(BuildContext context) => Text(widget.text);
}

void main() {
  setUp(() => _plays = 0);

  testWidgets(
    'the swipe back round the transition on iOS only, once',
    (tester) async {
      final ios = defaultTargetPlatform == TargetPlatform.iOS;
      await tester.pumpWidget(
        _navigator(const [
          RawPage<void>(transitionsBuilder: _Slide(), child: Text('Recipes')),
        ]),
      );
      await tester.pumpAndSettle();
      expect(_swipes, ios ? findsOneWidget : findsNothing);
      expect(_plays, greaterThan(0));
      // A builder that is a swipe back already is played as it is.
      await tester.pumpWidget(
        _navigator(const [
          RawPage<void>(
            key: ValueKey('swipe'),
            transitionsBuilder: SwipeBackPageTransitionsBuilder(_Slide()),
            child: Text('Recipes'),
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(_swipes, findsOneWidget);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets(
    "a drag from the leading edge takes the page back on iOS, not elsewhere",
    (tester) async {
      final ios = defaultTargetPlatform == TargetPlatform.iOS;
      final removed = <Page<Object?>>[];
      const recipe = RawPage<void>(
        key: ValueKey('recipe'),
        transitionsBuilder: _Slide(),
        child: SizedBox.expand(child: Text('Recipe')),
      );
      await tester.pumpWidget(
        _navigator(const [
          RawPage<void>(transitionsBuilder: _Slide(), child: Text('Recipes')),
          recipe,
        ], removed: removed.add),
      );
      await tester.pumpAndSettle();
      await tester.dragFrom(const Offset(4, 300), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(removed, ios ? [recipe] : isEmpty);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets(
    'under Reduce Motion the page fades in place of the look\'s transition',
    (tester) async {
      final ios = defaultTargetPlatform == TargetPlatform.iOS;
      await tester.pumpWidget(
        _navigator(const [
          RawPage<void>(transitionsBuilder: _Slide(), child: Text('Recipes')),
        ], reduceMotion: true),
      );
      expect(_plays, 0);
      expect(
        find.ancestor(
          of: find.text('Recipes'),
          matching: find.byType(FadeTransition),
        ),
        findsWidgets,
      );
      expect(_swipes, ios ? findsOneWidget : findsNothing);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('a new page under the same key rebuilds the screen in place, '
      'its state kept', (tester) async {
    await tester.pumpWidget(
      _navigator(const [
        RawPage<void>(
          key: ValueKey('note'),
          transitionsBuilder: _Slide(),
          child: _Note('one'),
        ),
      ]),
    );
    final before = tester.state<_NoteState>(find.byType(_Note));
    await tester.pumpWidget(
      _navigator(const [
        RawPage<void>(
          key: ValueKey('note'),
          transitionsBuilder: _Slide(),
          child: _Note('two'),
        ),
      ]),
    );
    expect(find.text('two'), findsOneWidget);
    expect(find.text('one'), findsNothing);
    expect(tester.state<_NoteState>(find.byType(_Note)), same(before));
  });

  testWidgets('a full-screen dialog page is one; the route reads it', (
    tester,
  ) async {
    late ModalRoute<Object?> route;
    await tester.pumpWidget(
      _navigator([
        RawPage<void>(
          transitionsBuilder: const _Slide(),
          fullscreenDialog: true,
          maintainState: false,
          child: Builder(
            builder: (context) {
              route = ModalRoute.of(context)!;
              return const Text('Compose');
            },
          ),
        ),
      ]),
    );
    expect(route, isA<PageRoute<void>>());
    expect((route as PageRoute<void>).fullscreenDialog, isTrue);
    expect(route.maintainState, isFalse);
    expect(route.transitionDuration, const Duration(milliseconds: 250));
  });

  test('it transitions to a page pushed over it, not to a full-screen '
      'dialog or a popup', () {
    Widget screen(BuildContext context) => const SizedBox();
    final route = RawPageRoute<void>(
      transitionsBuilder: const _Slide(),
      builder: screen,
    );
    expect(
      route.canTransitionTo(
        RawPageRoute<void>(transitionsBuilder: const _Slide(), builder: screen),
      ),
      isTrue,
    );
    expect(
      route.canTransitionTo(
        RawPageRoute<void>(
          transitionsBuilder: const _Slide(),
          fullscreenDialog: true,
          builder: screen,
        ),
      ),
      isFalse,
    );
    expect(
      route.canTransitionTo(
        RawDialogRoute<void>(pageBuilder: (context, _, _) => screen(context)),
      ),
      isFalse,
    );
  });

  testWidgets("pushed: the builder's screen, the transition's durations, a "
      'route scope for a screen reader', (tester) async {
    await tester.pumpWidget(harness(const SizedBox.expand()));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    final route = RawPageRoute<void>(
      transitionsBuilder: const _Slide(),
      settings: const RouteSettings(name: 'recipe'),
      builder: (context) => const Text('Recipe'),
    );
    navigator.push(route).ignore();
    await tester.pumpAndSettle();
    expect(find.text('Recipe'), findsOneWidget);
    expect(route.transitionDuration, const Duration(milliseconds: 250));
    expect(route.reverseTransitionDuration, const Duration(milliseconds: 250));
    expect(route.barrierColor, isNull);
    expect(route.debugLabel, contains('(recipe)'));
    expect(
      find.ancestor(
        of: find.text('Recipe'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.scopesRoute == true &&
              widget.explicitChildNodes,
        ),
      ),
      findsOneWidget,
    );
  });
}
