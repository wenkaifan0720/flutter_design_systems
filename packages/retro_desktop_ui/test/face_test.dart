// Jersey 15 has one weight and no slant. Flutter fakes a heavier one when it is asked, by thickening the outline, and a slanted
// one by skewing it, and either ruins a pixel face. Flutter has no `font-synthesis: none`, so the bundled file claims the
// heaviest weight and a slant while its outlines are untouched. Asking for either must change nothing.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

Future<Uint8List> _ink(WidgetTester tester, TextStyle style) async {
  return (await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final tp = TextPainter(
      text: TextSpan(
        text: 'Hamburgefons 0123',
        style: style.copyWith(color: const Color(0xFF000000)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset.zero);
    tp.dispose();
    final image = await recorder.endRecording().toImage(400, 80);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }))!;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadRetroDesktopFonts();
  });

  final t = RetroDesktopThemeData.preset('classic', Brightness.light);

  for (final weight in const [
    FontWeight.w100,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ]) {
    testWidgets('the system face asked for ${weight.value} stays itself', (
      tester,
    ) async {
      final plain = await _ink(tester, t.type.big);
      final asked = await _ink(tester, t.type.big.copyWith(fontWeight: weight));
      expect(asked, plain);
    }, tags: const ['goldens']);
  }

  testWidgets('the system face asked for italic stays itself', (tester) async {
    final plain = await _ink(tester, t.type.big);
    final asked = await _ink(
      tester,
      t.type.big.copyWith(fontStyle: FontStyle.italic),
    );
    expect(asked, plain);
  }, tags: const ['goldens']);

  testWidgets('every style in the system face is the one weight', (
    tester,
  ) async {
    for (final s in [
      t.type.chrome,
      t.type.small,
      t.type.sub,
      t.type.big,
      t.type.head,
      t.type.title,
    ]) {
      expect(s.fontFamily, retroDesktopFontFamily('Jersey15'));
      expect(s.fontWeight, FontWeight.w400);
    }
  });

  testWidgets('the reading face has a real bold: it changes', (tester) async {
    final plain = await _ink(tester, t.type.body);
    final bold = await _ink(
      tester,
      t.type.body.copyWith(fontWeight: FontWeight.w700),
    );
    expect(bold, isNot(plain));
  }, tags: const ['goldens']);

  testWidgets('the reading face stays legible at phone sizes', (tester) async {
    final phone = t.atWidth(390).type;
    expect(phone.body.fontSize, greaterThanOrEqualTo(15));
    expect(phone.read.fontSize, greaterThanOrEqualTo(16));
    expect(phone.meta.fontSize, greaterThanOrEqualTo(12));
  });
}
