import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'support/centred_host.dart';

void main() {
  group('MinimalDialog', () {
    Future<Future<bool?>> raise(
      WidgetTester tester, {
      String? cancelLabel = 'Keep',
      bool destructive = true,
    }) async {
      late BuildContext page;
      await tester.pumpWidget(
        centredHost(
          Builder(
            builder: (context) {
              page = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final answer = showMinimalDialog<bool>(
        page,
        builder: (_) => MinimalDialog(
          title: 'Delete habit?',
          message: 'Its history goes too.',
          confirmLabel: 'Delete',
          cancelLabel: cancelLabel,
          destructive: destructive,
        ),
      );
      await tester.pumpAndSettle();
      return answer;
    }

    testWidgets('completes true on confirm', (tester) async {
      final answer = await raise(tester);
      expect(find.text('Its history goes too.'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Delete'));
      await tester.pumpAndSettle();
      expect(await answer, isTrue);
      expect(find.text('Delete habit?'), findsNothing);
    });

    testWidgets('completes false on cancel', (tester) async {
      final answer = await raise(tester);
      await tester.tap(find.bySemanticsLabel('Keep'));
      await tester.pumpAndSettle();
      expect(await answer, isFalse);
    });

    testWidgets('completes null on a tap on the scrim', (tester) async {
      final answer = await raise(tester);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(await answer, isNull);
    });

    // Focus opens on the safe answer (ui_core's RawAlertDialog): the keep of
    // a destructive question, the confirm of a plain one.
    testWidgets('Enter answers the safe action and Escape dismisses with '
        'null', (tester) async {
      var answer = await raise(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(await answer, isFalse);
      answer = await raise(tester, destructive: false);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(await answer, isTrue);
      answer = await raise(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(await answer, isNull);
    });

    // Focus opens on a button, and Tab goes round the two: the card is no
    // stop (a stop there shows nothing, two blank stops a lap).
    testWidgets('Tab goes round the buttons, never the card', (tester) async {
      final answer = await raise(tester);
      final opened = FocusManager.instance.primaryFocus;
      expect(opened, isNotNull);
      final stops = <FocusNode?>[];
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        stops.add(FocusManager.instance.primaryFocus);
      }
      expect(stops, contains(opened));
      expect(stops.toSet(), hasLength(2));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(await answer, isNull);
    });

    testWidgets('names its route and offers the confirm alone when asked', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final answer = await raise(tester, cancelLabel: null);
      expect(find.bySemanticsLabel('Keep'), findsNothing);
      // The heading names the route; the route's node scopes it.
      final heading = tester.getSemantics(
        find.bySemanticsLabel('Delete habit?'),
      );
      expect(
        heading,
        matchesSemantics(
          label: 'Delete habit?',
          isHeader: true,
          namesRoute: true,
        ),
      );
      var scope = heading.parent;
      while (scope != null &&
          !scope.getSemanticsData().flagsCollection.scopesRoute) {
        scope = scope.parent;
      }
      expect(scope, isNotNull);
      await tester.tap(find.bySemanticsLabel('Delete'));
      await tester.pumpAndSettle();
      expect(await answer, isTrue);
      handle.dispose();
    });

    testWidgets('the card stands in place, its buttons small', (tester) async {
      var confirmed = 0;
      var cancelled = 0;
      await tester.pumpWidget(
        centredHost(
          MinimalDialog(
            title: 'Archive Morning run?',
            confirmLabel: 'Archive',
            cancelLabel: 'Cancel',
            onConfirm: () => confirmed += 1,
            onCancel: () => cancelled += 1,
          ),
        ),
      );
      expect(
        tester.getSize(find.bySemanticsLabel('Archive')).height,
        MinimalChromeMetrics.controlSm,
      );
      expect(
        tester.getSize(find.byType(MinimalDialog)).width,
        lessThanOrEqualTo(MinimalDialog.maxWidth),
      );
      await tester.tap(find.bySemanticsLabel('Archive'));
      await tester.tap(find.bySemanticsLabel('Cancel'));
      expect((confirmed, cancelled), (1, 1));
    });

    Finder shadowed() => find.descendant(
      of: find.byType(MinimalDialog),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).boxShadow != null,
      ),
    );

    testWidgets('in place the card casts no shadow and is no route; raised '
        'it floats', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        centredHost(
          MinimalDialog(
            title: 'Discard this draft?',
            confirmLabel: 'Discard',
            onConfirm: () {},
          ),
        ),
      );
      expect(shadowed(), findsNothing);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Discard this draft?'))
            .getSemanticsData()
            .flagsCollection
            .scopesRoute,
        isFalse,
      );
      await raise(tester);
      expect(shadowed(), findsOneWidget);
      handle.dispose();
    });
  });
}
