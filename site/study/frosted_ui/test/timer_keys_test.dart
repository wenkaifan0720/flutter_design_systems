// Frosted's timer keys at their real widths: the shipped faces are loaded, so
// the words measure as they do on a screen.
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_frosted/stint_frosted.dart';

Future<void> loadFaces() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

void main() {
  // The palettes differ in their letters' tracking by a fraction of a pixel:
  // the keys' words decide the row, not an estimate the tracking tips over.
  testWidgets('the palette does not change the timer keys\' row', (
    tester,
  ) async {
    await tester.runAsync(loadFaces);
    for (final width in [377.0, 390.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final rows = <String, bool>{};
      for (final accent in FrostedThemeData.presets) {
        await tester.pumpWidget(
          StintFrosted(
            key: UniqueKey(),
            launch: StintLaunch(accent: accent),
            repository: StintRepository(),
          ),
        );
        await tester.pumpAndSettle();
        final stop = tester.getRect(
          find.byKey(const ValueKey('today-action-first')),
        );
        final change = tester.getRect(
          find.byKey(const ValueKey('today-action-last')),
        );
        rows[accent] = stop.top == change.top;
      }
      expect(
        rows.values.toSet(),
        hasLength(1),
        reason: 'at $width, side by side: $rows',
      );
      // Both keys' words fit their halves with room at a phone's width.
      expect(rows.values.first, isTrue, reason: 'at $width');
    }
  });
}
