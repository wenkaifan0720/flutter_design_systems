// A menu bar command that destroys something (Delete) stands in the
// destructive ink, as a menu button's destructive item does; the commands
// beside it keep the foreground ink.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

Widget _host(Brightness brightness) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: brightness,
    child: navigator!,
  ),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: MinimalMenuBar(
        menus: [
          MinimalMenuEntry(
            'Edit',
            children: [
              MinimalMenuEntry('Rename', onPressed: () {}),
              MinimalMenuEntry(
                'Delete',
                isDestructiveAction: true,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);

Color? _ink(WidgetTester tester, String label) =>
    tester.renderObject<RenderParagraph>(find.text(label)).text.style?.color;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('a destructive menu bar command stands in the destructive '
        'ink (${brightness.name})', (tester) async {
      await tester.pumpWidget(_host(brightness));
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      final t = MinimalThemeData.preset('standard', brightness);
      expect(_ink(tester, 'Delete'), t.destructiveInk);
      expect(_ink(tester, 'Rename'), isNot(t.destructiveInk));
    });
  }
}
