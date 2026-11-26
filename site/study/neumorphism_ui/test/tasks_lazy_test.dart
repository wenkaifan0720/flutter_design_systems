import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart' show RawListDetail;
import 'package:stint_core/stint_core.dart';
import 'package:stint_neumorphism/stint_neumorphism.dart';

void main() {
  testWidgets('Tasks builds the rows in view and the rest as they scroll in', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = StintRepository();
    await tester.pumpWidget(
      StintNeumorphism(
        launch: StintLaunch.fromUri(Uri.parse('/?page=tasks')),
        repository: repo,
      ),
    );
    await tester.pumpAndSettle();
    final rows = (StintController(repo)..data = repo.snapshot).visible;
    const w = StintWords();
    final list = find.byType(RawListDetail<String>);
    Finder row(Task t) =>
        find.descendant(of: list, matching: find.text(w.text(t.title)));
    final built = rows.where((t) => row(t).evaluate().isNotEmpty).length;
    expect(rows.length, 30);
    expect(built, inInclusiveRange(1, 12), reason: '$built rows built');
    await tester.scrollUntilVisible(
      row(rows.last),
      400,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(row(rows.last), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
