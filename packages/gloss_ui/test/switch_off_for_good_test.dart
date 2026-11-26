// By night a switch that is off for good reads apart from one that is only
// switched off: its bead sinks halfway to the page, as a key off does,
// instead of shining as the moonlit bead a finger can move.
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
    testWidgets('a disabled switch dims its bead, $brightness', (tester) async {
      Future<double> bead({required bool enabled}) async {
        await _show(
          tester,
          GlossSwitch(value: false, onChanged: enabled ? (_) {} : null),
          brightness: brightness,
        );
        final box = tester.getRect(find.byType(GlossSwitch));
        final slot = Rect.fromCenter(center: box.center, width: 52, height: 30);
        final at = await _picture(tester);
        // The bead's middle: off, it sits at the start of the slot.
        return at(Offset(slot.left + 2 + 13, slot.center.dy))
            .computeLuminance();
      }

      final on = await bead(enabled: true);
      final off = await bead(enabled: false);
      expect(
        (on + .05) / (off + .05),
        greaterThanOrEqualTo(brightness == Brightness.dark ? 1.8 : 1.0),
        reason:
            'enabled bead ${on.toStringAsFixed(3)}, '
            'disabled ${off.toStringAsFixed(3)}',
      );
    });
  }
}
