import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _page = ValueKey('page');

Widget _button(String label, VoidCallback onPressed) => RawButton(
  minimumSize: const Size(44, 44),
  onPressed: onPressed,
  builder: (context, states, _) => Container(
    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    color: states.contains(WidgetState.focused)
        ? const Color(0xFF9E9E9E)
        : const Color(0xFFE0E0E0),
    child: Text(label),
  ),
);

// A recipe laid over the page from the bottom: its title names the route.
Widget _recipe(RawModalDetails details) => Align(
  alignment: Alignment.bottomCenter,
  child: Container(
    key: _page,
    color: const Color(0xFFFFFFFF),
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          namesRoute: true,
          header: true,
          child: const Text('Lemon tart'),
        ),
        _button('Save', () {}),
        _button('Close', details.close),
      ],
    ),
  ),
);

RawModalRoute<void> _route() =>
    RawModalRoute<void>(builder: (context, details) => _recipe(details));

// An opener that pushes [route] when pressed.
Widget _opener(Route<Object?> Function() route) => Builder(
  builder: (context) => Center(
    child: RawButton(
      semanticLabel: 'Open',
      excludeSemantics: true,
      minimumSize: const Size(44, 44),
      onPressed: () => Navigator.of(context).push(route()),
      builder: (context, states, _) => const Text('open'),
    ),
  ),
);

Future<void> _openByKeys(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

bool _focusedOn(String label) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  var found = false;
  void look(Element e) {
    if (found) return;
    final w = e.widget;
    if (w is Text && w.data == label) found = true;
    e.visitChildElements(look);
  }

  look(focused as Element);
  return found;
}

// Focus on [label]'s button alone, not on a scope round all of the page.
bool _on(String label) => _focusedOn(label) && !_focusedOn('Lemon tart');

// The route's own node: the scope round its page.
Finder _scope() => find
    .ancestor(
      of: find.byKey(_page),
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.scopesRoute ?? false),
      ),
    )
    .first;

// Every node in the tree.
List<SemanticsNode> _nodes() {
  final all = <SemanticsNode>[];
  void visit(SemanticsNode n) {
    all.add(n);
    n.visitChildren((c) {
      visit(c);
      return true;
    });
  }

  visit(semanticsOwner().rootSemanticsNode!);
  return all;
}

void main() {
  behaviourContract(
    'RawModalRoute',
    build: (c) => _opener(_route),
    open: _openByKeys,
    node: _scope,
    // A route of its own with no role: it scopes what a screen reader
    // reaches; its page names it.
    semantics: isSemantics(scopesRoute: true, namesRoute: false, label: ''),
    noDisabledState:
        'a modal route has no disabled state; its controls do (a null '
        'onPressed)',
    root: () => find.byKey(_page),
    keyboard: (p) async {
      await p.tab();
      expect(_on('Save'), isTrue, reason: 'Tab goes in from the top');
      await p.tab();
      expect(_on('Close'), isTrue);
      await p.tab();
      expect(_on('Save'), isTrue, reason: 'Tab stays inside');
      await p.key(LogicalKeyboardKey.escape);
      expect(find.byKey(_page), findsNothing, reason: 'Escape closes it');
      expect(
        p.tester.getSemantics(find.bySemanticsLabel('Open')),
        isSemantics(isFocused: true),
        reason: 'focus goes back to what opened it',
      );
    },
    motion: (p) async {
      await p.tester.tap(find.text('Close'));
      await p.tester.pump();
    },
  );

  testWidgets('a reader hears no dialog: the route has no role and its page '
      'names it', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(harness(_opener(_route)));
    await _openByKeys(tester);
    final scope = semanticsOf(tester, _scope());
    expect(scope.getSemanticsData().role, SemanticsRole.none);
    final roles = _nodes().map((n) => n.getSemanticsData().role);
    expect(roles, isNot(contains(SemanticsRole.dialog)));
    expect(roles, isNot(contains(SemanticsRole.alertDialog)));
    final names = _nodes().where(
      (n) => n.getSemanticsData().flagsCollection.namesRoute,
    );
    expect(names.map((n) => n.label), ['Lemon tart']);
    semantics.dispose();
  });

  testWidgets('a DesignDialogRoute over the same page still says dialog', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(
        _opener(
          () => DesignDialogRoute<void>(
            builder: (context, details) => _recipe(details),
          ),
        ),
      ),
    );
    await _openByKeys(tester);
    expect(
      semanticsOf(tester, _scope()).getSemanticsData().role,
      SemanticsRole.dialog,
    );
    semantics.dispose();
  });

  testWidgets('Tab stays inside on the web too, where a route lets it leave '
      'the page', (tester) async {
    // The web's navigator: Tab past a route's last stop leaves the view.
    Widget web(Route<Object?> Function() route) => harness(
      Navigator(
        routeTraversalEdgeBehavior: TraversalEdgeBehavior.leaveFlutterView,
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          pageBuilder: (context, _, _) => _opener(route),
        ),
      ),
    );

    // Flutter's own RawDialogRoute there: Tab leaves from the last stop.
    await tester.pumpWidget(
      web(
        () => RawDialogRoute<void>(
          pageBuilder: (context, _, _) => _recipe(
            RawModalDetails(
              animation: kAlwaysCompleteAnimation,
              close: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
    await _openByKeys(tester);
    for (var i = 0; i < 2; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(_on('Close'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_on('Save'), isFalse, reason: 'it left the page');

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(web(_route));
    await _openByKeys(tester);
    for (var i = 0; i < 2; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(_on('Close'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_on('Save'), isTrue, reason: 'Tab stays inside');
  });

  testWidgets('a barrier tap, Android\'s back and details.close close it, '
      'each through maybePop', (tester) async {
    await tester.pumpWidget(harness(_opener(_route)));
    await _openByKeys(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(_page), findsNothing, reason: 'the barrier');

    await _openByKeys(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(_page), findsNothing, reason: 'back');

    await _openByKeys(tester);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byKey(_page), findsNothing, reason: 'details.close');
  });
}
