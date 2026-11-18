// Harbor in motion, through ui_core's moving states (moving_states.dart): on
// a phone a transaction row pressed halfway and its sheet halfway up; at
// desktop width a filter chip hovered and the search reached by the Tab key;
// by day and by night. At each moment nothing throws or overflows. With
// MOTION_OUT set, each moment is written there as a PNG for the self-review.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:ui_core_test/ui_core_test.dart' show DesignShadowClipCheck;

import 'moving_states.dart';

// Harbor is the example app's; a test reads it from there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/harbor.dart';

const _screen = ValueKey('screen');

Widget _harbor(Brightness brightness) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => RepaintBoundary(
    key: _screen,
    child: FrostedHost(brightness: brightness, child: page!),
  ),
  home: HarborApp(
    host: HarborHost(onBackdrop: (_) {}, onBrightness: (_) {}, onExit: () {}),
  ),
);

/// The screen as drawn at [name], under MOTION_OUT when it is set.
Future<void> _write(WidgetTester tester, String name) async {
  final out = Platform.environment['MOTION_OUT'];
  if (out == null || out.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_screen),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    File('$out/${name.replaceAll(' ', '-')}.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// The bundled fonts under the names the look asks for (bare and as the
/// package's), so a written moment shows its words.
Future<void> _loadFonts() async {
  final manifest = (json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>).cast<Map<String, dynamic>>();
  for (final family in manifest) {
    final name = family['family'] as String;
    final fonts = (family['fonts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    for (final alias in [
      name,
      if (!name.startsWith('packages/')) 'packages/frosted_ui/$name',
    ]) {
      final loader = FontLoader(alias);
      for (final font in fonts) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 34));
  }
}

void main() {
  setUpAll(_loadFonts);
  const looks = {'day': Brightness.light, 'night': Brightness.dark};
  for (final MapEntry(key: look, value: brightness) in looks.entries) {
    Future<void> pump(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_harbor(brightness));
      await _settle(tester);
    }

    // Each moment: no exception, no shadow cut near the moving control (a
    // press, a hover or a focus changes only its own neighbourhood), and
    // its picture for review.
    MovingStateLook at(WidgetTester tester, String device, Finder near) =>
        (moment) async {
          expect(tester.takeException(), isNull, reason: '$device, $moment');
          final report = await const DesignShadowClipCheck(look: 'Frosted')
              .check(
                tester.element(find.byKey(_screen)),
                runAsync: tester.runAsync,
                near: near.evaluate().isEmpty ? null : tester.getRect(near),
              );
          report.verify();
          await _write(tester, '$device-$look-$moment');
        };

    testWidgets('on a phone by $look: a row pressed, its sheet coming up', (
      tester,
    ) async {
      await pump(tester, const Size(390, 844));
      final row = find
          .ancestor(
            of: find.text('Blue Fern Café').first,
            matching: find.byType(FrostedTransactionRow),
          )
          .first;
      await atPressHalfway(tester, row, at(tester, 'phone', row));
      await atSheetHalfway(
        tester,
        () => tester.widget<FrostedTransactionRow>(row).onPressed!(),
        at(tester, 'phone', find.byType(FrostedSheet)),
      );
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('at desktop width by $look: a chip hovered, the search '
        'reached by the Tab key', (tester) async {
      await pump(tester, const Size(1440, 900));
      final income = find.text('Income');
      await atHover(tester, income, at(tester, 'desktop', income));
      await atFocus(
        tester,
        find.byType(FrostedSearchField),
        at(tester, 'desktop', find.byType(FrostedSearchField)),
      );
    });
  }
}
