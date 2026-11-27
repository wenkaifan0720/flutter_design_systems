// A Clay part ignores an app's corners that differ (it takes one step on
// every corner), and a debug build says so once, however many parts ask.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mixed corners are ignored, and debug says so once', (
    tester,
  ) async {
    final lines = <String>[];
    final was = debugPrint;
    debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');
    const cut = ClayStyle(
      corners: WidgetStatePropertyAll(
        RawCorners(topEnd: RawCorner.none, bottomStart: RawCorner.none),
      ),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ClayTheme(
          data: ClayThemeData.clay(Brightness.light),
          child: const Column(
            children: [
              ClayCard(style: cut, child: SizedBox(width: 100, height: 40)),
              ClayCard(style: cut, child: SizedBox(width: 100, height: 40)),
              ClayGroup(
                style: cut,
                children: [ClayListTile(title: 'Read')],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    final said = lines.where((l) => l.contains('corners override')).toList();
    expect(said, [
      'Clay ignores a corners override whose corners differ: it takes one '
          'step on every corner.',
    ]);
    // A square step on every corner is moved, and said once too.
    lines.clear();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ClayTheme(
          data: ClayThemeData.clay(Brightness.light),
          child: const Column(
            children: [
              ClayCard(
                style: ClayStyle(
                  corners: WidgetStatePropertyAll(
                    RawCorners.all(RawCorner.none),
                  ),
                ),
                child: SizedBox(width: 100, height: 40),
              ),
              ClayCard(
                style: ClayStyle(
                  corners: WidgetStatePropertyAll(
                    RawCorners.all(RawCorner.none),
                  ),
                ),
                child: SizedBox(width: 100, height: 40),
              ),
            ],
          ),
        ),
      ),
    );
    expect(lines.where((l) => l.contains('corner none')).toList(), [
      'Clay holds corner none to extraSmall, the nearest step it allows.',
    ]);
    debugPrint = was;
  });
}
