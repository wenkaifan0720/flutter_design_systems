// A StudioSwipeRow on a StudioListGroup's pane is the pane's row: at rest
// the group looks as it does with plain rows, one pane of glass with its
// rules; dragged open, the row slides over the glass and its key stands in
// the metal it leaves, inside the pane's round outline.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:material_ui/material_ui.dart' show Icon, MaterialApp;

final _shot = GlobalKey();

Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary =
      _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

Widget _row(String title, {required bool swipe, VoidCallback? onDelete}) {
  final tile = StudioListTile(title: title, subtitle: 'Author', onTap: () {});
  if (!swipe) return tile;
  return StudioSwipeRow(
    endActions: [
      StudioSwipeAction(
        label: 'Delete',
        icon: const Icon(LucideIcons.trash2),
        destructive: true,
        onPressed: onDelete ?? () {},
      ),
    ],
    child: tile,
  );
}

Future<void> _group(
  WidgetTester tester, {
  required bool swipe,
  required Brightness brightness,
  VoidCallback? onDelete,
}) async {
  tester.view
    ..physicalSize = const Size(390, 420)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _shot,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            StudioHost(brightness: brightness, child: child!),
        home: StudioScreen(
          body: StudioListGroup(
            header: 'Books',
            children: [
              for (final title in ['Dune', 'Piranesi', 'Circe'])
                _row(title, swipe: swipe, onDelete: onDelete),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(studioLoadFonts);

  for (final brightness in Brightness.values) {
    testWidgets(
      'at rest a group of swipe rows is one pane (${brightness.name})',
      (tester) async {
        await _group(tester, swipe: false, brightness: brightness);
        final plain = await _pixels(tester);
        await _group(tester, swipe: true, brightness: brightness);
        expect(listEquals(plain, await _pixels(tester)), isTrue);
      },
    );
  }

  testWidgets("dragged open, the key stands inside the pane's outline", (
    tester,
  ) async {
    var deleted = 0;
    await _group(
      tester,
      swipe: true,
      brightness: Brightness.light,
      onDelete: () => deleted++,
    );
    final pane = tester.getRect(find.byType(StudioDisplay));
    await tester.drag(find.text('Piranesi'), const Offset(-110, 0));
    await tester.pumpAndSettle();
    final key = tester.getRect(find.text('Delete'));
    expect(
      pane.contains(key.topLeft) && pane.contains(key.bottomRight),
      isTrue,
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, 1);
  });
}
