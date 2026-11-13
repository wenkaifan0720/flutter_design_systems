import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

DesignRefreshDetails? _state;
int _refreshes = 0;
Completer<void>? _pending;

final GlobalKey<DesignPullToRefreshState> _key = GlobalKey();

// The bare reference painter: the mode's name in the indicator's room.
Widget _list({ScrollPhysics? physics}) => harness(_view(physics: physics));

Widget _view({ScrollPhysics? physics}) => DesignPullToRefresh(
  key: _key,
  onRefresh: () {
    _refreshes++;
    return (_pending = Completer<void>()).future;
  },
  indicatorBuilder: (context, state) {
    _state = state;
    return Center(child: Text(state.mode.name));
  },
  child: ListView.builder(
    physics: physics,
    itemCount: 30,
    itemExtent: 50,
    itemBuilder: (context, i) => Text('row $i'),
  ),
);

void main() {
  setUp(() {
    _state = null;
    _refreshes = 0;
    _pending = null;
  });

  behaviourContract(
    'DesignPullToRefresh',
    build: (c) => _view(),
    node: () => find.byType(DesignPullToRefresh),
    semantics: isSemantics(
      customActions: const [CustomSemanticsAction(label: 'Refresh')],
    ),
    noDisabledState: 'a list that may not refresh leaves it out',
    motion: (p) async {
      unawaited(_key.currentState!.refresh());
      await p.tester.pump();
      expect(_state!.mode, DesignRefreshMode.refresh);
      _pending!.complete();
      await p.tester.pump();
      await p.tester.pump(const Duration(milliseconds: 300));
    },
  );

  for (final (name, physics) in [
    ('clamping', const ClampingScrollPhysics()),
    ('bouncing', const BouncingScrollPhysics()),
  ]) {
    testWidgets('$name: a short pull springs back; a long one refreshes '
        'until it completes', (tester) async {
      await tester.pumpWidget(_list(physics: physics));
      final short = await tester.startGesture(const Offset(200, 200));
      await short.moveBy(const Offset(0, 20));
      await short.moveBy(const Offset(0, 40));
      await tester.pump();
      expect(_state!.mode, DesignRefreshMode.drag);
      await short.up();
      await tester.pumpAndSettle();
      expect(_refreshes, 0);

      final long = await tester.startGesture(const Offset(200, 200));
      await long.moveBy(const Offset(0, 20));
      for (var i = 0; i < 6; i++) {
        await long.moveBy(const Offset(0, 40));
        await tester.pump();
      }
      expect(_state!.mode, DesignRefreshMode.armed);
      await long.up();
      await tester.pumpAndSettle();
      expect(_refreshes, 1);
      expect(_state!.mode, DesignRefreshMode.refresh);
      expect(find.text('refresh'), findsOneWidget);
      _pending!.complete();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('refresh'), findsNothing);
    });
  }

  testWidgets('a screen reader and the app can refresh without a pull', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_list());
    final target = semanticsOf(tester, find.byType(DesignPullToRefresh));
    final owner = semanticsOwner();
    owner.performAction(
      target.id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(
        const CustomSemanticsAction(label: 'Refresh'),
      ),
    );
    await tester.pump();
    expect(_refreshes, 1);
    _pending!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeAnnouncements().map((a) => a.message), [
      'Refreshing',
      'Refreshed',
    ], reason: 'a screen reader is told it started and finished');
    unawaited(_key.currentState!.refresh());
    await tester.pump();
    expect(_refreshes, 2);
    _pending!.complete();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    semantics.dispose();
  });
}
