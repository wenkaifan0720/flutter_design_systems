// Parts that measure their words while they build measure again when a face
// arrives after the first frame (on the web, Space Grotesk or a script's
// fallback face often does): each then stands as one built after it.
import 'dart:convert';

import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

var _faces = 0;

/// A theme whose words are set in a face of its own that no test loaded
/// yet (until then the test font stands in), and what loads it: Space
/// Grotesk, from the package's fonts.
(BrutalThemeData, Future<void> Function()) _lateFace() {
  final family = 'Arriving${_faces++}';
  final theme = BrutalThemeData.light();
  final t = theme.textTheme;
  TextStyle late(TextStyle style) => style.copyWith(fontFamily: family);
  Future<void> load() async {
    final manifest = json.decode(
      await rootBundle.loadString('FontManifest.json'),
    ) as List<dynamic>;
    // A style keeps its package: the face registers under the package's
    // name for it.
    final loader = FontLoader(brutalRegisteredFamily(family));
    for (final entry in manifest.cast<Map<String, dynamic>>()) {
      if (!(entry['family'] as String).endsWith(brutalFontFamily)) continue;
      for (final font
          in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
    }
    await loader.load();
  }

  return (
    theme.copyWith(
      textTheme: t.copyWith(
        display: late(t.display),
        headline: late(t.headline),
        title: late(t.title),
        body: late(t.body),
        label: late(t.label),
        secondary: late(t.secondary),
        caption: late(t.caption),
      ),
    ),
    load,
  );
}

/// Builds [part] keyed `early`, loads the faces, then builds a second one
/// keyed `fresh` beside it, leaving the early one's widget as it was.
Future<void> _buildThenLoad(
  WidgetTester tester,
  Widget Function(Key key) part, {
  double width = 1440,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final (theme, load) = _lateFace();
  final early = part(const Key('early'));
  var fresh = false;
  late StateSetter rebuild;
  await tester.pumpWidget(
    MaterialApp(
      home: BrutalTheme(
        data: theme,
        child: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Align(
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [early, if (fresh) part(const Key('fresh'))],
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.runAsync(load);
  await tester.pumpAndSettle();
  rebuild(() => fresh = true);
  await tester.pumpAndSettle();
}

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(Key(key)));

void main() {
  testWidgets('a segmented button hugs its words in the face that arrived', (
    tester,
  ) async {
    await _buildThenLoad(
      tester,
      (key) => BrutalSegmentedButton<String>(
        key: key,
        expand: false,
        segments: const [
          BrutalSegment(value: 'en', label: 'English'),
          BrutalSegment(value: 'fr', label: 'Français'),
        ],
        value: 'en',
        onChanged: (_) {},
      ),
    );
    double second(String key) =>
        tester
            .getRect(
              find.descendant(
                of: find.byKey(Key(key)),
                matching: find.text('Français'),
              ),
            )
            .center
            .dx -
        _rect(tester, key).left;
    expect(second('early'), second('fresh'));
  });

  testWidgets("a stepper's number fits the face that arrived", (tester) async {
    await _buildThenLoad(
      tester,
      (key) => BrutalStepper(
        key: key,
        value: 5,
        max: 99999,
        semanticLabel: 'Guests',
        onChanged: (_) {},
      ),
    );
    expect(_rect(tester, 'early').size, _rect(tester, 'fresh').size);
  });

  testWidgets("a tab bar's tabs hold their words in the face that arrived", (
    tester,
  ) async {
    await _buildThenLoad(
      tester,
      (key) => BrutalTabBar(
        key: key,
        expand: false,
        tabs: const ['Overview', 'Schedule', 'Tickets'],
        selectedIndex: 0,
        onTap: (_) {},
      ),
    );
    expect(_rect(tester, 'early').size, _rect(tester, 'fresh').size);
    final early = find.descendant(
      of: find.byKey(const Key('early')),
      matching: find.text('Schedule'),
    );
    final fresh = find.descendant(
      of: find.byKey(const Key('fresh')),
      matching: find.text('Schedule'),
    );
    expect(
      tester.getRect(early).left - _rect(tester, 'early').left,
      tester.getRect(fresh).left - _rect(tester, 'fresh').left,
    );
  });

  testWidgets('a step progress lays its names in a row once they fit', (
    tester,
  ) async {
    await _buildThenLoad(
      tester,
      (key) => SizedBox(
        key: key,
        width: 400,
        child: const BrutalStepProgress(
          steps: ['Shipping', 'Payments', 'Confirms'],
          currentStep: 1,
        ),
      ),
    );
    expect(_rect(tester, 'early').size, _rect(tester, 'fresh').size);
  });

  testWidgets("a table's figures set their column in the face that arrived", (
    tester,
  ) async {
    await _buildThenLoad(
      tester,
      (key) => SizedBox(
        key: key,
        width: 300,
        child: const BrutalTable(
          columns: [
            BrutalTableColumn('Venue'),
            BrutalTableColumn('Seats', numeric: true),
          ],
          rows: [
            ['Gallery Nine', '1,204,880'],
            ['Kino 2', '96'],
          ],
          minColumnWidth: 0,
        ),
      ),
    );
    Rect cell(String key) => tester.getRect(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.text('1,204,880'),
      ),
    );
    expect(
      cell('early').left - _rect(tester, 'early').left,
      cell('fresh').left - _rect(tester, 'fresh').left,
    );
  });
}
