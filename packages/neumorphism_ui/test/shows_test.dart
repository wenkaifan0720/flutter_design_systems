import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);
  testWidgets(
    'portrait image failures retain initials and a single spoken name',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          neumorphicApp(
            NeumorphicAvatar(
              'NW',
              name: 'Nia Walker',
              image: MemoryImage(Uint8List.fromList([0, 1, 2])),
            ),
          ),
        );
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();
        expect(find.text('NW'), findsOneWidget);
        expect(find.bySemanticsLabel('Nia Walker'), findsOneWidget);
        expect(find.bySemanticsLabel('NW'), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets('face pile keeps hidden names, count and logical order', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      const faces = [
        NeumorphicFace('NW', name: 'Nia'),
        NeumorphicFace('AK', name: 'Amir'),
        NeumorphicFace('JR', name: 'June'),
      ];
      await tester.pumpWidget(
        neumorphicApp(
          const NeumorphicAvatarGroup(faces, most: 2),
          direction: TextDirection.rtl,
        ),
      );
      expect(find.text('+1'), findsOneWidget);
      expect(find.bySemanticsLabel('Nia, Amir, June'), findsOneWidget);
      expect(
        tester.getCenter(find.text('NW')).dx,
        greaterThan(tester.getCenter(find.text('AK')).dx),
      );
      await tester.pumpWidget(
        neumorphicApp(const NeumorphicAvatarGroup(faces, most: 0)),
      );
      expect(find.text('+3'), findsOneWidget);
      await tester.pumpWidget(neumorphicApp(const NeumorphicAvatarGroup([])));
      expect(find.byType(NeumorphicAvatar), findsNothing);
    } finally {
      semantics.dispose();
    }
  });
  testWidgets('photo accepts direct content and absent media', (tester) async {
    await tester.pumpWidget(
      neumorphicApp(
        const NeumorphicMedia(label: 'A place', child: Text('Custom picture')),
      ),
    );
    expect(find.text('Custom picture'), findsOneWidget);
    await tester.pumpWidget(
      neumorphicApp(const NeumorphicMedia(label: 'Missing picture')),
    );
    expect(tester.takeException(), isNull);
  });
  check(
    'portraits at large type',
    () => const Wrap(
      spacing: 12,
      children: [
        NeumorphicAvatar('NW', name: longLine),
        NeumorphicAvatar('大山', selected: true),
      ],
    ),
  );
  check(
    'face pile in a narrow slot',
    () => const NeumorphicAvatarGroup([
      NeumorphicFace('NW'),
      NeumorphicFace('AK'),
      NeumorphicFace('JR'),
      NeumorphicFace('SK'),
      NeumorphicFace('AT'),
    ]),
  );
}
