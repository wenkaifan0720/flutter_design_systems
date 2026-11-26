// On a phone the current place's bar stands at the place's foot, under its
// name, inside the band: at the top it stood on the band's rule, against the
// page, and read as an underline on whatever scrolled behind it.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _places = [
  CivicNavItem(LucideIcons.house, 'Today', ValueKey('today')),
  CivicNavItem(LucideIcons.fileText, 'Tasks', ValueKey('tasks')),
  CivicNavItem(LucideIcons.circleUser, 'Time', ValueKey('time')),
];

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      "the current place's bar stands under its name (${brightness.name})",
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) => CivicHost(
              brightness: brightness,
              child: child ?? const SizedBox.shrink(),
            ),
            home: CivicAppShell(
              destinations: _places,
              selectedIndex: 1,
              onDestinationSelected: (_) {},
              child: const CivicScreen(body: Text('Tasks')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final place = find.byKey(const ValueKey('tasks'));
        final action = CivicTheme.of(tester.element(place)).action;
        final bars = <Rect>[];
        expect(
          place,
          paints..everything((method, arguments) {
            if (method == #drawRect &&
                (arguments[1] as Paint).color.toARGB32() == action.toARGB32()) {
              bars.add(arguments[0] as Rect);
            }
            return true;
          }),
        );
        expect(bars, hasLength(1));
        final name = tester.getRect(
          find.descendant(of: place, matching: find.text('Tasks')),
        );
        final box = tester.getRect(place);
        final bar = bars.single.shift(box.topLeft);
        expect(bar.top, greaterThanOrEqualTo(name.bottom));
        expect(bar.bottom, lessThanOrEqualTo(box.bottom + 0.5));
      },
    );
  }
}
