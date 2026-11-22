// At the ordinary text size, a label lines up with what it stands beside:
// a navigation key centres its icon and label together, and a tracking
// timeline's timestamp shares its title's baseline when they fit.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  double scale = 2,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 620);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, navigator) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: ApplianceTheme(
            data: ApplianceThemeData.light(),
            child: navigator!,
          ),
        ),
      ),
      home: Center(child: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(applianceLoadFonts);
  testWidgets('navigation centres its icon and label at ordinary text size', (
    tester,
  ) async {
    await _show(
      tester,
      ApplianceNavigationBar(
        destinations: const [
          ApplianceDestination(label: 'Home', icon: Icons.home),
          ApplianceDestination(label: 'Shop', icon: Icons.store),
        ],
        selectedIndex: 0,
        onSelected: (_) {},
      ),
      scale: 1,
    );
    final label = find.text('Home');
    final bounds = tester.getRect(
      find
          .ancestor(
            of: label,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is ConstrainedBox &&
                  w.constraints.minHeight == ApplianceNavigationBar.keyHeight,
            ),
          )
          .first,
    );
    final top = tester.getTopLeft(find.byIcon(Icons.home)).dy;
    final bottom = tester.getBottomLeft(label).dy;
    expect((top + bottom) / 2, closeTo(bounds.center.dy, 0.5));
  });
  testWidgets('a tracking timestamp and title share a baseline when they fit', (
    tester,
  ) async {
    await _show(
      tester,
      const ApplianceTimeline(
        entries: [ApplianceTimelineEntry(title: 'Packed', time: 'Sat 16:05')],
      ),
      scale: 1,
    );
    double baseline(String text) {
      final item = find.text(text);
      final paragraph = tester.renderObject<RenderParagraph>(item);
      return tester.getTopLeft(item).dy +
          paragraph.getDryBaseline(
            paragraph.constraints,
            TextBaseline.alphabetic,
          )!;
    }

    expect(baseline('Sat 16:05'), closeTo(baseline('Packed'), 0.1));
  });
}
