// An avatar and a media window show a picture an app hands them as an
// ImageProvider (a network or an asset image), over a media slot when both
// are given, and a media window needs no slot with one.
import 'dart:typed_data';

import 'package:appliance_ui/appliance_ui.dart';
import 'package:appliance_ui/appliance_host.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// A one-pixel transparent PNG.
final Uint8List _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Future<void> _show(WidgetTester tester, Widget part) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Scaffold(
        body: Center(child: SizedBox(width: 240, child: part)),
      ),
    ),
  );
  await tester.pump();
}

ImageProvider _shown(WidgetTester tester, Type part) => tester
    .widget<Image>(
      find.descendant(of: find.byType(part), matching: find.byType(Image)),
    )
    .image;

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets('an avatar shows the image it is given, over its slot', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final picture = MemoryImage(_png);
    await _show(tester, ApplianceAvatar(name: 'Ada Brook', image: picture));
    expect(_shown(tester, ApplianceAvatar), same(picture));
    expect(
      tester.getSemantics(find.byType(ApplianceAvatar)),
      isSemantics(label: 'Ada Brook', isImage: true),
    );
    semantics.dispose();

    await _show(
      tester,
      ApplianceAvatar(name: 'Ada Brook', image: picture, slotId: 'ada'),
    );
    expect(_shown(tester, ApplianceAvatar), same(picture));
    expect(find.byType(MediaSlotImage), findsNothing);
  });

  testWidgets('a media window shows the image it is given, with no slot', (
    tester,
  ) async {
    final picture = MemoryImage(_png);
    await _show(
      tester,
      ApplianceMedia(image: picture, semanticLabel: 'A cream kettle'),
    );
    expect(_shown(tester, ApplianceMedia), same(picture));

    await _show(
      tester,
      ApplianceMedia(
        image: picture,
        slotId: 'kettle',
        semanticLabel: 'A cream kettle',
      ),
    );
    expect(_shown(tester, ApplianceMedia), same(picture));
    expect(find.byType(MediaSlotImage), findsNothing);
  });

  test('a media window needs an image or a slot', () {
    final label = 'A cream kettle'.trim();
    expect(() => ApplianceMedia(semanticLabel: label), throwsAssertionError);
  });
}
