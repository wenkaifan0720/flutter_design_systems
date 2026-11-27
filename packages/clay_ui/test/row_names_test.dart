// What a screen reader hears for a row and for a control in its field: a
// leading part (an avatar's monogram, a glyph tile) is decoration and stays
// out of the row's name, a status tag at its end is in it; a control in a
// ClayFormField takes the field's label once.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _pump(WidgetTester tester, Widget body) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => ClayHost(child: child!),
      home: ClayScreen(body: body),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(clayLoadFonts);

  testWidgets("a row's monogram stays out of its name, its tag is in it", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      ClayGroup(
        children: [
          ClayListTile(
            leading: const ClayAvatar(name: 'Mia Okafor'),
            title: 'Mia Okafor',
            subtitle: 'Designer',
            onTap: () {},
          ),
          ClayListTile(
            leading: const ClayAvatar(name: 'George Eliot'),
            title: 'Middlemarch',
            trailing: const ClayTag('Reading'),
            onTap: () {},
          ),
        ],
      ),
    );
    expect(find.bySemanticsLabel('Mia Okafor\nDesigner'), findsOneWidget);
    expect(find.bySemanticsLabel('Middlemarch\nReading'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('George Eliot')), findsNothing);
    handle.dispose();
  });

  testWidgets('a control in its field takes the label once', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClayFormField(
            labelText: 'Goal',
            helperText: '12 books',
            child: ClaySlider(value: 12, min: 4, max: 52, onChanged: (_) {}),
          ),
          ClayFormField(
            labelText: 'Status',
            child: ClaySegmentedButton<int>(
              segments: const [
                ClaySegment(value: 0, label: 'To read'),
                ClaySegment(value: 1, label: 'Done'),
              ],
              selected: 0,
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
    expect(find.bySemanticsLabel('Goal'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Goal')),
      isSemantics(isSlider: true, hint: '12 books'),
    );
    expect(find.bySemanticsLabel('Status'), findsOneWidget);
    expect(find.bySemanticsLabel('To read'), findsOneWidget);
    handle.dispose();
  });
}
