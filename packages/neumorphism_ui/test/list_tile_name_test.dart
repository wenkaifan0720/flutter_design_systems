import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart' show neumorphicApp;

void main() {
  testWidgets('a tappable list tile has one spoken name and keeps its action', (
    tester,
  ) async {
    var taps = 0;
    for (final (subtitle, note, override, expected)
        in <(String?, String?, String?, String)>[
          (null, null, null, 'Profile'),
          ('Name and email', null, null, 'Profile, Name and email'),
          (
            'Name and email',
            'Work account',
            null,
            'Profile, Name and email, Work account',
          ),
          (
            'Name and email',
            null,
            'Open account settings',
            'Open account settings',
          ),
        ]) {
      await tester.pumpWidget(
        neumorphicApp(
          NeumorphicListTile(
            title: 'Profile',
            subtitle: subtitle,
            note: note,
            semanticLabel: override,
            onPressed: () => taps++,
          ),
        ),
      );
      final name = find.bySemanticsLabel(expected);
      expect(name, findsOneWidget);
      expect(tester.getSemantics(name).label, expected);
      await tester.tap(find.byType(NeumorphicListTile));
      await tester.pumpAndSettle();
    }
    expect(taps, 4);
  });
}
