import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'support/column_host.dart';

void main() {
  group('MinimalAvatar', () {
    test('initials and tone are deterministic', () {
      expect(MinimalAvatar.initialsOf('Hanna Berg'), 'HB');
      expect(MinimalAvatar.initialsOf('  mara   quintero  x'), 'MQ');
      expect(MinimalAvatar.initialsOf('Oskar'), 'O');
      expect(
        MinimalAvatar.colorsOf('Hanna Berg', lightTheme),
        MinimalAvatar.colorsOf('Hanna Berg', lightTheme),
      );
    });

    test('a face is a neutral shade, never the accent or a status', () {
      const names = [
        'Hanna Berg',
        'Oskar Lind',
        'Ines Duarte',
        'Tom Alves',
        'Liv Sande',
        'Mara Quintero',
        'Jonas Weber',
        'Café Morgen',
      ];
      for (final id in MinimalThemeData.presets) {
        for (final b in Brightness.values) {
          final t = MinimalThemeData.preset(id, b);
          final status = [
            for (final tone in [MinimalTone.success, MinimalTone.warning]) ...[
              t.tone(tone).foreground,
              t.tone(tone).background,
            ],
            t.destructive,
            t.destructiveSubtle,
          ];
          // A face's tint is the muted fill's, never more.
          double chroma(Color c) =>
              [c.r, c.g, c.b].reduce(math.max) -
              [c.r, c.g, c.b].reduce(math.min);
          for (final name in names) {
            final c = MinimalAvatar.colorsOf(name, t);
            expect(status, isNot(contains(c.fill)), reason: '$id $b $name');
            expect(status, isNot(contains(c.ink)), reason: '$id $b $name');
            expect(c.fill, isNot(t.primary), reason: '$id $b $name');
            expect(
              chroma(c.fill),
              lessThanOrEqualTo(chroma(t.muted) + 1e-6),
              reason: '$id $b $name',
            );
            expect(c.ink, t.foreground, reason: '$id $b $name');
            // The initials read on their disc.
            final lf = c.fill.computeLuminance();
            final li = c.ink.computeLuminance();
            final ratio = (math.max(lf, li) + 0.05) / (math.min(lf, li) + 0.05);
            expect(ratio, greaterThanOrEqualTo(4.5), reason: '$id $b $name');
          }
          // A stack of three people shows three faces.
          final stack = {
            for (final name in ['Hanna Berg', 'Oskar Lind', 'Ines Duarte'])
              MinimalAvatar.colorsOf(name, t).fill,
          };
          expect(stack, hasLength(3), reason: '$id $b');
        }
      }
    });

    testWidgets('draws initials at its size and announces the name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        columnHost(const Align(child: MinimalAvatar('Hanna Berg', size: 32))),
      );
      expect(find.text('HB'), findsOneWidget);
      expect(tester.getSize(find.byType(MinimalAvatar)), const Size(32, 32));
      expect(
        tester.getSemantics(find.byType(MinimalAvatar)),
        matchesSemantics(label: 'Hanna Berg', isImage: true),
      );
      handle.dispose();
    });

    testWidgets('an unresolved media slot falls back to the initials', (
      tester,
    ) async {
      await tester.pumpWidget(
        columnHost(
          const Align(child: MinimalAvatar('Mara Quintero', media: 'x')),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(MinimalMediaImage), findsOneWidget);
      expect(find.text('MQ'), findsOneWidget);
    });

    testWidgets('a stack folds the rest into +N and speaks every name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        columnHost(
          const Align(
            child: MinimalAvatarGroup([
              'Hanna Berg',
              'Oskar Lind',
              'Ines Duarte',
              'Tom Alves',
              'Liv Sande',
            ], max: 3),
          ),
        ),
      );
      expect(find.text('+2'), findsOneWidget);
      expect(find.byType(MinimalAvatar), findsNWidgets(3));
      expect(
        tester.getSemantics(find.byType(MinimalAvatarGroup)),
        matchesSemantics(
          label: 'Hanna Berg, Oskar Lind, Ines Duarte and 2 more',
          isImage: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a stack rings its faces in the ground it stands on', (
      tester,
    ) async {
      Iterable<Color?> rings() => tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(MinimalAvatarGroup),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.shape == BoxShape.circle && d.border == null)
          .map((d) => d.color);
      const stack = MinimalAvatarGroup(['Hanna Berg', 'Oskar Lind']);
      await tester.pumpWidget(columnHost(const Align(child: stack)));
      expect(rings(), [lightTheme.background, lightTheme.background]);
      await tester.pumpWidget(
        columnHost(const Align(child: MinimalCard(child: stack))),
      );
      expect(rings(), [lightTheme.card, lightTheme.card]);
    });
  });
}
