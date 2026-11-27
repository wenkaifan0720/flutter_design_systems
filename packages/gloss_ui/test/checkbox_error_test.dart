// A checkbox in error says so on its own socket: the rim round the socket's
// mouth turns ruby, by day and by night, as Material's box turns its error
// colour, and nothing stands between the socket and its words (a glyph used
// to sit beside it, widening the gap to the label).
// GlossScaffold is deprecated (GlossAppShell replaces it); tested until 0.7.0 removes it.
// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

final _shot = GlobalKey();

Future<void> _show(
  WidgetTester tester,
  Widget part, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  double width = 390,
  GlossThemeData? theme,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _shot,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, app) => GlossHost(
          theme: theme ?? GlossThemeData.light(),
          darkTheme: theme ?? GlossThemeData.dark(),
          brightness: brightness,
          child: Directionality(textDirection: direction, child: app!),
        ),
        home: GlossScaffold(
          body: Align(
            alignment: AlignmentDirectional.topStart,
            child: Padding(padding: const EdgeInsets.all(24), child: part),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<Color Function(Offset)> _picture(WidgetTester tester) async {
  final boundary =
      _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final (width, data) = (await tester.runAsync<(int, ByteData)>(() async {
    final image = await boundary.toImage();
    final bytes = (await image.toByteData())!;
    final width = image.width;
    image.dispose();
    return (width, bytes);
  }))!;
  return (Offset at) {
    final i = 4 * (at.dy.floor() * width + at.dx.floor());
    return Color.fromARGB(
      data.getUint8(i + 3),
      data.getUint8(i),
      data.getUint8(i + 1),
      data.getUint8(i + 2),
    );
  };
}

void main() {
  setUpAll(glossLoadFonts);

  for (final brightness in Brightness.values) {
    testWidgets('an erring checkbox rims its socket in ruby, $brightness', (
      tester,
    ) async {
      Future<Color> rim({required bool error}) async {
        await _show(
          tester,
          GlossCheckbox(value: false, isError: error, onChanged: (_) {}),
          brightness: brightness,
        );
        final box = tester.getRect(find.byType(GlossCheckbox));
        final socket = Rect.fromCenter(
          center: box.center,
          width: 24,
          height: 24,
        );
        final at = await _picture(tester);
        // The rim at the middle of the socket's start side.
        return at(Offset(socket.left + 0.5, socket.center.dy));
      }

      final plain = await rim(error: false);
      final erring = await rim(error: true);
      final ruby = brightness == Brightness.light
          ? GlossThemeData.light().colors.danger
          : GlossThemeData.dark().colors.danger;
      expect(
        (erring.r - erring.g) * 255,
        greaterThan(40),
        reason: 'the rim $erring is not ruby (plain $plain, ruby $ruby)',
      );
      expect((plain.r - plain.g).abs() * 255, lessThan(20));
      // The socket is all it draws: the same 40 slot as a plain one.
      expect(tester.getSize(find.byType(GlossCheckbox)), const Size(40, 40));
      expect(find.byType(Icon), findsNothing);
    });
  }
}
