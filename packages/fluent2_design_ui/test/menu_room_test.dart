// A split button's menu and a popover low on a phone open on the side with
// the room: above their trigger when the room under it is short of what they
// want, rather than a sliver scrolling under it.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

Widget _app(Widget page) => WidgetsApp(
  color: const Color(0xFF000000),
  debugShowCheckedModeBanner: false,
  supportedLocales: RawWidgetsLocalizations.supportedLocales,
  localizationsDelegates: const [
    RawWidgetsLocalizations.delegate,
    Fluent2Localizations.delegate,
  ],
  builder: (context, child) => Fluent2Host(child: child!),
  onGenerateRoute: (settings) => PageRouteBuilder<void>(
    settings: settings,
    pageBuilder: (context, _, _) => page,
  ),
);

Widget _low(double above, Widget trigger) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: above),
      trigger,
    ],
  ),
);

void main() {
  for (final above in [700.0, 740.0, 780.0]) {
    testWidgets(
      'a split button ${above.round()} down a phone opens its menu above it',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final button = Fluent2SplitButton(
          'Reply',
          onPressed: () {},
          actions: [
            for (var i = 0; i < 12; i++)
              Fluent2SplitAction('Choice $i', onPressed: () {}),
          ],
        );
        await tester.pumpWidget(_app(_low(above, button)));
        await tester.pumpAndSettle();
        final trigger = tester.getRect(find.byWidget(button));
        // The chevron half, at the button's end.
        await tester.tapAt(trigger.centerRight - const Offset(8, 0));
        await tester.pumpAndSettle();
        // The menu's first and last rows, both on screen above the button.
        final first = tester.getRect(find.text('Choice 0'));
        final last = tester.getRect(find.text('Choice 11'));
        expect(first.top, greaterThanOrEqualTo(0));
        expect(
          last.bottom,
          lessThanOrEqualTo(trigger.top),
          reason:
              'the menu stayed under its button: $first..$last, '
              'button $trigger',
        );
      },
    );
    testWidgets(
      'a popover ${above.round()} down a phone opens above its trigger',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const content = SizedBox(height: 320, child: Text('Notes'));
        final popover = Fluent2Popover(
          label: 'Notes',
          trigger: (context, toggle) =>
              Fluent2Button('Notes', onPressed: toggle),
          content: content,
        );
        await tester.pumpWidget(_app(_low(above, popover)));
        await tester.pumpAndSettle();
        final trigger = tester.getRect(find.byType(Fluent2Button));
        await tester.tap(find.byType(Fluent2Button));
        await tester.pumpAndSettle();
        final panel = tester.getRect(find.byWidget(content));
        expect(panel.top, greaterThanOrEqualTo(0));
        expect(
          panel.bottom,
          lessThanOrEqualTo(trigger.top),
          reason: 'the popover stayed under its trigger: $panel, $trigger',
        );
      },
    );
  }
}
