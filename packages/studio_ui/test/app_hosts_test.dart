// Studio under each of Flutter's app hosts: StudioHost over MaterialApp,
// CupertinoApp and WidgetsApp, by day and by night, with a field, a switch,
// a select and a dialog working the same in each.
import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:studio_ui/studio_ui.dart';

typedef _Host = Widget Function(Brightness brightness, Widget home);

Widget _hosted(BuildContext context, Widget? child, Brightness brightness) =>
    StudioHost(brightness: brightness, child: child!);

final Map<String, _Host> _hosts = {
  'MaterialApp': (b, home) => material.MaterialApp(
    builder: (context, child) => _hosted(context, child, b),
    home: home,
  ),
  'CupertinoApp': (b, home) => cupertino.CupertinoApp(
    builder: (context, child) => _hosted(context, child, b),
    home: home,
  ),
  'WidgetsApp': (b, home) => WidgetsApp(
    color: const Color(0xFF1B1D21),
    pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
        PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
    builder: (context, child) => _hosted(context, child, b),
    home: home,
  ),
};

class _Desk extends StatefulWidget {
  const _Desk();

  @override
  State<_Desk> createState() => _DeskState();
}

class _DeskState extends State<_Desk> {
  String typed = '';
  bool monitor = false;
  String speed = '1x';
  String? answer;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      StudioTextField(
        labelText: 'Show name',
        onChanged: (value) => setState(() => typed = value),
      ),
      const SizedBox(height: 16),
      StudioSwitch(
        value: monitor,
        semanticLabel: 'Monitor',
        onChanged: (value) => setState(() => monitor = value),
      ),
      const SizedBox(height: 16),
      StudioSelect<String>(
        labelText: 'Speed',
        value: speed,
        items: const [
          StudioSelectItem(value: '1x', label: 'Normal'),
          StudioSelectItem(value: '1.5x', label: 'Faster'),
        ],
        onChanged: (value) => setState(() => speed = value),
      ),
      const SizedBox(height: 16),
      StudioButton(
        'Export',
        onPressed: () => showStudioDialog<void>(
          context: context,
          builder: (context) => StudioDialog(
            title: 'Export this take?',
            actions: [
              StudioButton.lit(
                'Export now',
                onPressed: () {
                  setState(() => answer = 'exported');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
      Text('$typed|$monitor|$speed|${answer ?? '-'}'),
    ],
  );
}

void main() {
  setUpAll(studioLoadFonts);
  for (final MapEntry(key: name, value: host) in _hosts.entries) {
    for (final b in Brightness.values) {
      testWidgets(
        '$name, ${b.name}: Studio themes the app and its parts work',
        (tester) async {
          await tester.pumpWidget(host(b, const _Desk()));
          await tester.pumpAndSettle();

          final theme = StudioTheme.of(
            tester.element(find.byType(StudioSwitch)),
          );
          expect(
            theme.colors.chassis,
            StudioThemeData.preset('anodised', b).colors.chassis,
          );

          await tester.enterText(find.byType(EditableText), 'Roomtone');
          await tester.tap(find.byType(StudioSwitch));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Normal'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Faster').last);
          await tester.pumpAndSettle();

          await tester.tap(find.text('Export'));
          await tester.pumpAndSettle();
          expect(find.text('Export this take?'), findsOneWidget);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(find.text('Export this take?'), findsNothing);
          await tester.tap(find.text('Export'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Export now'));
          await tester.pumpAndSettle();

          expect(find.text('Roomtone|true|1.5x|exported'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
