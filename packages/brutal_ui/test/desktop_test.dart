// Admit's ten screens as a desktop app meets them, at 1440 on a Mac: the
// keyboard reaches everything the pointer can press (each node a screen
// reader can tap takes focus too), and the side list's places are among them.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:ui' show Tristate;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/everyday_screens.dart';

const _ten = {
  'home',
  'events',
  'event',
  'checkout',
  'payment-failed',
  'search',
  'search-none',
  'tickets',
  'ticket',
  'settings',
};

void main() {
  for (final screen in everydayScreens.where((s) => _ten.contains(s.id))) {
    testWidgets(
      '${screen.id} at 1440: the keyboard reaches all a pointer presses',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          screen.app(Brightness.light, TextDirection.ltr),
        );
        await tester.pumpAndSettle();
        final unreached = <String>[];
        final reached = <String>{};
        void visit(SemanticsNode node) {
          final data = node.getSemanticsData();
          final presses =
              data.hasAction(SemanticsAction.tap) &&
              data.flagsCollection.isEnabled != Tristate.isFalse &&
              !data.flagsCollection.isHidden;
          if (presses) {
            if (data.flagsCollection.isFocused == Tristate.none) {
              unreached.add(data.label.isEmpty ? '$data' : data.label);
            } else {
              // A place says its name, then "Tab 2 of 5".
              reached.add(data.label.split('\n').first);
            }
          }
          node.visitChildren((child) {
            visit(child);
            return true;
          });
        }

        visit(
          tester
              .binding
              .renderViews
              .first
              .owner!
              .semanticsOwner!
              .rootSemanticsNode!,
        );
        expect(unreached, isEmpty, reason: 'pressable, but no focus stop');
        expect(reached, containsAll(const ['Home', 'Events', 'Tickets']));
        semantics.dispose();
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );
  }
}
