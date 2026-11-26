// Roomtone on a desk: the Home fills its screen as a rack does, its two rows
// even; the Overview's pitch and player start on one line; the record key
// keeps its deck's centre between the keys either side.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';

import 'package:studio_ui/studio_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/everyday_screens.dart';
import '../example/lib/kit_gallery/roomtone/episode.dart' show RoomtonePlayer;

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : studioRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

Future<void> _open(
  WidgetTester tester,
  String id,
  Size size, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  final screen = everydayScreens.firstWhere((s) => s.id == id);
  await tester.pumpWidget(screen.app(Brightness.light, direction));
  await tester.pumpAndSettle();
}

Rect _box(WidgetTester tester, Finder f) => tester.getRect(f);

void main() {
  setUpAll(_loadFonts);

  for (final size in const [Size(1440, 900), Size(1280, 800)]) {
    testWidgets('on a ${size.width.round()} desk the Home fills its screen', (
      tester,
    ) async {
      await _open(tester, 'home', size);
      final groups = find.byType(StudioListGroup);
      final panels = find.byType(StudioPanel);
      final bottoms = [
        for (final e in [...groups.evaluate(), ...panels.evaluate()])
          tester.getRect(find.byElementPredicate((x) => x == e)).bottom,
      ];
      final lowest = bottoms.reduce((a, b) => a > b ? a : b);
      expect(
        lowest,
        greaterThanOrEqualTo(size.height * 0.8),
        reason:
            'the Home ends at ${(lowest / size.height * 100).round()}% of the screen',
      );
      expect(
        lowest,
        lessThanOrEqualTo(size.height),
        reason: 'one screen, no scroll',
      );
      // The drafts and the shows they follow close the page on one line.
      final drafts = _box(
        tester,
        find.byWidgetPredicate(
          (w) => w is StudioListGroup && w.header == 'Your drafts',
        ),
      );
      final shows = _box(tester, panels.last);
      expect(
        (drafts.bottom - shows.bottom).abs(),
        lessThanOrEqualTo(StudioSpacing.regular),
      );
      expect(
        find.byType(RoomtonePlayer),
        findsOneWidget,
        reason: 'the whole player on a desk',
      );
      // Each show's name and count on one line.
      for (final e
          in find
              .descendant(of: panels.last, matching: find.byType(Text))
              .evaluate()) {
        final text = e.widget as Text;
        final style = DefaultTextStyle.of(e).style.merge(text.style);
        expect(
          tester.getSize(find.byElementPredicate((x) => x == e)).height,
          lessThan(style.fontSize! * (style.height ?? 1.2) * 1.5),
          reason: '"${text.data}" wraps',
        );
      }
    });
  }

  testWidgets('on a narrow desk the Home keeps the card beside the latest', (
    tester,
  ) async {
    await _open(tester, 'home', const Size(1024, 768));
    expect(find.text('Resume'), findsOneWidget);
    expect(find.byType(RoomtonePlayer), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is StudioSectionHeader && w.text == 'Shows you follow',
      ),
      findsNothing,
    );
  });

  testWidgets('on a phone the Home keeps its column', (tester) async {
    await _open(tester, 'home', const Size(390, 844));
    expect(
      find.byWidgetPredicate(
        (w) => w is StudioSectionHeader && w.text == 'Shows you follow',
      ),
      findsNothing,
    );
    expect(find.text('Resume'), findsOneWidget);
  });

  testWidgets("on a desk the pitch's card and the player start on one line", (
    tester,
  ) async {
    await _open(tester, 'overview', const Size(1440, 900));
    final card = _box(
      tester,
      find
          .ancestor(
            of: find.text('An app as a well-made piece of studio gear.'),
            matching: find.byType(StudioSurface),
          )
          .first,
    );
    final player = _box(
      tester,
      find
          .descendant(
            of: find.byType(RoomtonePlayer),
            matching: find.byType(StudioDisplay),
          )
          .first,
    );
    expect(card.top, closeTo(player.top, 0.5));
  });

  for (final width in const [390.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'the record key keeps the deck\'s centre at ${width.round()}, ${direction.name}',
        (tester) async {
          await _open(
            tester,
            'record',
            Size(width, width < 600 ? 844 : 900),
            direction: direction,
          );
          final key = find.byWidgetPredicate(
            (w) => w is StudioTransportKey && w.record,
          );
          final row = find.ancestor(of: key, matching: find.byType(Wrap)).first;
          expect(
            _box(tester, key).center.dx,
            closeTo(_box(tester, row).center.dx, 0.5),
          );
        },
      );
    }
  }
}
