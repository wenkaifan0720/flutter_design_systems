// A select's list fades and slides in from its field, then fades out before
// it goes, as Fluent 2's menus and popovers do: it never lands in one frame.
import 'package:fluent2_design_ui/fluent2_design_parts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _show(WidgetTester tester, Widget child) async {
  tester.view
    ..physicalSize = const Size(1440, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          Fluent2Host(brightness: Brightness.light, child: app!),
      home: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(width: 320, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("a select's list fades in, and out before it goes", (
    tester,
  ) async {
    await _show(
      tester,
      Fluent2Select<String>(
        semanticLabel: 'Channel',
        prompt: 'Choose a channel',
        value: null,
        options: const [
          Fluent2Option('general', 'General'),
          Fluent2Option('design', 'Design'),
        ],
        onChanged: (_) {},
      ),
    );
    double shown() => tester
        .widget<Opacity>(
          find
              .ancestor(of: find.text('Design'), matching: find.byType(Opacity))
              .first,
        )
        .opacity;
    await tester.tap(find.text('Choose a channel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(shown(), inExclusiveRange(0.0, 1.0));
    await tester.pumpAndSettle();
    expect(shown(), 1.0);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.text('Design'), findsOneWidget);
    expect(shown(), inExclusiveRange(0.0, 1.0));
    await tester.pumpAndSettle();
    expect(find.text('Design'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
