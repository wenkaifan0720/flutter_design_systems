// FrostedThemeData.from changes colour only: every text style keeps Opal's
// face, size, weight, line and tracking (the look's own type), in the seeded
// theme's own inks. It took the base set's tracking (0.1 on 13), so a label
// set wider than the default's and a phone's pair of acts stacked under
// every seed where the default kept them side by side.
import 'dart:ui' show Brightness;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

const _seeds = <String, Color>{
  'navy': Color(0xFF1F3A68),
  'green': Color(0xFF2E7D32),
  'gold': Color(0xFFC9A227),
  'purple': Color(0xFF6D28D9),
  'pastel': Color(0xFFF4A7B9),
};

List<TextStyle> _slots(FrostedTextTheme t) => [
  t.displayLarge,
  t.displayMedium,
  t.displaySmall,
  t.headlineLarge,
  t.headlineMedium,
  t.headlineSmall,
  t.titleLarge,
  t.titleMedium,
  t.titleSmall,
  t.bodyLarge,
  t.bodyMedium,
  t.bodySmall,
  t.labelLarge,
  t.labelMedium,
  t.labelSmall,
  t.overline,
  t.stat,
  t.amount,
  t.amountSmall,
  t.link,
  t.tab,
  t.mono,
  t.monoSmall,
  t.monogram,
  t.wordmark,
];

double _width(String text, TextStyle style) {
  final p = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final w = p.width;
  p.dispose();
  return w;
}

void main() {
  for (final brightness in Brightness.values) {
    final own = FrostedThemeData.opal(brightness);
    for (final MapEntry(key: name, value: accent) in _seeds.entries) {
      test('from($name) sets every word in the look\'s own type, '
          '${brightness.name}', () {
        final seeded = FrostedThemeData.from(
          accent: accent,
          brightness: brightness,
        );
        final mine = _slots(seeded.textTheme);
        final theirs = _slots(own.textTheme);
        for (var i = 0; i < mine.length; i++) {
          expect(
            mine[i].copyWith(color: theirs[i].color),
            theirs[i],
            reason: 'slot $i',
          );
        }
        // The words keep the seeded theme's inks.
        expect(
          seeded.textTheme.titleMedium.color,
          seeded.colorScheme.textPrimary,
        );
        expect(seeded.colorScheme.accent, isNot(own.colorScheme.accent));
        // So a label measures as the default's.
        expect(
          _width('Switch task', seeded.textTheme.labelLarge),
          _width('Switch task', own.textTheme.labelLarge),
        );
      });
    }
  }
}
