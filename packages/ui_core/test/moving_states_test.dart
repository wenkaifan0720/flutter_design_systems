import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'moving_states.dart';

Widget _app(Widget home) => WidgetsApp(
  color: const Color(0xFF000000),
  debugShowCheckedModeBanner: false,
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  home: home,
);

void main() {
  late Set<WidgetState> states;
  Widget button(String label) => RawButton(
    onPressed: () {},
    semanticLabel: label,
    builder: (context, s, _) {
      if (label == 'Save') states = s;
      return SizedBox(width: 120, height: 44, child: Text(label));
    },
  );

  testWidgets('it holds a press, a hover and a focus where they show', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(Column(children: [button('Back'), button('Save')])),
    );
    final save = find.byType(RawButton).last;
    final seen = <String, Set<WidgetState>>{};
    Future<void> look(String moment) async => seen[moment] = {...states};
    await atPressHalfway(tester, save, look);
    await atHover(tester, save, look);
    await atFocus(tester, save, look);
    expect(seen.keys, [
      'press held halfway',
      'hover halfway',
      'hover',
      'focus halfway',
      'focus',
    ]);
    expect(seen['press held halfway'], contains(WidgetState.pressed));
    expect(seen['hover'], contains(WidgetState.hovered));
    expect(seen['focus'], contains(WidgetState.focused));
    // Each moment let go once it is captured.
    expect(states, isNot(contains(WidgetState.pressed)));
    expect(states, isNot(contains(WidgetState.hovered)));
    expect(states, isNot(contains(WidgetState.focused)));
  });

  testWidgets('it holds a sheet halfway up', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      _app(
        Navigator(
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (c, _, _) {
              context = c;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    double? at;
    double? held;
    await atSheetHalfway(
      tester,
      () => Navigator.of(context).push(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, animation, _) => const SizedBox.expand(),
          transitionsBuilder: (_, animation, _, child) {
            at = animation.value;
            return child;
          },
        ),
      ),
      (_) async => held = at,
    );
    expect(held, closeTo(.5, .01));
    expect(at, 1);
  });

  testWidgets('it holds a carousel halfway through a swipe', (tester) async {
    final pages = PageController();
    addTearDown(pages.dispose);
    await tester.pumpWidget(
      _app(
        PageView(
          controller: pages,
          children: [
            for (var i = 0; i < 3; i++) SizedBox.expand(child: Text('$i')),
          ],
        ),
      ),
    );
    double? held;
    await atSwipeHalfway(
      tester,
      find.byType(PageView),
      (_) async => held = pages.page,
    );
    expect(held, closeTo(.5, .05));
    expect(pages.page, 1);
  });
}
