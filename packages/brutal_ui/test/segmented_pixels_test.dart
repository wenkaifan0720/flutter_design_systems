// A segmented button that hugs its words stands on whole pixels: each cell
// is as wide as its widest words and its padding, rounded up, so the rules
// between the cells and round them fall on the pixel grid. On a fraction a
// chosen cell showed a grey seam inside each rule and a soft end rule.
import 'dart:convert';

import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadSpaceGrotesk() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  final loader = FontLoader(brutalRegisteredFamily(brutalFontFamily));
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    if (!(entry['family'] as String).endsWith(brutalFontFamily)) continue;
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
  }
  await loader.load();
}

void main() {
  setUpAll(_loadSpaceGrotesk);

  testWidgets('a hugging segmented button stands on whole pixels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: BrutalTheme(
          data: BrutalThemeData.light(),
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BrutalSegmentedButton<String>(
                expand: false,
                segments: const [
                  BrutalSegment(value: 'en', label: 'English'),
                  BrutalSegment(value: 'fr', label: 'Français'),
                ],
                value: 'fr',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final control = find.byType(BrutalSegmentedButton<String>);
    final edges = <double>[
      for (final words in ['English', 'Français']) ...[
        tester
            .getRect(
              find
                  .ancestor(
                    of: find.text(words),
                    matching: find.byWidgetPredicate(
                      (w) => w is SizedBox && w.width != null && w.width! > 40,
                    ),
                  )
                  .first,
            )
            .left,
        tester
            .getRect(
              find
                  .ancestor(
                    of: find.text(words),
                    matching: find.byWidgetPredicate(
                      (w) => w is SizedBox && w.width != null && w.width! > 40,
                    ),
                  )
                  .first,
            )
            .right,
      ],
      tester.getRect(control).right,
    ];
    for (final x in edges) {
      expect(x, x.roundToDouble(), reason: 'an edge between pixels');
    }
  });
}
